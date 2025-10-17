# ############################################################################
# Script de Instalación Automática - Laboratorio WiFi Enterprise + RADIUS
# Plataforma: Windows 10/11 (con WSL2)
# Versión: 1.0
# ############################################################################

#Requires -RunAsAdministrator

# Colores para output
function Write-Header {
    param([string]$Message)
    Write-Host "`n================================================================" -ForegroundColor Blue
    Write-Host "  $Message" -ForegroundColor Blue
    Write-Host "================================================================`n" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Yellow
}

# ############################################################################
# Variables globales
# ############################################################################

$WSL_DISTRO = "Ubuntu-22.04"
$RADIUS_IP = "localhost"  # En WSL2 se accede vía localhost
$SHARED_SECRET = "SuperSecretRADIUS2024!"
$SCRIPTS_DIR = "$env:USERPROFILE\radius-lab-scripts"

# ############################################################################
# Verificar ejecución como administrador
# ############################################################################

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Error-Custom "Este script debe ejecutarse como Administrador"
    Write-Info "Click derecho en PowerShell > Ejecutar como Administrador"
    exit 1
}

# ############################################################################
# Habilitar WSL2
# ############################################################################

function Install-WSL {
    Write-Header "PASO 1: Instalando WSL2"

    # Verificar si WSL ya está instalado
    $wslVersion = wsl --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "WSL ya instalado"
        return
    }

    Write-Info "Instalando WSL2..."

    # Habilitar características de Windows
    Write-Info "Habilitando características de Windows (requiere reinicio)..."

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

    # Instalar WSL
    wsl --install --no-distribution

    Write-Success "WSL instalado"
    Write-Info "⚠ IMPORTANTE: Debe reiniciar Windows antes de continuar"
    Write-Info "Después de reiniciar, ejecute este script nuevamente"

    $reboot = Read-Host "¿Desea reiniciar ahora? (S/N)"
    if ($reboot -eq 'S' -or $reboot -eq 's') {
        Restart-Computer
    }
    exit 0
}

# ############################################################################
# Instalar Ubuntu en WSL
# ############################################################################

function Install-Ubuntu {
    Write-Header "PASO 2: Instalando Ubuntu 22.04 en WSL"

    # Verificar si Ubuntu ya está instalado
    $distros = wsl --list --quiet
    if ($distros -contains $WSL_DISTRO) {
        Write-Success "Ubuntu 22.04 ya instalado"
        return
    }

    Write-Info "Instalando Ubuntu 22.04..."
    wsl --install -d $WSL_DISTRO

    Write-Info "Configurando usuario en Ubuntu..."
    Write-Info "Cuando se le solicite, ingrese:"
    Write-Info "  Username: admin"
    Write-Info "  Password: admin123"

    Start-Sleep -Seconds 5

    Write-Success "Ubuntu instalado"
}

# ############################################################################
# Configurar WSL2 como versión predeterminada
# ############################################################################

function Set-WSL2-Default {
    Write-Info "Configurando WSL2 como predeterminado..."
    wsl --set-default-version 2
    wsl --set-default $WSL_DISTRO
    Write-Success "WSL2 configurado"
}

# ############################################################################
# Instalar FreeRADIUS en WSL
# ############################################################################

