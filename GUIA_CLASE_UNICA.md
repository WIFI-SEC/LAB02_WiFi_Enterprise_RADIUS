# Clase Práctica: WiFi Empresarial con RADIUS y Certificados
## Configuración, Captura y Análisis en una Sesión

**Duración**: 3-4 horas
**Nivel**: Intermedio en seguridad informática
**Modalidad**: Práctica con demostración

---

## Objetivos de la Clase

Al finalizar, los alumnos comprenderán:

1. ✅ **Diferencia entre WPA2-Personal y WPA2-Enterprise**
2. ✅ **Componentes de 802.1X**: Cliente, AP, RADIUS
3. ✅ **Cómo funcionan los certificados** en autenticación WiFi
4. ✅ **Flujo completo de autenticación** EAP-TLS
5. ✅ **Análisis de captura de paquetes** - VER cómo se produce la autenticación
6. ✅ **Configuración práctica** de un ambiente empresarial básico
7. ✅ **Troubleshooting** de problemas comunes

---

## Agenda de la Clase

### BLOQUE 1: Introducción Teórica (30 min)

#### 1.1 Contexto: ¿Por qué WiFi Enterprise?

**Problema con WPA2-Personal (PSK):**
```
Oficina con 50 empleados usando WiFi
Contraseña: "Empresa2024!"

Problemas:
❌ Todos usan la misma contraseña
❌ Cuando alguien sale, ¿cambiamos la clave de todos?
❌ No sabemos quién está conectado
❌ No podemos dar accesos diferenciados (empleados vs invitados)
```

**Solución: WPA2-Enterprise (802.1X)**
```
Cada usuario tiene sus propias credenciales (certificado)
✅ Autenticación individual
✅ Revocación granular
✅ Auditoría completa
✅ Segmentación por VLANs
```

#### 1.2 Arquitectura 802.1X

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   Cliente    │         │     AP       │         │   Servidor   │
│ (Suplicante) │◄───────►│(Autenticador)│◄───────►│   RADIUS     │
│              │  EAPOL  │              │ RADIUS  │              │
└──────────────┘         └──────────────┘         └──────────────┘
     WiFi                       Ethernet
  (802.11)                    (UDP 1812)
```

**Componentes:**
- **Suplicante**: Cliente WiFi (laptop, celular)
- **Autenticador**: Access Point (controla acceso)
- **RADIUS**: Servidor que valida credenciales

#### 1.3 Flujo de Autenticación (SIMPLIFICADO)

```
1. Cliente → AP: "Hola, quiero conectarme"
2. AP → Cliente: "¿Quién eres?" (EAP-Request Identity)
3. Cliente → AP → RADIUS: "Soy Juan Pérez" (EAP-Response)
4. RADIUS ↔ Cliente: Túnel TLS + intercambio de certificados
   - Servidor muestra su certificado
   - Cliente valida que es el servidor correcto
   - Cliente muestra su certificado
   - Servidor valida que es un usuario autorizado
5. RADIUS → AP: "OK, dejar pasar + asignar VLAN 10"
6. AP → Cliente: "Bienvenido, aquí están las claves de cifrado"
7. Cliente → AP: Tráfico cifrado con AES
```

#### 1.4 Certificados X.509

```
         CA (Autoridad Certificadora)
              │
              ├─ Certificado Servidor RADIUS
              └─ Certificado Cliente (Juan, María, etc.)

Cada uno confía en la CA raíz
```

---

### BLOQUE 2: Demostración Pre-configurada (45 min)

**IMPORTANTE**: Para optimizar el tiempo, mostrar un ambiente **YA CONFIGURADO**.

#### 2.1 Tour del Laboratorio (10 min)

**Mostrar componentes:**

```bash
# 1. Servidor RADIUS (VM Ubuntu)
ssh admin@192.168.1.10

# Mostrar que está corriendo
systemctl status freeradius

# Mostrar configuración de clientes (APs)
sudo cat /etc/freeradius/3.0/clients.conf
# Explicar: IP del AP, shared secret

# Mostrar usuarios
sudo cat /etc/freeradius/3.0/users
# Explicar: usuario, VLAN asignada
```

```bash
# 2. Certificados
cd /etc/ssl/radius-certs
ls -la

