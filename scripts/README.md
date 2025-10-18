# Scripts de Instalación Automática
## Laboratorio WiFi Enterprise + RADIUS

Estos scripts instalan y configuran **automáticamente** un laboratorio completo de WiFi Enterprise con FreeRADIUS, certificados PKI, y herramientas de análisis.

---

## 📦 Scripts Disponibles

### 1. **install-linux.sh** - Para Linux (Ubuntu/Debian)
Instalación nativa en Linux con FreeRADIUS directo.

### 2. **install-macos.sh** - Para macOS (Apple Silicon)
Instalación usando UTM para virtualizar Ubuntu ARM64.

### 3. **install-windows.ps1** - Para Windows 10/11
Instalación usando WSL2 con Ubuntu.

---

## 🚀 Uso Rápido

### Linux (Ubuntu/Debian)

```bash
# Descargar script
curl -O https://raw.githubusercontent.com/.../install-linux.sh

# O si ya lo tienes localmente
cd TP_WiFi_Enterprise_RADIUS/scripts

# Dar permisos de ejecución
chmod +x install-linux.sh

# Ejecutar como root
sudo ./install-linux.sh
```

**Proceso completamente automatizado**

**Requisitos:**
- Ubuntu 22.04+ o Debian 11+
- Acceso root (sudo)
- Conexión a Internet
- 2 GB RAM mínimo
- 10 GB espacio en disco

---

### macOS (Apple Silicon M1/M2/M3/M4)

```bash
# Dar permisos de ejecución
chmod +x install-macos.sh

# Ejecutar (NO requiere sudo)
./install-macos.sh
```

**Proceso completamente automatizado**

Incluye:
- Descarga automática de ISO de Ubuntu Server ARM64
- Instalación de herramientas (Homebrew, UTM, Wireshark)
- Guía interactiva para creación de VM
- Instalación completa de Ubuntu en VM
- Configuración automática de FreeRADIUS y PKI

**Requisitos:**
- macOS 12.0+ (Monterey o superior)
- Apple Silicon (M1/M2/M3/M4)
- 8 GB RAM mínimo
- 30 GB espacio en disco libre
- Conexión a Internet

**Nota:** El script te guiará para crear la VM en UTM. Algunas partes requieren interacción manual.

---

### Windows 10/11

```powershell
# Abrir PowerShell como Administrador
# Click derecho en PowerShell > Ejecutar como Administrador

# Cambiar política de ejecución (temporal)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Ejecutar script
.\install-windows.ps1
```

**Proceso completamente automatizado**

Incluye:
- Habilitación de WSL2 si no está instalado (puede requerir reinicio)
- Instalación de Ubuntu 22.04 en WSL
- Configuración completa de FreeRADIUS y PKI
- Instalación de Wireshark en Windows host

**Requisitos:**
- Windows 10 versión 2004+ o Windows 11
- Acceso de Administrador
- 8 GB RAM mínimo
- 20 GB espacio en disco libre
- Virtualización habilitada en BIOS
- Conexión a Internet

**Nota:** El script puede requerir reinicio de Windows para habilitar WSL2.

---

## 📋 ¿Qué Instala Cada Script?

### Componentes Comunes (todas las plataformas)

✅ **FreeRADIUS 3.x**
- Servidor RADIUS con EAP-TLS
- Configurado y funcionando

✅ **Infraestructura PKI**
- CA (Certificate Authority) auto-firmada
- Certificado del servidor RADIUS
- 4 certificados de cliente (alumno1, alumno2, director, invitado)

✅ **Usuarios Pre-configurados**
- `testuser` / `testpass` - Usuario de prueba
- `alumno1` / `password1` - VLAN 10
- `alumno2` / `password2` - VLAN 10
- `director` / `password3` - VLAN 20
- `invitado` / `guest123` - VLAN 30 (timeout limitado)

✅ **Herramientas de Testing**
- `radtest` - Testing de autenticación
- `radwho` - Ver usuarios conectados
- Configuraciones wpa_supplicant de ejemplo

✅ **Wireshark**
- Análisis de tráfico RADIUS
- Pre-configurado con filtros

✅ **Documentación Completa**
- README con todas las instrucciones
- Ejemplos de comandos
- Guía de troubleshooting

---

## 🎯 Después de la Instalación

