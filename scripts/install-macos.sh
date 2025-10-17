#!/bin/bash

###############################################################################
# Script de Instalación Automática - Laboratorio WiFi Enterprise + RADIUS
# Plataforma: macOS (con UTM para virtualización)
# Versión: 1.0
###############################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

###############################################################################
# Variables
###############################################################################

UTM_VM_NAME="RADIUS-Server"
UBUNTU_ISO_URL="https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso"
UBUNTU_ISO_FILE="$HOME/Downloads/ubuntu-22.04.3-live-server-arm64.iso"
SCRIPTS_DIR="$HOME/radius-lab-scripts"
VM_IP="192.168.64.10"

###############################################################################
# Verificar arquitectura
###############################################################################

check_architecture() {
    print_header "Verificando Sistema"

    ARCH=$(uname -m)
    if [[ "$ARCH" != "arm64" ]]; then
        print_error "Este script está diseñado para Apple Silicon (M1/M2/M3/M4)"
        print_info "Arquitectura detectada: $ARCH"
        exit 1
    fi

    print_success "Apple Silicon detectado: $ARCH"

    OS_VERSION=$(sw_vers -productVersion)
    print_success "macOS version: $OS_VERSION"
}

###############################################################################
# Instalar Homebrew si no existe
###############################################################################

install_homebrew() {
    if ! command -v brew &> /dev/null; then
        print_info "Instalando Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Configurar PATH para Apple Silicon
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"

        print_success "Homebrew instalado"
    else
        print_success "Homebrew ya instalado"
    fi
}

###############################################################################
# Instalar herramientas necesarias
###############################################################################

install_tools() {
    print_header "PASO 1: Instalando Herramientas"

    # UTM (virtualización)
    if ! brew list --cask utm &> /dev/null; then
        print_info "Instalando UTM (virtualización)..."
        brew install --cask utm
        print_success "UTM instalado"
    else
        print_success "UTM ya instalado"
    fi

    # Wireshark
    if ! brew list --cask wireshark &> /dev/null; then
        print_info "Instalando Wireshark..."
        brew install --cask wireshark
        print_success "Wireshark instalado"
    else
        print_success "Wireshark ya instalado"
    fi

    # FreeRADIUS client tools
    if ! brew list freeradius-server &> /dev/null; then
        print_info "Instalando herramientas de cliente RADIUS..."
        brew install freeradius-server
        print_success "Herramientas RADIUS instaladas"
    else
        print_success "Herramientas RADIUS ya instaladas"
    fi

    # wget para descargas
    if ! command -v wget &> /dev/null; then
        brew install wget
    fi
}

###############################################################################
# Descargar Ubuntu Server ARM64
###############################################################################

download_ubuntu() {
    print_header "PASO 2: Descargando Ubuntu Server ARM64"

    if [ -f "$UBUNTU_ISO_FILE" ]; then
        print_success "ISO de Ubuntu ya descargada"
        return
    fi

    print_info "Descargando Ubuntu Server 22.04 ARM64..."
    print_info "Tamaño: ~1.5 GB - Esto puede tardar varios minutos..."

    cd ~/Downloads
    curl -L -o "$UBUNTU_ISO_FILE" "$UBUNTU_ISO_URL"

    if [ -f "$UBUNTU_ISO_FILE" ]; then
        print_success "Ubuntu Server descargado"
    else
        print_error "Error al descargar Ubuntu"
        exit 1
    fi
}

###############################################################################
# Crear scripts de configuración para VM
###############################################################################

create_vm_scripts() {
    print_header "PASO 3: Creando Scripts de Configuración"

    mkdir -p "$SCRIPTS_DIR"

    # Script de instalación para ejecutar DENTRO de la VM
    cat > "$SCRIPTS_DIR/install-in-vm.sh" << 'VMSCRIPT'
#!/bin/bash

# Este script se ejecuta DENTRO de la VM Ubuntu

set -e

echo "=== Instalando FreeRADIUS en VM ==="

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar FreeRADIUS y dependencias
sudo apt install -y \
    freeradius \
    freeradius-utils \
    freeradius-eap \
    openssl \
    net-tools \
    tcpdump

# Descargar script principal de Linux
cd /tmp
wget https://raw.githubusercontent.com/... # URL del script Linux

# O copiar desde shared folder si está disponible

echo "=== Instalación completada en VM ==="
echo "Próximo paso: ejecutar script de configuración"
VMSCRIPT

    chmod +x "$SCRIPTS_DIR/install-in-vm.sh"

    print_success "Scripts creados en: $SCRIPTS_DIR"
}

