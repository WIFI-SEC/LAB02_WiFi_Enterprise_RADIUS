# Captura y Análisis de Tráfico con Wireshark

## Introducción

Esta es la sección más técnica y educativa del trabajo práctico. Aquí aprenderemos a capturar y analizar el tráfico de red para entender **exactamente** cómo funciona el proceso de autenticación 802.1X con EAP-TLS y RADIUS.

**Objetivos:**
- Capturar tráfico WiFi (EAPOL) y Ethernet (RADIUS)
- Identificar cada fase del handshake 802.1X
- Analizar mensajes RADIUS (Access-Request, Challenge, Accept)
- Entender el túnel TLS dentro de EAP
- Visualizar la asignación de VLANs
- Detectar ataques y anomalías

---

## 1. Preparación del Entorno de Captura

### 1.1 Instalación de Wireshark

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install wireshark tshark -y

# Durante instalación, permitir que no-root capture paquetes
sudo dpkg-reconfigure wireshark-common
# Seleccionar "Yes"

# Agregar usuario al grupo wireshark
sudo usermod -a -G wireshark $USER

# Re-login para que los cambios surtan efecto
newgrp wireshark

# Verificar instalación
wireshark --version
```

### 1.2 Configuración de captura WiFi

Para capturar tráfico WiFi 802.11, necesitamos poner la interfaz en modo monitor.

#### Linux con airmon-ng

```bash
# Instalar herramientas
sudo apt install aircrack-ng -y

# Ver interfaces disponibles
iwconfig

# Activar modo monitor en wlan0
sudo airmon-ng start wlan0

# Esto crea una nueva interfaz: wlan0mon

# Verificar
iwconfig
# Debe mostrar: Mode:Monitor
```

#### macOS

```bash
# macOS soporta nativamente captura WiFi
# Crear interfaz de captura
sudo airport en0 sniff [canal]

# Ejemplo: capturar en canal 6
sudo airport en0 sniff 6

# Esto crea un archivo .cap en /tmp
```

### 1.3 Puntos de captura

```
┌──────────────┐              ┌──────────────┐              ┌──────────────┐
│   Cliente    │              │     AP       │              │   RADIUS     │
│  (Suplicante)│              │(Autenticador)│              │   Server     │
└──────┬───────┘              └──────┬───────┘              └──────┬───────┘
       │                             │                             │
       │◄──── EAPOL (WiFi) ─────────►│                             │
       │                             │                             │
       │                             │◄───── RADIUS (Ethernet)────►│
       │                             │                             │
    Punto A                       Punto B                       Punto C
   (Cliente)                    (AP o Switch)              (Servidor RADIUS)
```

**Puntos de captura:**
- **Punto A**: Captura EAPOL en el cliente (modo monitor)
- **Punto B**: Captura EAPOL + RADIUS en switch (port mirroring)
- **Punto C**: Captura RADIUS en servidor (tcpdump/tshark)

---

## 2. Captura de Tráfico EAPOL (WiFi)

### 2.1 Captura en modo monitor

```bash
# Iniciar captura en interfaz de monitor
sudo wireshark -i wlan0mon -k &

# O con tshark (CLI)
sudo tshark -i wlan0mon -w /tmp/wifi-eapol.pcap

# Filtro para solo EAPOL:
sudo tshark -i wlan0mon -f "ether proto 0x888e" -w /tmp/eapol-only.pcap
```

### 2.2 Filtros de captura útiles

```bash
# Solo EAPOL (802.1X authentication)
ether proto 0x888e

# EAPOL + beacons
ether proto 0x888e or wlan.fc.type_subtype == 0x08

# Solo para un SSID específico
wlan.ssid == "WiFi-Corporativo"

# Solo para una MAC específica (cliente)
wlan.addr == aa:bb:cc:dd:ee:ff
```

### 2.3 Trigger de captura

Para capturar una autenticación completa:

```bash
# 1. Iniciar captura
sudo tshark -i wlan0mon -f "ether proto 0x888e" -w auth.pcap &
TSHARK_PID=$!

