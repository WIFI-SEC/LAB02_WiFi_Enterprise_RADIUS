# Generación y Gestión de Certificados X.509

## Introducción

En esta sección crearemos una infraestructura PKI (Public Key Infrastructure) completa para soportar autenticación EAP-TLS. Generaremos:

1. **Certificado CA** (Certificate Authority) - Autoridad raíz
2. **Certificado del Servidor RADIUS**
3. **Certificados de Clientes** (usuarios/dispositivos)

---

## 1. Conceptos de PKI

### 1.1 Jerarquía de Certificados

```
┌─────────────────────────────────────┐
│      Certificado CA (Root)          │
│  - Auto-firmado                     │
│  - Válido por 10 años               │
│  - Firma otros certificados         │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌──────▼──────────┐
│  Servidor   │  │    Clientes     │
│   RADIUS    │  │  (usuarios)     │
│             │  │                 │
│ CN=radius   │  │ CN=jperez       │
│ Válido 2    │  │ CN=mbianchi     │
│ años        │  │ Válido 1 año    │
└─────────────┘  └─────────────────┘
```

### 1.2 Componentes de un Certificado X.509

- **Subject**: Identidad del propietario (CN, O, OU, C)
- **Issuer**: Quién firmó el certificado (CA)
- **Public Key**: Clave pública para cifrado
- **Private Key**: Clave privada (debe protegerse)
- **Validity**: Fechas de validez (NotBefore, NotAfter)
- **Extensions**: Uso de la clave, SAN, etc.

---

## 2. Preparación del Entorno

### 2.1 Instalación de OpenSSL

```bash
# Verificar versión de OpenSSL
openssl version

# Debería mostrar: OpenSSL 3.0.x o superior

# Crear directorio de trabajo
sudo mkdir -p /etc/ssl/radius-certs
cd /etc/ssl/radius-certs

# Crear estructura de directorios
sudo mkdir -p {ca,server,clients}/{private,certs,csr}
sudo chmod 700 */private
```

### 2.2 Estructura de directorios

```
/etc/ssl/radius-certs/
├── ca/
│   ├── private/        # Clave privada de CA (protegida)
│   ├── certs/          # Certificado CA público
│   └── index.txt       # Base de datos de certificados firmados
├── server/
│   ├── private/        # Clave privada del servidor
│   ├── certs/          # Certificado del servidor
│   └── csr/            # Certificate Signing Request
└── clients/
    ├── private/        # Claves privadas de clientes
    ├── certs/          # Certificados de clientes
    └── csr/            # CSRs de clientes
```

---

## 3. Generación del Certificado CA (Autoridad Raíz)

### 3.1 Crear archivo de configuración OpenSSL

```bash
sudo nano /etc/ssl/radius-certs/ca.cnf
```

**Contenido del archivo `ca.cnf`:**

```ini
[ ca ]
default_ca = CA_default

[ CA_default ]
dir              = /etc/ssl/radius-certs/ca
certs            = $dir/certs
crl_dir          = $dir/crl
new_certs_dir    = $dir/certs
database         = $dir/index.txt
serial           = $dir/serial
RANDFILE         = $dir/private/.rand

# Certificado y clave de la CA
certificate      = $dir/certs/ca.pem
private_key      = $dir/private/ca.key

# Política de nombres
name_opt         = ca_default
cert_opt         = ca_default
default_days     = 365
default_crl_days = 30
default_md       = sha256
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
default_keyfile     = privkey.pem
distinguished_name  = req_distinguished_name
attributes          = req_attributes
x509_extensions     = v3_ca
string_mask         = utf8only

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = AR
countryName_min                 = 2
countryName_max                 = 2

stateOrProvinceName             = State or Province Name
stateOrProvinceName_default     = Buenos Aires

localityName                    = Locality Name
localityName_default            = CABA

0.organizationName              = Organization Name
0.organizationName_default      = Mi Empresa SA

organizationalUnitName          = Organizational Unit Name
organizationalUnitName_default  = IT Security

commonName                      = Common Name
commonName_max                  = 64

emailAddress                    = Email Address
emailAddress_max                = 64

[ req_attributes ]
challengePassword              = A challenge password
challengePassword_min          = 4
challengePassword_max          = 20

[ v3_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical,CA:true
keyUsage               = critical, digitalSignature, cRLSign, keyCertSign

[ v3_req ]
basicConstraints       = CA:FALSE
keyUsage               = nonRepudiation, digitalSignature, keyEncipherment

[ server_cert ]
basicConstraints       = CA:FALSE
nsCertType             = server
nsComment              = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage               = critical, digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth, 1.3.6.1.5.5.7.3.13
subjectAltName         = @alt_names

[ client_cert ]
basicConstraints       = CA:FALSE
nsCertType             = client, email
nsComment              = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
keyUsage               = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage       = clientAuth, emailProtection

[ alt_names ]
DNS.1 = radius.empresa.local
DNS.2 = radius
IP.1  = 192.168.1.10
```

