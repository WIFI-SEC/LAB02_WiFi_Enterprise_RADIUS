# Ejercicios Prácticos y Troubleshooting

## Introducción

Esta sección contiene ejercicios prácticos guiados, escenarios de troubleshooting y casos de estudio para consolidar el conocimiento adquirido.

---

## PARTE I: EJERCICIOS PRÁCTICOS GUIADOS

### Ejercicio 1: Implementación Completa desde Cero

**Tiempo estimado**: 4 horas
**Dificultad**: Media
**Objetivo**: Implementar una infraestructura WiFi Enterprise completa

#### Pasos:

1. **Preparar servidor RADIUS (45 min)**
   - Instalar Ubuntu Server 22.04 en VM
   - Instalar FreeRADIUS y dependencias
   - Configurar red estática
   - Configurar firewall

2. **Generar infraestructura PKI (30 min)**
   - Crear CA raíz
   - Generar certificado del servidor RADIUS
   - Crear certificados para 3 usuarios

3. **Configurar FreeRADIUS (45 min)**
   - Configurar módulo EAP para EAP-TLS
   - Agregar clientes (APs) en `clients.conf`
   - Configurar usuarios con VLANs diferentes
   - Probar con `radtest` y `eapol_test`

4. **Configurar Access Point (30 min)**
   - Crear SSID "WiFi-LAB"
   - Configurar WPA2-Enterprise
   - Apuntar a servidor RADIUS
   - Habilitar VLAN dinámica

5. **Configurar switch (20 min)**
   - Crear VLANs 10, 20, 30
   - Configurar puerto del AP como trunk
   - Configurar gateways para cada VLAN

6. **Conectar clientes (40 min)**
   - Configurar cliente Windows
   - Configurar cliente Linux
   - Configurar cliente Android
   - Verificar conectividad en cada VLAN

7. **Capturar y analizar tráfico (30 min)**
   - Capturar EAPOL durante autenticación
   - Capturar RADIUS en servidor
   - Identificar todas las fases
   - Exportar certificados desde captura

**Entregables:**
- Capturas de pantalla de cada paso
- Archivo .pcap con autenticación completa
- Documento con arquitectura implementada
- Scripts de backup creados

---

### Ejercicio 2: Migración de WPA2-PSK a Enterprise

**Escenario**: Una empresa tiene WiFi con WPA2-Personal (PSK compartido) y necesita migrar a Enterprise.

**Tareas:**

1. **Análisis de situación actual**
   - Documentar configuración actual
   - Identificar usuarios y dispositivos
   - Planificar período de transición

2. **Implementación paralela**
   - Crear nuevo SSID "WiFi-Corporativo-NEW" con 802.1X
   - Mantener SSID viejo temporalmente
   - Configurar RADIUS server

3. **Migración de usuarios**
   - Generar certificados para todos los usuarios
   - Distribuir certificados de forma segura
   - Crear documentación de configuración
   - Migrar usuarios grupo por grupo

4. **Validación**
   - Verificar que todos los usuarios pueden conectarse
   - Confirmar asignación correcta de VLANs
   - Testear desde diferentes dispositivos

5. **Desactivación del SSID antiguo**
   - Programar fecha de fin
   - Notificar a usuarios rezagados
   - Deshabilitar SSID-PSK

**Pregunta de análisis**: ¿Cuáles son los riesgos de este proceso y cómo mitigarlos?

---

### Ejercicio 3: Implementación de Alta Disponibilidad

**Objetivo**: Configurar redundancia completa para el servicio RADIUS.

**Componentes:**

1. **Segundo servidor RADIUS**
   - Clonar configuración del primario
   - Sincronizar certificados
   - Configurar como secondary en APs

2. **Sincronización automatizada**
   - Script para replicar configuración
   - Cron job cada 15 minutos
   - Alertas si fallan sincronización

3. **Pruebas de failover**
   - Desconectar servidor primario
   - Verificar que secundario toma el control
   - Medir tiempo de failover
   - Verificar que clientes siguen autenticándose