# 2. En otra terminal, desconectar y reconectar cliente
# En el cliente (si es Linux):
sudo nmcli connection down "WiFi-Corporativo"
sleep 2
sudo nmcli connection up "WiFi-Corporativo"

# 3. Esperar a que termine autenticación (10-15 segundos)
sleep 15

# 4. Detener captura
sudo kill $TSHARK_PID
```

---

## 3. Captura de Tráfico RADIUS (Ethernet)

### 3.1 Captura en servidor RADIUS

```bash
# Captura simple en interfaz eth0
sudo tcpdump -i eth0 port 1812 or port 1813 -w /tmp/radius.pcap

# Con Wireshark
sudo wireshark -i eth0 -k -f "udp port 1812 or udp port 1813"

# Con tshark (más detalles)
sudo tshark -i eth0 -f "udp port 1812 or udp port 1813" \
    -w /tmp/radius-full.pcap -P

# Ver en tiempo real con decodificación
sudo tshark -i eth0 -f "udp port 1812 or udp port 1813" \
    -O radius -V
```

### 3.2 Configuración de RADIUS Shared Secret en Wireshark

Para que Wireshark pueda decodificar atributos cifrados de RADIUS:

```
1. Edit > Preferences
2. Protocols > RADIUS
3. Click "Edit..." en "RADIUS Shared Secrets"
4. Click "+"
5. Agregar:
   - IP Address: 192.168.1.20 (IP del AP)
   - Shared Secret: SuperSecretRADIUS2024!
6. OK > OK

Ahora Wireshark puede descifrar:
  - User-Password
  - Tunnel-Password
  - MS-CHAP attributes
```

---

## 4. Análisis de Flujo 802.1X con EAP-TLS

### 4.1 Diagrama de secuencia completo

```
Cliente                  AP                    RADIUS Server
  │                      │                          │
  │──1. Association──►   │                          │
  │◄─2. Association OK───│                          │
  │                      │                          │
  │◄─3. EAP-Request─────│                          │
  │   Identity           │                          │
  │                      │                          │
  │──4. EAP-Response────►│                          │
  │   Identity="jperez"  │                          │
  │                      │──5. Access-Request───►  │
  │                      │   User-Name=jperez       │
  │                      │   EAP-Message=Identity   │
  │                      │                          │
  │                      │◄─6. Access-Challenge────│
  │                      │   EAP-Message=TLS Start  │
  │◄─7. EAP-Request─────│                          │
  │   TLS Start          │                          │
  │                      │                          │
  │──8. EAP-Response────►│                          │
  │   TLS ClientHello    │──9. Access-Request───►  │
  │                      │                          │
  │                      │◄─10. Access-Challenge───│
  │◄─11. EAP-Request────│   EAP=TLS ServerHello    │
  │   TLS ServerHello    │   + Certificate          │
  │   + Certificate      │   + ServerKeyExchange    │
  │   + CertRequest      │   + CertificateRequest   │
  │                      │                          │
  │──12. EAP-Response───►│                          │
  │   TLS Certificate    │──13. Access-Request──►  │
  │   + ClientKeyEx      │                          │
  │   + CertVerify       │                          │
  │                      │◄─14. Access-Challenge───│
  │                      │                          │
  │◄─15. EAP-Request────│                          │
  │   TLS Finished       │                          │
  │                      │                          │
  │──16. EAP-Response───►│                          │
  │   TLS Finished       │──17. Access-Request──►  │
  │                      │                          │
  │                      │◄─18. Access-Accept──────│
  │                      │   EAP-Success            │
  │◄─19. EAP-Success────│   Tunnel-Private-Group-Id│
  │                      │   MS-MPPE-Keys           │
  │                      │                          │
  │◄─20. 4-Way Handshake│                          │
  │   (WPA2 Key Install) │                          │
  │                      │                          │
  │═══21. Data Traffic══►│                          │
  │   (Encrypted)        │                          │
  │                      │──22. Accounting-Request──►│
  │                      │   (Acct-Status=Start)    │
  │                      │◄─23. Accounting-Response─│