### 3.2 Generar clave privada y certificado CA

```bash
cd /etc/ssl/radius-certs

# Inicializar archivos de control
sudo touch ca/index.txt
echo 1000 | sudo tee ca/serial

# Generar clave privada de la CA (4096 bits para mayor seguridad)
sudo openssl genrsa -aes256 -out ca/private/ca.key 4096

# Se solicitará una contraseña - GUARDARLA SEGURA
# Ejemplo: CASecurePassword2024!

# Generar certificado CA auto-firmado (válido 10 años)
sudo openssl req -config ca.cnf \
    -key ca/private/ca.key \
    -new -x509 -days 3650 \
    -sha256 -extensions v3_ca \
    -out ca/certs/ca.pem

# Completar información:
# Country Name: AR
# State: Buenos Aires
# Locality: CABA
# Organization: Mi Empresa SA
# Organizational Unit: IT Security
# Common Name: Mi Empresa CA
# Email Address: ca@empresa.local
```

### 3.3 Verificar certificado CA

```bash
# Ver detalles del certificado
sudo openssl x509 -noout -text -in ca/certs/ca.pem

# Información importante a verificar:
# - Issuer = Subject (auto-firmado)
# - Validity: Not Before / Not After
# - CA:TRUE en Basic Constraints
# - Key Usage: Certificate Sign, CRL Sign
```

**Salida esperada (resumida):**

```
Certificate:
    Data:
        Issuer: C = AR, ST = Buenos Aires, O = Mi Empresa SA, CN = Mi Empresa CA
        Subject: C = AR, ST = Buenos Aires, O = Mi Empresa SA, CN = Mi Empresa CA
        X509v3 extensions:
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
```

---

## 4. Generación del Certificado del Servidor RADIUS

### 4.1 Generar clave privada del servidor

```bash
# Generar clave privada (sin contraseña para que FreeRADIUS pueda iniciar automáticamente)
sudo openssl genrsa -out server/private/server.key 2048

# Alternativamente, con contraseña:
# sudo openssl genrsa -aes256 -out server/private/server.key 2048

# Proteger la clave
sudo chmod 400 server/private/server.key
```

### 4.2 Crear Certificate Signing Request (CSR)

```bash
# Generar CSR del servidor
sudo openssl req -config ca.cnf \
    -key server/private/server.key \
    -new -sha256 \
    -out server/csr/server.csr

# Completar información:
# Country Name: AR
# State: Buenos Aires
# Organization: Mi Empresa SA
# Organizational Unit: IT Department
# Common Name: radius.empresa.local  ⚠️ IMPORTANTE: FQDN del servidor
# Email: radius@empresa.local
```

**Nota crítica sobre Common Name (CN):**
- Debe coincidir con el nombre DNS o IP que los clientes usarán
- Si usas IP: CN = 192.168.1.10
- Si usas hostname: CN = radius.empresa.local
- Los clientes validarán este nombre durante la conexión

### 4.3 Firmar certificado del servidor con CA

```bash
# Firmar el CSR con la CA (válido 730 días = 2 años)
sudo openssl ca -config ca.cnf \
    -extensions server_cert \
    -days 730 -notext -md sha256 \
    -in server/csr/server.csr \
    -out server/certs/server.pem

# Se solicitará la contraseña de la CA
# Confirmar firma del certificado: y
# Confirmar commit: y
```