4. **VIP con Keepalived (opcional)**
   - Configurar IP virtual
   - Configurar VRRP
   - Health checks
   - Probar failover automático

**Métrica de éxito**: Failover < 30 segundos sin intervención manual

---

### Ejercicio 4: Segmentación Avanzada con VLANs

**Escenario**: Implementar segmentación de red por roles y dispositivos.

**VLANs a crear:**

| VLAN | Nombre | Usuarios | Acceso |
|------|--------|----------|--------|
| 10 | Empleados | Staff general | Recursos limitados |
| 20 | Gerencia | Directivos, IT | Acceso completo |
| 30 | Invitados | Visitantes | Solo Internet |
| 40 | IoT | Impresoras, cámaras | Recursos específicos |
| 50 | VoIP | Teléfonos IP | QoS prioritario |

**Tareas:**

1. **Configurar VLANs en RADIUS**
   ```
   # Crear usuarios de cada tipo
   # Asignar VLAN correspondiente
   # Configurar atributos específicos (QoS, timeout)
   ```

2. **Configurar ACLs por VLAN**
   ```
   # VLAN 10: Bloquear acceso a servidores críticos
   # VLAN 20: Sin restricciones
   # VLAN 30: Solo Internet, bloquear redes internas
   # VLAN 40: Solo protocolo específico de cada dispositivo
   ```

3. **Implementar QoS para VLAN 50 (VoIP)**
   ```
   # Marcar tráfico VoIP como prioritario
   # Reservar ancho de banda
   # Configurar CoS/DSCP
   ```

4. **Probar segmentación**
   - Conectar usuario de cada VLAN
   - Verificar aislamiento entre VLANs
   - Probar acceso a recursos permitidos
   - Intentar acceso a recursos bloqueados

**Entregable**: Mapa de red con todas las VLANs y sus políticas de acceso

---

### Ejercicio 5: Integración con Active Directory

**Objetivo**: Autenticar usuarios contra AD en lugar de archivos planos.

**Prerequisitos**: Servidor Windows con AD instalado

**Pasos:**

1. **Configurar módulo LDAP en FreeRADIUS**
   ```bash
   # /etc/freeradius/3.0/mods-available/ldap

   ldap {
       server = "dc.empresa.local"
       port = 389
       identity = "cn=radiusauth,cn=Users,dc=empresa,dc=local"
       password = "PasswordSeguro123"
       base_dn = "cn=Users,dc=empresa,dc=local"

       user {
           filter = "(sAMAccountName=%{%{Stripped-User-Name}:-%{User-Name}})"
       }
   }
   ```

2. **Habilitar módulo LDAP**
   ```bash
   ln -s /etc/freeradius/3.0/mods-available/ldap \
         /etc/freeradius/3.0/mods-enabled/ldap
   ```

3. **Configurar site default**
   ```conf
   authorize {
       ldap
       if (ok || updated) {
           update control {
               Auth-Type := ldap
           }
       }
   }

   authenticate {
       Auth-Type ldap {
           ldap
       }
   }
   ```

4. **Mapear grupos AD a VLANs**
   ```conf
   # Si usuario es miembro de "CN=IT,CN=Users,DC=empresa,DC=local"
   # Asignar VLAN 20

   if (LDAP-Group == "CN=IT,CN=Users,DC=empresa,DC=local") {
       update reply {
           Tunnel-Type = VLAN
           Tunnel-Medium-Type = IEEE-802
           Tunnel-Private-Group-Id = 20
       }
   }
   ```

5. **Probar autenticación**
   ```bash
   radtest usuario@empresa.local Password123 localhost 0 testing123
   ```

**Pregunta**: ¿Cómo manejar certificados si ahora se usa PEAP-MSCHAPv2 en lugar de EAP-TLS?

---

## PARTE II: CASOS DE TROUBLESHOOTING

### Caso 1: Cliente no puede conectarse - Diagnóstico completo

**Síntoma**: Usuario reporta "No se puede conectar a WiFi-Corporativo"

