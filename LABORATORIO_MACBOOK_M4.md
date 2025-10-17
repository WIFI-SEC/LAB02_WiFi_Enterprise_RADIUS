# Laboratorio WiFi Enterprise Completo en MacBook M4
## Sin Hardware Adicional - Todo Virtualizado

**Plataforma**: MacBook M4 (Apple Silicon - ARM64)
**Objetivo**: Simular completamente la infraestructura WiFi Enterprise
**Tiempo de setup**: 2-3 horas
**Costo**: $0 (todo software libre)

---

## 🎯 Arquitectura del Laboratorio Virtual

```
┌─────────────────────────────────────────────────────────────┐
│              MacBook M4 (Host macOS)                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          UTM / Parallels / Docker                   │   │
│  │                                                     │   │
│  │  ┌──────────────┐      ┌──────────────┐           │   │
│  │  │   VM Ubuntu  │      │  Hostapd AP  │           │   │
│  │  │   (RADIUS)   │◄────►│  (Simulado)  │           │   │
│  │  │192.168.64.10 │      │192.168.64.20 │           │   │
│  │  └──────────────┘      └──────────────┘           │   │
│  │                                                     │   │
│  │  Red virtual (bridge): 192.168.64.0/24             │   │
│  └─────────────────────────────────────────────────────┘   │
│                           ▲                                 │
│                           │                                 │
│  ┌────────────────────────┴──────────────────────┐         │
│  │      Cliente WiFi (macOS nativo)              │         │
│  │  Se conectará al AP virtual vía loopback      │         │
│  └───────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Opción 1: UTM (Recomendada - Gratis y Nativa para ARM)

### Ventajas de UTM
- ✅ **Gratis y open source**
- ✅ **Optimizado para Apple Silicon**
- ✅ **Virtualización nativa (muy rápida)**
- ✅ **Interfaz simple**

### Paso 1: Instalar UTM

```bash
# Opción A: Desde la App Store (recomendado, soporta el proyecto)
# https://apps.apple.com/app/utm-virtual-machines/id1538878817

# Opción B: Descarga directa (gratis)
# https://mac.getutm.app/

# Opción C: Con Homebrew
brew install --cask utm
```

### Paso 2: Crear VM Ubuntu Server 22.04 ARM64

**2.1 Descargar ISO de Ubuntu Server ARM64**

```bash
# Ir a navegador y descargar
# https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso

# O con curl
cd ~/Downloads
curl -L -O https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso
```

**2.2 Crear VM en UTM**

1. Abrir UTM
2. Click en "+" → "Virtualize"
3. Seleccionar "Linux"
4. Configuración:
   ```
   Nombre: RADIUS-Server

   System:
   - Architecture: ARM64 (aarch64)
   - Memory: 4096 MB (4 GB)
   - CPU Cores: 2

   Storage:
   - Size: 20 GB

   Shared Directory: (opcional)

   Boot ISO: Seleccionar ubuntu-22.04.3-live-server-arm64.iso
   ```

5. Click "Save"

**2.3 Instalar Ubuntu**

```
1. Start VM
2. Install Ubuntu Server
   - Language: English
   - Network: Use DHCP (anotará IP, ej: 192.168.64.10)
   - Storage: Use entire disk
   - Profile:
     - Name: admin
     - Server name: radius-server
     - Username: admin
     - Password: admin123
   - SSH: Enable OpenSSH Server
   - No featured snaps
3. Reboot
4. Login: admin / admin123
```

**2.4 Configurar red estática (opcional pero recomendado)**

```bash
# Dentro de la VM Ubuntu
sudo nano /etc/netplan/00-installer-config.yaml
```

```yaml
network:
  version: 2
  ethernets:
    enp0s1:  # O el nombre de tu interfaz
      dhcp4: no
      addresses:
        - 192.168.64.10/24
      gateway4: 192.168.64.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
```

```bash
sudo netplan apply
ip addr show
```

### Paso 3: Instalar FreeRADIUS en la VM

**Desde el Mac, conectar por SSH:**

```bash
# En terminal de macOS
ssh admin@192.168.64.10
# Password: admin123
```

**Instalar FreeRADIUS:**

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar FreeRADIUS
sudo apt install freeradius freeradius-utils freeradius-eap openssl -y

# Verificar
freeradius -v
sudo systemctl status freeradius
```

**Continuar con configuración estándar:**
- Seguir archivo `01_Configuracion_Servidor_RADIUS.md`
- Generar certificados según `02_Gestion_Certificados_PKI.md`

