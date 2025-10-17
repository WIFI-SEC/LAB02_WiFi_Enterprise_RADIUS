# Configuración de Clientes WiFi Enterprise

## Introducción

En esta sección configuraremos dispositivos cliente (Windows, Linux, Android, iOS) para conectarse a la red WiFi empresarial usando autenticación EAP-TLS con certificados.

---

## 1. Preparación de Certificados para Clientes

### 1.1 Archivos necesarios

Cada usuario necesita:

```
usuario/
├── ca.pem                 # Certificado de la CA (para validar servidor)
├── usuario.p12            # Bundle PKCS#12 (certificado + clave privada)
└── README.txt             # Instrucciones
```

### 1.2 Distribución segura

**Métodos recomendados:**
- Portal interno HTTPS con autenticación
- Email cifrado (S/MIME, PGP)
- USB cifrado entregado en persona
- Sistema MDM (Mobile Device Management)

---

## 2. Windows 10/11

### 2.1 Importar certificados

#### Método A: Interfaz gráfica

**Paso 1: Importar certificado PKCS#12**

```
1. Doble clic en archivo "usuario.p12"
2. Store Location: "Current User" > Next
3. File to Import: (debe estar pre-seleccionado) > Next
4. Password: [contraseña del .p12] > Next
5. Certificate Store: "Automatically select..." > Next
6. Finish
```

**Paso 2: Verificar instalación**

```
1. Win + R > certmgr.msc > Enter
2. Personal > Certificates
   - Debe aparecer: CN=usuario
3. Trusted Root Certification Authorities > Certificates
   - Debe aparecer: CN=Mi Empresa CA
```

#### Método B: PowerShell (para despliegue masivo)

```powershell
# Ejecutar como Administrador

# Importar certificado del usuario (.p12)
$Password = ConvertTo-SecureString -String "usuario" -Force -AsPlainText
Import-PfxCertificate -FilePath "C:\Certs\usuario.p12" `
                      -CertStoreLocation Cert:\CurrentUser\My `
                      -Password $Password

# Importar certificado CA
Import-Certificate -FilePath "C:\Certs\ca.pem" `
                   -CertStoreLocation Cert:\CurrentUser\Root

# Verificar
Get-ChildItem Cert:\CurrentUser\My
Get-ChildItem Cert:\CurrentUser\Root
```

### 2.2 Configurar conexión WiFi

#### Método A: Interfaz gráfica

**Paso 1: Conectar a la red**

```
1. Click en icono WiFi (bandeja de sistema)
2. Seleccionar "WiFi-Corporativo"
3. Click "Connect"
```

**Paso 2: Configuración de seguridad**

```
Windows solicitará configuración:

Security type: WPA2-Enterprise o WPA3-Enterprise
Encryption type: AES
Network authentication method: Microsoft: Smart Card or other certificate

[✓] Remember my credentials
Connect
```

**Paso 3: Configuración avanzada (si no conecta automáticamente)**

```
1. Settings > Network & Internet > WiFi
2. Manage known networks > WiFi-Corporativo
3. Properties
4. Security tab:

   Security type: WPA2-Enterprise
   Network authentication method: Microsoft: Smart Card or other certificate

   Click "Settings":

   ┌────────────────────────────────────────────┐
   │ Smart Card or other Certificate Properties │
   ├────────────────────────────────────────────┤
   │ When connecting:                           │
   │ [✓] Use my smart card                      │
   │ [ ] Use a certificate on this computer     │ ← Seleccionar esto
   │ [✓] Use simple certificate selection       │
   │ [ ] Advanced                               │
   │                                            │
   │ Trusted Root Certification Authorities:    │
   │ [✓] Mi Empresa CA                          │ ← Marcar esto
   │                                            │
   │ Notifications before connecting:           │
   │ [ ] Server validation fails                │
   │ [✓] User is prompted                       │
   │                                            │
   │ [Advanced Settings]                        │
   └────────────────────────────────────────────┘

   OK
```

**Paso 4: Advanced Settings (opcional pero recomendado)**

```
Click "Advanced Settings":

Specify authentication mode: User authentication
[✓] Enable Single Sign On (SSO)
Maximum authentication failures: 1