#### Metodología de diagnóstico:

```
┌─────────────────────────────────────────────────────────┐
│              TROUBLESHOOTING FLOWCHART                  │
└─────────────────────────────────────────────────────────┘

1. ¿El SSID es visible?
   NO → Verificar AP está encendido, SSID broadcast habilitado
   SÍ → Continuar

2. ¿Cliente puede asociarse al AP?
   NO → Verificar MAC filtering, max clients, señal débil
   SÍ → Continuar

3. ¿Proceso de autenticación se inicia?
   NO → Verificar cliente configurado para WPA2-Enterprise
   SÍ → Continuar

4. ¿Cliente envía EAP-Response Identity?
   NO → Verificar configuración de identity en cliente
   SÍ → Continuar

5. ¿AP puede comunicarse con RADIUS?
   NO → Verificar red, firewall, IP del RADIUS
   SÍ → Continuar

6. ¿RADIUS recibe Access-Request?
   NO → Verificar shared secret coincide
   SÍ → Continuar

7. ¿RADIUS envía Access-Challenge (TLS)?
   NO → Verificar módulo EAP habilitado
   SÍ → Continuar

8. ¿Cliente acepta certificado del servidor?
   NO → Verificar CA instalada en cliente
   SÍ → Continuar

9. ¿Servidor acepta certificado del cliente?
   NO → Verificar certificado válido, no expirado, no revocado
   SÍ → Continuar

10. ¿RADIUS envía Access-Accept?
    NO → Ver logs de RADIUS para causa de rechazo
    SÍ → Continuar

11. ¿4-Way Handshake WPA2 completa?
    NO → Verificar PMK derivation
    SÍ → Continuar

12. ¿Cliente obtiene IP vía DHCP?
    NO → Verificar DHCP server en VLAN correcta
    SÍ → CONECTADO EXITOSAMENTE
```

#### Comandos de diagnóstico:

**En el cliente (Linux):**

```bash
# Ver estado de conexión WiFi
nmcli device status

# Ver logs de autenticación
journalctl -u NetworkManager -f

# Modo debug de wpa_supplicant
sudo wpa_supplicant -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf -d

# Verificar certificados instalados
ls -la ~/.cert/

# Verificar validez de certificado
openssl x509 -in ~/.cert/usuario.pem -noout -dates
```

**En el Access Point:**

```bash
# Ver clientes asociados (MikroTik)
/interface wireless registration-table print

# Ver intentos de autenticación (UniFi, vía SSH)
tail -f /var/log/messages | grep hostapd

# Ver configuración RADIUS
# (Depende del fabricante)
```

**En el servidor RADIUS:**

```bash
# Modo debug (CRÍTICO para troubleshooting)
sudo systemctl stop freeradius
sudo freeradius -X

# Ver últimos rechazos
sudo grep "Access-Reject" /var/log/freeradius/radius.log | tail -20

# Ver por usuario específico
sudo grep "jperez" /var/log/freeradius/radius.log | tail -50

# Verificar conectividad desde AP
sudo tcpdump -i eth0 port 1812 -vv
```

#### Escenarios específicos:

**Escenario A: "TLS Alert: Unknown CA"**

```
Causa: Cliente no confía en el certificado del servidor
Solución:
  1. Verificar que ca.pem está instalado en cliente
  2. En Windows: debe estar en "Trusted Root Certification Authorities"
  3. En Linux: ruta correcta en wpa_supplicant.conf
  4. Verificar CN del servidor coincide (radius.empresa.local)
```

**Escenario B: "Invalid shared secret"**

```
En logs de RADIUS:
  "Ignoring request from unknown client 192.168.1.20"
  O "Invalid Message-Authenticator!"

Causa: Shared secret no coincide entre AP y RADIUS
Solución:
  1. Verificar secret en /etc/freeradius/3.0/clients.conf
  2. Verificar secret configurado en el AP
  3. Atención a espacios, case-sensitive
  4. Reiniciar FreeRADIUS después de cambios
```

