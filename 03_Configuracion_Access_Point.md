# Configuración del Access Point para WPA2/WPA3-Enterprise

## Introducción

En esta sección configuraremos el Access Point para utilizar autenticación 802.1X con el servidor RADIUS. Cubriremos configuraciones para diferentes marcas de APs empresariales.

---

## 1. Conceptos Previos

### 1.1 Modos de Seguridad WiFi

| Modo | Descripción | Uso |
|------|-------------|-----|
| **Open** | Sin cifrado | Hotspots públicos con portal cautivo |
| **WEP** | Obsoleto, inseguro | ❌ NO USAR |
| **WPA-Personal** | PSK (Pre-Shared Key) | Hogares |
| **WPA2-Personal** | AES-CCMP | Hogares, SOHO |
| **WPA2-Enterprise** | 802.1X + RADIUS | ✓ Empresas (este lab) |
| **WPA3-Personal** | SAE (Simultaneous Authentication) | Hogares modernos |
| **WPA3-Enterprise** | 802.1X + RADIUS + PMF | ✓✓ Empresas (más seguro) |

### 1.2 Parámetros clave para configuración

```
┌─────────────────────────────────────────────────┐
│         Configuración del Access Point          │
├─────────────────────────────────────────────────┤
│ SSID: WiFi-Corporativo                          │
│ Seguridad: WPA2-Enterprise (802.1X)             │
│ Cifrado: AES-CCMP                               │
│ Servidor RADIUS Primario: 192.168.1.10:1812    │
│ Servidor RADIUS Secundario: 192.168.1.11:1812  │
│ Shared Secret: SuperSecretRADIUS2024!           │
│ Accounting: Habilitado (puerto 1813)            │
│ VLAN: Dinámica (asignada por RADIUS)            │
│ PMF: Habilitado (Protected Management Frames)   │
└─────────────────────────────────────────────────┘
```

---

## 2. Configuración por Fabricante

### 2.1 UniFi (Ubiquiti)

#### A. Acceso al Controller

```bash
# Acceder a UniFi Controller
# https://192.168.1.1:8443
```

#### B. Crear nueva red WiFi

**Paso 1: Settings > WiFi > Create New**

```
Name: WiFi-Corporativo
SSID: WiFi-Corporativo
Enabled: ✓
Security: WPA2 Enterprise
```

**Paso 2: Configuración RADIUS**

```
RADIUS Profile: Crear nuevo
  Name: RADIUS-Corporativo

Authentication Servers:
  IP Address: 192.168.1.10
  Port: 1812
  Shared Secret: SuperSecretRADIUS2024!

Accounting Servers:
  IP Address: 192.168.1.10
  Port: 1813
  Shared Secret: SuperSecretRADIUS2024!

RADIUS Assigned VLAN: Habilitado
```

**Paso 3: Configuración avanzada**

```
Advanced Configuration:
  PMF: Enabled (WPA3 Ready)
  Group Rekey Interval: 3600 seconds
  802.11r (Fast Roaming): Enabled
  802.11k (Neighbor Reports): Enabled
  802.11v (BSS Transition): Enabled
  Multicast Enhancement: Enabled
  Minimum Data Rate: 12 Mbps (desabilitar velocidades bajas)
```

#### C. Configuración CLI (alternativa)

Para configuración avanzada vía SSH:

```bash
# Conectar por SSH al UniFi AP
ssh ubnt@192.168.1.20
# Password: ubnt (por defecto)

# Configurar RADIUS en hostapd
mca-cli-op set wireless.1.security=wpaeap
mca-cli-op set wireless.1.radius.1.ip=192.168.1.10
mca-cli-op set wireless.1.radius.1.port=1812
mca-cli-op set wireless.1.radius.1.secret=SuperSecretRADIUS2024!

# Reiniciar servicio WiFi
syswrapper.sh restart-wireless
```

---

### 2.2 TP-Link EAP (Omada)

#### A. Acceso web

```
http://192.168.1.20
Usuario: admin
Password: admin
```

#### B. Configuración del SSID

