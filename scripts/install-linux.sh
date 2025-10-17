#!/bin/bash

###############################################################################
# Script de Instalación Automática - Laboratorio WiFi Enterprise + RADIUS
# Plataforma: Linux (Ubuntu/Debian)
# Versión: 1.0
###############################################################################

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuración
RADIUS_IP="127.0.0.1"
SHARED_SECRET="SuperSecretRADIUS2024!"
ORG_NAME="Mi Empresa SA"
COUNTRY="AR"
STATE="Buenos Aires"
CITY="CABA"

# Usuarios de prueba
declare -A USERS=(
    ["alumno1"]="password1:10"  # usuario:password:vlan
    ["alumno2"]="password2:10"
    ["director"]="password3:20"
    ["invitado"]="guest123:30"
)

###############################################################################
# Funciones auxiliares
###############################################################################

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root (sudo)"
        exit 1
    fi
}

###############################################################################
# Instalación de dependencias
###############################################################################

install_dependencies() {
    print_header "PASO 1: Instalando Dependencias"

    print_info "Actualizando repositorios..."
    apt update -qq

    print_info "Instalando paquetes necesarios..."
    DEBIAN_FRONTEND=noninteractive apt install -y \
        freeradius \
        freeradius-utils \
        freeradius-eap \
        openssl \
        net-tools \
        tcpdump \
        wireshark \
        tshark \
        wpasupplicant \
        hostapd \
        nano \
        curl \
        wget \
        git \
        > /dev/null 2>&1

    print_success "Dependencias instaladas"
}

###############################################################################
# Configuración de FreeRADIUS
###############################################################################

configure_freeradius() {
    print_header "PASO 2: Configurando FreeRADIUS"

    # Detener servicio
    systemctl stop freeradius 2>/dev/null || true

    # Backup de configuración original
    if [ ! -d /etc/freeradius/3.0.backup ]; then
        print_info "Creando backup de configuración original..."
        cp -r /etc/freeradius/3.0 /etc/freeradius/3.0.backup
    fi

    # Configurar clientes RADIUS
    print_info "Configurando clientes RADIUS..."
    cat > /etc/freeradius/3.0/clients.conf << EOF
# Cliente localhost para testing
client localhost {
    ipaddr = 127.0.0.1
    secret = testing123
    shortname = localhost
    nastype = other
}

# Cliente de red local
client localnet {
    ipaddr = 192.168.0.0/16
    secret = $SHARED_SECRET
    shortname = local-network
    nastype = other
}

# Cliente para Access Point simulado
client hostapd {
    ipaddr = 127.0.0.1
    secret = $SHARED_SECRET
    shortname = hostapd-ap
    nastype = other
}
EOF

    # Configurar usuarios
    print_info "Configurando usuarios de prueba..."
    cat > /etc/freeradius/3.0/users << 'EOF'
# Usuarios de prueba con VLANs dinámicas

alumno1 Cleartext-Password := "password1"
    Reply-Message = "Bienvenido Alumno 1",
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 10

alumno2 Cleartext-Password := "password2"
    Reply-Message = "Bienvenido Alumno 2",
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 10

director Cleartext-Password := "password3"
    Reply-Message = "Bienvenido Director",
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 20,
    Session-Timeout = 28800

invitado Cleartext-Password := "guest123"
    Reply-Message = "Acceso de Invitado",
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 30,
    Session-Timeout = 3600,
    Idle-Timeout = 600

# Usuario de test
testuser Cleartext-Password := "testpass"
    Reply-Message = "Test User Authentication OK"

# DEFAULT - rechazar usuarios no definidos
DEFAULT Auth-Type := Reject
    Reply-Message = "Usuario no autorizado"
EOF

    # Habilitar módulo EAP
    print_info "Habilitando módulo EAP..."
    ln -sf /etc/freeradius/3.0/mods-available/eap /etc/freeradius/3.0/mods-enabled/eap 2>/dev/null || true

    # Ajustar permisos
    chown -R freerad:freerad /etc/freeradius/3.0/

    print_success "FreeRADIUS configurado"
}

###############################################################################
# Generación de certificados
###############################################################################