OK
```

#### Método B: Configuración XML (GPO)

Para despliegue empresarial vía Group Policy:

```xml
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>WiFi-Corporativo</name>
    <SSIDConfig>
        <SSID>
            <hex>576946692D436F72706F726174697</hex>
            <name>WiFi-Corporativo</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2</authentication>
                <encryption>AES</encryption>
                <useOneX>true</useOneX>
            </authEncryption>
            <PMKCacheMode>enabled</PMKCacheMode>
            <OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
                <authMode>user</authMode>
                <EAPConfig>
                    <EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig">
                        <EapMethod>
                            <Type xmlns="http://www.microsoft.com/provisioning/EapCommon">13</Type>
                            <VendorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorId>
                            <VendorType xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorType>
                            <AuthorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</AuthorId>
                        </EapMethod>
                        <Config xmlns="http://www.microsoft.com/provisioning/EapHostConfig">
                            <Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1">
                                <Type>13</Type>
                                <EapType xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV1">
                                    <CredentialsSource>
                                        <CertificateStore>
                                            <SimpleCertSelection>true</SimpleCertSelection>
                                        </CertificateStore>
                                    </CredentialsSource>
                                    <ServerValidation>
                                        <DisableUserPromptForServerValidation>false</DisableUserPromptForServerValidation>
                                        <ServerNames></ServerNames>
                                        <TrustedRootCA>THUMBPRINT_DE_CA</TrustedRootCA>
                                    </ServerValidation>
                                    <DifferentUsername>false</DifferentUsername>
                                    <PerformServerValidation xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">true</PerformServerValidation>
                                    <AcceptServerName xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">false</AcceptServerName>
                                </EapType>
                            </Eap>
                        </Config>
                    </EapHostConfig>
                </EAPConfig>
            </OneX>
        </security>
    </MSM>
</WLANProfile>
```

**Importar perfil WiFi:**

```powershell
# Como Administrador
netsh wlan add profile filename="C:\WiFi-Corporativo.xml" user=all

# Verificar
netsh wlan show profiles
```

### 2.3 Troubleshooting Windows

#### Ver logs de autenticación

```powershell
# Event Viewer
eventvwr.msc

# Navegar a:
Applications and Services Logs > Microsoft > Windows > WLAN-AutoConfig > Operational

# Buscar Event IDs:
# 8001: Autenticación iniciada
# 8002: Autenticación exitosa
# 8003: Autenticación fallida
```

#### Eliminar y recrear perfil

```powershell
# Listar perfiles
netsh wlan show profiles

# Eliminar perfil específico
netsh wlan delete profile name="WiFi-Corporativo"

# Volver a conectar desde GUI
```

---

## 3. Linux (Ubuntu / Debian)

### 3.1 Network Manager (GUI)

**Paso 1: Importar certificados**

```bash
# Copiar certificados a directorio del usuario
mkdir -p ~/.cert
cp ca.pem ~/.cert/
cp usuario.p12 ~/.cert/

# Convertir .p12 a .pem (si es necesario)
openssl pkcs12 -in ~/.cert/usuario.p12 -out ~/.cert/usuario.pem -nodes
# Password: [contraseña del .p12]

# Extraer clave privada separada (opcional)
openssl pkcs12 -in ~/.cert/usuario.p12 -nocerts -out ~/.cert/usuario.key -nodes

# Extraer solo certificado
openssl pkcs12 -in ~/.cert/usuario.p12 -clcerts -nokeys -out ~/.cert/usuario-cert.pem