### Verificar que todo funciona:

#### Linux:
```bash
# Probar autenticación
radtest testuser testpass localhost 0 testing123

# Debería mostrar: "Received Access-Accept"
```

#### macOS:
```bash
# Conectar a la VM
ssh admin@192.168.64.10
# Password: admin123

# Dentro de la VM, probar
radtest testuser testpass localhost 0 testing123

# Desde macOS (host)
radtest testuser testpass 192.168.64.10 0 testing123
```

#### Windows:
```powershell
# Probar desde WSL
wsl radtest testuser testpass localhost 0 testing123

# Debería mostrar: "Received Access-Accept"
```

---

## 🔍 Modo Debug (Ver Autenticaciones en Detalle)

### Linux:
```bash
# Detener servicio
sudo systemctl stop freeradius

# Iniciar en modo debug
sudo freeradius -X

# En otra terminal, ejecutar autenticación
radtest alumno1 password1 localhost 0 testing123

# Ver logs detallados en la primera terminal
```

### macOS:
```bash
# SSH a la VM
ssh admin@192.168.64.10

# Modo debug
sudo systemctl stop freeradius
sudo freeradius -X

# Desde macOS, probar
radtest alumno1 password1 192.168.64.10 0 testing123
```

### Windows:
```powershell
# Entrar a WSL
wsl

# Modo debug
sudo systemctl stop freeradius
sudo freeradius -X

# En otra ventana PowerShell
wsl radtest alumno1 password1 localhost 0 testing123
```

---

## 📊 Capturar Tráfico con Wireshark

### Linux:
```bash
# Capturar en interfaz loopback
sudo tcpdump -i lo port 1812 -w /tmp/radius.pcap

# Ejecutar autenticación
radtest testuser testpass localhost 0 testing123

# Detener captura (Ctrl+C)

# Analizar
wireshark /tmp/radius.pcap
```

### macOS:
```bash
# Capturar interfaz de UTM (bridge)
sudo tcpdump -i bridge100 port 1812 -w ~/Desktop/radius.pcap

# Ejecutar autenticación
radtest testuser testpass 192.168.64.10 0 testing123

# Analizar
wireshark ~/Desktop/radius.pcap
```

### Windows:
```powershell
# Abrir Wireshark como Administrador

# Seleccionar interfaz: "Adapter for loopback traffic capture"
# Filtro: udp.port == 1812
# Start

# En PowerShell:
wsl radtest testuser testpass localhost 0 testing123

# Ver paquetes en Wireshark
```

---

## 📁 Estructura de Archivos Generados

### Linux:
```
/etc/freeradius/3.0/          - Configuración RADIUS
/etc/ssl/radius-certs/        - Certificados PKI
/root/LABORATORIO_README.txt  - Documentación completa
/root/radius-lab-configs/     - Configs de cliente
```

### macOS:
```
UTM VM: RADIUS-Server
~/radius-lab-scripts/         - Scripts
~/radius-certs/               - Certificados (copiados de VM)
~/LABORATORIO_MACOS_README.txt - Documentación
```

### Windows:
```
WSL: Ubuntu-22.04
C:\Users\<user>\radius-certs\       - Certificados
C:\Users\<user>\LABORATORIO_WINDOWS_README.txt - Documentación
```

---

## 🛠️ Troubleshooting

### Script falla en Linux

**Error: "Package not found"**
```bash
# Actualizar repos
sudo apt update
sudo apt upgrade

# Re-ejecutar script
sudo ./install-linux.sh
```

**Error: "FreeRADIUS won't start"**
```bash
# Ver logs
sudo journalctl -u freeradius -n 50

# Verificar configuración
sudo freeradius -CX
```

### Script falla en macOS

**Error: "UTM not found"**
```bash
# Instalar UTM manualmente
brew install --cask utm

# O descargar de: https://mac.getutm.app/
```

**Error: "Cannot download Ubuntu ISO"**
```bash
# Descargar manualmente:
# https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso

# Colocar en: ~/Downloads/ubuntu-22.04.3-live-server-arm64.iso
```

### Script falla en Windows

**Error: "WSL not installed"**
```powershell
# Instalar WSL manualmente
wsl --install

# Reiniciar Windows
# Re-ejecutar script
```