```

### 4.2 Identificación de paquetes en Wireshark

#### A. Filtros de visualización (Display Filters)

```wireshark
# Ver solo EAPOL
eapol

# Ver solo paquetes EAP
eap

# Ver solo RADIUS
radius

# Ver autenticación completa (EAPOL + RADIUS)
eapol or radius

# Ver solo EAP-TLS
eap.type == 13

# Ver solo Access-Request
radius.code == 1

# Ver solo Access-Accept
radius.code == 2

# Ver solo Access-Reject
radius.code == 3

# Ver identidad del usuario
eap.identity contains "jperez"

# Ver handshake TLS
tls.handshake

# Ver certificados en TLS
tls.handshake.type == 11

# Ver asignación de VLAN
radius.Tunnel-Private-Group-Id
```

#### B. Análisis paso a paso

**Paquete 1-2: Asociación WiFi**

```
Frame 1: Beacon (del AP)
  SSID: WiFi-Corporativo
  Capabilities: ESS, Privacy
  RSN Information:
    Group Cipher: CCMP (AES)
    Pairwise Cipher: CCMP
    Auth Key Management: 802.1X

Frame 2: Probe Request (del cliente)
Frame 3: Probe Response (del AP)
Frame 4: Authentication Request
Frame 5: Authentication Response (Success)
Frame 6: Association Request
Frame 7: Association Response (Success)
```

**Paquete 8: EAP-Request Identity**

```
Frame 8: EAPOL
  Version: 802.1X-2001 (1)
  Type: EAP Packet (0)
  Length: 5

Extensible Authentication Protocol
  Code: Request (1)
  Id: 1
  Length: 5
  Type: Identity (1)
```

**Paquete 9: EAP-Response Identity**

```
Frame 9: EAPOL
  Version: 802.1X-2001
  Type: EAP Packet

EAP
  Code: Response (2)
  Id: 1
  Length: 18
  Type: Identity (1)
  Identity: jperez@empresa.local
```

**Paquete 10: RADIUS Access-Request (con Identity)**

```
Frame 10: UDP (AP → RADIUS)
  Src Port: 1645
  Dst Port: 1812

RADIUS
  Code: Access-Request (1)
  Identifier: 123
  Length: 150
  Authenticator: [random 16 bytes]

  Attribute Value Pairs:
    User-Name: "jperez@empresa.local"
    NAS-IP-Address: 192.168.1.20
    NAS-Port: 0
    NAS-Port-Type: Wireless-802.11 (19)
    NAS-Identifier: "ap-oficina-01"
    Called-Station-Id: "00:11:22:33:44:55:WiFi-Corporativo"
    Calling-Station-Id: "aa:bb:cc:dd:ee:ff" (MAC del cliente)
    Framed-MTU: 1400
    EAP-Message: <EAP Response Identity>
    Message-Authenticator: [MD5 hash]
```

**Paquete 11: RADIUS Access-Challenge (EAP-TLS Start)**

```
RADIUS
  Code: Access-Challenge (11)
  Identifier: 123
  Length: 64

  AVPs:
    EAP-Message: <EAP Request, Type: TLS (13), TLS Start>
    Message-Authenticator: [hash]
    State: [session state]
```

**Paquetes 12-15: TLS ClientHello**

```
EAPOL > EAP > TLS
  TLS Record Layer
    Content Type: Handshake (22)
    Version: TLS 1.0
    Length: 256

  Handshake Protocol: Client Hello
    Version: TLS 1.2
    Random: [32 bytes]
    Session ID: (empty)
    Cipher Suites (16 suites):
      TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
      TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
      ...
    Compression Methods: null
    Extensions:
      server_name: radius.empresa.local
      ec_point_formats
      supported_groups
      signature_algorithms