# Mostrar CA
openssl x509 -in ca/certs/ca.pem -noout -subject -issuer -dates

# Mostrar certificado del servidor
openssl x509 -in server/certs/server.pem -noout -subject -issuer -dates

# Mostrar certificado de cliente
openssl x509 -in clients/certs/alumno1.pem -noout -subject -dates
```

#### 2.2 Configuración del Access Point (5 min)

**Mostrar configuración en el AP** (usar interfaz web):

```
SSID: WiFi-LAB
Seguridad: WPA2-Enterprise

RADIUS Server:
  IP: 192.168.1.10
  Puerto: 1812
  Shared Secret: SuperSecretRADIUS2024!

VLAN: Dinámica (asignada por RADIUS)
```

#### 2.3 Conectar un Cliente (10 min)

**Demostración en vivo - Windows:**

```
1. Mostrar certificados instalados:
   Win + R → certmgr.msc
   - Personal > Certificates: alumno1
   - Trusted Root: Mi Empresa CA

2. Conectar a WiFi-LAB:
   - Security: WPA2-Enterprise
   - Authentication: Smart Card or other certificate
   - Select certificate: alumno1
   - Trust CA: Mi Empresa CA

3. ¡CONECTADO!
```

**Verificar conexión:**

```cmd
ipconfig
# Debe mostrar IP en VLAN 10 (192.168.10.x)

ping 8.8.8.8
# Debe funcionar
```

#### 2.4 Ver el Proceso en RADIUS (20 min)

**Modo DEBUG - CLAVE PARA ENTENDER**

```bash
# En servidor RADIUS
sudo systemctl stop freeradius
sudo freeradius -X
```

**Ahora DESCONECTAR y RECONECTAR el cliente mientras observan**

**Narrar lo que aparece en pantalla:**

```
(0) Received Access-Request Id 45 from 192.168.1.20:1645
    → "El AP (192.168.1.20) pregunta por un usuario"

(0)   User-Name = "alumno1@empresa.local"
    → "El usuario dice llamarse alumno1"

(0)   NAS-IP-Address = 192.168.1.20
    → "Petición viene del AP con esta IP"

(0)   EAP-Message = 0x02...
    → "Mensaje EAP (protocolo de autenticación)"

(0) eap: Continuing tunnel setup
    → "Estableciendo túnel TLS seguro"

(0) eap_tls: (TLS) EAP Peer hello
    → "Cliente inicia handshake TLS"

(0) eap_tls: (TLS) EAP Sending server certificate
    → "RADIUS envía su certificado al cliente"

(0) eap_tls: (TLS) EAP Got client certificate
    → "Cliente envió su certificado - VALIDANDO..."

(0) eap_tls: Certificate CN matches User-Name
    → "✓ El certificado pertenece a alumno1"

(0) eap_tls: Certificate is valid
    → "✓ No expiró, firmado por CA correcta"

(0) [eap] = ok
    → "Autenticación exitosa"

(0) Sent Access-Accept Id 45
    → "RADIUS dice al AP: DEJAR PASAR"

(0)   Tunnel-Type = VLAN
(0)   Tunnel-Private-Group-Id = "10"
    → "Asignar a VLAN 10"

(0)   MS-MPPE-Recv-Key = 0x...
(0)   MS-MPPE-Send-Key = 0x...
    → "Claves para cifrar tráfico WiFi"
```

**Preguntar a los alumnos:**
- ¿En qué momento se validan los certificados?
- ¿Qué pasa si el certificado expira?
- ¿Dónde se decide la VLAN?

---

### BLOQUE 3: Captura y Análisis con Wireshark (60 min) ⭐ **SECCIÓN CRÍTICA**

#### 3.1 Preparar Captura (10 min)

**En el servidor RADIUS:**

```bash
# Capturar tráfico RADIUS
sudo tcpdump -i eth0 port 1812 or port 1813 -w /tmp/radius.pcap