# Proteger archivos
chmod 600 ~/.cert/*
```

**Paso 2: Configurar conexión WiFi**

```
1. Click en icono de red (bandeja superior)
2. "WiFi Settings"
3. Seleccionar "WiFi-Corporativo"
4. Click en engranaje de configuración
```

**Configuración de seguridad:**

```
Security: WPA & WPA2 Enterprise

Authentication:
  TLS

Identity: usuario@empresa.local  (o solo "usuario")

Domain: (dejar vacío o "empresa.local")

CA certificate: /home/usuario/.cert/ca.pem
  [✓] No CA certificate is required

User certificate: /home/usuario/.cert/usuario-cert.pem
  (o seleccionar .p12 directamente)

User private key: /home/usuario/.cert/usuario.key
  (si usas .p12, este campo no aplica)

User key password: [contraseña si la clave está protegida]

Apply
```

### 3.2 Configuración mediante CLI (wpa_supplicant)

**Crear archivo de configuración:**

```bash
sudo nano /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
```

**Contenido del archivo:**

```conf
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=wheel
update_config=1

network={
    ssid="WiFi-Corporativo"
    key_mgmt=WPA-EAP
    eap=TLS
    identity="usuario@empresa.local"

    # Certificado CA (para validar servidor RADIUS)
    ca_cert="/home/usuario/.cert/ca.pem"

    # Certificado del cliente
    client_cert="/home/usuario/.cert/usuario-cert.pem"

    # Clave privada del cliente
    private_key="/home/usuario/.cert/usuario.key"

    # Contraseña de la clave privada (si tiene)
    private_key_passwd="contraseña"

    # Alternativamente, usar PKCS#12 directamente
    # private_key="/home/usuario/.cert/usuario.p12"
    # private_key_passwd="usuario"

    # Validación del servidor
    # phase1="tls_disable_tlsv1_0=1 tls_disable_tlsv1_1=1"

    # Prioridad (mayor = preferida)
    priority=1
}
```

**Proteger archivo y conectar:**

```bash
# Proteger archivo de configuración
sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# Detener Network Manager (si está activo)
sudo systemctl stop NetworkManager

# Iniciar wpa_supplicant manualmente
sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# Obtener IP vía DHCP
sudo dhclient wlan0

# Verificar conexión
ip addr show wlan0
ping -c 4 8.8.8.8
```

**Automatizar al inicio (systemd):**

```bash
# Habilitar servicio
sudo systemctl enable wpa_supplicant@wlan0.service
sudo systemctl start wpa_supplicant@wlan0.service

# Verificar status
sudo systemctl status wpa_supplicant@wlan0.service
```

### 3.3 NetworkManager CLI (nmcli)

```bash
# Crear conexión WiFi con EAP-TLS
nmcli connection add \
    type wifi \
    con-name "WiFi-Corporativo" \
    ifname wlan0 \
    ssid "WiFi-Corporativo" \
    wifi-sec.key-mgmt wpa-eap \
    802-1x.eap tls \
    802-1x.identity "usuario@empresa.local" \
    802-1x.ca-cert "/home/usuario/.cert/ca.pem" \
    802-1x.client-cert "/home/usuario/.cert/usuario-cert.pem" \
    802-1x.private-key "/home/usuario/.cert/usuario.key" \
    802-1x.private-key-password "contraseña"

# Activar conexión
nmcli connection up "WiFi-Corporativo"

# Ver detalles
nmcli connection show "WiFi-Corporativo"

# Ver estado
nmcli device status
```

### 3.4 Troubleshooting Linux

```bash
# Ver logs de wpa_supplicant
sudo journalctl -u wpa_supplicant@wlan0.service -f

# Modo debug de wpa_supplicant
sudo wpa_supplicant -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant-wlan0.conf -d

# Ver información de la conexión actual
iw dev wlan0 link

# Escanear redes disponibles
sudo iw dev wlan0 scan | grep -E "SSID|signal"

# Ver logs de NetworkManager
journalctl -u NetworkManager.service -f
```

---

## 4. Android

### 4.1 Importar certificados

**Paso 1: Transferir archivos al dispositivo**

Opciones:
- Email (enviar ca.pem y usuario.p12)
- USB
- Google Drive / Dropbox
- Descargar desde portal interno

**Paso 2: Instalar certificado PKCS#12**

```
1. Abrir archivo usuario.p12
   - Desde "Descargas" o "Archivos"
   - Click en el archivo

2. Sistema solicitará:
   - Nombre del certificado: "usuario" (dejar default)
   - Uso: VPN y aplicaciones / WiFi
   - Password: [contraseña del .p12]

3. Si solicita, configurar PIN/Patrón de pantalla

4. Certificado se instala en "Credential Storage"
```

**Verificar instalación:**

```
Settings > Security > Encryption & credentials
> Trusted credentials
> User tab
  - Debe aparecer: Mi Empresa CA

> User credentials
  - Debe aparecer: usuario
```

### 4.2 Configurar WiFi

**Paso 1: Conectar a la red**

```
1. Settings > Network & Internet > WiFi
2. Tap en "WiFi-Corporativo"
3. Configurar:

EAP method: TLS

Phase 2 authentication: (None)

CA certificate:
  - Seleccionar "Mi Empresa CA"
  - O "Use system certificates"

User certificate:
  - Seleccionar "usuario" (el que importaste)

Identity: usuario@empresa.local
  (o solo "usuario", según configuración RADIUS)

Anonymous identity: (dejar vacío)

Domain: (dejar vacío o "empresa.local")

[Advanced options]
  IP settings: DHCP
  Proxy: None

4. CONNECT
```

**Paso 2: Configuración avanzada (si disponible)**

```
Advanced options:

  [✓] Randomize MAC (Android 10+)
      - Recomendado para privacidad

  IP settings: DHCP

  Proxy: None (o Manual si es necesario)
```

### 4.3 Troubleshooting Android

#### Ver logs de WiFi (requiere root o ADB)

```bash
# Conectar dispositivo con USB debugging habilitado
adb shell

# Ver logs del sistema
logcat | grep -i "wpa\|supplicant\|eap"

# Ver configuración actual de WiFi
wpa_cli status
```

#### Eliminar y recrear conexión

```
Settings > Network & Internet > WiFi
> WiFi-Corporativo (mantener presionado)
> Forget network

Volver a configurar desde cero
```

#### Problemas comunes

| Problema | Causa | Solución |
|----------|-------|----------|
| "No se puede conectar" | Certificado no instalado | Re-importar .p12 |
| "Autenticando..." loop | Identity incorrecta | Verificar username en RADIUS |
| "Obteniendo IP..." | VLAN/DHCP issue | Verificar RADIUS asigna VLAN correcta |

---

## 5. iOS / iPadOS

### 5.1 Importar certificados

**Método A: Email**

```
1. Enviar ca.pem y usuario.p12 por email al usuario
2. En iPhone/iPad, abrir email
3. Tap en attachment "usuario.p12"
4. iOS pregunta: "Review the profile in Settings?"
5. Tap "Allow"
6. Settings > Profile Downloaded
7. Tap "Install"
8. Ingresar passcode del dispositivo
9. Ingresar contraseña del .p12
10. Tap "Install" (confirmar)
11. Tap "Done"
```

**Método B: Safari (desde URL)**

```
1. Abrir Safari
2. Navegar a: https://portal.empresa.local/certs/usuario.p12
3. Descargar archivo
4. Seguir pasos de instalación (igual que Método A)
```

**Verificar instalación:**

```
Settings > General > VPN & Device Management
> Configuration Profiles
  - Debe aparecer el perfil instalado
```

### 5.2 Configurar WiFi

```
1. Settings > WiFi
2. Tap en "WiFi-Corporativo"
3. Configurar:

Security: WPA2/WPA3 Enterprise

Mode: Automatic
  (o seleccionar "EAP-TLS" si está disponible)

Username: usuario@empresa.local

Password: (dejar vacío para EAP-TLS)

Identity certificate:
  - Seleccionar "usuario" (el que importaste)

Trust: Mi Empresa CA
  (Tap "Trust" si pregunta)

4. Tap "Join"
```

**Si aparece advertencia de certificado:**

```
Certificate Trust Settings:

  Tap "Trust"

  [✓] Enable Full Trust for Root Certificate: Mi Empresa CA

  Enter passcode
```

### 5.3 Configuración mediante MDM (Apple Configurator / Profile)

Para despliegue empresarial masivo, crear perfil `.mobileconfig`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <!-- Certificado CA -->
        <dict>
            <key>PayloadType</key>
            <string>com.apple.security.root</string>
            <key>PayloadIdentifier</key>
            <string>com.empresa.ca</string>
            <key>PayloadUUID</key>
            <string>GENERATE-UUID-1</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
            <key>PayloadContent</key>
            <data>
            <!-- BASE64 encoded ca.pem -->
            </data>
        </dict>

        <!-- Certificado de usuario (PKCS#12) -->
        <dict>
            <key>PayloadType</key>
            <string>com.apple.security.pkcs12</string>
            <key>PayloadIdentifier</key>
            <string>com.empresa.usuario</string>
            <key>PayloadUUID</key>
            <string>GENERATE-UUID-2</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
            <key>PayloadContent</key>
            <data>
            <!-- BASE64 encoded usuario.p12 -->
            </data>
            <key>Password</key>
            <string>contraseña_p12</string>
        </dict>

        <!-- Configuración WiFi -->
        <dict>
            <key>PayloadType</key>
            <string>com.apple.wifi.managed</string>
            <key>PayloadIdentifier</key>
            <string>com.empresa.wifi</string>
            <key>PayloadUUID</key>
            <string>GENERATE-UUID-3</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
            <key>SSID_STR</key>
            <string>WiFi-Corporativo</string>
            <key>HIDDEN_NETWORK</key>
            <false/>
            <key>AutoJoin</key>
            <true/>
            <key>EncryptionType</key>
            <string>WPA2</string>
            <key>EAPClientConfiguration</key>
            <dict>
                <key>UserName</key>
                <string>usuario@empresa.local</string>
                <key>AcceptEAPTypes</key>
                <array>
                    <integer>13</integer> <!-- EAP-TLS -->
                </array>
                <key>PayloadCertificateAnchorUUID</key>
                <array>
                    <string>GENERATE-UUID-1</string>
                </array>
                <key>TLSTrustedServerNames</key>
                <array>
                    <string>radius.empresa.local</string>
                </array>
            </dict>
        </dict>
    </array>

    <key>PayloadDisplayName</key>
    <string>WiFi Corporativo - Empresa SA</string>
    <key>PayloadIdentifier</key>
    <string>com.empresa.profile</string>
    <key>PayloadRemovalDisallowed</key>
    <false/>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>GENERATE-UUID-ROOT</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>
```

**Instalar perfil:**

```
1. Enviar .mobileconfig por email o alojar en web
2. Usuario abre el archivo
3. iOS automáticamente lo reconoce como perfil de configuración
4. Seguir pasos de instalación
```

### 5.4 Troubleshooting iOS

#### Ver logs (requiere Mac con Apple Configurator)

```
1. Conectar iPhone/iPad al Mac
2. Abrir Console.app
3. Seleccionar dispositivo
4. Filtrar por "WiFi" o "EAP"
```

#### Eliminar perfil y certificados

```
Settings > General > VPN & Device Management
> Configuration Profiles
> Tap en el perfil
> Remove Profile
```

---

## 6. macOS

### 6.1 Importar certificados

**Paso 1: Importar a Keychain**

```
1. Doble click en "ca.pem"
2. Keychain Access se abre
3. Seleccionar keychain: "login" o "System"
4. Click "Add"

5. Doble click en "usuario.p12"
6. Ingresar contraseña del .p12
7. Click "OK"
```

**Paso 2: Confiar en el certificado CA**

```
1. Abrir "Keychain Access.app"
2. Seleccionar keychain "login"
3. Buscar "Mi Empresa CA"
4. Doble click en el certificado
5. Expandir "Trust"
6. "When using this certificate": Always Trust
7. Cerrar ventana (pedirá contraseña del Mac)
```

### 6.2 Configurar WiFi

```
1. System Preferences > Network
2. Click en "Wi-Fi" (sidebar)
3. Network Name: Seleccionar "WiFi-Corporativo"
4. Click "Advanced..."
5. Tab "Wi-Fi"
6. Seleccionar "WiFi-Corporativo" en la lista
7. Click en "-" para remover (si existe)
8. Click en "+" para agregar nueva

Configuración:
  Network Name: WiFi-Corporativo
  Security: WPA2/WPA3 Enterprise

  802.1X: Automatic (o click Configure...)

User Profile:

  Configuration: Automatic

  Username: usuario@empresa.local

  Mode: Use certificate authentication

  Identity: Seleccionar "usuario" (el certificado importado)

  Trust: Seleccionar "Mi Empresa CA"

  Verification:
    [✓] Verify certificate identity
    Certificate name: radius.empresa.local

9. Click "OK"
10. Click "Apply"
```

### 6.3 Configuración avanzada (802.1X Settings)

```
Security: WPA2 Enterprise (o WPA3)

Mode: Automatic (o seleccionar "EAP-TLS")

Username: usuario@empresa.local

[Advanced...]

Protocols:
  [✓] TLS

Certificate:
  Identity: usuario (el certificado del cliente)

  CA certificates: Mi Empresa CA

Trust:
  [✓] Require certificate verification
  Trusted server certificate names: radius.empresa.local

[OK]
```

### 6.4 Troubleshooting macOS

```bash
# Ver logs de WiFi
log show --predicate 'subsystem == "com.apple.wifi"' --info

# Ver configuración actual
airport -I

# Desconectar de red actual
sudo airport -z

# Capturar paquetes WiFi (incluye handshake)
sudo airport en0 sniff 6  # Canal 6

# Ver redes disponibles con detalles
airport -s

# Ver perfiles 802.1X
system_profiler SPConfigurationProfileDataType
```

---

## 7. Script de Validación para Clientes

### 7.1 Script de verificación pre-conexión

```bash
#!/bin/bash
# validate-wifi-client.sh
# Verificar que el cliente tenga todo lo necesario para conectarse

echo "=== Validación de Configuración WiFi Enterprise ==="
echo ""

# Verificar certificado CA instalado
echo "[1] Verificando certificado CA..."
if [ -f "$HOME/.cert/ca.pem" ]; then
    echo "  ✓ CA certificate encontrado"
    openssl x509 -in "$HOME/.cert/ca.pem" -noout -subject
else
    echo "  ✗ CA certificate NO encontrado en $HOME/.cert/ca.pem"
fi

# Verificar certificado de usuario
echo ""
echo "[2] Verificando certificado de usuario..."
if [ -f "$HOME/.cert/usuario.p12" ]; then
    echo "  ✓ Certificado PKCS#12 encontrado"
    echo "  Verificando validez..."

    # Extraer y verificar
    openssl pkcs12 -in "$HOME/.cert/usuario.p12" -passin pass:usuario -noout 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "  ✓ Certificado válido"
    else
        echo "  ✗ Error al leer certificado (contraseña incorrecta?)"
    fi
else
    echo "  ✗ Certificado de usuario NO encontrado"
fi

# Verificar conectividad al servidor RADIUS (desde AP)
echo ""
echo "[3] Verificando conectividad..."
ping -c 2 192.168.1.10 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  ✓ Red accesible"
else
    echo "  ⚠ No hay conectividad (¿aún no está en la red?)"
fi

echo ""
echo "Validación completa."
```

---

## Ejercicios Prácticos

### Ejercicio 1: Configuración multi-plataforma
Configurar el mismo usuario en Windows, Linux y Android, y verificar que todos pueden conectarse.

### Ejercicio 2: Troubleshooting guiado
Provocar errores comunes (certificado incorrecto, CA no confiada) y diagnosticar.

### Ejercicio 3: Despliegue masivo
Crear scripts de instalación automatizada para Windows (PowerShell) y Linux (bash).

### Ejercicio 4: Comparar métodos EAP
Configurar un usuario con EAP-TLS y otro con PEAP, capturar ambas autenticaciones y comparar.

### Ejercicio 5: Movilidad entre dispositivos
Exportar certificado de un dispositivo e importarlo en otro, verificar portabilidad.

---

## Checklist de Configuración por Cliente

### Windows
- [ ] Certificado .p12 importado en almacén de certificados personal
- [ ] Certificado CA importado en autoridades raíz de confianza
- [ ] Conexión WiFi configurada con WPA2-Enterprise
- [ ] Método de autenticación: Smart Card or other certificate
- [ ] CA de confianza seleccionada correctamente
- [ ] Conexión exitosa verificada

### Linux
- [ ] Certificados copiados a ~/.cert/
- [ ] Permisos correctos (600) en archivos de certificados
- [ ] Conexión WiFi configurada con EAP-TLS
- [ ] CA certificate, User certificate y Private key configurados
- [ ] Identity configurada (usuario@dominio)
- [ ] Conexión exitosa verificada

### Android
- [ ] Certificado .p12 instalado desde almacenamiento
- [ ] CA visible en "Trusted credentials > User"
- [ ] User certificate visible en "User credentials"
- [ ] Conexión WiFi con EAP method: TLS
- [ ] CA certificate y User certificate seleccionados
- [ ] Identity configurada
- [ ] Conexión exitosa verificada

### iOS/macOS
- [ ] Certificado .p12 instalado (perfil descargado)
- [ ] CA certificate configurado como "Trusted"
- [ ] Conexión WiFi con WPA2 Enterprise
- [ ] Certificate authentication habilitado
- [ ] Identity y Trust configurados
- [ ] Conexión exitosa verificada

---

**Próximo paso**: Captura y análisis de tráfico con Wireshark (archivo 05)