generate_certificates() {
    print_header "PASO 3: Generando Certificados PKI"

    CERT_DIR="/etc/ssl/radius-certs"

    # Crear estructura de directorios
    print_info "Creando estructura de directorios..."
    mkdir -p $CERT_DIR/{ca,server,clients}/{private,certs,csr}
    chmod 700 $CERT_DIR/*/private

    cd $CERT_DIR

    # Crear configuración de OpenSSL
    print_info "Creando configuración de OpenSSL..."
    cat > ca.cnf << EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir              = $CERT_DIR/ca
certs            = \$dir/certs
new_certs_dir    = \$dir/certs
database         = \$dir/index.txt
serial           = \$dir/serial
private_key      = \$dir/private/ca.key
certificate      = \$dir/certs/ca.pem
default_md       = sha256
default_days     = 365
preserve         = no
policy           = policy_match

[ policy_match ]
countryName             = match
stateOrProvinceName     = optional
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 2048
distinguished_name  = req_distinguished_name
x509_extensions     = v3_ca
string_mask         = utf8only

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = $COUNTRY
stateOrProvinceName             = State or Province Name
stateOrProvinceName_default     = $STATE
localityName                    = Locality Name
localityName_default            = $CITY
0.organizationName              = Organization Name
0.organizationName_default      = $ORG_NAME
commonName                      = Common Name
commonName_max                  = 64

[ v3_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical,CA:true
keyUsage               = critical, digitalSignature, cRLSign, keyCertSign

[ server_cert ]
basicConstraints       = CA:FALSE
nsCertType             = server
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage               = critical, digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth, 1.3.6.1.5.5.7.3.13

[ client_cert ]
basicConstraints       = CA:FALSE
nsCertType             = client, email
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
keyUsage               = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage       = clientAuth, emailProtection
EOF

    # Inicializar base de datos de CA
    touch ca/index.txt
    echo 1000 > ca/serial

    # Generar CA
    print_info "Generando Certificado de CA..."
    openssl genrsa -out ca/private/ca.key 4096 2>/dev/null
    openssl req -config ca.cnf \
        -key ca/private/ca.key \
        -new -x509 -days 3650 -sha256 \
        -extensions v3_ca \
        -out ca/certs/ca.pem \
        -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG_NAME/CN=$ORG_NAME CA" \
        2>/dev/null

    print_success "CA generada"

    # Generar certificado del servidor RADIUS
    print_info "Generando certificado del servidor RADIUS..."
    openssl genrsa -out server/private/server.key 2048 2>/dev/null
    openssl req -config ca.cnf \
        -key server/private/server.key \
        -new -sha256 \
        -out server/csr/server.csr \
        -subj "/C=$COUNTRY/ST=$STATE/O=$ORG_NAME/CN=radius.empresa.local" \
        2>/dev/null

    openssl ca -config ca.cnf \
        -extensions server_cert \
        -days 730 -notext -md sha256 \
        -in server/csr/server.csr \
        -out server/certs/server.pem \
        -batch \
        2>/dev/null

    print_success "Certificado de servidor generado"

    # Generar certificados de clientes
    print_info "Generando certificados de clientes..."
    for username in "${!USERS[@]}"; do
        # Extraer password (no usado para certificado, solo para referencia)
        IFS=':' read -r password vlan <<< "${USERS[$username]}"

        # Generar clave privada
        openssl genrsa -out clients/private/$username.key 2048 2>/dev/null

        # Generar CSR
        openssl req -config ca.cnf \
            -key clients/private/$username.key \
            -new -sha256 \
            -out clients/csr/$username.csr \
            -subj "/C=$COUNTRY/ST=$STATE/O=$ORG_NAME/CN=$username" \
            2>/dev/null

        # Firmar con CA
        openssl ca -config ca.cnf \
            -extensions client_cert \
            -days 365 -notext -md sha256 \
            -in clients/csr/$username.csr \
            -out clients/certs/$username.pem \
            -batch \
            2>/dev/null

        # Crear bundle PKCS#12
        openssl pkcs12 -export \
            -out clients/certs/$username.p12 \
            -inkey clients/private/$username.key \
            -in clients/certs/$username.pem \
            -certfile ca/certs/ca.pem \
            -passout pass:$username \
            2>/dev/null

        print_success "Certificado generado para: $username"
    done

    # Generar parámetros DH
    print_info "Generando parámetros Diffie-Hellman (esto puede tardar)..."
    openssl dhparam -out dh 2048 2>/dev/null

    # Copiar certificados a FreeRADIUS
    print_info "Instalando certificados en FreeRADIUS..."
    cp ca/certs/ca.pem /etc/freeradius/3.0/certs/
    cp server/certs/server.pem /etc/freeradius/3.0/certs/
    cp server/private/server.key /etc/freeradius/3.0/certs/
    cp dh /etc/freeradius/3.0/certs/

    # Ajustar permisos
    chown -R freerad:freerad /etc/freeradius/3.0/certs/
    chmod 640 /etc/freeradius/3.0/certs/*
    chmod 600 /etc/freeradius/3.0/certs/server.key

    print_success "Certificados instalados en FreeRADIUS"
}

###############################################################################
# Configuración de EAP
###############################################################################

configure_eap() {
    print_header "PASO 4: Configurando EAP-TLS"

    print_info "Configurando módulo EAP..."

    # Backup del archivo original
    cp /etc/freeradius/3.0/mods-available/eap /etc/freeradius/3.0/mods-available/eap.backup

    # Configurar EAP
    cat > /etc/freeradius/3.0/mods-available/eap << 'EOF'
eap {
    default_eap_type = tls
    timer_expire = 60
    ignore_unknown_eap_types = no
    cisco_accounting_username_bug = no
    max_sessions = ${max_requests}

    tls-config tls-common {
        private_key_password = whatever
        private_key_file = ${certdir}/server.key
        certificate_file = ${certdir}/server.pem
        ca_file = ${cadir}/ca.pem
        dh_file = ${certdir}/dh
        ca_path = ${cadir}
        cipher_list = "HIGH"
        cipher_server_preference = no
        tls_min_version = "1.2"
        tls_max_version = "1.3"

        # Validar certificados de clientes
        verify_client_cert = yes

        cache {
            enable = yes
            lifetime = 24
            max_entries = 255
        }

        verify {
            skip_if_ocsp_ok = no
        }

        ocsp {
            enable = no
            override_cert_url = yes
            url = "http://127.0.0.1/ocsp/"
        }
    }

    tls {
        tls = tls-common
        include_length = yes
        auto_chain = yes
    }

    ttls {
        tls = tls-common
        default_eap_type = md5
        copy_request_to_tunnel = no
        use_tunneled_reply = no
        virtual_server = "inner-tunnel"
    }

    peap {
        tls = tls-common
        default_eap_type = mschapv2
        copy_request_to_tunnel = no
        use_tunneled_reply = no
        virtual_server = "inner-tunnel"
        soh = no
        require_client_cert = no
    }

    mschapv2 {
        send_error = no
    }
}
EOF

    print_success "EAP configurado"
}

###############################################################################
# Iniciar servicios
###############################################################################

start_services() {
    print_header "PASO 5: Iniciando Servicios"

    print_info "Verificando configuración de FreeRADIUS..."
    if freeradius -CX >/dev/null 2>&1; then
        print_success "Configuración válida"
    else
        print_error "Error en configuración de FreeRADIUS"
        print_info "Ejecute: sudo freeradius -X para ver detalles"
        exit 1
    fi

    print_info "Iniciando FreeRADIUS..."
    systemctl enable freeradius
    systemctl restart freeradius

    sleep 2

    if systemctl is-active --quiet freeradius; then
        print_success "FreeRADIUS iniciado correctamente"
    else
        print_error "FreeRADIUS no pudo iniciarse"
        print_info "Ver logs: sudo journalctl -u freeradius -n 50"
        exit 1
    fi
}

###############################################################################
# Testing
###############################################################################

test_installation() {
    print_header "PASO 6: Probando Instalación"

    print_info "Probando autenticación con usuario 'testuser'..."

    result=$(radtest testuser testpass localhost 0 testing123 2>&1)

    if echo "$result" | grep -q "Access-Accept"; then
        print_success "Autenticación exitosa - FreeRADIUS funcionando correctamente"
    else
        print_error "Autenticación fallida"
        echo "$result"
        exit 1
    fi

    print_info "Probando usuarios con VLANs..."

    for username in "${!USERS[@]}"; do
        IFS=':' read -r password vlan <<< "${USERS[$username]}"

        result=$(radtest $username $password localhost 0 testing123 2>&1)

        if echo "$result" | grep -q "Access-Accept"; then
            print_success "Usuario $username - OK (VLAN $vlan)"
        else
            print_error "Usuario $username - FALLÓ"
        fi
    done
}

###############################################################################
# Crear archivos de configuración de cliente
###############################################################################

create_client_configs() {
    print_header "PASO 7: Creando Configuraciones de Cliente"

    CONFIG_DIR="/root/radius-lab-configs"
    mkdir -p $CONFIG_DIR

    # Crear configuración wpa_supplicant para cada usuario
    for username in "${!USERS[@]}"; do
        cat > $CONFIG_DIR/wpa-$username.conf << EOF
network={
    ssid="WiFi-LAB"
    key_mgmt=WPA-EAP
    eap=TLS
    identity="$username@empresa.local"

    ca_cert="/etc/ssl/radius-certs/ca/certs/ca.pem"
    client_cert="/etc/ssl/radius-certs/clients/certs/$username.pem"
    private_key="/etc/ssl/radius-certs/clients/private/$username.key"
}
EOF
        print_success "Configuración creada: wpa-$username.conf"
    done

    # Crear script de prueba con eapol_test
    cat > $CONFIG_DIR/test-eap.sh << 'EOF'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Uso: $0 <usuario>"
    echo "Usuarios disponibles: alumno1, alumno2, director, invitado"
    exit 1
fi

USERNAME=$1
CONFIG="/root/radius-lab-configs/wpa-$USERNAME.conf"

if [ ! -f "$CONFIG" ]; then
    echo "Error: Configuración no encontrada para $USERNAME"
    exit 1
fi

echo "Probando autenticación EAP-TLS para: $USERNAME"
eapol_test -c $CONFIG -a 127.0.0.1 -p 1812 -s testing123
EOF

    chmod +x $CONFIG_DIR/test-eap.sh

    print_success "Scripts de prueba creados en $CONFIG_DIR"
}

###############################################################################
# Crear documentación
###############################################################################

create_documentation() {
    print_header "PASO 8: Generando Documentación"

    DOC_FILE="/root/LABORATORIO_README.txt"

    cat > $DOC_FILE << EOF
═══════════════════════════════════════════════════════════════════
  LABORATORIO WIFI ENTERPRISE + RADIUS - INSTALACIÓN COMPLETADA
═══════════════════════════════════════════════════════════════════

FECHA DE INSTALACIÓN: $(date)
HOSTNAME: $(hostname)

═══════════════════════════════════════════════════════════════════
  INFORMACIÓN DEL SERVIDOR RADIUS
═══════════════════════════════════════════════════════════════════

IP del Servidor: $(hostname -I | awk '{print $1}')
Puerto Auth: 1812/udp
Puerto Acct: 1813/udp
Shared Secret: $SHARED_SECRET

Estado del servicio:
$(systemctl status freeradius --no-pager | head -5)

═══════════════════════════════════════════════════════════════════
  USUARIOS CONFIGURADOS
═══════════════════════════════════════════════════════════════════

EOF

    for username in "${!USERS[@]}"; do
        IFS=':' read -r password vlan <<< "${USERS[$username]}"
        echo "Usuario: $username" >> $DOC_FILE
        echo "  Password: $password" >> $DOC_FILE
        echo "  VLAN: $vlan" >> $DOC_FILE
        echo "  Certificado: /etc/ssl/radius-certs/clients/certs/$username.p12" >> $DOC_FILE
        echo "  Password del .p12: $username" >> $DOC_FILE
        echo "" >> $DOC_FILE
    done

    cat >> $DOC_FILE << 'EOF'

═══════════════════════════════════════════════════════════════════
  CERTIFICADOS GENERADOS
═══════════════════════════════════════════════════════════════════

CA Raíz:
  /etc/ssl/radius-certs/ca/certs/ca.pem

Servidor RADIUS:
  Certificado: /etc/ssl/radius-certs/server/certs/server.pem
  Clave: /etc/ssl/radius-certs/server/private/server.key

Clientes:
  Directorio: /etc/ssl/radius-certs/clients/certs/
  Formato PKCS#12: *.p12 (para importar en dispositivos)

═══════════════════════════════════════════════════════════════════
  COMANDOS ÚTILES
═══════════════════════════════════════════════════════════════════

# Ver estado de FreeRADIUS
sudo systemctl status freeradius

# Ver logs en tiempo real
sudo tail -f /var/log/freeradius/radius.log

# Modo debug (ver autenticaciones en detalle)
sudo systemctl stop freeradius
sudo freeradius -X

# Probar autenticación (simple)
radtest testuser testpass localhost 0 testing123

# Probar autenticación con VLAN
radtest alumno1 password1 localhost 0 testing123

# Ver usuarios conectados
radwho

# Capturar tráfico RADIUS
sudo tcpdump -i any port 1812 or port 1813 -w radius.pcap

# Analizar captura
wireshark radius.pcap

═══════════════════════════════════════════════════════════════════
  CONFIGURACIÓN DE CLIENTES
═══════════════════════════════════════════════════════════════════

Configuraciones wpa_supplicant generadas en:
  /root/radius-lab-configs/wpa-*.conf

Script de prueba EAP-TLS:
  /root/radius-lab-configs/test-eap.sh alumno1

═══════════════════════════════════════════════════════════════════
  PRÓXIMOS PASOS
═══════════════════════════════════════════════════════════════════

1. Probar autenticación:
   radtest alumno1 password1 localhost 0 testing123

2. Ver logs en modo debug:
   sudo systemctl stop freeradius
   sudo freeradius -X

   En otra terminal:
   radtest alumno1 password1 localhost 0 testing123

3. Capturar tráfico RADIUS:
   sudo tcpdump -i lo port 1812 -w /tmp/radius.pcap
   radtest alumno1 password1 localhost 0 testing123
   wireshark /tmp/radius.pcap

4. Exportar certificados para clientes:
   # Copiar a dispositivos Windows/Mac/Android
   scp /etc/ssl/radius-certs/clients/certs/alumno1.p12 usuario@cliente:/destino/

5. Configurar Access Point real:
   SSID: WiFi-LAB
   Seguridad: WPA2-Enterprise
   RADIUS Server: <IP de este servidor>
   RADIUS Port: 1812
   RADIUS Secret: $SHARED_SECRET

═══════════════════════════════════════════════════════════════════
  ARCHIVOS DE CONFIGURACIÓN IMPORTANTES
═══════════════════════════════════════════════════════════════════

/etc/freeradius/3.0/clients.conf    - Clientes RADIUS (APs)
/etc/freeradius/3.0/users           - Usuarios y VLANs
/etc/freeradius/3.0/mods-available/eap  - Configuración EAP
/etc/ssl/radius-certs/              - Todos los certificados

Backup original:
/etc/freeradius/3.0.backup/

═══════════════════════════════════════════════════════════════════
  TROUBLESHOOTING
═══════════════════════════════════════════════════════════════════

Problema: FreeRADIUS no inicia
Solución: sudo freeradius -X
         (ver errores de configuración)

Problema: Autenticación falla
Solución: sudo freeradius -X
         radtest usuario password localhost 0 testing123
         (ver logs detallados)

Problema: "Unknown client"
Solución: Verificar /etc/freeradius/3.0/clients.conf
         Verificar shared secret coincide

Problema: "Certificate expired"
Solución: Regenerar certificados
         cd /etc/ssl/radius-certs
         (ejecutar comandos de generación)

═══════════════════════════════════════════════════════════════════
  SOPORTE
═══════════════════════════════════════════════════════════════════

Documentación FreeRADIUS: https://wiki.freeradius.org/
Material completo del TP: /root/TP_WiFi_Enterprise_RADIUS/

═══════════════════════════════════════════════════════════════════
EOF

    print_success "Documentación generada: $DOC_FILE"

    # Mostrar resumen
    cat $DOC_FILE
}

###############################################################################
# Función principal
###############################################################################

main() {
    clear

    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   INSTALADOR AUTOMÁTICO - LABORATORIO WIFI ENTERPRISE + RADIUS   ║
║                                                                   ║
║   Plataforma: Linux (Ubuntu/Debian)                              ║
║   Versión: 1.0                                                   ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF

    echo ""
    print_info "Este script instalará y configurará:"
    echo "  • FreeRADIUS con EAP-TLS"
    echo "  • Infraestructura PKI (CA + certificados)"
    echo "  • 4 usuarios de prueba con VLANs"
    echo "  • Herramientas de testing"
    echo ""

    read -p "¿Desea continuar? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_info "Instalación cancelada"
        exit 0
    fi

    check_root

    # Ejecutar pasos
    install_dependencies
    configure_freeradius
    generate_certificates
    configure_eap
    start_services
    test_installation
    create_client_configs
    create_documentation

    # Resumen final
    print_header "INSTALACIÓN COMPLETADA"

    print_success "Laboratorio WiFi Enterprise + RADIUS instalado exitosamente"
    echo ""
    print_info "Documentación completa en: /root/LABORATORIO_README.txt"
    print_info "Configuraciones de cliente en: /root/radius-lab-configs/"
    echo ""
    print_info "Próximos pasos:"
    echo "  1. Revisar: cat /root/LABORATORIO_README.txt"
    echo "  2. Probar: radtest alumno1 password1 localhost 0 testing123"
    echo "  3. Debug: sudo freeradius -X"
    echo ""
}

# Ejecutar
main "$@"