### 4.4 Verificar certificado del servidor

```bash
# Ver detalles
sudo openssl x509 -noout -text -in server/certs/server.pem

# Verificar firma con CA
sudo openssl verify -CAfile ca/certs/ca.pem server/certs/server.pem

# Salida esperada:
# server/certs/server.pem: OK
```

**Verificar extensiones importantes:**

```
X509v3 extensions:
    X509v3 Basic Constraints:
        CA:FALSE
    X509v3 Key Usage: critical
        Digital Signature, Key Encipherment
    X509v3 Extended Key Usage:
        TLS Web Server Authentication, EAP over TLS
    X509v3 Subject Alternative Name:
        DNS:radius.empresa.local, DNS:radius, IP Address:192.168.1.10
```

---

## 5. Generación de Certificados de Clientes

### 5.1 Script para generación masiva

Crear script `generate-client-cert.sh`:

```bash
sudo nano /etc/ssl/radius-certs/generate-client-cert.sh
```

**Contenido del script:**

```bash
#!/bin/bash

# Script para generar certificados de cliente
# Uso: ./generate-client-cert.sh <username>

if [ $# -ne 1 ]; then
    echo "Uso: $0 <username>"
    exit 1
fi

USERNAME=$1
BASE_DIR="/etc/ssl/radius-certs"
CA_DIR="$BASE_DIR/ca"
CLIENT_DIR="$BASE_DIR/clients"

echo "Generando certificado para usuario: $USERNAME"

# 1. Generar clave privada del cliente
echo "[1/5] Generando clave privada..."
openssl genrsa -out "$CLIENT_DIR/private/$USERNAME.key" 2048

# 2. Crear CSR
echo "[2/5] Creando Certificate Signing Request..."
openssl req -config "$BASE_DIR/ca.cnf" \
    -key "$CLIENT_DIR/private/$USERNAME.key" \
    -new -sha256 \
    -out "$CLIENT_DIR/csr/$USERNAME.csr" \
    -subj "/C=AR/ST=Buenos Aires/O=Mi Empresa SA/OU=Empleados/CN=$USERNAME/emailAddress=$USERNAME@empresa.local"

# 3. Firmar certificado con CA
echo "[3/5] Firmando certificado con CA..."
openssl ca -config "$BASE_DIR/ca.cnf" \
    -extensions client_cert \
    -days 365 -notext -md sha256 \
    -in "$CLIENT_DIR/csr/$USERNAME.csr" \
    -out "$CLIENT_DIR/certs/$USERNAME.pem" \
    -batch

# 4. Crear bundle PKCS#12 (.p12) para importar en dispositivos
echo "[4/5] Creando bundle PKCS#12..."
openssl pkcs12 -export \
    -out "$CLIENT_DIR/certs/$USERNAME.p12" \
    -inkey "$CLIENT_DIR/private/$USERNAME.key" \
    -in "$CLIENT_DIR/certs/$USERNAME.pem" \
    -certfile "$CA_DIR/certs/ca.pem" \
    -passout pass:$USERNAME

# 5. Verificar certificado
echo "[5/5] Verificando certificado..."
openssl verify -CAfile "$CA_DIR/certs/ca.pem" "$CLIENT_DIR/certs/$USERNAME.pem"

echo ""
echo "✓ Certificado generado exitosamente para: $USERNAME"
echo "  - Certificado PEM: $CLIENT_DIR/certs/$USERNAME.pem"
echo "  - Clave privada: $CLIENT_DIR/private/$USERNAME.key"
echo "  - Bundle PKCS#12: $CLIENT_DIR/certs/$USERNAME.p12 (contraseña: $USERNAME)"
echo ""
echo "Para instalar en el cliente, usar el archivo .p12"
```

### 5.2 Hacer ejecutable y generar certificados

```bash
# Hacer ejecutable
sudo chmod +x /etc/ssl/radius-certs/generate-client-cert.sh

# Generar certificados para usuarios
cd /etc/ssl/radius-certs
sudo ./generate-client-cert.sh jperez
sudo ./generate-client-cert.sh mbianchi
sudo ./generate-client-cert.sh admin
```