**Escenario C: "Certificate has expired"**

```
En logs:
  "TLS Alert write:fatal:certificate expired"

Solución:
  1. Verificar fecha del servidor (NTP sincronizado)
  2. Verificar validez del certificado:
     openssl x509 -in server.pem -noout -dates
  3. Renovar certificado si expiró
  4. Reiniciar FreeRADIUS
```

**Escenario D: "Login incorrect"**

```
En logs (si se usa PEAP con password):
  "Login incorrect: [username/password]"

Causa: Credenciales incorrectas
Solución:
  1. Verificar usuario existe en /etc/freeradius/3.0/users
  2. Verificar password es correcto
  3. Probar con radtest:
     radtest usuario password localhost 0 testing123
```

---

### Caso 2: Intermitencia en conexiones

**Síntoma**: Clientes se desconectan aleatoriamente y deben reconectar.

#### Causas posibles:

1. **Interferencia WiFi**
   ```bash
   # Escanear espectro
   sudo airodump-ng wlan0mon

   # Buscar:
   # - Canales congestionados
   # - Rogue APs
   # - Overlap de canales
   ```

2. **Problemas de roaming**
   ```
   # Si hay múltiples APs:
   # - 802.11r mal configurado
   # - PMK caching issues
   # - Diferente configuración entre APs
   ```

3. **Timeout de sesión RADIUS**
   ```conf
   # En users file
   Session-Timeout = 28800  # 8 horas
   Idle-Timeout = 600       # 10 minutos

   # Verificar si timeout es muy corto
   ```

4. **DHCP lease expira**
   ```bash
   # Verificar duración de lease DHCP
   # Debe ser menor que Session-Timeout
   ```

#### Diagnóstico:

```bash
# Capturar durante desconexión
sudo tcpdump -i wlan0mon -w disconnect.pcap &
TCPDUMP_PID=$!

# Esperar a que ocurra desconexión
# ...

# Detener captura
sudo kill $TCPDUMP_PID

# Analizar en Wireshark
wireshark disconnect.pcap

# Buscar:
# - Deauth frames (posible ataque)
# - EAPOL-Logoff
# - RADIUS Disconnect-Request
```

---

### Caso 3: VLAN no se asigna correctamente

**Síntoma**: Usuario se autentica pero queda en VLAN incorrecta.

#### Checklist de verificación:

1. **RADIUS envía atributos de VLAN**
   ```bash
   # En logs de RADIUS (modo debug)
   sudo freeradius -X

   # Buscar en Access-Accept:
   Tunnel-Type = VLAN
   Tunnel-Medium-Type = IEEE-802
   Tunnel-Private-Group-Id = "10"
   ```

2. **AP soporta VLAN dinámica**
   ```
   # Verificar en configuración del AP:
   ✓ RADIUS VLAN Assignment: Enabled
   ✓ VLAN: Use RADIUS assigned VLAN
   ```

3. **Puerto del AP es trunk**
   ```cisco
   # En switch
   show interface gi0/1 switchport

   # Debe mostrar:
   Switchport: Enabled
   Mode: trunk
   Trunking VLANs Enabled: 10,20,30,...
   ```

4. **VLAN existe en switch**
   ```cisco
   show vlan brief

   # VLAN 10 debe existir
   ```

5. **Capturar tráfico para verificar tag VLAN**
   ```bash
   # Capturar en puerto del switch (con SPAN/mirror)
   sudo tcpdump -i eth0 -e -vv

   # Buscar: 802.1Q VLAN tag
   # Debe mostrar: vlan 10
   ```

#### Solución por pasos:

```bash
# 1. Verificar configuración de usuario en RADIUS
sudo nano /etc/freeradius/3.0/users

# Debe tener:
jperez Cleartext-Password := "password"
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 10

# 2. Probar autenticación y ver respuesta
echo "User-Name=jperez,User-Password=password" | \
radtest jperez password localhost 0 testing123 -x

# 3. Verificar en Access-Accept:
# Received Access-Accept
#   Tunnel-Type:0 = VLAN
#   Tunnel-Medium-Type:0 = IEEE-802
#   Tunnel-Private-Group-Id:0 = "10"

# 4. Si RADIUS envía correctamente pero AP no asigna:
# - Verificar firmware del AP actualizado
# - Verificar documentación del fabricante
# - Verificar attribute format (string vs integer)
```