```

Este va encapsulado en Access-Request al RADIUS.

**Paquetes 16-20: TLS ServerHello + Certificate**

```
RADIUS Access-Challenge
  EAP-Message: <TLS ServerHello + Certificate>

TLS Handshake
  Server Hello
    Version: TLS 1.2
    Cipher Suite: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
    Random: [32 bytes]

  Certificate
    Certificate Length: 1234
    Certificate:
      Subject: CN=radius.empresa.local, O=Mi Empresa SA
      Issuer: CN=Mi Empresa CA, O=Mi Empresa SA
      Validity: 2024-01-01 to 2026-01-01
      Public Key Algorithm: rsaEncryption (2048 bit)

  Server Key Exchange
    EC Diffie-Hellman Server Params
      Curve Type: named_curve
      Named Curve: secp256r1

  Certificate Request
    Certificate types: RSA Sign, ECDSA Sign
    Signature algorithms: sha256+rsa, sha256+ecdsa
    Distinguished Names: CN=Mi Empresa CA

  Server Hello Done
```

**Paquetes 21-25: TLS Client Certificate + Key Exchange**

```
RADIUS Access-Request
  EAP-Message: <TLS Client Certificate + Key Exchange>

TLS Handshake
  Certificate
    Certificate:
      Subject: CN=jperez, O=Mi Empresa SA
      Issuer: CN=Mi Empresa CA
      Validity: 2024-01-01 to 2025-01-01

  Client Key Exchange
    EC Diffie-Hellman Client Params
      Pubkey: [32 bytes]

  Certificate Verify
    Signature Algorithm: sha256WithRSAEncryption
    Signature: [256 bytes]

  Change Cipher Spec

  Encrypted Handshake Message (Finished)
```

**Paquetes 26-28: TLS Server Finished**

```
RADIUS Access-Challenge
  EAP-Message: <TLS Change Cipher Spec + Finished>

TLS
  Change Cipher Spec

  Encrypted Handshake Message (Finished)
```

**Paquete 29-30: RADIUS Access-Accept**

```
RADIUS
  Code: Access-Accept (2)
  Identifier: 123
  Length: 180
  Response Authenticator: [hash]

  AVPs:
    EAP-Message: <EAP Success>
    Message-Authenticator: [hash]

    # Asignación de VLAN
    Tunnel-Type(64): VLAN (13)
    Tunnel-Medium-Type(65): IEEE-802 (6)
    Tunnel-Private-Group-Id(81): "10"

    # Claves para WPA2
    MS-MPPE-Recv-Key: [encrypted key material]
    MS-MPPE-Send-Key: [encrypted key material]

    # Atributos adicionales
    Session-Timeout: 28800  (8 horas)
    Idle-Timeout: 600       (10 minutos)
    Acct-Interim-Interval: 300  (5 minutos)

    # Mensaje al usuario
    Reply-Message: "Bienvenido a la red corporativa"
```

**Paquetes 31-35: 4-Way Handshake WPA2**

```
EAPOL-Key Message 1 of 4 (AP → Cliente)
  Key Information:
    Key Descriptor Version: 2 (HMAC-SHA1-128)
    Key Type: Pairwise Key
    Install: Not set
    Key ACK: Set
    Key MIC: Not set
  Key Nonce (ANonce): [32 random bytes del AP]

EAPOL-Key Message 2 of 4 (Cliente → AP)
  Key Information:
    Key MIC: Set
  Key Nonce (SNonce): [32 random bytes del cliente]
  RSN Information Element

EAPOL-Key Message 3 of 4 (AP → Cliente)
  Key Information:
    Key MIC: Set
    Install: Set (señal para instalar PTK)
  GTK (Group Temporal Key): [encrypted]

EAPOL-Key Message 4 of 4 (Cliente → AP)
  Key Information:
    Key MIC: Set