###############################################################################
# Instrucciones para crear VM en UTM
###############################################################################

create_utm_vm_instructions() {
    print_header "PASO 4: Crear VM en UTM"

    cat << EOF

${YELLOW}INSTRUCCIONES PARA CREAR VM EN UTM:${NC}

1. ${GREEN}Abrir UTM${NC}
   open -a UTM

2. ${GREEN}Crear Nueva VM${NC}
   - Click en "+" (esquina superior izquierda)
   - Seleccionar "Virtualize"
   - Seleccionar "Linux"

3. ${GREEN}Configuración:${NC}

   ${BLUE}Boot ISO Image:${NC}
   - Browse → Seleccionar: $UBUNTU_ISO_FILE

   ${BLUE}Hardware:${NC}
   - Memory: 4096 MB (4 GB)
   - CPU Cores: 2

   ${BLUE}Storage:${NC}
   - Size: 20 GB

   ${BLUE}Shared Directory (opcional):${NC}
   - Path: $SCRIPTS_DIR
   - Esto permite compartir archivos entre macOS y VM

   ${BLUE}Nombre:${NC}
   - VM Name: $UTM_VM_NAME

4. ${GREEN}Guardar${NC}
   - Click en "Save"

5. ${GREEN}Iniciar VM e Instalar Ubuntu${NC}
   - Click en ▶️ (Start)
   - Seguir instalación de Ubuntu:
     * Language: English
     * Network: DHCP (automático)
     * Storage: Use entire disk
     * Profile:
       - Name: admin
       - Server name: radius-server
       - Username: admin
       - Password: admin123
     * SSH: ${RED}IMPORTANTE - Habilitar OpenSSH Server${NC}
     * No featured snaps
   - Reboot

6. ${GREEN}Obtener IP de la VM${NC}
   - Login en VM: admin / admin123
   - Ejecutar: ip addr show
   - Anotar IP (normalmente 192.168.64.X)

EOF

    read -p "Presione Enter cuando la VM esté instalada y tenga IP..."

    echo ""
    read -p "Ingrese la IP de la VM (ej: 192.168.64.10): " VM_IP

    echo "$VM_IP" > "$SCRIPTS_DIR/vm-ip.txt"

    print_success "IP de VM guardada: $VM_IP"
}

###############################################################################
# Copiar e instalar en VM
###############################################################################

install_in_vm() {
    print_header "PASO 5: Instalando FreeRADIUS en VM"

    VM_IP=$(cat "$SCRIPTS_DIR/vm-ip.txt")

    print_info "Conectando a VM: $VM_IP"

    # Esperar a que SSH esté disponible
    print_info "Esperando a que SSH esté disponible..."
    for i in {1..30}; do
        if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no admin@$VM_IP "echo 'SSH OK'" &> /dev/null; then
            print_success "SSH disponible"
            break
        fi
        echo -n "."
        sleep 2
    done

    # Copiar script de instalación de Linux a la VM
    print_info "Copiando script de instalación a VM..."

    LINUX_SCRIPT="../install-linux.sh"

    if [ -f "$LINUX_SCRIPT" ]; then
        scp -o StrictHostKeyChecking=no "$LINUX_SCRIPT" admin@$VM_IP:/tmp/install.sh

        print_info "Ejecutando instalación en VM..."
        ssh -o StrictHostKeyChecking=no admin@$VM_IP "sudo bash /tmp/install.sh"

        print_success "Instalación completada en VM"
    else
        print_error "Script de instalación no encontrado: $LINUX_SCRIPT"
        print_info "Ejecutar manualmente en la VM:"
        echo "  ssh admin@$VM_IP"
        echo "  # Luego seguir instalación manual"
    fi
}

###############################################################################
# Configurar cliente macOS
###############################################################################