---

### Caso 4: Performance degradada

**Síntoma**: Autenticaciones lentas, timeouts frecuentes.

#### Causas y soluciones:

**A. Servidor RADIUS sobrecargado**

```bash
# Verificar CPU y memoria
top
htop

# Ver número de procesos FreeRADIUS
ps aux | grep radiusd | wc -l

# Aumentar threads en radiusd.conf
thread pool {
    start_servers = 10
    max_servers = 32
}
```

**B. Latencia de red**

```bash
# Medir latencia AP ↔ RADIUS
ping -c 100 192.168.1.10

# Debe ser < 10ms en LAN

# Verificar packet loss
# 0% loss esperado en LAN
```

**C. Certificados grandes**

```bash
# Verificar tamaño del certificado
openssl x509 -in server.pem -noout -text | head -20

# Si es > 4096 bits, considerar reducir a 2048 para WiFi
```

**D. Logs excesivos**

```bash
# Deshabilitar logs muy verbose en producción
# /etc/freeradius/3.0/radiusd.conf

log {
    auth = no  # Cambiar a 'yes' solo para debugging
    auth_badpass = yes
    auth_goodpass = no
}
```

**E. Base de datos lenta (si se usa MySQL/PostgreSQL)**

```bash
# Verificar índices en tabla de usuarios
# Agregar cache en FreeRADIUS

cache {
    enable = yes
    ttl = 600
    max_entries = 5000
}
```

#### Benchmarking:

```bash
#!/bin/bash
# benchmark-radius.sh

RADIUS="192.168.1.10"
USER="testuser"
PASS="testpass"
SECRET="testing123"
ITERATIONS=100

echo "Benchmarking RADIUS server..."

start=$(date +%s%N)

for i in $(seq 1 $ITERATIONS); do
    radtest $USER $PASS $RADIUS 0 $SECRET > /dev/null 2>&1
done

end=$(date +%s%N)
duration=$(( ($end - $start) / 1000000 ))
avg=$(( $duration / $ITERATIONS ))

echo "Total time: $duration ms"
echo "Average per auth: $avg ms"
echo "Auths per second: $(( 1000 / $avg ))"
```

---

## PARTE III: ESCENARIOS DE SEGURIDAD

### Escenario 1: Detección de Rogue AP

**Situación**: Alguien instaló un AP no autorizado con SSID "WiFi-Corporativo".

#### Detección:

```bash
# 1. Escanear redes WiFi
sudo airodump-ng wlan0mon

# 2. Identificar APs con mismo SSID pero BSSID diferente
# BSSID = MAC address del AP

# 3. Capturar beacon frames
sudo airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w rogue wlan0mon

# 4. Analizar beacon frame en Wireshark
# Ver: Security type, channel, signal strength

# 5. Triangular ubicación física usando señal
# Moverse con laptop y medir signal strength
```

#### Mitigación:

```
1. Deshabilitar puerto del switch donde está conectado
2. Localizar físicamente y remover
3. Investigar quién lo instaló
4. Implementar monitoreo continuo:
   - Wireless IDS/IPS
   - Controllers con detección de Rogue AP
```

---

### Escenario 2: Ataque de desautenticación (Deauth Attack)

**Situación**: Clientes se desconectan constantemente.

#### Detección:

```bash
# Capturar frames de desautenticación
sudo airodump-ng -c 6 wlan0mon -w deauth

# Filtrar en Wireshark
wlan.fc.type_subtype == 0x0c

# Analizar:
# - ¿Reason code? (normal: 1-3, ataque: puede ser cualquiera)
# - ¿Frecuencia? (normal: ocasional, ataque: múltiples por segundo)
# - ¿Destination? (ataque broadcast: ff:ff:ff:ff:ff:ff)
```