→ Handshake completo, tráfico cifrado con AES-CCMP
```

---

## 5. Análisis de Casos Específicos

### 5.1 Autenticación exitosa

**Características observables:**

```
✓ EAP-Request Identity
✓ EAP-Response con username
✓ Múltiples Access-Request / Access-Challenge (TLS handshake)
✓ Certificados intercambiados en ambas direcciones
✓ RADIUS Access-Accept con:
  - EAP-Success
  - Tunnel-Private-Group-Id (VLAN)
  - MS-MPPE keys
✓ 4-Way Handshake completo
✓ Inicio de tráfico de datos cifrado
```

**Tiempo típico:** 2-4 segundos

### 5.2 Autenticación fallida - Certificado incorrecto

```
✓ EAP-Request Identity
✓ EAP-Response
✓ TLS ClientHello
✓ TLS ServerHello + Server Certificate
✗ Cliente no envía certificado válido (o no envía nada)
✗ RADIUS Access-Reject

Características:
- EAP-Failure en lugar de EAP-Success
- No hay 4-Way Handshake
- Cliente se desconecta

Filtro Wireshark:
  radius.code == 3  (Access-Reject)
```

### 5.3 Autenticación fallida - CA no confiada

```
✓ EAP-Request Identity
✓ EAP-Response
✓ TLS ClientHello
✓ TLS ServerHello + Server Certificate
✗ TLS Alert: Unknown CA (48)
✗ Cliente cierra conexión TLS

Características:
- El cliente rechaza el certificado del servidor
- Visible en TLS layer, no llega a RADIUS Access-Reject
- Error antes de presentar certificado de cliente

Filtro:
  tls.alert_message.desc == 48
```

### 5.4 Autenticación con PEAP-MSCHAPv2 (comparación)

Para contrastar con EAP-TLS:

```
Diferencias observables:

1. Solo servidor presenta certificado (no cliente)
2. Túnel TLS se establece primero
3. Dentro del túnel: MSCHAPv2 con usuario/contraseña
4. Challenge/Response visible (cifrado en túnel)
5. No hay Certificate Request al cliente
6. No hay Client Certificate en handshake

Filtro:
  eap.type == 25  (PEAP)
  eap.type == 26  (MSCHAPv2 dentro de túnel)
```

---

## 6. Captura de RADIUS Accounting

### 6.1 Mensajes de Accounting

```bash
# Filtro para solo accounting
tshark -i eth0 -f "udp port 1813" -O radius
```

**Accounting-Request (Acct-Status-Type: Start)**

```
RADIUS
  Code: Accounting-Request (4)
  Identifier: 45
  Length: 200

  AVPs:
    Acct-Status-Type: Start (1)
    Acct-Session-Id: "8A2F3B4C5D6E7F89"
    User-Name: "jperez@empresa.local"
    NAS-IP-Address: 192.168.1.20
    NAS-Port: 1
    Framed-IP-Address: 192.168.10.25  (IP asignada al cliente)
    Called-Station-Id: "00:11:22:33:44:55:WiFi-Corporativo"
    Calling-Station-Id: "aa:bb:cc:dd:ee:ff"
    Acct-Authentic: RADIUS (1)
    Event-Timestamp: 1234567890
```

**Accounting-Request (Acct-Status-Type: Interim-Update)**

```
AVPs:
  Acct-Status-Type: Interim-Update (3)
  Acct-Session-Id: "8A2F3B4C5D6E7F89"
  Acct-Session-Time: 300  (5 minutos)
  Acct-Input-Octets: 12345678  (bytes recibidos)
  Acct-Output-Octets: 87654321 (bytes enviados)
  Acct-Input-Packets: 8765
  Acct-Output-Packets: 6543
```

**Accounting-Request (Acct-Status-Type: Stop)**

```
AVPs:
  Acct-Status-Type: Stop (2)
  Acct-Session-Id: "8A2F3B4C5D6E7F89"
  Acct-Session-Time: 7200  (2 horas)
  Acct-Terminate-Cause: User-Request (1)
  Acct-Input-Octets: 156789012
  Acct-Output-Octets: 987654321