# Dejar corriendo...
```

**En un equipo con Wireshark y adaptador WiFi:**

```bash
# Capturar tráfico EAPOL (WiFi)
sudo airodump-ng wlan0mon -c 6 --bssid [MAC_AP] -w /tmp/eapol
```

#### 3.2 Provocar Autenticación

```
1. Desconectar cliente del WiFi
2. Esperar 5 segundos
3. Reconectar cliente
4. Esperar hasta que esté completamente conectado (15-20 seg)
5. Detener ambas capturas (Ctrl+C)
```

#### 3.3 Análisis en Wireshark (50 min)

**Abrir ambas capturas en Wireshark**

##### PARTE A: Análisis de RADIUS (Ethernet)

```wireshark
Filtro: radius
```

**Identificar paquetes clave:**

| # | Código RADIUS | Descripción |
|---|---------------|-------------|
| 1 | Access-Request (1) | AP pregunta por "alumno1" |
| 2 | Access-Challenge (11) | RADIUS: "Vamos a usar EAP-TLS, muéstrame tu certificado" |
| 3 | Access-Request (1) | Cliente envía su certificado |
| 4 | Access-Challenge (11) | Más negociación TLS... |
| ... | ... | (múltiples roundtrips) |
| N | Access-Accept (2) | ✓ "Autenticación OK + VLAN 10" |

**Expandir el Access-Accept:**

```
RADIUS Protocol
  Code: Access-Accept (2)
  Identifier: 45
  Authenticator: [16 bytes]

  Attribute Value Pairs:
    EAP-Message: Success

    Tunnel-Type(64): VLAN (13)
    Tunnel-Medium-Type(65): IEEE-802 (6)
    Tunnel-Private-Group-Id(81): "10"     ← VLAN ASIGNADA

    MS-MPPE-Recv-Key: [encrypted]
    MS-MPPE-Send-Key: [encrypted]        ← CLAVES WPA2

    Message-Authenticator: [hash]
```

**Preguntas para los alumnos:**
- ¿Cuántos paquetes Access-Request hay?
- ¿Cuántos Access-Challenge?
- ¿Dónde está la VLAN?
- ¿Las claves están cifradas? ¿Con qué?

##### PARTE B: Análisis de EAPOL (WiFi)

```wireshark
Filtro: eapol
```

**Identificar fases:**

**1. EAP-Request Identity**
```
Frame X: EAPOL
  EAP Code: Request (1)
  EAP Type: Identity (1)

→ AP pregunta "¿Quién eres?"
```

**2. EAP-Response Identity**
```
Frame X+1: EAPOL
  EAP Code: Response (2)
  EAP Type: Identity (1)
  Identity: alumno1@empresa.local

→ Cliente responde su identidad
```

**3. EAP-TLS Start**
```
Frame X+2: EAPOL
  EAP Type: TLS (13)
  TLS Flags: Start

→ Inicia túnel TLS
```

**4-8. TLS Handshake (MOSTRAR DETALLES)**

```wireshark
Filtro: eap.type == 13 and tls.handshake
```

**Expandir paquete con "TLS Server Certificate":**

```
Extensible Authentication Protocol
  Type: EAP-TLS (13)
  TLS Message Length: 1234

Transport Layer Security
  TLS Record Layer
    Content Type: Handshake (22)

    Handshake Protocol: Server Hello
      Version: TLS 1.2
      Random: [32 bytes]
      Cipher Suite: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256

    Handshake Protocol: Certificate
      Certificate Length: 1024
      Certificates (1024 bytes)
        Certificate: 3082... (DER format)
          Subject: CN=radius.empresa.local, O=Mi Empresa
          Issuer: CN=Mi Empresa CA
          Validity
            Not Before: 2024-01-01
            Not After: 2026-01-01
          Public Key Algorithm: rsaEncryption (2048 bit)
```

**EJERCICIO PRÁCTICO**: Exportar el certificado

```
1. Click derecho en "Certificate"
2. Export Packet Bytes → server-cert.der
3. En terminal:
   openssl x509 -inform der -in server-cert.der -text -noout
```

**9. 4-Way Handshake WPA2**

```wireshark
Filtro: eapol.type == 3
```

**Mostrar 4 frames:**

```
Frame A: EAPOL-Key Message 1/4
  Key Information: Key ACK
  Key Nonce (ANonce): [32 bytes del AP]

Frame B: EAPOL-Key Message 2/4
  Key Information: Key MIC
  Key Nonce (SNonce): [32 bytes del cliente]

Frame C: EAPOL-Key Message 3/4
  Key Information: Key MIC, Install, ACK
  GTK (Group Key): [encrypted]