#### Mitigación:

```
Solución: Habilitar 802.11w (PMF - Protected Management Frames)

En Access Point:
  PMF: Required

Esto protege frames de management (deauth, disassoc) con cifrado.

Verificación:
  - Frames deauth tendrán "Protected" flag
  - Frames no protegidos serán ignorados
```

#### Demostración (solo en laboratorio controlado):

```bash
# ADVERTENCIA: Solo usar en red propia de prueba

# Instalar herramientas
sudo apt install aircrack-ng

# Modo monitor
sudo airmon-ng start wlan0

# Escanear
sudo airodump-ng wlan0mon

# Ataque de deauth (SOLO EN LAB PROPIO)
sudo aireplay-ng --deauth 10 -a [BSSID_AP] wlan0mon

# Observar clientes desconectándose

# Habilitar PMF y repetir
# Ataque no tendrá efecto
```

---

### Escenario 3: Credential Stuffing (intentos masivos de autenticación)

**Situación**: Logs muestran cientos de intentos fallidos de autenticación.

#### Detección:

```bash
# Ver intentos fallidos
sudo grep "Access-Reject" /var/log/freeradius/radius.log | \
    tail -100 | \
    awk '{print $10}' | sort | uniq -c | sort -rn

# Output:
#  85 username="admin"
#  42 username="root"
#  38 username="test"
```

#### Automatizar detección:

```bash
#!/bin/bash
# detect-bruteforce.sh

LOGFILE="/var/log/freeradius/radius.log"
THRESHOLD=10  # Max intentos fallidos por usuario en 1 hora
WINDOW="1 hour ago"

# Contar Access-Reject por usuario en última hora
rejects=$(grep "Access-Reject" "$LOGFILE" --since="$WINDOW" | \
          grep -oP 'User-Name = "\K[^"]+' | \
          sort | uniq -c | sort -rn)

echo "$rejects" | while read count username; do
    if [ "$count" -gt "$THRESHOLD" ]; then
        echo "ALERTA: Usuario $username tiene $count intentos fallidos"

        # Opcional: Bloquear temporalmente en RADIUS
        echo "DEFAULT User-Name == \"$username\", Auth-Type := Reject" >> \
            /etc/freeradius/3.0/users.blocked

        # Enviar alerta
        echo "Usuario $username bloqueado por $count intentos fallidos" | \
            mail -s "ALERTA: Posible ataque de fuerza bruta" security@empresa.local
    fi
done
```

#### Mitigación:

1. **Rate limiting en RADIUS**
   ```conf
   # /etc/freeradius/3.0/sites-available/default

   limit {
       max_concurrent_requests = 100
       lifetime = 0
       idle_timeout = 30
   }
   ```

2. **Fail2ban para RADIUS**
   ```bash
   # /etc/fail2ban/jail.local

   [freeradius]
   enabled = true
   port = 1812,1813
   protocol = udp
   filter = freeradius
   logpath = /var/log/freeradius/radius.log
   maxretry = 5
   bantime = 3600
   findtime = 600
   ```

3. **Certificados en lugar de contraseñas**
   ```
   Migrar de PEAP-MSCHAPv2 a EAP-TLS
   - No hay contraseñas que adivinar
   - Requiere certificado válido
   ```

---

## PARTE IV: EJERCICIOS DE EVALUACIÓN

### Ejercicio Final 1: Auditoría de Seguridad

**Objetivo**: Realizar una auditoría completa de la implementación WiFi Enterprise.

**Tareas:**

1. **Revisión de configuración**
   - ¿Qué versión de WPA se usa? (WPA2/WPA3)
   - ¿PMF está habilitado?
   - ¿Qué método EAP? (TLS, PEAP, TTLS)
   - ¿Certificados válidos y no expirados?

2. **Revisión de seguridad de servidor**
   - ¿Firewall configurado correctamente?
   - ¿Servicios innecesarios deshabilitados?
   - ¿Logs centralizados?
   - ¿Backups configurados?