---

## ✅ Opción 2: Docker (Más Rápido para Demo)

### Ventajas de Docker
- ✅ **Muy rápido de levantar**
- ✅ **Contenedores pre-configurados**
- ✅ **Fácil de resetear**

### Paso 1: Instalar Docker Desktop para Mac

```bash
# Opción A: Descargar desde web
# https://www.docker.com/products/docker-desktop/

# Opción B: Con Homebrew
brew install --cask docker

# Abrir Docker Desktop y completar setup
```

### Paso 2: Crear Dockerfile para FreeRADIUS

```bash
# Crear directorio
mkdir -p ~/radius-lab
cd ~/radius-lab
```

**Crear `Dockerfile`:**

```dockerfile
FROM ubuntu:22.04

# Variables de entorno
ENV DEBIAN_FRONTEND=noninteractive

# Instalar FreeRADIUS
RUN apt update && \
    apt install -y \
    freeradius \
    freeradius-utils \
    freeradius-eap \
    openssl \
    nano \
    net-tools \
    iputils-ping \
    tcpdump \
    && rm -rf /var/lib/apt/lists/*

# Exponer puertos RADIUS
EXPOSE 1812/udp 1813/udp

# Crear directorio para configuración
RUN mkdir -p /etc/freeradius/3.0/certs

# Copiar script de inicio
COPY start-radius.sh /start-radius.sh
RUN chmod +x /start-radius.sh

CMD ["/start-radius.sh"]
```

**Crear `start-radius.sh`:**

```bash
#!/bin/bash

echo "Iniciando FreeRADIUS en modo debug..."
echo "RADIUS Server: $(hostname -I)"
echo "Puertos: 1812/udp (auth), 1813/udp (acct)"
echo ""

# Ejecutar en foreground con debug
/usr/sbin/freeradius -X
```

**Crear `docker-compose.yml`:**

```yaml
version: '3.8'

services:
  radius:
    build: .
    container_name: radius-server
    ports:
      - "1812:1812/udp"
      - "1813:1813/udp"
    volumes:
      - ./config:/etc/freeradius/3.0
      - ./certs:/etc/ssl/radius-certs
    networks:
      radius-net:
        ipv4_address: 172.20.0.10

  # AP simulado con hostapd (opcional)
  hostapd:
    image: ubuntu:22.04
    container_name: wifi-ap
    privileged: true
    command: tail -f /dev/null  # Mantener vivo
    networks:
      radius-net:
        ipv4_address: 172.20.0.20

networks:
  radius-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
```

**Construir y levantar:**

```bash
# Construir imagen
docker-compose build

# Levantar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f radius
```

**Acceder al contenedor:**

```bash
# Shell en RADIUS server
docker exec -it radius-server bash

# Configurar FreeRADIUS normalmente
cd /etc/freeradius/3.0
nano clients.conf
# etc...
```

---

## 📡 Simular Access Point WiFi

### Opción A: Hostapd en VM/Container (WiFi Simulado)

**NOTA**: No será WiFi real, pero permite probar RADIUS.

```bash
# En VM Ubuntu o contenedor
sudo apt install hostapd -y

# Configurar hostapd
sudo nano /etc/hostapd/hostapd.conf
```

```conf
# Configuración de hostapd para testing
interface=eth0  # Usar interfaz ethernet como simulación
driver=wired    # Driver para ethernet (simula WiFi)
ssid=WiFi-LAB
hw_mode=g
channel=6

# WPA2-Enterprise
wpa=2
wpa_key_mgmt=WPA-EAP
wpa_pairwise=CCMP
auth_algs=1

# RADIUS
auth_server_addr=127.0.0.1
auth_server_port=1812
auth_server_shared_secret=testing123

# Accounting
acct_server_addr=127.0.0.1
acct_server_port=1813
acct_server_shared_secret=testing123

# IEEE 802.1X
ieee8021x=1
eapol_version=2
eapol_key_index_workaround=0
```

**Iniciar hostapd:**

```bash
sudo hostapd -dd /etc/hostapd/hostapd.conf
```

### Opción B: Usar Network Link Conditioner (macOS)

**Simular conexión WiFi con limitaciones:**

```bash
# Instalar Additional Tools for Xcode
# https://developer.apple.com/download/all/

# Abrir Network Link Conditioner
# System Settings > Developer > Network Link Conditioner

# Configurar perfil "WiFi" con:
# - Downlink: 20 Mbps
# - Uplink: 5 Mbps
# - Latency: 10ms
```