function Install-FreeRADIUS-WSL {
    Write-Header "PASO 3: Instalando FreeRADIUS en Ubuntu (WSL)"

    # Crear script de instalación
    $installScript = @'
#!/bin/bash
set -e

echo "=== Instalando FreeRADIUS ==="

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar FreeRADIUS y dependencias
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    freeradius \
    freeradius-utils \
    freeradius-eap \
    openssl \
    net-tools \
    tcpdump

echo "✓ FreeRADIUS instalado"

# Detener servicio para configuración
sudo systemctl stop freeradius

echo "=== Configurando FreeRADIUS ==="

# Configurar clientes
sudo bash -c 'cat > /etc/freeradius/3.0/clients.conf << EOF
client localhost {
    ipaddr = 127.0.0.1
    secret = testing123
    shortname = localhost
}

client localnet {
    ipaddr = 192.168.0.0/16
    secret = SuperSecretRADIUS2024!
    shortname = localnet
}
EOF'

# Configurar usuarios
sudo bash -c 'cat > /etc/freeradius/3.0/users << EOF
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
    Tunnel-Private-Group-Id = 20

invitado Cleartext-Password := "guest123"
    Reply-Message = "Acceso Invitado",
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 30,
    Session-Timeout = 3600

testuser Cleartext-Password := "testpass"
    Reply-Message = "Test User OK"

DEFAULT Auth-Type := Reject
    Reply-Message = "Usuario no autorizado"
EOF'

echo "=== Generando Certificados ==="

CERT_DIR="/etc/ssl/radius-certs"
sudo mkdir -p $CERT_DIR/{ca,server,clients}/{private,certs,csr}
sudo chmod 700 $CERT_DIR/*/private

cd $CERT_DIR

# Generar CA
echo "Generando CA..."
sudo openssl genrsa -out ca/private/ca.key 4096
sudo openssl req -key ca/private/ca.key -new -x509 -days 3650 -sha256 \
    -out ca/certs/ca.pem \
    -subj "/C=AR/ST=Buenos Aires/O=Mi Empresa SA/CN=Mi Empresa CA"

sudo touch ca/index.txt
echo 1000 | sudo tee ca/serial

# Generar certificado servidor
echo "Generando certificado servidor..."
sudo openssl genrsa -out server/private/server.key 2048
sudo openssl req -key server/private/server.key -new -sha256 \
    -out server/csr/server.csr \
    -subj "/C=AR/ST=Buenos Aires/O=Mi Empresa SA/CN=radius.empresa.local"

# Configuración mínima para firmar
sudo bash -c 'cat > ca.cnf << EOFCONF
[ca]
default_ca = CA_default

[CA_default]
dir = /etc/ssl/radius-certs/ca
database = \$dir/index.txt
serial = \$dir/serial
default_md = sha256
default_days = 730
policy = policy_anything

[policy_anything]
countryName = optional
stateOrProvinceName = optional
organizationName = optional
commonName = supplied
EOFCONF'

sudo openssl ca -config ca.cnf -in server/csr/server.csr \
    -out server/certs/server.pem -batch

# Generar DH
echo "Generando parámetros DH..."
sudo openssl dhparam -out dh 2048

# Copiar a FreeRADIUS
sudo cp ca/certs/ca.pem /etc/freeradius/3.0/certs/
sudo cp server/certs/server.pem /etc/freeradius/3.0/certs/
sudo cp server/private/server.key /etc/freeradius/3.0/certs/
sudo cp dh /etc/freeradius/3.0/certs/

sudo chown -R freerad:freerad /etc/freeradius/3.0/certs/
sudo chmod 640 /etc/freeradius/3.0/certs/*
sudo chmod 600 /etc/freeradius/3.0/certs/server.key

echo "=== Iniciando FreeRADIUS ==="

sudo systemctl enable freeradius
sudo systemctl start freeradius

sleep 2

if sudo systemctl is-active --quiet freeradius; then
    echo "✓ FreeRADIUS iniciado correctamente"
else
    echo "✗ Error al iniciar FreeRADIUS"
    exit 1
fi

echo "=== Probando autenticación ==="

radtest testuser testpass localhost 0 testing123

echo ""
echo "=== INSTALACIÓN COMPLETADA ==="
echo "FreeRADIUS está corriendo en WSL"
echo "Servidor RADIUS: localhost:1812"
'@

    # Guardar script temporalmente
    $tempScript = "$env:TEMP\install-radius.sh"
    $installScript | Out-File -FilePath $tempScript -Encoding ASCII

    # Copiar a WSL y ejecutar
    Write-Info "Copiando script a WSL..."
    wsl cp "/mnt/c/Users/$env:USERNAME/AppData/Local/Temp/install-radius.sh" /tmp/install-radius.sh

    Write-Info "Ejecutando instalación en WSL..."
    Write-Info "Esto puede tardar varios minutos..."

    wsl chmod +x /tmp/install-radius.sh
    wsl bash /tmp/install-radius.sh

    Write-Success "FreeRADIUS instalado en WSL"
}

# ############################################################################
# Instalar Wireshark
# ############################################################################

function Install-Wireshark {
    Write-Header "PASO 4: Instalando Wireshark"

    # Verificar si Wireshark ya está instalado
    $wireshark = Get-Command wireshark.exe -ErrorAction SilentlyContinue
    if ($wireshark) {
        Write-Success "Wireshark ya instalado"
        return
    }

    Write-Info "Descargando Wireshark..."

    $wiresharkUrl = "https://1.as.dl.wireshark.org/win64/Wireshark-latest-x64.exe"
    $installerPath = "$env:TEMP\Wireshark-installer.exe"

    # Descargar
    Invoke-WebRequest -Uri $wiresharkUrl -OutFile $installerPath

    Write-Info "Instalando Wireshark..."
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait

    Write-Success "Wireshark instalado"
}

# ############################################################################
# Configurar cliente Windows
# ############################################################################

function Configure-Windows-Client {
    Write-Header "PASO 5: Configurando Cliente Windows"

    # Crear directorio para certificados
    $certDir = "$env:USERPROFILE\radius-certs"
    New-Item -ItemType Directory -Force -Path $certDir | Out-Null

    # Copiar certificados desde WSL
    Write-Info "Copiando certificados desde WSL..."

    wsl bash -c "sudo cp /etc/ssl/radius-certs/ca/certs/ca.pem /tmp/"
    wsl bash -c "sudo chmod 644 /tmp/ca.pem"

    # Convertir path de Windows a WSL
    $wslPath = wsl wslpath "'$certDir'"
    wsl cp /tmp/ca.pem "$wslPath/"

    Write-Success "Certificado CA copiado a: $certDir"

    # Crear instrucciones
    $instructions = @"
═══════════════════════════════════════════════════════════════════
  INSTRUCCIONES - CERTIFICADOS EN WINDOWS
═══════════════════════════════════════════════════════════════════

UBICACIÓN: $certDir

═══════════════════════════════════════════════════════════════════
  IMPORTAR CERTIFICADO CA
═══════════════════════════════════════════════════════════════════

1. Doble click en ca.pem
2. Instalar certificado
3. Ubicación: Equipo local
4. Almacén: Entidades de certificación raíz de confianza
5. Finalizar

O desde PowerShell (como Administrador):
  Import-Certificate -FilePath "$certDir\ca.pem" ``
    -CertStoreLocation Cert:\LocalMachine\Root

═══════════════════════════════════════════════════════════════════
  VERIFICAR CERTIFICADOS
═══════════════════════════════════════════════════════════════════

Win + R > certmgr.msc > Enter

Verificar en:
  - Entidades de certificación raíz de confianza > Certificados
    Debe aparecer: Mi Empresa CA

═══════════════════════════════════════════════════════════════════
  PROBAR AUTENTICACIÓN RADIUS
═══════════════════════════════════════════════════════════════════

Desde WSL:
  wsl radtest testuser testpass localhost 0 testing123

Debería mostrar:
  Received Access-Accept...

═══════════════════════════════════════════════════════════════════
"@

    $instructions | Out-File -FilePath "$certDir\INSTRUCCIONES.txt" -Encoding UTF8

    Write-Success "Instrucciones creadas: $certDir\INSTRUCCIONES.txt"
}

# ############################################################################
# Testing
# ############################################################################

function Test-Installation {
    Write-Header "PASO 6: Probando Instalación"

    Write-Info "Probando autenticación RADIUS..."

    $result = wsl radtest testuser testpass localhost 0 testing123 2>&1

    if ($result -match "Access-Accept") {
        Write-Success "Autenticación exitosa"
    } else {
        Write-Error-Custom "Autenticación fallida"
        Write-Info "Ver logs: wsl sudo journalctl -u freeradius -n 50"
    }
}

# ############################################################################
# Crear documentación
# ############################################################################

function Create-Documentation {
    Write-Header "PASO 7: Creando Documentación"

    $docFile = "$env:USERPROFILE\LABORATORIO_WINDOWS_README.txt"

    $documentation = @"
═══════════════════════════════════════════════════════════════════
  LABORATORIO WIFI ENTERPRISE + RADIUS - Windows con WSL2
═══════════════════════════════════════════════════════════════════

FECHA: $(Get-Date)
SISTEMA: Windows $(Get-WmiObject Win32_OperatingSystem).Version

═══════════════════════════════════════════════════════════════════
  COMPONENTES INSTALADOS
═══════════════════════════════════════════════════════════════════

✓ WSL2 (Windows Subsystem for Linux)
✓ Ubuntu 22.04 en WSL
✓ FreeRADIUS en Ubuntu/WSL
✓ Wireshark

═══════════════════════════════════════════════════════════════════
  SERVIDOR RADIUS
═══════════════════════════════════════════════════════════════════

Ubicación: Ubuntu en WSL2
Acceso desde Windows: localhost:1812
Shared Secret: $SHARED_SECRET

═══════════════════════════════════════════════════════════════════
  USUARIOS CONFIGURADOS
═══════════════════════════════════════════════════════════════════

alumno1 / password1 → VLAN 10
alumno2 / password2 → VLAN 10
director / password3 → VLAN 20
invitado / guest123 → VLAN 30
testuser / testpass → (sin VLAN)

═══════════════════════════════════════════════════════════════════
  COMANDOS ÚTILES
═══════════════════════════════════════════════════════════════════

# DESDE POWERSHELL:

# Acceder a WSL (Ubuntu)
wsl

# Probar autenticación desde WSL
wsl radtest testuser testpass localhost 0 testing123

# Ver logs de RADIUS
wsl sudo tail -f /var/log/freeradius/radius.log

# Iniciar Wireshark
& "C:\Program Files\Wireshark\Wireshark.exe"

# DENTRO DE WSL (después de 'wsl'):

# Ver estado de FreeRADIUS
sudo systemctl status freeradius

# Modo debug
sudo systemctl stop freeradius
sudo freeradius -X

# Reiniciar servicio
sudo systemctl restart freeradius

# Probar autenticación
radtest alumno1 password1 localhost 0 testing123

═══════════════════════════════════════════════════════════════════
  CAPTURAR TRÁFICO CON WIRESHARK
═══════════════════════════════════════════════════════════════════

1. Abrir Wireshark (como Administrador)
2. Seleccionar interfaz: Loopback (o vEthernet WSL)
3. Filtro: udp.port == 1812
4. Start Capture
5. En PowerShell:
   wsl radtest testuser testpass localhost 0 testing123
6. Ver paquetes RADIUS en Wireshark

═══════════════════════════════════════════════════════════════════
  INICIAR/DETENER WSL
═══════════════════════════════════════════════════════════════════

Iniciar WSL (si está apagada):
  wsl

Detener WSL:
  wsl --shutdown

Listar distribuciones:
  wsl --list --verbose

═══════════════════════════════════════════════════════════════════
  DEMO PARA CLASE
═══════════════════════════════════════════════════════════════════

Terminal 1 (PowerShell) - Iniciar RADIUS debug:
  wsl
  sudo systemctl stop freeradius
  sudo freeradius -X

Terminal 2 (PowerShell) - Ejecutar autenticación:
  wsl radtest alumno1 password1 localhost 0 testing123

Wireshark - Capturar tráfico:
  Interface: Loopback
  Filter: udp.port == 1812

═══════════════════════════════════════════════════════════════════
  TROUBLESHOOTING
═══════════════════════════════════════════════════════════════════

Problema: WSL no inicia
  wsl --shutdown
  wsl

Problema: FreeRADIUS no responde
  wsl sudo systemctl status freeradius
  wsl sudo journalctl -u freeradius -n 50

Problema: "Access-Reject"
  wsl sudo freeradius -X
  (ejecutar autenticación y ver logs)

═══════════════════════════════════════════════════════════════════
  RECURSOS
═══════════════════════════════════════════════════════════════════

Certificados: $env:USERPROFILE\radius-certs\
Scripts: $SCRIPTS_DIR\

═══════════════════════════════════════════════════════════════════
"@

    $documentation | Out-File -FilePath $docFile -Encoding UTF8

    Write-Success "Documentación creada: $docFile"

    # Mostrar resumen
    Write-Host $documentation
}

# ############################################################################
# Función principal
# ############################################################################

function Main {
    Clear-Host

    Write-Host @"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   INSTALADOR AUTOMÁTICO - LABORATORIO WIFI ENTERPRISE + RADIUS   ║
║                                                                   ║
║   Plataforma: Windows 10/11 (con WSL2)                           ║
║   Versión: 1.0                                                   ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

    Write-Info "Este script instalará:"
    Write-Host "  • WSL2 (Windows Subsystem for Linux)"
    Write-Host "  • Ubuntu 22.04 en WSL"
    Write-Host "  • FreeRADIUS en Ubuntu"
    Write-Host "  • Wireshark para análisis"
    Write-Host ""

    $continue = Read-Host "¿Desea continuar? (S/N)"
    if ($continue -ne 'S' -and $continue -ne 's') {
        Write-Info "Instalación cancelada"
        exit 0
    }

    # Ejecutar pasos
    Install-WSL
    Install-Ubuntu
    Set-WSL2-Default
    Install-FreeRADIUS-WSL
    Install-Wireshark
    Configure-Windows-Client
    Test-Installation
    Create-Documentation

    # Resumen final
    Write-Header "INSTALACIÓN COMPLETADA"

    Write-Success "Laboratorio WiFi Enterprise + RADIUS instalado exitosamente"
    Write-Host ""
    Write-Info "Próximos pasos:"
    Write-Host "  1. Leer: notepad $env:USERPROFILE\LABORATORIO_WINDOWS_README.txt"
    Write-Host "  2. Probar: wsl radtest testuser testpass localhost 0 testing123"
    Write-Host "  3. Debug: wsl sudo freeradius -X"
    Write-Host ""
}

# Ejecutar
Main