**Network > Wireless > SSIDs > Add New SSID**

```
SSID Name: WiFi-Corporativo
SSID Broadcast: Enabled
Security Mode: WPA/WPA2-Enterprise

WPA Encryption: AES
WPA Group Rekey: 3600 seconds
```

#### C. Configuración RADIUS

**RADIUS Server Settings:**

```
Primary RADIUS Server:
  IP Address: 192.168.1.10
  Port: 1812
  Shared Secret: SuperSecretRADIUS2024!

Secondary RADIUS Server: (opcional)
  IP Address: 192.168.1.11
  Port: 1812
  Shared Secret: SuperSecretRADIUS2024!

RADIUS Accounting:
  Status: Enable
  Primary Server: 192.168.1.10
  Port: 1813
  Shared Secret: SuperSecretRADIUS2024!
  Interim Update Interval: 600 seconds
```

#### D. Configuración de VLANs

**Network > VLAN**

```
VLAN 10 (Empleados):
  VLAN ID: 10
  Interface: LAN
  IP Subnet: 192.168.10.0/24

VLAN 20 (Gerencia):
  VLAN ID: 20
  Interface: LAN
  IP Subnet: 192.168.20.0/24

VLAN 30 (Invitados):
  VLAN ID: 30
  Interface: LAN
  IP Subnet: 192.168.30.0/24
```

**Habilitar RADIUS-Assigned VLAN:**

```
Network > Wireless > Advanced:
  VLAN: Enable
  RADIUS VLAN Assignment: Enable
```

---

### 2.3 MikroTik

#### A. Acceso vía Winbox o SSH

```bash
# SSH
ssh admin@192.168.1.20

# O usar Winbox (GUI)
```

#### B. Configuración completa vía CLI

```bash
# 1. Configurar interfaz WiFi
/interface wireless security-profiles
add name=radius-profile \
    mode=dynamic-keys \
    authentication-types=wpa2-eap \
    eap-methods=eap-tls,passthrough \
    group-ciphers=aes-ccm \
    unicast-ciphers=aes-ccm

# 2. Configurar servidor RADIUS
/radius
add address=192.168.1.10 \
    secret=SuperSecretRADIUS2024! \
    service=wireless \
    timeout=5s

# Servidor secundario (opcional)
add address=192.168.1.11 \
    secret=SuperSecretRADIUS2024! \
    service=wireless \
    timeout=5s

# 3. Habilitar RADIUS Accounting
/radius
add address=192.168.1.10 \
    secret=SuperSecretRADIUS2024! \
    service=wireless,accounting \
    timeout=5s

# 4. Aplicar perfil de seguridad a interfaz WiFi
/interface wireless
set wlan1 \
    ssid=WiFi-Corporativo \
    mode=ap-bridge \
    band=2ghz-b/g/n \
    security-profile=radius-profile \
    disabled=no

# 5. Configurar VLANs dinámicas
/interface wireless
set wlan1 vlan-mode=use-tag

# 6. Habilitar 802.11w (PMF)
/interface wireless security-profiles
set radius-profile management-protection=allowed
```

#### C. Configuración de VLANs

```bash
# Crear VLANs en el switch/bridge
/interface vlan
add name=vlan10-empleados vlan-id=10 interface=bridge
add name=vlan20-gerencia vlan-id=20 interface=bridge
add name=vlan30-invitados vlan-id=30 interface=bridge

# Configurar IP en cada VLAN
/ip address
add address=192.168.10.1/24 interface=vlan10-empleados
add address=192.168.20.1/24 interface=vlan20-gerencia
add address=192.168.30.1/24 interface=vlan30-invitados
```

---

### 2.4 Cisco (WLC - Wireless LAN Controller)

#### A. Acceso al WLC

```
https://192.168.1.30
Usuario: admin
```

#### B. Configurar servidor RADIUS

**Security > AAA > RADIUS > Authentication**

```
Click "New..."

Server Address: 192.168.1.10
Shared Secret: SuperSecretRADIUS2024!
Port: 1812
Server Status: Enabled
Support for RFC 3576: Enabled
```