### Opción C: wpa_supplicant como Cliente (Recomendado)

**En lugar de AP real, usar wpa_supplicant para simular cliente:**

```bash
# En la VM Ubuntu
sudo apt install wpasupplicant -y

# Crear configuración
nano ~/wpa-test.conf
```

```conf
network={
    ssid="WiFi-LAB"
    key_mgmt=WPA-EAP
    eap=TLS
    identity="alumno1@empresa.local"

    ca_cert="/home/admin/certs/ca.pem"
    client_cert="/home/admin/certs/alumno1.pem"
    private_key="/home/admin/certs/alumno1.key"
    private_key_passwd="whatever"
}
```

**Probar autenticación:**

```bash
# Usando eapol_test (herramienta de testing)
sudo apt install build-essential libssl-dev libnl-3-dev libnl-genl-3-dev -y

# Compilar eapol_test
wget http://w1.fi/cgit/hostap/plain/wpa_supplicant/eapol_test.c
# (o usar desde repositorio)

# Probar autenticación
eapol_test -c wpa-test.conf -a 127.0.0.1 -p 1812 -s testing123
```

---

## 🖥️ Configurar Cliente en macOS (Nativo)

### Escenario: Conectar el Mac al RADIUS virtual

**Problema**: No hay WiFi real, entonces usaremos interfaz loopback o ethernet virtual.

### Solución 1: Usar Ethernet Virtual con VLAN

```bash
# Crear interfaz VLAN virtual
sudo ifconfig vlan1 create

# Configurar VLAN
sudo ifconfig vlan1 vlan 10 vlandev en0

# Asignar IP
sudo ifconfig vlan1 192.168.64.50 netmask 255.255.255.0
```

### Solución 2: Probar con radtest (Más Simple)

```bash
# Instalar FreeRADIUS utils en macOS
brew install freeradius-server

# Probar autenticación contra VM
radtest alumno1 password 192.168.64.10 0 testing123

# Ver resultado:
# Sent Access-Request Id 123...
# Received Access-Accept Id 123... ← ÉXITO
```

### Solución 3: Usar wpa_supplicant en el Mac

```bash
# Instalar wpa_supplicant
brew install wpa_supplicant

# Crear configuración (igual que antes)
nano ~/wpa-test.conf

# Probar
sudo wpa_supplicant -i en0 -c ~/wpa-test.conf -D wired
```

---

## 📊 Captura de Tráfico con Wireshark en macOS

### Instalar Wireshark

```bash
# Opción A: Homebrew
brew install --cask wireshark

# Opción B: Descargar desde web
# https://www.wireshark.org/download.html
# Descargar versión ARM64
```

### Capturar Tráfico RADIUS

**Entre macOS y VM:**

```bash
# 1. Identificar interfaz de VM
ifconfig | grep -A 5 bridge

# 2. Iniciar Wireshark
wireshark

# 3. Seleccionar interfaz (ej: bridge100)

# 4. Filtro de captura:
udp port 1812 or udp port 1813

# 5. En otra terminal, provocar autenticación:
radtest alumno1 password 192.168.64.10 0 testing123
```

**Dentro de la VM:**

```bash
# Conectar a VM por SSH
ssh admin@192.168.64.10

# Capturar con tcpdump
sudo tcpdump -i any port 1812 or port 1813 -w /tmp/radius.pcap

# Transferir a Mac
# En Mac:
scp admin@192.168.64.10:/tmp/radius.pcap ~/Desktop/

# Abrir en Wireshark
wireshark ~/Desktop/radius.pcap
```

### Capturar Tráfico "WiFi" Simulado

```bash
# Si usas hostapd en la VM
ssh admin@192.168.64.10

# Capturar EAPOL
sudo tcpdump -i eth0 'ether proto 0x888e' -w /tmp/eapol.pcap

# Copiar a Mac y analizar
scp admin@192.168.64.10:/tmp/eapol.pcap ~/Desktop/
wireshark ~/Desktop/eapol.pcap
```

---

## 🧪 Testing Completo del Laboratorio

### Test 1: Conectividad básica

```bash
# Desde macOS
ping 192.168.64.10
# Debe responder

# SSH
ssh admin@192.168.64.10
# Debe conectar
```

### Test 2: RADIUS funcionando