**Error: "Ubuntu installation failed"**
```powershell
# Reiniciar WSL
wsl --shutdown

# Listar distribuciones
wsl --list

# Reinstalar Ubuntu
wsl --install -d Ubuntu-22.04
```

---

## 🔄 Desinstalar / Limpiar

### Linux:
```bash
# Remover FreeRADIUS
sudo apt remove --purge freeradius*
sudo rm -rf /etc/freeradius
sudo rm -rf /etc/ssl/radius-certs
```

### macOS:
```bash
# Borrar VM en UTM (desde la interfaz)
# Borrar scripts y certs
rm -rf ~/radius-lab-scripts
rm -rf ~/radius-certs
```

### Windows:
```powershell
# Desinstalar distribución WSL
wsl --unregister Ubuntu-22.04

# Limpiar archivos
Remove-Item -Recurse "$env:USERPROFILE\radius-certs"
```

---

## 📚 Próximos Pasos

Después de la instalación exitosa:

1. **Leer la documentación generada**
   - Linux: `cat /root/LABORATORIO_README.txt`
   - macOS: `cat ~/LABORATORIO_MACOS_README.txt`
   - Windows: `notepad %USERPROFILE%\LABORATORIO_WINDOWS_README.txt`

2. **Revisar material del TP**
   - Ver archivo: `00_Introduccion_Teorica.md`
   - Seguir: `GUIA_CLASE_UNICA.md`

3. **Practicar con Wireshark**
   - Capturar autenticaciones
   - Analizar paquetes RADIUS
   - Identificar fases de EAP-TLS

4. **Configurar Access Point real** (opcional)
   - Usar configuración de `03_Configuracion_Access_Point.md`
   - Apuntar AP a la IP del servidor RADIUS
   - Configurar shared secret

---

## ⚠️ Notas Importantes

### Seguridad

❗ **Este es un laboratorio de PRUEBA**
- Las contraseñas son genéricas (password1, password2, etc.)
- Los certificados son auto-firmados
- El shared secret es conocido

❗ **NO usar en producción sin:**
- Cambiar todas las contraseñas
- Generar certificados de CA privada real
- Configurar shared secrets únicos y fuertes
- Implementar políticas de seguridad

### Performance

Los scripts están optimizados para laboratorio educativo:
- No están tuneados para alto rendimiento
- No tienen HA (High Availability)
- Logs en modo básico

Para producción, revisar: `06_Mejores_Practicas_Empresariales.md`

### Compatibilidad

✅ **Probado en:**
- Ubuntu 22.04 LTS
- macOS Ventura (M2)
- Windows 11

⚠️ **Puede funcionar en:**
- Otras distros Debian-based
- macOS Monterey+
- Windows 10 (2004+)

❌ **No compatible:**
- macOS Intel (requiere VM x86_64)
- Windows 7/8
- Distribuciones no-Debian

---

## 🆘 Soporte

**Si tienes problemas:**

1. Revisar sección de Troubleshooting arriba
2. Ejecutar script en modo debug (bash -x script.sh)
3. Revisar logs del sistema
4. Consultar documentación completa del TP

**Logs importantes:**

- FreeRADIUS: `/var/log/freeradius/radius.log`
- System: `journalctl -u freeradius`
- Script: Output en pantalla durante ejecución

---

## 📊 Estadísticas de Instalación

| Plataforma | Tamaño Descarga | Espacio Disco | Notas |
|------------|-----------------|---------------|-------|
| Linux | ~100 MB | ~500 MB | Instalación nativa, más eficiente |
| macOS | ~1.5 GB | ~5 GB | Incluye ISO de Ubuntu ARM64 |
| Windows | ~300 MB | ~2 GB | Mediante WSL2 |

---

## ✅ Checklist Post-Instalación

Verifica que todo esté funcionando:

```
[ ] FreeRADIUS está corriendo
[ ] radtest funciona correctamente
[ ] Certificados generados (CA + servidor + clientes)
[ ] Usuarios configurados con VLANs
[ ] Wireshark instalado y puede capturar
[ ] Documentación generada y legible
[ ] Modo debug funciona (freeradius -X)
[ ] Puedo ver logs en tiempo real
```

---

**¡Laboratorio listo para usar!** 🎉

Para comenzar la clase práctica, ver: `GUIA_CLASE_UNICA.md`