Frame D: EAPOL-Key Message 4/4
  Key Information: Key MIC

→ PTK (Pairwise Transient Key) instalada
→ Tráfico de datos ahora cifrado con AES-CCMP
```

**Después del 4-Way Handshake:**

```wireshark
Filtro: wlan.fc.type == 2
```

**Mostrar datos cifrados:**

```
Frame: Data
  CCMP parameters
    Encrypted Data: [no se puede ver sin la clave]

→ Tráfico protegido con AES
```

#### 3.4 Ejercicio para Alumnos (si hay tiempo)

**Entregar archivo .pcap y pedirles que identifiquen:**

1. ¿En qué frame se envía la identidad del usuario?
2. ¿En qué frame aparece el certificado del servidor?
3. ¿Cuántos roundtrips TLS hay?
4. ¿En qué frame RADIUS envía el Access-Accept?
5. ¿Qué VLAN se asigna?
6. ¿Cuál es el cipher suite TLS negociado?

---

### BLOQUE 4: Configuración Empresarial (30 min)

#### 4.1 VLANs Dinámicas (10 min)

**Mostrar configuración de usuarios con VLANs diferentes:**

```bash
sudo nano /etc/freeradius/3.0/users
```

```
# Empleado regular → VLAN 10
alumno1 Cleartext-Password := "password1"
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 10

# Gerente → VLAN 20 (más privilegios)
director Cleartext-Password := "password2"
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 20

# Invitado → VLAN 30 (solo Internet)
invitado Cleartext-Password := "guest123"
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 30,
    Session-Timeout = 3600  # 1 hora máximo
```

**Mostrar arquitectura de VLANs:**

```
Switch
  ├─ VLAN 10 (Empleados)    → 192.168.10.0/24 → Acceso a recursos internos
  ├─ VLAN 20 (Gerencia)     → 192.168.20.0/24 → Acceso completo
  └─ VLAN 30 (Invitados)    → 192.168.30.0/24 → Solo Internet

Access Point
  Puerto configurado como TRUNK (permite todas las VLANs)
```

**Demostrar:**
- Conectar con "alumno1" → IP 192.168.10.x
- Desconectar y conectar con "director" → IP 192.168.20.x

#### 4.2 Seguridad Adicional (10 min)

**Protected Management Frames (PMF / 802.11w)**

```
Problema: Ataques de desautenticación

Atacante envía frame falso:
  "AP → Cliente: DESCONÉCTATE"

Cliente se desconecta (ataque DoS)

Solución: PMF
  - Frames de management cifrados
  - Frames falsos son ignorados

Configuración en AP:
  PMF: Required
```

**Demostración de ataque (solo conceptual, NO ejecutar en clase):**

```bash
# Ataque de deauth (NO HACER)
# aireplay-ng --deauth 10 -a [AP] wlan0mon

# Con PMF habilitado → ataque no funciona
```

#### 4.3 Troubleshooting Común (10 min)

**Problema 1: "No se puede conectar"**

```
Diagnóstico:
1. ¿Logs en RADIUS?
   sudo tail -f /var/log/freeradius/radius.log

2. Errores comunes:
   - "Unknown client" → Shared secret incorrecto
   - "TLS Alert: Unknown CA" → Cliente no confía en CA
   - "Certificate expired" → Renovar certificado
   - "Login incorrect" → Usuario/password mal
```

**Problema 2: "VLAN incorrecta"**

```
Verificar:
1. RADIUS envía atributos → Ver en logs de Access-Accept
2. AP soporta VLAN dinámica → Ver configuración
3. Puerto del AP es trunk → Ver config del switch
4. VLAN existe en switch → show vlan brief
```

**Herramientas esenciales:**

```bash
# Modo debug de RADIUS (MÁS IMPORTANTE)
sudo freeradius -X

# Test de autenticación
radtest usuario password localhost 0 testing123

# Capturar tráfico RADIUS
sudo tcpdump -i eth0 port 1812 -vv