```bash
# En VM
sudo systemctl status freeradius
# Debe estar "active (running)"

# Ver logs
sudo tail -f /var/log/freeradius/radius.log
```

### Test 3: Autenticación local

```bash
# Dentro de VM
radtest testuser testpass localhost 0 testing123

# Salida esperada:
# Sent Access-Request...
# Received Access-Accept...
```

### Test 4: Autenticación desde macOS

```bash
# Desde macOS
radtest testuser testpass 192.168.64.10 0 testing123

# Debe recibir Access-Accept
```

### Test 5: EAP-TLS con certificados

```bash
# En VM, generar certificados (ver archivo 02)
cd /etc/ssl/radius-certs
sudo ./generate-client-cert.sh alumno1

# Copiar certificados al Mac
scp -r admin@192.168.64.10:/etc/ssl/radius-certs/clients/certs/alumno1.p12 ~/Desktop/

# Importar en Keychain del Mac
open ~/Desktop/alumno1.p12
# Password: alumno1

# Probar con eapol_test
eapol_test -c wpa-test.conf -a 192.168.64.10 -p 1812 -s testing123
```

---

## 🎓 Configuración para la Clase

### Setup Pre-Clase

**1 día antes:**

```bash
# Crear snapshot de VM
# En UTM: Click derecho en VM > Snapshot > Create

# O en Docker:
docker commit radius-server radius-backup:v1

# Probar todo el flujo completo
# Crear captura .pcap de ejemplo
```

**2 horas antes:**

```bash
# Iniciar VM/containers
cd ~/radius-lab
docker-compose up -d

# O iniciar VM en UTM

# Verificar todo funciona
radtest testuser testpass 192.168.64.10 0 testing123
```

### Durante la Clase

**Proyectar terminal con:**

```bash
# En una ventana: RADIUS en modo debug
ssh admin@192.168.64.10
sudo freeradius -X

# En otra ventana: Ejecutar comandos
radtest alumno1 password 192.168.64.10 0 testing123

# En otra: Wireshark capturando
wireshark -i bridge100 -k -f "udp port 1812"
```

**Usar pantalla dividida:**
```
┌────────────────────┬────────────────────┐
│   RADIUS Debug     │    Wireshark       │
│   (Ver logs)       │  (Ver paquetes)    │
│                    │                    │
│ (0) Received...    │ Frame 1: Access-   │
│ (0) User-Name...   │  Request           │
│ (0) Access-Accept  │ Frame 2: Access-   │
│                    │  Accept            │
└────────────────────┴────────────────────┘
```

---

## 💾 Backup y Restore

### Guardar configuración

```bash
# Desde macOS, backup de VM
cd ~/radius-lab

# Si usas Docker:
docker exec radius-server tar -czf /tmp/radius-backup.tar.gz /etc/freeradius/3.0 /etc/ssl/radius-certs
docker cp radius-server:/tmp/radius-backup.tar.gz ~/Desktop/

# Si usas UTM:
# Snapshot automático al apagar VM
```

### Restore

```bash
# En Docker:
docker cp ~/Desktop/radius-backup.tar.gz radius-server:/tmp/
docker exec radius-server tar -xzf /tmp/radius-backup.tar.gz -C /

# En UTM:
# Restore from snapshot en la UI
```

---

## 🚀 Quick Start Script

**Crear script para levantar todo:**

```bash
#!/bin/bash
# quick-start-lab.sh

echo "=== Iniciando Laboratorio WiFi Enterprise ==="

# Opción 1: Docker
if command -v docker &> /dev/null; then
    echo "Usando Docker..."
    cd ~/radius-lab
    docker-compose up -d
    echo "✓ RADIUS Server: 172.20.0.10"
    echo "✓ Puertos: 1812/1813"

    # Esperar que inicie
    sleep 5

    # Probar conectividad
    docker exec radius-server radtest testuser testpass localhost 0 testing123

# Opción 2: UTM
elif [ -d "$HOME/Library/Containers/com.utmapp.UTM" ]; then
    echo "Usando UTM..."
    # UTM debe iniciarse manualmente desde la app
    echo "Iniciar VM 'RADIUS-Server' desde UTM"

else
    echo "Error: Instalar Docker o UTM primero"
    exit 1
fi

echo ""
echo "=== Laboratorio listo ==="
echo "RADIUS Server: 192.168.64.10 (UTM) o 172.20.0.10 (Docker)"
echo "Test: radtest testuser testpass <IP> 0 testing123"
echo "SSH: ssh admin@<IP>"
echo "Wireshark: Capturar en bridge100 con filtro 'udp port 1812'"
```