### 5.3 Verificar certificados de clientes

```bash
# Listar certificados generados
ls -lh clients/certs/

# Ver detalles de un certificado
sudo openssl x509 -noout -text -in clients/certs/jperez.pem

# Ver contenido del PKCS#12
sudo openssl pkcs12 -info -in clients/certs/jperez.p12 -password pass:jperez
```

---

## 6. Configuración de Certificados en FreeRADIUS

### 6.1 Copiar certificados al directorio de FreeRADIUS

```bash
# Crear backup de certificados de ejemplo
sudo mv /etc/freeradius/3.0/certs /etc/freeradius/3.0/certs.bak

# Crear nuevo directorio
sudo mkdir -p /etc/freeradius/3.0/certs

# Copiar certificados necesarios
sudo cp /etc/ssl/radius-certs/ca/certs/ca.pem /etc/freeradius/3.0/certs/
sudo cp /etc/ssl/radius-certs/server/certs/server.pem /etc/freeradius/3.0/certs/
sudo cp /etc/ssl/radius-certs/server/private/server.key /etc/freeradius/3.0/certs/

# Generar parámetros DH (para Perfect Forward Secrecy)
sudo openssl dhparam -out /etc/freeradius/3.0/certs/dh 2048

# Ajustar permisos
sudo chown -R freerad:freerad /etc/freeradius/3.0/certs
sudo chmod 640 /etc/freeradius/3.0/certs/*
sudo chmod 600 /etc/freeradius/3.0/certs/server.key
```

### 6.2 Actualizar configuración EAP en FreeRADIUS

Verificar que `/etc/freeradius/3.0/mods-available/eap` apunte a los certificados correctos:

```bash
sudo nano /etc/freeradius/3.0/mods-available/eap
```

**Verificar sección `tls-config`:**

```conf
tls-config tls-common {
    private_key_password = whatever
    private_key_file = ${certdir}/server.key
    certificate_file = ${certdir}/server.pem
    ca_file = ${cadir}/ca.pem
    dh_file = ${certdir}/dh

    # Validar certificados de clientes
    verify_client_cert = yes

    # Versiones TLS seguras
    tls_min_version = "1.2"
    tls_max_version = "1.3"

    # Cipher suites seguros
    cipher_list = "HIGH:!aNULL:!MD5:!RC4"
}
```

### 6.3 Reiniciar FreeRADIUS y probar

```bash
# Verificar configuración
sudo freeradius -CX

# Reiniciar servicio
sudo systemctl restart freeradius

# Verificar logs
sudo tail -f /var/log/freeradius/radius.log
```

---

## 7. Distribución de Certificados a Clientes

### 7.1 Archivos necesarios por cliente

Cada cliente necesita:

1. **Certificado CA** (`ca.pem`): Para validar el servidor RADIUS
2. **Certificado del Cliente** (`username.pem` o `username.p12`)
3. **Clave Privada del Cliente** (incluida en .p12)

### 7.2 Crear paquete de distribución

```bash
# Crear directorio para cada usuario
sudo mkdir -p /home/distribuciones

# Para usuario jperez
sudo mkdir /home/distribuciones/jperez
sudo cp /etc/ssl/radius-certs/ca/certs/ca.pem /home/distribuciones/jperez/
sudo cp /etc/ssl/radius-certs/clients/certs/jperez.p12 /home/distribuciones/jperez/

# Crear archivo README
cat << 'EOF' | sudo tee /home/distribuciones/jperez/README.txt
INSTRUCCIONES DE INSTALACIÓN - WiFi Corporativo
================================================

Usuario: jperez

ARCHIVOS INCLUIDOS:
- ca.pem: Certificado de la Autoridad Certificadora
- jperez.p12: Tu certificado personal (contraseña: jperez)

INSTRUCCIONES:

Windows:
1. Doble clic en jperez.p12
2. Importar en "Usuario actual"
3. Ingresar contraseña: jperez
4. Configurar WiFi con seguridad WPA2-Enterprise (EAP-TLS)

Linux:
1. Importar certificado en Network Manager
2. Seleccionar ca.pem como CA certificate
3. Seleccionar jperez.p12 como User certificate

Android/iOS:
1. Transferir jperez.p12 al dispositivo
2. Instalar certificado (Configuración > Seguridad > Instalar desde almacenamiento)
3. Configurar WiFi corporativo con EAP-TLS

SOPORTE: soporte@empresa.local
EOF

# Crear archivo ZIP protegido
sudo apt install zip -y
cd /home/distribuciones
sudo zip -P "jperez2024" jperez.zip jperez/*

# Cambiar permisos
sudo chown -R $USER:$USER /home/distribuciones
```