3. **Revisión de segregación de red**
   - ¿VLANs implementadas?
   - ¿ACLs configuradas por VLAN?
   - ¿Invitados aislados de red interna?

4. **Pruebas de penetración básicas**
   - Intentar fuerza bruta (debe ser bloqueado)
   - Intentar deauth attack (debe ser mitigado por PMF)
   - Verificar cifrado de datos

**Entregable**: Reporte de auditoría con hallazgos y recomendaciones

---

### Ejercicio Final 2: Disaster Recovery Drill

**Escenario**: El servidor RADIUS principal ha fallado completamente.

**Objetivo**: Recuperar el servicio en menos de 2 horas.

**Pasos a documentar:**

1. Detectar el problema
2. Activar servidor secundario (o restaurar desde backup)
3. Verificar funcionamiento
4. Comunicar a usuarios
5. Identificar causa raíz
6. Implementar mejoras

**Métrica**: Tiempo de servicio caído (downtime)

---

### Ejercicio Final 3: Caso de Estudio Completo

**Situación**: Una empresa de 500 empleados necesita implementar WiFi Enterprise.

**Requerimientos:**

- 3 edificios, 50 APs totales
- 4 tipos de usuarios: Empleados, Gerencia, Invitados, Dispositivos IoT
- Alta disponibilidad (99.9% uptime)
- Integración con Active Directory existente
- Cumplimiento con normativa de seguridad (ej. ISO 27001)

**Tareas:**

1. **Diseñar arquitectura completa**
   - Diagrama de red
   - VLANs y segmentación
   - Ubicación de servidores RADIUS
   - Estrategia de HA

2. **Planificar implementación**
   - Cronograma por fases
   - Recursos necesarios (HW, SW, personal)
   - Plan de rollback
   - Plan de capacitación

3. **Documentar configuraciones**
   - Templates de configuración de APs
   - Configuración de RADIUS servers
   - Políticas de acceso por grupo
   - Procedimientos operacionales

4. **Plan de operación y mantenimiento**
   - Monitoreo y alertas
   - Renovación de certificados
   - Backup y DR
   - Proceso de onboarding/offboarding

**Entregable**: Documento completo de diseño e implementación (20-30 páginas)

---

## PARTE V: TROUBLESHOOTING QUICK REFERENCE

### Guía rápida de resolución de problemas

```
┌────────────────────────────────────────────────────────────┐
│              SÍNTOMA → CAUSA → SOLUCIÓN                    │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ SSID no visible                                            │
│   └→ AP apagado o SSID broadcast deshabilitado            │
│      └→ Verificar energía, habilitar broadcast            │
│                                                            │
│ "No se puede conectar"                                     │
│   └→ Múltiples causas, usar flowchart de diagnóstico      │
│                                                            │
│ "Autenticando..." infinito                                 │
│   └→ EAP handshake falla                                  │
│      └→ Verificar certificados, logs de RADIUS            │
│                                                            │
│ "Obteniendo dirección IP..." infinito                      │
│   └→ DHCP no funciona en VLAN asignada                    │
│      └→ Verificar DHCP server, relay agent                │
│                                                            │
│ Conexión intermitente                                      │
│   └→ Interferencia, problemas de roaming, timeouts        │
│      └→ Analizar espectro, ajustar timeouts               │
│                                                            │
│ "TLS Alert: Unknown CA"                                    │
│   └→ Cliente no confía en certificado del servidor        │
│      └→ Instalar ca.pem en cliente                        │
│                                                            │
│ "Certificate expired"                                      │
│   └→ Certificado expirado o reloj desincronizado          │
│      └→ Renovar certificado, sincronizar NTP              │
│                                                            │
│ VLAN incorrecta                                            │
│   └→ RADIUS no envía atributos o AP no los procesa        │
│      └→ Verificar configuración RADIUS y AP               │
│                                                            │
│ Rendimiento degradado                                      │
│   └→ Servidor sobrecargado, red lenta, logs excesivos     │
│      └→ Escalar recursos, optimizar configuración         │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### Comandos esenciales por situación

```bash
# Verificar conectividad básica
ping 192.168.1.10
traceroute 192.168.1.10