```bash
# Hacer ejecutable
chmod +x quick-start-lab.sh

# Ejecutar
./quick-start-lab.sh
```

---

## 📋 Checklist de Laboratorio Funcional

```
Infraestructura:
[ ] UTM o Docker instalado
[ ] VM Ubuntu 22.04 ARM64 funcionando
[ ] Red virtual configurada (192.168.64.0/24)
[ ] SSH accesible desde macOS a VM

RADIUS:
[ ] FreeRADIUS instalado en VM
[ ] Servicio freeradius activo
[ ] Puerto 1812/1813 abierto
[ ] Test con radtest funciona

Certificados:
[ ] CA creada
[ ] Certificado servidor generado
[ ] Al menos 1 certificado cliente generado
[ ] Certificados instalados en /etc/freeradius/3.0/certs/

Cliente:
[ ] radtest funciona desde macOS a VM
[ ] wpa_supplicant instalado (opcional)
[ ] eapol_test compilado (opcional)

Captura:
[ ] Wireshark instalado en macOS
[ ] Puede capturar tráfico en interfaz de VM
[ ] Filtros RADIUS configurados
[ ] .pcap de ejemplo creado

Demo:
[ ] Modo debug de RADIUS funciona
[ ] Captura en vivo funciona
[ ] Autenticación con certificados funciona
[ ] Todo testeado end-to-end
```

---

## 🔧 Troubleshooting del Laboratorio Virtual

### Problema: VM no tiene red

```bash
# Verificar interfaz en UTM
# Settings > Network > Network Mode: Shared Network

# Dentro de VM
ip addr show
ping 8.8.8.8

# Si no funciona, reiniciar VM
sudo reboot
```

### Problema: No puedo conectar por SSH

```bash
# En VM (usar consola de UTM)
sudo systemctl status ssh

# Ver IP de la VM
ip addr show

# Desde macOS
ping <IP-de-VM>
ssh admin@<IP-de-VM>
```

### Problema: RADIUS no inicia

```bash
# En VM
sudo systemctl status freeradius

# Ver logs
sudo journalctl -u freeradius -n 50

# Probar en foreground
sudo freeradius -X
# Ver errores de configuración
```

### Problema: Wireshark no captura tráfico

```bash
# Identificar interfaz correcta
ifconfig

# Buscar bridge100 o similar
# Iniciar captura en esa interfaz

# Si no aparece tráfico, verificar que VM use "bridge mode"
```

---

## 💰 Costos y Requisitos

### Software (TODO GRATIS)

| Software | Costo | Propósito |
|----------|-------|-----------|
| UTM | Gratis ($10 en App Store opcional) | Virtualización |
| Docker Desktop | Gratis | Contenedores |
| Ubuntu Server 22.04 | Gratis | OS para RADIUS |
| FreeRADIUS | Gratis | Servidor RADIUS |
| Wireshark | Gratis | Análisis de tráfico |
| **TOTAL** | **$0** | |

### Recursos de Hardware

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| RAM | 8 GB | 16 GB+ |
| Disco | 30 GB libres | 50 GB+ |
| CPU | M4 (cualquier) | M4 Pro/Max |

**Para clase con 20 alumnos:**
- Cada alumno: MacBook con 8GB+ RAM
- Instructor: MacBook con 16GB+ RAM (para proyectar)

---

## ✅ Ventajas del Laboratorio Virtual

1. **Portátil**: Todo en una laptop
2. **Sin costo**: No requiere APs reales
3. **Repetible**: Snapshots/containers rápidos de resetear
4. **Seguro**: No afecta red de producción
5. **Educativo**: Mismo aprendizaje que con HW real
6. **Escalable**: Cada alumno puede tener su propio lab

---

## 📚 Material Complementario

Después de montar el lab virtual, seguir con:

1. **Configuración de RADIUS**: `01_Configuracion_Servidor_RADIUS.md`
2. **Generación de Certificados**: `02_Gestion_Certificados_PKI.md`
3. **Análisis con Wireshark**: `05_Captura_Analisis_Wireshark.md`
4. **Clase única**: `GUIA_CLASE_UNICA.md`

---

**¡Laboratorio completamente funcional sin hardware adicional!** 🎉

Todo lo que se aprende aquí es 100% aplicable a un ambiente real con APs físicos.