### 7.3 Distribución segura

**Métodos recomendados:**

1. **Portal interno (HTTPS)**: Los usuarios descargan sus certificados
2. **Correo cifrado**: Enviar .p12 por email cifrado (S/MIME, PGP)
3. **USB cifrado**: Para usuarios locales
4. **MDM (Mobile Device Management)**: Para dispositivos móviles corporativos

**NUNCA:**
- Enviar por email sin cifrar
- Compartir en drives públicos
- Usar la misma contraseña de protección para todos

---

## 8. Gestión y Renovación de Certificados

### 8.1 Listar certificados emitidos

```bash
# Ver base de datos de certificados
sudo cat /etc/ssl/radius-certs/ca/index.txt

# Formato: V/R/E  fecha_exp  fecha_revoc  serial  subject
# V = Valid, R = Revoked, E = Expired
```

### 8.2 Renovar certificado de servidor

```bash
cd /etc/ssl/radius-certs

# Generar nuevo CSR (usando la misma clave o una nueva)
sudo openssl req -config ca.cnf \
    -key server/private/server.key \
    -new -sha256 \
    -out server/csr/server-renew.csr

# Firmar nuevo certificado
sudo openssl ca -config ca.cnf \
    -extensions server_cert \
    -days 730 -notext -md sha256 \
    -in server/csr/server-renew.csr \
    -out server/certs/server-new.pem

# Hacer backup del certificado actual
sudo cp /etc/freeradius/3.0/certs/server.pem \
        /etc/freeradius/3.0/certs/server.pem.old

# Instalar nuevo certificado
sudo cp server/certs/server-new.pem /etc/freeradius/3.0/certs/server.pem

# Reiniciar FreeRADIUS
sudo systemctl restart freeradius
```

### 8.3 Renovar certificado de cliente

```bash
# Usar el mismo script con el usuario existente
sudo ./generate-client-cert.sh jperez

# NOTA: Esto generará un NUEVO certificado con nuevo serial
# El certificado anterior sigue siendo válido hasta su expiración
```

### 8.4 Revocar certificado

```bash
# Revocar certificado de un usuario
sudo openssl ca -config /etc/ssl/radius-certs/ca.cnf \
    -revoke /etc/ssl/radius-certs/clients/certs/jperez.pem

# Generar CRL (Certificate Revocation List)
sudo openssl ca -config /etc/ssl/radius-certs/ca.cnf \
    -gencrl -out /etc/ssl/radius-certs/ca/crl/crl.pem

# Copiar CRL a FreeRADIUS
sudo cp /etc/ssl/radius-certs/ca/crl/crl.pem /etc/freeradius/3.0/certs/
```

### 8.5 Configurar verificación de CRL en FreeRADIUS

Editar `/etc/freeradius/3.0/mods-available/eap`:

```conf
tls-config tls-common {
    # ... configuración existente ...

    # Habilitar verificación de CRL
    check_crl = yes
    ca_path = ${cadir}

    # Archivo CRL
    # ca_file debe incluir tanto CA como CRL, o usar check_all_crl
    check_all_crl = yes
}
```

---

## 9. Monitoreo y Auditoría de Certificados

### 9.1 Script de monitoreo de expiración

Crear `/usr/local/bin/check-cert-expiration.sh`:

```bash
#!/bin/bash

CERT_DIR="/etc/ssl/radius-certs"
WARNING_DAYS=30

echo "=== Reporte de Expiración de Certificados ==="
echo ""

# Verificar certificado CA
echo "Certificado CA:"
openssl x509 -enddate -noout -in "$CERT_DIR/ca/certs/ca.pem" | \
    sed 's/notAfter=/  Expira: /'

# Verificar certificado del servidor
echo ""
echo "Certificado del Servidor:"
openssl x509 -enddate -noout -in "$CERT_DIR/server/certs/server.pem" | \
    sed 's/notAfter=/  Expira: /'

# Verificar certificados de clientes
echo ""
echo "Certificados de Clientes:"
for cert in "$CERT_DIR/clients/certs"/*.pem; do
    username=$(basename "$cert" .pem)
    expiry=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
    echo "  $username: $expiry"
done
```

### 9.2 Automatizar revisión con cron

```bash
# Hacer ejecutable
sudo chmod +x /usr/local/bin/check-cert-expiration.sh

# Agregar a crontab (ejecutar cada lunes)
sudo crontab -e

# Agregar línea:
0 9 * * 1 /usr/local/bin/check-cert-expiration.sh | mail -s "Reporte Certificados" admin@empresa.local
```

---

## 10. Mejores Prácticas de Seguridad

### 10.1 Protección de claves privadas

```bash
# Verificar permisos correctos
sudo find /etc/ssl/radius-certs -name "*.key" -exec ls -l {} \;

# Deben ser 400 (r--------) o 600 (rw-------)
sudo find /etc/ssl/radius-certs -name "*.key" -exec chmod 400 {} \;

# Verificar propietario
sudo chown -R root:root /etc/ssl/radius-certs/ca/private
sudo chown -R freerad:freerad /etc/freeradius/3.0/certs
```

### 10.2 Backup de certificados

```bash
# Crear script de backup
cat << 'EOF' | sudo tee /usr/local/bin/backup-radius-certs.sh
#!/bin/bash
BACKUP_DIR="/backup/radius-certs"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/radius-certs-$DATE.tar.gz" \
    -C /etc/ssl radius-certs \
    -C /etc/freeradius/3.0 certs

# Mantener solo últimos 30 días
find "$BACKUP_DIR" -name "radius-certs-*.tar.gz" -mtime +30 -delete

echo "Backup completado: radius-certs-$DATE.tar.gz"
EOF

sudo chmod +x /usr/local/bin/backup-radius-certs.sh

# Ejecutar diariamente
echo "0 2 * * * /usr/local/bin/backup-radius-certs.sh" | sudo crontab -
```

### 10.3 Políticas recomendadas

| Aspecto | Recomendación |
|---------|---------------|
| **Validez CA** | 10 años |
| **Validez Servidor** | 2 años |
| **Validez Cliente** | 1 año |
| **Algoritmo** | RSA 2048+ o ECDSA P-256+ |
| **Hash** | SHA-256 o superior |
| **Rotación** | Renovar 30 días antes de expiración |
| **Revocación** | CRL o OCSP habilitado |

---

## Ejercicios Prácticos

### Ejercicio 1: Generar certificado de cliente
Generar un certificado para un nuevo usuario "alumno1" y verificar su validez.

### Ejercicio 2: Verificar cadena de confianza
Usar `openssl verify` para confirmar que un certificado de cliente está correctamente firmado por la CA.

### Ejercicio 3: Inspeccionar certificado
Usar `openssl x509 -text` para ver todos los detalles de un certificado y explicar cada campo.

### Ejercicio 4: Simular revocación
Revocar un certificado, generar CRL, y verificar que el certificado aparece como revocado.

### Ejercicio 5: Exportar certificado
Convertir un certificado .pem a diferentes formatos (.der, .p12, .pfx).

---

## Checklist de Configuración

- [ ] Certificado CA generado y verificado
- [ ] Certificado del servidor RADIUS creado y firmado
- [ ] Certificados de cliente generados (mínimo 2)
- [ ] Certificados copiados a directorio de FreeRADIUS
- [ ] Permisos correctos aplicados (400/600 en claves privadas)
- [ ] Parámetros DH generados
- [ ] Configuración EAP actualizada con rutas correctas
- [ ] FreeRADIUS reiniciado sin errores
- [ ] Script de generación de certificados probado
- [ ] Backup de certificados configurado

---

**Próximo paso**: Configuración del Access Point con WPA2-Enterprise (archivo 03)