**Security > AAA > RADIUS > Accounting**

```
Server Address: 192.168.1.10
Shared Secret: SuperSecretRADIUS2024!
Port: 1813
Server Status: Enabled
```

#### C. Crear WLAN

**WLANs > Create New**

```
Profile Name: Corporativo
SSID: WiFi-Corporativo
Status: Enabled
Security > Layer 2:
  Security: WPA+WPA2
  Authentication Key Management:
    ✓ 802.1X
  Encryption:
    ✓ AES
```

**Security > AAA Servers:**

```
Authentication Servers:
  [✓] Server 1: 192.168.1.10

Accounting Servers:
  [✓] Server 1: 192.168.1.10
```

#### D. Configuración avanzada

**Advanced > Allow AAA Override: Enabled**

Esto permite que RADIUS asigne:
- VLAN ID
- QoS políticas
- ACLs

**QoS > QoS Profile: Silver** (o según necesidad)

---

## 3. Configuración de VLANs Dinámicas

### 3.1 Arquitectura de VLANs

```
                  Access Point (802.1X)
                         │
                         │ Trunk (VLANs 10,20,30)
                         │
                    Switch Core
                         │
           ┌─────────────┼─────────────┐
           │             │             │
        VLAN 10       VLAN 20       VLAN 30
      Empleados      Gerencia      Invitados
           │             │             │
    192.168.10.0/24  192.168.20.0/24  192.168.30.0/24
```

### 3.2 Configuración del Switch (ejemplo Cisco)

```cisco
! Configurar puerto del AP como trunk
interface GigabitEthernet0/1
 description Access Point WiFi-Corporativo
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30
 spanning-tree portfast trunk
 no shutdown

! Crear VLANs
vlan 10
 name EMPLEADOS
vlan 20
 name GERENCIA
vlan 30
 name INVITADOS

! Configurar interfaces VLAN con gateway
interface Vlan10
 ip address 192.168.10.1 255.255.255.0
 no shutdown

interface Vlan20
 ip address 192.168.20.1 255.255.255.0
 no shutdown

interface Vlan30
 ip address 192.168.30.1 255.255.255.0
 no shutdown
```

### 3.3 Verificación de VLAN asignada por RADIUS

En FreeRADIUS, los atributos para asignar VLAN son:

```conf
# En /etc/freeradius/3.0/users
jperez Cleartext-Password := "Empleado2024!"
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 10
```

**Atributos RADIUS para VLANs:**

| Atributo | Valor | Descripción |
|----------|-------|-------------|
| `Tunnel-Type` | VLAN (13) | Tipo de túnel |
| `Tunnel-Medium-Type` | IEEE-802 (6) | Medio 802 |
| `Tunnel-Private-Group-Id` | 1-4094 | ID de VLAN |

---

## 4. Configuración de Seguridad Avanzada

### 4.1 Protected Management Frames (PMF / 802.11w)

**¿Qué protege?**
- Ataques de desautenticación forzada
- Ataques de desasociación
- Manipulación de beacon frames

**Configuración:**

```
PMF Mode:
  - Disabled: Sin protección (NO recomendado)
  - Capable: Opcional, compatible con clientes antiguos
  - Required: Obligatorio (solo clientes con soporte PMF)

Recomendación: Capable (para transición)
              Required (para máxima seguridad)
```

**UniFi:**
```
Settings > WiFi > Advanced > PMF: Required
```

**MikroTik:**
```
/interface wireless security-profiles
set radius-profile management-protection=required
```

### 4.2 Fast Roaming (802.11r)

Mejora la experiencia al roaming entre APs.

**Configuración UniFi:**
```
Settings > WiFi > Advanced:
  802.11r Fast Roaming: Enabled
  FT Pre-Authentication: Enabled
```

**MikroTik:**
```
/interface wireless
set wlan1 wds-mode=dynamic-mesh ft-over-ds=yes
```

### 4.3 Restricciones de velocidad mínima

Deshabilitar velocidades antiguas mejora performance:

**Velocidades recomendadas (802.11n/ac/ax):**
- Deshabilitar: 1, 2, 5.5, 6, 9, 11 Mbps
- Habilitar: 12, 18, 24, 36, 48, 54 Mbps + MCS

**UniFi:**
```
Settings > WiFi > Advanced:
  Minimum Data Rate Control: 12 Mbps (2.4GHz)
  Minimum Data Rate Control: 24 Mbps (5GHz)
```

### 4.4 Beacon Interval y DTIM

```
Beacon Interval: 100 ms (default, OK)
DTIM Period: 3 (balance entre power saving y latencia)
```

---

## 5. Verificación y Testing

### 5.1 Verificar configuración del AP

#### UniFi (SSH)

```bash
ssh ubnt@192.168.1.20

# Ver configuración RADIUS
mca-cli-op get wireless

# Ver clientes conectados
wlanconfig ath0 list

# Ver estadísticas
hostapd_cli -i ath0 all_sta
```

#### TP-Link

```
Web UI > Status > Wireless Clients
```

#### MikroTik

```bash
# Ver clientes conectados
/interface wireless registration-table print

# Ver estadísticas de RADIUS
/radius monitor 0

# Ver logs
/log print where topics~"wireless"
```

### 5.2 Captura de tráfico RADIUS en el AP

```bash
# En el servidor RADIUS, capturar tráfico
sudo tcpdump -i eth0 -n port 1812 or port 1813 -vv

# Intentar conectar un cliente y observar:
# - Access-Request
# - Access-Challenge (EAP)
# - Access-Accept / Access-Reject
```

### 5.3 Verificar asignación de VLAN

#### Desde el switch

```cisco
! Ver tabla MAC con VLAN
show mac address-table | include <MAC-del-cliente>

! Verificar puerto y VLAN
show vlan brief
```

#### Desde logs de RADIUS

```bash
# Ver logs de autenticación
sudo tail -f /var/log/freeradius/radius.log | grep "Tunnel-Private-Group-Id"

# Buscar usuario específico
sudo grep "jperez" /var/log/freeradius/radius.log | tail -20
```

---

## 6. Troubleshooting Común

### 6.1 Cliente no puede conectarse

**Síntomas:**
- Cliente muestra "No se puede conectar a la red"
- No aparece en logs de RADIUS

**Verificaciones:**

1. **Conectividad entre AP y RADIUS**

```bash
# Desde el AP, hacer ping al servidor RADIUS
ping 192.168.1.10

# Verificar puerto UDP 1812 abierto
nc -u -v 192.168.1.10 1812
```

2. **Shared Secret correcto**

```bash
# En FreeRADIUS debug
sudo freeradius -X

# Buscar errores como:
# "Ignoring request from unknown client"
# "Received packet from 192.168.1.20 with invalid Message-Authenticator!"
```

3. **Verificar firewall**

```bash
# En servidor RADIUS
sudo ufw status | grep 181

# Si bloqueado, permitir
sudo ufw allow from 192.168.1.20 to any port 1812 proto udp
```

### 6.2 Autenticación falla

**Síntomas:**
- Cliente pide credenciales repetidamente
- En RADIUS: Access-Reject

**Verificaciones:**

```bash
# Modo debug de RADIUS
sudo freeradius -X

# Buscar líneas como:
# "Login incorrect: [username/password]"
# "Certificate validation failed"
# "TLS Alert write:fatal:unknown CA"
```

**Causas comunes:**

| Error | Causa | Solución |
|-------|-------|----------|
| Login incorrect | Contraseña errónea | Verificar credentials en `users` |
| Unknown CA | Cliente no confía en CA | Instalar ca.pem en cliente |
| Certificate expired | Certificado vencido | Renovar certificado |
| No User-Name | Cliente no envía identidad | Configurar identity en cliente |

### 6.3 VLAN no se asigna

**Síntomas:**
- Cliente se autentica pero queda en VLAN por defecto

**Verificaciones:**

1. **RADIUS enviando atributos correctos**