```

### 6.2 Análisis de tráfico de usuarios

Script para procesar captures de accounting:

```bash
#!/bin/bash
# analyze-accounting.sh

PCAP_FILE="$1"

echo "=== Análisis de Accounting RADIUS ==="
echo ""

# Extraer sesiones únicas
tshark -r "$PCAP_FILE" -Y "radius.code == 4" \
  -T fields -e radius.Acct-Session-Id | sort -u > /tmp/sessions.txt

echo "Total de sesiones: $(wc -l < /tmp/sessions.txt)"
echo ""

# Por cada sesión, extraer estadísticas
while read session_id; do
    echo "Sesión: $session_id"

    # Buscar username
    user=$(tshark -r "$PCAP_FILE" \
      -Y "radius.Acct-Session-Id == $session_id" \
      -T fields -e radius.User-Name | head -1)

    echo "  Usuario: $user"

    # Buscar mensajes Start/Stop
    tshark -r "$PCAP_FILE" \
      -Y "radius.Acct-Session-Id == $session_id" \
      -T fields -e radius.Acct-Status-Type \
                -e radius.Acct-Session-Time \
                -e radius.Acct-Input-Octets \
                -e radius.Acct-Output-Octets

    echo ""
done < /tmp/sessions.txt
```

---

## 7. Ejercicios Prácticos de Análisis

### Ejercicio 1: Identificar fases de autenticación

**Objetivo:** Abrir una captura y marcar manualmente cada fase.

**Instrucciones:**
1. Capturar una autenticación completa (EAPOL + RADIUS)
2. Identificar y anotar número de frame para:
   - EAP-Request Identity
   - EAP-Response Identity
   - Primer Access-Request
   - TLS ClientHello
   - TLS ServerHello + Certificate
   - TLS Client Certificate
   - Access-Accept
   - 4-Way Handshake (4 frames)

3. Calcular tiempos:
   - Tiempo total de autenticación
   - Tiempo del handshake TLS
   - Tiempo del 4-Way Handshake

### Ejercicio 2: Extraer certificados de la captura

**Objetivo:** Exportar certificados desde Wireshark.

**Instrucciones:**
1. Abrir captura con autenticación EAP-TLS
2. Buscar frame con TLS Server Certificate:
   ```
   tls.handshake.type == 11 and tls.handshake.certificate
   ```
3. Click derecho en "Certificate" > Export Packet Bytes
4. Guardar como `server-cert.der`
5. Convertir a PEM:
   ```bash
   openssl x509 -inform der -in server-cert.der -out server-cert.pem
   openssl x509 -in server-cert.pem -noout -text
   ```
6. Repetir para certificado de cliente

### Ejercicio 3: Comparar EAP-TLS vs PEAP

**Objetivo:** Entender diferencias en el handshake.

**Instrucciones:**
1. Capturar autenticación con EAP-TLS
2. Capturar autenticación con PEAP (configurar un usuario diferente)
3. Filtrar solo TLS handshake:
   ```
   tls.handshake
   ```
4. Comparar:
   - ¿Ambos tienen TLS ServerHello?
   - ¿Cuál tiene Certificate Request?
   - ¿Cuál tiene Client Certificate?
   - ¿Dónde están las credenciales en PEAP?

### Ejercicio 4: Detectar ataque de desautenticación

**Objetivo:** Identificar deauth frames maliciosos.

**Instrucciones:**
1. Capturar tráfico WiFi normal
2. Generar ataque de desautenticación (solo en ambiente controlado):
   ```bash
   # ADVERTENCIA: Solo en laboratorio propio
   sudo aireplay-ng --deauth 10 -a [BSSID] wlan0mon
   ```
3. En Wireshark, filtrar:
   ```
   wlan.fc.type_subtype == 0x0c  (Deauthentication)
   ```
4. Analizar:
   - ¿Cuántos frames de deauth se enviaron?
   - ¿Reason code?
   - ¿Cómo se vería con 802.11w (PMF) habilitado?

### Ejercicio 5: Verificar asignación de VLAN

**Objetivo:** Confirmar que RADIUS asigna VLAN correctamente.

**Instrucciones:**
1. Capturar Access-Accept de dos usuarios diferentes (uno en VLAN 10, otro en VLAN 20)
2. Filtrar:
   ```
   radius.code == 2 and radius.Tunnel-Private-Group-Id
   ```
3. Verificar atributos:
   ```
   Tunnel-Type
   Tunnel-Medium-Type
   Tunnel-Private-Group-Id
   ```
4. Correlacionar con tráfico posterior:
   - Capturar tráfico del cliente después de conectarse
   - Verificar que las tramas Ethernet tienen VLAN tag correcto
   ```
   vlan.id == 10
   ```

### Ejercicio 6: Análisis forense de autenticación fallida

**Objetivo:** Diagnosticar por qué falló una autenticación.

**Instrucciones:**
1. Provocar fallo (certificado incorrecto, CA no confiada, etc.)
2. Capturar intento de autenticación
3. Analizar:
   - ¿Dónde se detuvo el proceso?
   - ¿Hay TLS Alert? ¿Cuál?
   - ¿RADIUS envió Access-Reject?
   - ¿Qué atributos venían en el Reject?
4. Documentar causa raíz del problema

---

## 8. Display Filters Avanzados

### 8.1 Cheat Sheet de filtros

```wireshark
# ==== EAPOL / EAP ====