# Ver certificado
openssl x509 -in cert.pem -noout -text
```

---

### BLOQUE 5: Cierre y Mejores Prácticas (15 min)

#### 5.1 Resumen de Conceptos Clave

**¿Qué aprendimos?**

1. ✅ **WPA2-Enterprise** es para ambientes empresariales
2. ✅ **802.1X** tiene 3 componentes: Cliente, AP, RADIUS
3. ✅ **EAP-TLS** usa certificados (más seguro que passwords)
4. ✅ **Flujo de autenticación** tiene múltiples fases (EAP + TLS + 4WHS)
5. ✅ **Wireshark** nos permite ver cada paso del proceso
6. ✅ **VLANs dinámicas** permiten segmentación automática
7. ✅ **PMF** protege contra ataques de desautenticación

#### 5.2 Mejores Prácticas para Implementación Real

```
1. Usar WPA3-Enterprise (si es posible)
2. Certificados con validez de 1 año
3. Renovación automatizada 30 días antes de expirar
4. Servidor RADIUS redundante (primario + secundario)
5. VLANs separadas por tipo de usuario
6. Logs centralizados
7. Monitoreo de intentos fallidos
8. PMF habilitado (802.11w)
9. Backups diarios de configuración y certificados
10. Documentación actualizada
```

#### 5.3 Configuración Lógica para Ambiente Empresarial

**Ejemplo: Empresa de 200 empleados**

```
Infraestructura:
  - 2 Servidores RADIUS (primario + backup)
  - 20 Access Points
  - Switch core con VLANs
  - Firewall

Segmentación:
  VLAN 10: Empleados (150 usuarios)
    - Acceso a: Email, Intranet, Impresoras
    - Bloqueado: Servidores de producción

  VLAN 20: IT/Gerencia (20 usuarios)
    - Acceso completo

  VLAN 30: Invitados (temporal)
    - Solo Internet
    - Aislado de red interna

  VLAN 40: IoT (30 dispositivos)
    - Impresoras, cámaras, sensores
    - Sin acceso a PCs de usuarios

Certificados:
  - CA interna (validez 10 años)
  - Certificado servidor RADIUS (2 años)
  - Certificados de usuarios (1 año, auto-renovación)

Monitoreo:
  - SIEM para logs de RADIUS
  - Alertas si > 5 intentos fallidos
  - Dashboard con usuarios conectados
  - Reportes mensuales de auditoría

Operaciones:
  - Onboarding: Generar certificado + enviar por portal seguro
  - Offboarding: Revocar certificado + actualizar CRL
  - Backup: Diario a servidor remoto
  - DR: RTO 2 horas, RPO 24 horas
```

#### 5.4 ¿Qué Considerar?

**Aspectos técnicos:**
- ¿Cuántos usuarios simultáneos?
- ¿Múltiples ubicaciones? → Servidores RADIUS por sitio
- ¿Integración con Active Directory?
- ¿Dispositivos IoT sin soporte de certificados? → VLAN especial con MAC auth

**Aspectos operacionales:**
- ¿Quién gestiona los certificados?
- ¿Proceso de onboarding/offboarding?
- ¿Soporte 24/7 o solo horario laboral?
- ¿Portal self-service para usuarios?

**Aspectos de seguridad:**
- ¿Renovación de certificados automática?
- ¿Monitoreo de intentos fallidos?
- ¿Detección de Rogue APs?
- ¿Cumplimiento normativo? (ISO 27001, SOC 2, etc.)

**Costos:**
- Servidores RADIUS (pueden ser VMs)
- APs enterprise (vs consumer)
- Licencias de controlador WiFi (si aplica)
- Personal capacitado
- Horas de implementación

---

## Materiales para Entregar a los Alumnos

### 1. Archivo .pcap con autenticación completa
- `autenticacion-completa.pcap` - Para que analicen en casa

### 2. Guía de filtros Wireshark

```
# Ver solo EAPOL
eapol

# Ver solo RADIUS
radius

# Ver Access-Accept
radius.code == 2

# Ver certificados TLS
tls.handshake.type == 11

# Ver 4-Way Handshake
eapol.type == 3