```bash
# En logs de RADIUS
sudo grep "Tunnel-Private-Group-Id" /var/log/freeradius/radius.log

# Debe mostrar:
# Tunnel-Private-Group-Id = "10"
```

2. **AP soporta VLAN dinámica**

Verificar que "RADIUS VLAN Assignment" esté habilitado en el AP.

3. **Puerto del AP es trunk**

```cisco
! En switch
show interface gi0/1 switchport

# Debe mostrar:
# Switchport: Enabled
# Mode: trunk
# Trunking VLANs Enabled: 10,20,30
```

### 6.4 Problemas de certificados

**Error: "TLS Alert write:fatal:unknown CA"**

```bash
# Verificar que ca.pem esté instalado en cliente
# Verificar CN del servidor coincide con FQDN

# En servidor RADIUS
openssl x509 -noout -subject -in /etc/freeradius/3.0/certs/server.pem

# Subject: CN = radius.empresa.local
# Cliente debe conectar a "radius.empresa.local" (o la IP si CN=IP)
```

---

## 7. Monitoreo y Estadísticas

### 7.1 Dashboard de clientes conectados

**Script de monitoreo:**

```bash
#!/bin/bash
# monitor-wifi-clients.sh

echo "=== Clientes WiFi Conectados ==="
echo ""

# Usar radwho para ver usuarios autenticados
radwho | awk '{print $1, $2, $3}' | column -t

echo ""
echo "Total de clientes: $(radwho | wc -l)"
```

### 7.2 Logs consolidados

```bash
# Ver autenticaciones exitosas
sudo grep "Access-Accept" /var/log/freeradius/radius.log | tail -20

# Ver autenticaciones fallidas
sudo grep "Access-Reject" /var/log/freeradius/radius.log | tail -20

# Ver por usuario
sudo grep "jperez" /var/log/freeradius/radius.log | tail -20
```

### 7.3 Alertas de seguridad

Crear script de alerta para intentos de acceso denegados:

```bash
#!/bin/bash
# alert-failed-auth.sh

THRESHOLD=5
LOGFILE="/var/log/freeradius/radius.log"

# Contar intentos fallidos en última hora
failed=$(grep "Access-Reject" "$LOGFILE" | \
         grep "$(date +%Y-%m-%d)" | \
         tail -100 | wc -l)

if [ "$failed" -gt "$THRESHOLD" ]; then
    echo "ALERTA: $failed intentos fallidos de autenticación en la última hora" | \
    mail -s "Alerta RADIUS" admin@empresa.local
fi
```

---

## Ejercicios Prácticos

### Ejercicio 1: Configurar segundo SSID
Crear un segundo SSID "WiFi-Invitados" con acceso limitado.

### Ejercicio 2: Implementar rate limiting por usuario
Configurar límites de ancho de banda usando atributos RADIUS.

### Ejercicio 3: Configurar múltiples APs
Agregar un segundo AP y verificar roaming entre ellos.

### Ejercicio 4: Troubleshooting dirigido
Provocar errores (shared secret incorrecto, certificado expirado) y diagnosticar.

### Ejercicio 5: Implementar VLAN por grupo
Crear grupos de usuarios (empleados, gerencia, IT) con diferentes VLANs.

---

## Checklist de Configuración

- [ ] SSID creado con nombre apropiado
- [ ] Seguridad configurada como WPA2-Enterprise o WPA3-Enterprise
- [ ] Servidor RADIUS primario configurado (IP, puerto, secret)
- [ ] Servidor RADIUS secundario configurado (opcional)
- [ ] RADIUS Accounting habilitado
- [ ] RADIUS VLAN Assignment habilitado
- [ ] PMF (802.11w) habilitado (Capable o Required)
- [ ] Velocidades lentas deshabilitadas
- [ ] Puerto del AP configurado como trunk en switch
- [ ] VLANs creadas en switch
- [ ] Prueba de conectividad exitosa
- [ ] Verificación de asignación de VLAN correcta

---

**Próximo paso**: Configuración de clientes (Windows, Linux, Android) - archivo 04