# Todo el tráfico EAPOL
eapol

# Solo EAP packets
eap

# EAP por tipo
eap.type == 1   # Identity
eap.type == 13  # TLS
eap.type == 25  # PEAP
eap.type == 21  # TTLS

# EAP Success/Failure
eap.code == 3   # Success
eap.code == 4   # Failure

# Identidad de usuario
eap.identity contains "jperez"

# ==== RADIUS ====

# Por código
radius.code == 1   # Access-Request
radius.code == 2   # Access-Accept
radius.code == 3   # Access-Reject
radius.code == 4   # Accounting-Request
radius.code == 5   # Accounting-Response
radius.code == 11  # Access-Challenge

# Por atributo
radius.User-Name
radius.User-Name == "jperez@empresa.local"

# Atributos de VLAN
radius.Tunnel-Private-Group-Id
radius.Tunnel-Type
radius.Tunnel-Medium-Type

# Accounting
radius.Acct-Status-Type == 1  # Start
radius.Acct-Status-Type == 2  # Stop
radius.Acct-Status-Type == 3  # Interim-Update

# Desde IP específica (AP)
ip.src == 192.168.1.20 and radius

# ==== TLS ====

# Handshake completo
tls.handshake

# Por tipo de mensaje
tls.handshake.type == 1   # Client Hello
tls.handshake.type == 2   # Server Hello
tls.handshake.type == 11  # Certificate
tls.handshake.type == 12  # Server Key Exchange
tls.handshake.type == 13  # Certificate Request
tls.handshake.type == 14  # Server Hello Done
tls.handshake.type == 16  # Client Key Exchange
tls.handshake.type == 20  # Finished

# Alertas TLS (errores)
tls.alert_message

# Alertas específicas
tls.alert_message.desc == 48  # Unknown CA
tls.alert_message.desc == 42  # Bad Certificate
tls.alert_message.desc == 45  # Certificate Expired

# Certificados
tls.handshake.certificate

# ==== WiFi 802.11 ====

# Por SSID
wlan.ssid == "WiFi-Corporativo"

# Beacons
wlan.fc.type_subtype == 0x08

# Probe Request/Response
wlan.fc.type_subtype == 0x04  # Probe Request
wlan.fc.type_subtype == 0x05  # Probe Response

# Authentication
wlan.fc.type_subtype == 0x0b

# Association
wlan.fc.type_subtype == 0x00  # Association Request
wlan.fc.type_subtype == 0x01  # Association Response

# Deauthentication (posible ataque)
wlan.fc.type_subtype == 0x0c

# Por MAC address
wlan.addr == aa:bb:cc:dd:ee:ff