# Ver VLAN asignada
radius.Tunnel-Private-Group-Id
```

### 3. Diagrama de arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                   ARQUITECTURA COMPLETA                  │
└─────────────────────────────────────────────────────────┘

                        Internet
                           │
                    ┌──────▼──────┐
                    │   Firewall  │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ Switch Core │
                    │  + VLANs    │
                    └─┬─────────┬─┘
                      │         │
        ┌─────────────┴┐       └─────────────┐
        │              │                     │
  ┌─────▼─────┐   ┌────▼────┐          ┌────▼────┐
  │  RADIUS   │   │  RADIUS │          │   APs   │
  │  Primary  │   │ Backup  │          │ (20x)   │
  └───────────┘   └─────────┘          └────┬────┘
                                            │
                                       (WiFi 802.1X)
                                            │
                                   ┌────────┼────────┐
                                   │        │        │
                              VLAN 10   VLAN 20  VLAN 30
                             Empleados Gerencia Invitados
```

### 4. Comandos de referencia rápida

```bash
# RADIUS debug (MÁS IMPORTANTE)
sudo systemctl stop freeradius && sudo freeradius -X

# Test de autenticación
radtest usuario password 192.168.1.10 0 testing123

# Ver certificado
openssl x509 -in cert.pem -noout -text

# Capturar RADIUS
sudo tcpdump -i eth0 port 1812 -w radius.pcap

# Verificar validez de certificado
openssl x509 -in cert.pem -noout -dates

# Ver logs
sudo tail -f /var/log/freeradius/radius.log
```

---

## Evaluación (Opcional)

### Preguntas de Comprensión

1. ¿Cuál es la diferencia principal entre WPA2-Personal y WPA2-Enterprise?
2. ¿Qué hace cada componente en 802.1X? (suplicante, autenticador, servidor)
3. ¿En qué fase se intercambian los certificados?
4. ¿Qué atributo RADIUS indica la VLAN asignada?
5. ¿Para qué sirve el 4-Way Handshake?
6. ¿Cómo se protege contra ataques de desautenticación?

### Ejercicio Práctico

**Entregar archivo .pcap y pedir:**

1. Identificar frame con EAP-Request Identity
2. Identificar frame con Access-Accept
3. ¿Qué VLAN se asignó?
4. ¿Qué cipher suite TLS se negoció?
5. Exportar el certificado del servidor

---

## Notas para el Instructor

### Preparación Pre-Clase

**CRÍTICO - Tener listo:**
- ✅ Servidor RADIUS configurado y funcionando
- ✅ Certificados generados (CA + servidor + 3-5 clientes)
- ✅ Access Point configurado con SSID de prueba
- ✅ Switch con VLANs configuradas
- ✅ Al menos 1 cliente configurado (para demo rápida)
- ✅ Wireshark instalado en equipo de proyección
- ✅ Captura .pcap de ejemplo lista

**Setup del laboratorio:**
```
VM1: Ubuntu Server (RADIUS) - 192.168.1.10
AP: UniFi/TP-Link/MikroTik - 192.168.1.20
Switch: Con VLANs 10, 20, 30
Laptop: Windows/Linux con WiFi + Wireshark
Proyector: Para mostrar debug de RADIUS
```

### Durante la Clase

**Timing crítico:**
- No extenderse en teoría (máximo 30 min)
- Priorizar la demostración práctica
- El análisis de Wireshark es lo MÁS IMPORTANTE
- Dejar tiempo para preguntas

**Si se atrasa:**
- Acortar parte de configuración (ya está hecha)
- Enfocarse en Wireshark (Bloque 3)
- Mostrar solo capturas pre-hechas

**Engagement:**
- Hacer preguntas durante la demo
- Pedir que identifiquen paquetes en Wireshark
- Mostrar errores comunes (provocados)

### Después de la Clase

**Entregar:**
- Esta guía en PDF
- Archivo .pcap de ejemplo
- Diagramas
- Referencias a material completo (los otros 7 archivos)

---

## Material Complementario

Para profundizar, los alumnos pueden consultar:

- `00_Introduccion_Teorica.md` - Fundamentos completos
- `01_Configuracion_Servidor_RADIUS.md` - Setup paso a paso
- `02_Gestion_Certificados_PKI.md` - PKI en detalle
- `05_Captura_Analisis_Wireshark.md` - 100+ filtros y ejercicios
- `07_Ejercicios_Troubleshooting.md` - Casos prácticos

---

**FIN DE LA GUÍA DE CLASE ÚNICA**

Con esta clase, los alumnos tendrán una comprensión sólida de WiFi empresarial y habrán **VISTO** en vivo cómo funciona el protocolo, que es el objetivo principal.