configure_macos_client() {
    print_header "PASO 6: Configurando Cliente macOS"

    VM_IP=$(cat "$SCRIPTS_DIR/vm-ip.txt")

    # Probar conectividad
    print_info "Probando conectividad con VM..."
    if ping -c 2 $VM_IP &> /dev/null; then
        print_success "Conectividad OK con VM"
    else
        print_error "No se puede alcanzar la VM"
        exit 1
    fi

    # Copiar certificados desde VM
    print_info "Copiando certificados desde VM..."

    mkdir -p ~/radius-certs

    scp -r admin@$VM_IP:/etc/ssl/radius-certs/ca/certs/ca.pem ~/radius-certs/
    scp -r admin@$VM_IP:/etc/ssl/radius-certs/clients/certs/*.p12 ~/radius-certs/

    print_success "Certificados copiados a: ~/radius-certs/"

    # Instalar CA en Keychain
    print_info "¿Desea instalar el certificado CA en Keychain? (s/N)"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/radius-certs/ca.pem
        print_success "CA instalada en Keychain"
    fi

    # Crear guía de importación de certificados
    cat > ~/radius-certs/INSTRUCCIONES.txt << EOF
═══════════════════════════════════════════════════════════════════
  INSTRUCCIONES - IMPORTAR CERTIFICADOS EN macOS
═══════════════════════════════════════════════════════════════════

CERTIFICADOS DISPONIBLES:

CA: ~/radius-certs/ca.pem
Clientes: ~/radius-certs/*.p12

═══════════════════════════════════════════════════════════════════
  IMPORTAR CERTIFICADO DE CLIENTE
═══════════════════════════════════════════════════════════════════

1. Doble click en archivo .p12 (ej: alumno1.p12)
2. Seleccionar Keychain: "login"
3. Password del certificado: <nombre-usuario>
   (ej: para alumno1.p12, password es: alumno1)
4. Click "OK"

O desde terminal:
  security import ~/radius-certs/alumno1.p12 -k ~/Library/Keychains/login.keychain-db

═══════════════════════════════════════════════════════════════════
  VERIFICAR CERTIFICADOS INSTALADOS
═══════════════════════════════════════════════════════════════════

Abrir "Keychain Access" (Acceso a Llaveros):
  Applications > Utilities > Keychain Access

Verificar:
  - Keychain "login" > Certificates
    Debe aparecer: alumno1, Mi Empresa CA

═══════════════════════════════════════════════════════════════════
  PROBAR AUTENTICACIÓN RADIUS DESDE macOS
═══════════════════════════════════════════════════════════════════

# Probar con radtest
radtest alumno1 password1 $VM_IP 0 testing123

# Debería mostrar:
# Received Access-Accept...

═══════════════════════════════════════════════════════════════════
  CAPTURAR TRÁFICO CON WIRESHARK
═══════════════════════════════════════════════════════════════════

1. Abrir Wireshark
2. Seleccionar interfaz: bridge100 (o la que use UTM)
3. Filtro de captura: udp port 1812
4. Start capture
5. En otra terminal:
   radtest alumno1 password1 $VM_IP 0 testing123
6. Ver paquetes RADIUS en Wireshark

═══════════════════════════════════════════════════════════════════
EOF

    print_success "Instrucciones creadas: ~/radius-certs/INSTRUCCIONES.txt"
}

###############################################################################
# Testing final
###############################################################################

test_from_macos() {
    print_header "PASO 7: Probando desde macOS"

    VM_IP=$(cat "$SCRIPTS_DIR/vm-ip.txt")

    print_info "Probando autenticación RADIUS desde macOS..."

    # Verificar que radtest está disponible
    if ! command -v radtest &> /dev/null; then
        print_error "radtest no encontrado"
        print_info "Instalar con: brew install freeradius-server"
        return
    fi

    # Probar autenticación
    print_info "Ejecutando: radtest testuser testpass $VM_IP 0 testing123"

    if radtest testuser testpass $VM_IP 0 testing123 | grep -q "Access-Accept"; then
        print_success "Autenticación exitosa desde macOS"
    else
        print_error "Autenticación fallida"
        print_info "Verificar que FreeRADIUS esté corriendo en VM:"
        echo "  ssh admin@$VM_IP 'sudo systemctl status freeradius'"
    fi
}

###############################################################################
# Crear documentación final
###############################################################################

create_final_documentation() {
    print_header "PASO 8: Documentación Final"

    VM_IP=$(cat "$SCRIPTS_DIR/vm-ip.txt" 2>/dev/null || echo "192.168.64.10")

    DOC_FILE="$HOME/LABORATORIO_MACOS_README.txt"

    cat > "$DOC_FILE" << EOF
═══════════════════════════════════════════════════════════════════
  LABORATORIO WIFI ENTERPRISE + RADIUS - macOS con UTM
═══════════════════════════════════════════════════════════════════

FECHA: $(date)
SISTEMA: macOS $(sw_vers -productVersion)
ARQUITECTURA: $(uname -m)

═══════════════════════════════════════════════════════════════════
  COMPONENTES INSTALADOS
═══════════════════════════════════════════════════════════════════

✓ UTM (virtualización)
✓ VM Ubuntu Server 22.04 ARM64
✓ FreeRADIUS en VM
✓ Wireshark
✓ Herramientas cliente RADIUS

═══════════════════════════════════════════════════════════════════
  INFORMACIÓN DE LA VM
═══════════════════════════════════════════════════════════════════

Nombre VM: $UTM_VM_NAME
IP: $VM_IP
Usuario: admin
Password: admin123

Conectar por SSH:
  ssh admin@$VM_IP

═══════════════════════════════════════════════════════════════════
  SERVIDOR RADIUS
═══════════════════════════════════════════════════════════════════

IP: $VM_IP
Puerto Auth: 1812/udp
Puerto Acct: 1813/udp
Shared Secret: SuperSecretRADIUS2024!

═══════════════════════════════════════════════════════════════════
  USUARIOS CONFIGURADOS
═══════════════════════════════════════════════════════════════════

alumno1 / password1 → VLAN 10
alumno2 / password2 → VLAN 10
director / password3 → VLAN 20
invitado / guest123 → VLAN 30
testuser / testpass → (sin VLAN)

═══════════════════════════════════════════════════════════════════
  CERTIFICADOS
═══════════════════════════════════════════════════════════════════

Ubicación en macOS: ~/radius-certs/

- ca.pem: Certificado de CA
- alumno1.p12: Certificado de alumno1 (password: alumno1)
- alumno2.p12: Certificado de alumno2 (password: alumno2)
- director.p12: Certificado de director (password: director)
- invitado.p12: Certificado de invitado (password: invitado)

Importar en Keychain:
  Doble click en archivo .p12

═══════════════════════════════════════════════════════════════════
  COMANDOS ÚTILES
═══════════════════════════════════════════════════════════════════

# DESDE macOS:

# Probar autenticación
radtest alumno1 password1 $VM_IP 0 testing123

# Capturar tráfico RADIUS
sudo tcpdump -i bridge100 port 1812 -w ~/Desktop/radius.pcap

# Abrir captura en Wireshark
wireshark ~/Desktop/radius.pcap

# Conectar a VM
ssh admin@$VM_IP

# DESDE LA VM (después de SSH):

# Ver estado de FreeRADIUS
sudo systemctl status freeradius

# Modo debug
sudo systemctl stop freeradius
sudo freeradius -X

# Ver logs
sudo tail -f /var/log/freeradius/radius.log

# Ver documentación completa
cat /root/LABORATORIO_README.txt

═══════════════════════════════════════════════════════════════════
  INICIAR/DETENER LABORATORIO
═══════════════════════════════════════════════════════════════════

Iniciar:
  1. Abrir UTM
  2. Seleccionar VM "$UTM_VM_NAME"
  3. Click en ▶️ Start
  4. Esperar 30 segundos
  5. Probar: ping $VM_IP

Detener:
  1. En UTM: Click en ⏹ Stop
  O desde terminal: ssh admin@$VM_IP 'sudo shutdown -h now'

═══════════════════════════════════════════════════════════════════
  DEMO PARA CLASE
═══════════════════════════════════════════════════════════════════

Terminal 1 - RADIUS Debug:
  ssh admin@$VM_IP
  sudo freeradius -X

Terminal 2 - Ejecutar autenticación:
  radtest alumno1 password1 $VM_IP 0 testing123

Terminal 3 - Wireshark:
  wireshark -i bridge100 -k -f "udp port 1812"

Proyectar pantalla dividida mostrando las 3 ventanas.

═══════════════════════════════════════════════════════════════════
  CAPTURA DE TRÁFICO PARA ANÁLISIS
═══════════════════════════════════════════════════════════════════

1. Iniciar captura:
   sudo tcpdump -i bridge100 port 1812 -w ~/Desktop/clase.pcap

2. Ejecutar autenticación:
   radtest alumno1 password1 $VM_IP 0 testing123

3. Detener captura (Ctrl+C)

4. Analizar:
   wireshark ~/Desktop/clase.pcap

Filtros útiles en Wireshark:
  - radius
  - radius.code == 1  (Access-Request)
  - radius.code == 2  (Access-Accept)
  - radius.Tunnel-Private-Group-Id  (Ver VLAN)

═══════════════════════════════════════════════════════════════════
  TROUBLESHOOTING
═══════════════════════════════════════════════════════════════════

Problema: No puedo hacer ping a VM
  - Verificar VM está iniciada en UTM
  - Verificar IP: ssh admin@$VM_IP 'ip addr show'
  - Probar red UTM: Settings > Network

Problema: FreeRADIUS no responde
  - SSH a VM: ssh admin@$VM_IP
  - Ver status: sudo systemctl status freeradius
  - Ver logs: sudo journalctl -u freeradius -n 50

Problema: radtest no encontrado en macOS
  - Instalar: brew install freeradius-server

Problema: Wireshark no captura tráfico
  - Identificar interfaz correcta: ifconfig | grep bridge
  - Usar esa interfaz en Wireshark

═══════════════════════════════════════════════════════════════════
  RECURSOS ADICIONALES
═══════════════════════════════════════════════════════════════════

Material completo del TP:
  ~/TP_WiFi_Enterprise_RADIUS/

Instrucciones certificados:
  ~/radius-certs/INSTRUCCIONES.txt

Scripts de configuración:
  $SCRIPTS_DIR/

═══════════════════════════════════════════════════════════════════
EOF

    print_success "Documentación creada: $DOC_FILE"

    # Mostrar resumen
    cat "$DOC_FILE"
}

###############################################################################
# Main
###############################################################################

main() {
    clear

    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   INSTALADOR AUTOMÁTICO - LABORATORIO WIFI ENTERPRISE + RADIUS   ║
║                                                                   ║
║   Plataforma: macOS (Apple Silicon con UTM)                      ║
║   Versión: 1.0                                                   ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF

    echo ""
    print_info "Este script instalará:"
    echo "  • UTM (virtualización para Apple Silicon)"
    echo "  • VM Ubuntu Server 22.04 ARM64"
    echo "  • FreeRADIUS en la VM"
    echo "  • Wireshark para análisis"
    echo "  • Herramientas cliente RADIUS"
    echo ""

    read -p "¿Desea continuar? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_info "Instalación cancelada"
        exit 0
    fi

    check_architecture
    install_homebrew
    install_tools
    download_ubuntu
    create_vm_scripts
    create_utm_vm_instructions

    # Opciones para continuar
    echo ""
    print_info "La VM debe estar instalada y corriendo para continuar."
    echo ""
    echo "Opciones:"
    echo "  1. Ya instalé la VM, continuar con instalación de RADIUS"
    echo "  2. Salir y continuar manualmente después"
    echo ""
    read -p "Seleccione opción (1/2): " -n 1 -r
    echo

    if [[ $REPLY == "1" ]]; then
        install_in_vm
        configure_macos_client
        test_from_macos
        create_final_documentation

        print_header "INSTALACIÓN COMPLETADA"
        print_success "Laboratorio WiFi Enterprise + RADIUS instalado exitosamente"
        echo ""
        print_info "Documentación: cat ~/LABORATORIO_MACOS_README.txt"
        print_info "Probar: radtest testuser testpass $VM_IP 0 testing123"
    else
        print_info "Para continuar después:"
        echo "  1. Instalar VM en UTM siguiendo instrucciones"
        echo "  2. Ejecutar: bash $SCRIPTS_DIR/install-in-vm.sh"
    fi
}

main "$@"