# Solo datos
wlan.fc.type == 2

# ==== Combinaciones útiles ====

# Autenticación completa (EAPOL + RADIUS)
eapol or radius

# Solo TLS dentro de EAP
eap.type == 13 and tls.handshake

# Access-Accept con VLAN
radius.code == 2 and radius.Tunnel-Private-Group-Id

# Errores de autenticación
radius.code == 3 or eap.code == 4 or tls.alert_message

# 4-Way Handshake WPA2
eapol.type == 3  # EAPOL-Key

# Tráfico de un usuario específico (por IP después de conectarse)
ip.addr == 192.168.10.25

# VLANs específicas en tráfico Ethernet
vlan.id == 10
```

---

## 9. Exportación y Reportes

### 9.1 Exportar estadísticas

```bash
# Estadísticas de protocolos
tshark -r captura.pcap -q -z io,phs

# Estadísticas RADIUS
tshark -r captura.pcap -q -z radius,tree

# Conversaciones (flows)
tshark -r captura.pcap -q -z conv,ip

# Endpoints
tshark -r captura.pcap -q -z endpoints,ip
```

### 9.2 Generar reporte HTML

En Wireshark GUI:

```
Statistics > Capture File Properties
File > Export Packet Dissections > As Plain Text
```

### 9.3 Script de análisis automático

```bash
#!/bin/bash
# auto-analyze.sh - Análisis automático de captura 802.1X

PCAP="$1"

echo "=== Análisis Automático de Autenticación 802.1X ==="
echo "Archivo: $PCAP"
echo ""

# Contar paquetes por tipo
echo "[1] Resumen de paquetes:"
echo "  EAPOL: $(tshark -r "$PCAP" -Y eapol | wc -l)"
echo "  RADIUS: $(tshark -r "$PCAP" -Y radius | wc -l)"
echo "  TLS Handshake: $(tshark -r "$PCAP" -Y tls.handshake | wc -l)"
echo ""

# Identificar usuarios
echo "[2] Usuarios detectados:"
tshark -r "$PCAP" -Y "radius.User-Name" -T fields -e radius.User-Name | sort -u
echo ""

# Resultados de autenticación
echo "[3] Resultados:"
accepts=$(tshark -r "$PCAP" -Y "radius.code == 2" | wc -l)
rejects=$(tshark -r "$PCAP" -Y "radius.code == 3" | wc -l)
echo "  Access-Accept: $accepts"
echo "  Access-Reject: $rejects"
echo ""

# VLANs asignadas
echo "[4] VLANs asignadas:"
tshark -r "$PCAP" -Y "radius.Tunnel-Private-Group-Id" \
  -T fields -e radius.User-Name -e radius.Tunnel-Private-Group-Id | \
  sort -u
echo ""

# Duración aproximada
echo "[5] Tiempos:"
first=$(tshark -r "$PCAP" -T fields -e frame.time_epoch | head -1)
last=$(tshark -r "$PCAP" -T fields -e frame.time_epoch | tail -1)
duration=$(echo "$last - $first" | bc)
echo "  Duración total de captura: $duration segundos"
```

---

## Checklist de Análisis

- [ ] Captura de EAPOL (WiFi) realizada
- [ ] Captura de RADIUS (Ethernet) realizada
- [ ] EAP-Request Identity identificado
- [ ] EAP-Response con username identificado
- [ ] TLS ClientHello identificado
- [ ] TLS ServerHello + Certificate del servidor identificado
- [ ] TLS Client Certificate identificado
- [ ] Access-Accept con atributos de VLAN identificado
- [ ] 4-Way Handshake WPA2 identificado (4 frames)
- [ ] Certificados exportados y validados
- [ ] Tiempo total de autenticación medido
- [ ] Accounting packets capturados y analizados
- [ ] Comparación EAP-TLS vs PEAP realizada (si aplica)

---

**Próximo paso**: Mejores prácticas y configuración empresarial (archivo 06)