# Ver estado WiFi (Linux)
nmcli device status
iwconfig

# Reiniciar NetworkManager
sudo systemctl restart NetworkManager

# Modo debug RADIUS (MÁS IMPORTANTE)
sudo systemctl stop freeradius
sudo freeradius -X

# Ver logs en tiempo real
sudo tail -f /var/log/freeradius/radius.log
sudo journalctl -u freeradius -f

# Test de autenticación
radtest usuario password 192.168.1.10 0 testing123

# Verificar certificado
openssl x509 -in certificado.pem -noout -text
openssl x509 -in certificado.pem -noout -dates

# Verificar cadena de certificados
openssl verify -CAfile ca.pem certificado.pem

# Captura de paquetes
sudo tcpdump -i eth0 port 1812 -vv
sudo tcpdump -i wlan0mon ether proto 0x888e -w auth.pcap

# Escanear WiFi
sudo iwlist wlan0 scan
sudo nmcli device wifi list
```

---

## Checklist de Evaluación del TP

### Conocimientos teóricos
- [ ] Comprende diferencia entre WPA2-Personal y WPA2-Enterprise
- [ ] Conoce componentes de 802.1X (suplicante, autenticador, RADIUS)
- [ ] Entiende métodos EAP (TLS, TTLS, PEAP)
- [ ] Conoce estructura de PKI (CA, certificados servidor/cliente)
- [ ] Comprende flujo completo de autenticación

### Habilidades prácticas
- [ ] Puede instalar y configurar FreeRADIUS
- [ ] Puede generar y gestionar certificados X.509
- [ ] Puede configurar Access Points para 802.1X
- [ ] Puede configurar clientes (Windows, Linux, Android)
- [ ] Puede capturar y analizar tráfico con Wireshark

### Troubleshooting
- [ ] Puede diagnosticar problemas de conectividad
- [ ] Puede interpretar logs de RADIUS
- [ ] Puede usar modo debug efectivamente
- [ ] Puede identificar problemas de certificados
- [ ] Puede resolver problemas de VLANs

### Seguridad
- [ ] Comprende importancia de PMF (802.11w)
- [ ] Conoce mejores prácticas de gestión de certificados
- [ ] Puede detectar ataques básicos (deauth, rogue AP)
- [ ] Entiende segmentación de red con VLANs
- [ ] Conoce principios de defensa en profundidad

### Operaciones
- [ ] Puede implementar alta disponibilidad
- [ ] Puede configurar monitoreo y alertas
- [ ] Puede realizar backups y restauración
- [ ] Puede documentar configuraciones
- [ ] Comprende procedimientos de mantenimiento

---

## Recursos Adicionales

### Documentación oficial
- FreeRADIUS: https://wiki.freeradius.org/
- IEEE 802.1X: https://standards.ieee.org/standard/802_1X-2020.html
- RFC 2865 (RADIUS): https://tools.ietf.org/html/rfc2865
- RFC 3748 (EAP): https://tools.ietf.org/html/rfc3748
- RFC 5216 (EAP-TLS): https://tools.ietf.org/html/rfc5216

### Herramientas
- Wireshark: https://www.wireshark.org/
- Aircrack-ng suite: https://www.aircrack-ng.org/
- wpa_supplicant: https://w1.fi/wpa_supplicant/
- hostapd: https://w1.fi/hostapd/

### Labs virtuales
- GNS3: Simular infraestructura de red
- EVE-NG: Emulación de red empresarial
- Packet Tracer: Simulación Cisco (incluye 802.1X)

---

**FIN DEL TRABAJO PRÁCTICO**

Este material proporciona una base sólida para comprender, implementar y mantener una infraestructura WiFi empresarial segura con autenticación 802.1X y RADIUS.
