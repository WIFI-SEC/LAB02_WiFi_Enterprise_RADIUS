# Mejores Prácticas y Configuración Empresarial

## Introducción

Este documento presenta las mejores prácticas para implementar y mantener una infraestructura WiFi empresarial segura con autenticación 802.1X y RADIUS.

---

## 1. Arquitectura de Seguridad en Capas

### 1.1 Modelo de defensa en profundidad

```
┌──────────────────────────────────────────────────────────────┐
│                  Capa 7: Monitoreo y Auditoría               │
│  - SIEM, Logs centralizados, Alertas de seguridad            │
└──────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────┐
│            Capa 6: Políticas de Acceso y Segmentación        │
│  - VLANs dinámicas, ACLs, Firewall policies                  │
└──────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────┐
│         Capa 5: Autenticación y Autorización (RADIUS)        │
│  - EAP-TLS, Certificados, Multi-factor authentication        │
└──────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────┐
│           Capa 4: Cifrado de Datos (WPA2/WPA3)               │
│  - AES-CCMP, PMF (802.11w), Perfect Forward Secrecy          │
└──────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────┐
│        Capa 3: Control de Acceso al Medio (802.1X)           │
│  - Port-based authentication, EAP negotiation                │
└──────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────┐
│         Capa 2: Infraestructura WiFi (APs, Controllers)      │
│  - Detección de Rogue APs, Wireless IDS/IPS                  │
└──────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────┐
│              Capa 1: Seguridad Física                        │
│  - Control de acceso a equipos, Rack security                │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Diseño de Red Empresarial

### 2.1 Segmentación por VLANs

#### Modelo recomendado

```
┌────────────────────────────────────────────────────────────┐
│                     Access Points                          │
│               (802.1X Authentication)                      │
└────────────────────────┬───────────────────────────────────┘
                         │
                         │ Trunk (todas las VLANs)
                         │
┌────────────────────────▼───────────────────────────────────┐
│                    Core Switch                             │
│              (VLAN Routing & ACLs)                         │
└──┬──────┬──────┬───────┬───────┬──────────────────────────┘
   │      │      │       │       │
 VLAN10 VLAN20 VLAN30  VLAN40  VLAN99
   │      │      │       │       │
Empleados Gerencia Invitados IoT  Cuarentena
```

#### Tabla de VLANs recomendadas

| VLAN ID | Nombre | Propósito | Acceso a | Restricciones |
|---------|--------|-----------|----------|---------------|
| **10** | Empleados | Usuarios estándar | Internet, Recursos internos (limitados) | ACL: No acceso a servidores críticos |
| **20** | Gerencia | Directivos, IT | Internet, Todos los recursos | Sin restricciones (monitoreado) |
| **30** | Invitados | Visitantes temporales | Solo Internet | Aislado completamente de red interna |
| **40** | IoT/Dispositivos | Impresoras, cámaras, sensores | Recursos específicos | Sin acceso a equipos de usuarios |
| **50** | VoIP | Teléfonos IP | Servidor VoIP, Gateway | QoS prioritario |
| **99** | Cuarentena | Dispositivos no conformes | Solo servidor de remediación | NAC (Network Access Control) |

### 2.2 ACLs (Access Control Lists)

#### Ejemplo: ACL para VLAN de Empleados

```cisco
! Permitir acceso a servicios corporativos específicos
ip access-list extended ACL-VLAN-EMPLEADOS
 ! Permitir DNS
 permit udp any any eq 53
 ! Permitir HTTP/HTTPS
 permit tcp any any eq 80
 permit tcp any any eq 443
 ! Permitir email (SMTP, IMAP, POP3)
 permit tcp any any eq 25
 permit tcp any any eq 587
 permit tcp any any eq 993
 permit tcp any any eq 995
 ! Permitir servidor de archivos
 permit tcp any host 192.168.100.10 eq 445
 ! Permitir impresoras en VLAN 40
 permit tcp any 192.168.40.0 0.0.0.255 eq 9100
 ! DENEGAR acceso a servidores críticos
 deny ip any 192.168.200.0 0.0.0.255
 ! DENEGAR acceso a VLAN de gerencia
 deny ip any 192.168.20.0 0.0.0.255
 ! Permitir todo lo demás a Internet
 permit ip any any

! Aplicar ACL a interfaz VLAN 10
interface Vlan10
 ip access-group ACL-VLAN-EMPLEADOS in
```

#### Ejemplo: ACL para VLAN de Invitados

```cisco
ip access-list extended ACL-VLAN-INVITADOS
 ! Permitir DNS
 permit udp any any eq 53
 ! Permitir HTTP/HTTPS
 permit tcp any any eq 80
 permit tcp any any eq 443
 ! DENEGAR TODO acceso a redes internas
 deny ip any 192.168.0.0 0.0.255.255
 deny ip any 10.0.0.0 0.255.255.255
 ! Permitir solo Internet
 permit ip any any

interface Vlan30
 ip access-group ACL-VLAN-INVITADOS in
```

### 2.3 Portal cautivo para invitados (opcional)

Para VLAN de invitados, implementar portal captive:

```
┌──────────────┐
│   Cliente    │
│  Invitado    │
└──────┬───────┘
       │
       │ 1. Conecta a "WiFi-Invitados"
       │    (WPA2-Enterprise o Portal Abierto)
       │
       ▼
┌──────────────┐
│  Controlador │
│    WiFi      │
└──────┬───────┘
       │
       │ 2. Redirige a portal cautivo
       │
       ▼
┌──────────────┐
│    Portal    │
│   Cautivo    │  3. Usuario ingresa:
│              │     - Email, Teléfono, etc.
│              │     - Acepta Términos de Uso
└──────┬───────┘
       │
       │ 4. RADIUS autoriza acceso temporal
       │
       ▼
   Internet
```

---

## 3. Alta Disponibilidad y Redundancia

### 3.1 Servidores RADIUS redundantes

```
             ┌─────────────────────┐
             │   Access Points     │
             └──────────┬──────────┘
                        │
         ┌──────────────┴──────────────┐
         │                             │
         ▼                             ▼
┌─────────────────┐           ┌─────────────────┐
│  RADIUS Primary │           │ RADIUS Secondary│
│  192.168.1.10   │           │  192.168.1.11   │
│  (Active)       │           │  (Standby)      │
└────────┬────────┘           └────────┬────────┘
         │                             │
         └──────────────┬──────────────┘
                        │
              Replicación de configuración
              y base de datos de usuarios
```

#### Configuración en el AP

```
Primary RADIUS Server:
  IP: 192.168.1.10
  Port: 1812
  Secret: SuperSecretRADIUS2024!
  Timeout: 3 seconds
  Retries: 2

Secondary RADIUS Server:
  IP: 192.168.1.11
  Port: 1812
  Secret: SuperSecretRADIUS2024!
  Timeout: 3 seconds
  Retries: 2
```

#### Sincronización de certificados

```bash
#!/bin/bash
# sync-radius-servers.sh

PRIMARY="192.168.1.10"
SECONDARY="192.168.1.11"

# Sincronizar configuración de FreeRADIUS
rsync -avz /etc/freeradius/3.0/ \
      root@$SECONDARY:/etc/freeradius/3.0/

# Sincronizar certificados
rsync -avz /etc/ssl/radius-certs/ \
      root@$SECONDARY:/etc/ssl/radius-certs/

# Reiniciar servicio en secundario
ssh root@$SECONDARY "systemctl restart freeradius"

echo "Sincronización completada: $PRIMARY → $SECONDARY"
```

### 3.2 Monitoreo de salud de RADIUS

```bash
#!/bin/bash
# health-check-radius.sh

RADIUS_SERVER="192.168.1.10"
TEST_USER="testuser"
TEST_PASS="testpass"
SHARED_SECRET="testing123"

# Usar radtest para verificar funcionamiento
result=$(echo "User-Name=$TEST_USER,User-Password=$TEST_PASS" | \
         radtest $TEST_USER $TEST_PASS $RADIUS_SERVER 0 $SHARED_SECRET 2>&1)

if echo "$result" | grep -q "Access-Accept"; then
    echo "OK: RADIUS server respondiendo correctamente"
    exit 0
else
    echo "CRITICAL: RADIUS server no responde o rechaza autenticación"
    # Enviar alerta
    echo "$result" | mail -s "ALERTA: RADIUS DOWN" admin@empresa.local
    exit 2
fi
```

**Automatizar con cron (cada 5 minutos):**

```bash
*/5 * * * * /usr/local/bin/health-check-radius.sh
```

### 3.3 Failover automático (con Keepalived)

```bash
# Instalar keepalived
sudo apt install keepalived -y

# Configurar VIP (Virtual IP)
sudo nano /etc/keepalived/keepalived.conf
```

**En servidor primario:**

```conf
vrrp_instance RADIUS_HA {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 150
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass SecurePass2024
    }

    virtual_ipaddress {
        192.168.1.100/24  # VIP que usan los APs
    }

    track_script {
        check_radius
    }
}

vrrp_script check_radius {
    script "/usr/local/bin/health-check-radius.sh"
    interval 5
    fall 2
    rise 2
}
```

**En servidor secundario:**

```conf
vrrp_instance RADIUS_HA {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass SecurePass2024
    }

    virtual_ipaddress {
        192.168.1.100/24
    }
}
```

**Configurar APs para usar VIP:**

```
RADIUS Server: 192.168.1.100 (VIP)
```

---

## 4. Gestión de Certificados en Producción

### 4.1 Ciclo de vida de certificados

```
┌─────────────────────────────────────────────────────────┐
│                 CICLO DE VIDA                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. GENERACIÓN                                          │
│     - Crear CSR                                         │
│     - Firmar con CA                                     │
│     - Distribuir a usuarios                             │
│                 ↓                                       │
│  2. ACTIVACIÓN                                          │
│     - Instalar en dispositivos                          │
│     - Verificar funcionamiento                          │
│                 ↓                                       │
│  3. OPERACIÓN (1 año típico)                            │
│     - Monitoreo de expiración                           │
│     - Logs de uso                                       │
│                 ↓                                       │
│  4. RENOVACIÓN (30 días antes de expirar)               │
│     - Generar nuevo certificado                         │
│     - Distribuir a usuarios                             │
│     - Usuario instala nuevo (overlap permitido)         │
│                 ↓                                       │
│  5. EXPIRACIÓN / REVOCACIÓN                             │
│     - Certificado viejo expira automáticamente          │
│     - O revocación manual (empleado sale, pérdida)      │
│     - Actualizar CRL                                    │
│                 ↓                                       │
│  6. ARCHIVO                                             │
│     - Guardar logs de auditoría                         │
│     - Mantener por período legal                        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Automatización de renovación

```bash
#!/bin/bash
# auto-renew-certificates.sh

CA_DIR="/etc/ssl/radius-certs"
WARNING_DAYS=30

# Buscar certificados próximos a expirar
find "$CA_DIR/clients/certs" -name "*.pem" -type f | while read cert; do
    username=$(basename "$cert" .pem)

    # Verificar fecha de expiración
    expiry_date=$(openssl x509 -in "$cert" -noout -enddate | cut -d= -f2)
    expiry_epoch=$(date -d "$expiry_date" +%s)
    now_epoch=$(date +%s)
    days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))

    if [ $days_left -lt $WARNING_DAYS ]; then
        echo "ADVERTENCIA: Certificado de $username expira en $days_left días"

        # Auto-renovar
        echo "  Generando nuevo certificado..."
        /etc/ssl/radius-certs/generate-client-cert.sh "$username"

        # Enviar email al usuario
        mail -s "Renovación de Certificado WiFi" "$username@empresa.local" <<EOF
Estimado/a,

Su certificado WiFi expirará en $days_left días.

Se ha generado un nuevo certificado. Por favor descárguelo desde:
https://portal.empresa.local/certs/$username

Instrucciones de instalación disponibles en el portal.

Saludos,
IT Security Team
EOF

        echo "  ✓ Certificado renovado y notificación enviada"
    fi
done
```

### 4.3 Revocación de certificados

**Proceso de revocación:**

```bash
#!/bin/bash
# revoke-certificate.sh

USERNAME="$1"

if [ -z "$USERNAME" ]; then
    echo "Uso: $0 <username>"
    exit 1
fi

CA_DIR="/etc/ssl/radius-certs"
CERT_FILE="$CA_DIR/clients/certs/$USERNAME.pem"

if [ ! -f "$CERT_FILE" ]; then
    echo "Error: Certificado no encontrado para $USERNAME"
    exit 1
fi

echo "Revocando certificado de: $USERNAME"

# 1. Revocar con OpenSSL
openssl ca -config "$CA_DIR/ca.cnf" \
    -revoke "$CERT_FILE"

# 2. Generar nueva CRL (Certificate Revocation List)
openssl ca -config "$CA_DIR/ca.cnf" \
    -gencrl -out "$CA_DIR/ca/crl/crl.pem"

# 3. Actualizar CRL en FreeRADIUS
cp "$CA_DIR/ca/crl/crl.pem" /etc/freeradius/3.0/certs/

# 4. Reiniciar FreeRADIUS para cargar nueva CRL
systemctl restart freeradius

# 5. Registrar en log de auditoría
echo "$(date): Certificado revocado: $USERNAME por $(whoami)" >> \
    /var/log/cert-revocations.log

# 6. Notificar al usuario
mail -s "Certificado WiFi Revocado" "$USERNAME@empresa.local" <<EOF
Su certificado WiFi ha sido revocado.

Si esto es un error, contacte a IT Security.

Si salió de la empresa, por favor devuelva todo el equipamiento corporativo.

Saludos,
IT Security Team
EOF

echo "✓ Certificado revocado exitosamente"
echo "  - CRL actualizada"
echo "  - FreeRADIUS reiniciado"
echo "  - Usuario notificado"
```

### 4.4 OCSP (Online Certificate Status Protocol)

Para verificación en tiempo real (alternativa a CRL):

```bash
# Instalar OCSP responder
sudo apt install ocspd -y

# Configurar en FreeRADIUS (/etc/freeradius/3.0/mods-available/eap)
ocsp {
    enable = yes
    override_cert_url = yes
    url = "http://ocsp.empresa.local:8888/"
    use_nonce = yes
    timeout = 5
    softfail = no
}
```

---

## 5. Monitoreo y Logging

### 5.1 Logs centralizados (Syslog)

```bash
# Configurar FreeRADIUS para enviar logs a servidor syslog central
sudo nano /etc/freeradius/3.0/radiusd.conf
```

```conf
log {
    destination = syslog
    syslog_facility = daemon

    # Enviar a servidor central
    file = /var/log/freeradius/radius.log

    # También enviar a syslog remoto
    # (configurar rsyslog por separado)
}
```

**Configurar rsyslog:**

```bash
sudo nano /etc/rsyslog.d/50-radius.conf
```

```conf
# Enviar logs de RADIUS a servidor central
if $programname == 'radiusd' then @@syslog.empresa.local:514
& stop
```

### 5.2 Métricas importantes a monitorear

```bash
#!/bin/bash
# metrics-radius.sh

LOG="/var/log/freeradius/radius.log"
TIMEFRAME="1 hour ago"

echo "=== Métricas RADIUS (última hora) ==="
echo ""

# Total de autenticaciones
total=$(grep -c "Access-Request" "$LOG" --since="$TIMEFRAME")
echo "Total de intentos de autenticación: $total"

# Exitosas
accepts=$(grep -c "Access-Accept" "$LOG" --since="$TIMEFRAME")
echo "Autenticaciones exitosas: $accepts"

# Fallidas
rejects=$(grep -c "Access-Reject" "$LOG" --since="$TIMEFRAME")
echo "Autenticaciones fallidas: $rejects"

# Tasa de éxito
if [ $total -gt 0 ]; then
    success_rate=$(echo "scale=2; $accepts * 100 / $total" | bc)
    echo "Tasa de éxito: $success_rate%"
fi

echo ""

# Usuarios más activos
echo "Top 5 usuarios:"
grep "Access-Accept" "$LOG" --since="$TIMEFRAME" | \
    grep -oP 'User-Name = "\K[^"]+' | \
    sort | uniq -c | sort -rn | head -5

echo ""

# APs más activos
echo "Top 5 Access Points:"
grep "Access-Request" "$LOG" --since="$TIMEFRAME" | \
    grep -oP 'NAS-IP-Address = \K[0-9.]+' | \
    sort | uniq -c | sort -rn | head -5
```

### 5.3 Integración con SIEM

**Ejemplo de configuración para Splunk:**

```bash
# Instalar Splunk Universal Forwarder
wget -O splunkforwarder.deb 'https://...'
sudo dpkg -i splunkforwarder.deb

# Configurar inputs
sudo /opt/splunkforwarder/bin/splunk add monitor \
    /var/log/freeradius/radius.log \
    -sourcetype radius

# Configurar forward server
sudo /opt/splunkforwarder/bin/splunk add forward-server \
    siem.empresa.local:9997

# Iniciar
sudo /opt/splunkforwarder/bin/splunk start
```

**Queries útiles en SIEM:**

```spl
# Autenticaciones fallidas en última hora
source="/var/log/freeradius/radius.log" "Access-Reject"
| stats count by User-Name
| sort -count

# Detección de ataques de fuerza bruta
source="/var/log/freeradius/radius.log" "Access-Reject"
| stats count by User-Name, NAS-IP-Address
| where count > 5

# Usuarios conectándose desde múltiples APs (posible roaming anómalo)
source="/var/log/freeradius/radius.log" "Access-Accept"
| stats dc(NAS-IP-Address) as AP_count by User-Name
| where AP_count > 3
```

---

## 6. Seguridad Operacional

### 6.1 Hardening del servidor RADIUS

```bash
#!/bin/bash
# harden-radius-server.sh

echo "=== Hardening de Servidor RADIUS ==="

# 1. Actualizar sistema
apt update && apt upgrade -y

# 2. Deshabilitar servicios innecesarios
systemctl disable bluetooth
systemctl disable cups
systemctl disable avahi-daemon

# 3. Configurar firewall estricto
ufw default deny incoming
ufw default allow outgoing
ufw allow from 192.168.1.0/24 to any port 22 proto tcp  # SSH solo desde LAN
ufw allow from 192.168.1.0/24 to any port 1812 proto udp # RADIUS auth
ufw allow from 192.168.1.0/24 to any port 1813 proto udp # RADIUS accounting
ufw enable

# 4. Configurar fail2ban para SSH
apt install fail2ban -y
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
systemctl enable fail2ban
systemctl start fail2ban

# 5. Configurar auditoría de archivos (auditd)
apt install auditd -y
auditctl -w /etc/freeradius/3.0/ -p wa -k radius_config_change
auditctl -w /etc/ssl/radius-certs/ -p wa -k cert_change

# 6. Deshabilitar root login
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# 7. Configurar NTP para sincronización de tiempo
apt install chrony -y
systemctl enable chrony

# 8. Habilitar automatic security updates
apt install unattended-upgrades -y
dpkg-reconfigure -plow unattended-upgrades

echo "✓ Hardening completado"
```

### 6.2 Políticas de contraseñas (para métodos no-certificate)

Si se usa PEAP/TTLS con contraseñas:

```bash
# /etc/freeradius/3.0/mods-config/files/authorize

# Política de contraseña
DEFAULT Auth-Type := Reject, Password-Policy-Name := "strong"
    Reply-Message = "Contraseña no cumple políticas de seguridad"

# En mods-available/pap
pap {
    auto_header = yes
    normalise = yes
}

# Integrar con PAM para políticas del sistema
# mods-available/pam
pam {
    pam_auth = radiusd
}
```

**Configurar PAM para contraseñas fuertes:**

```bash
sudo nano /etc/pam.d/radiusd
```

```conf
auth    required    pam_unix.so
auth    required    pam_pwquality.so retry=3 minlen=12 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1
account required    pam_unix.so
```

### 6.3 Segregación de privilegios

```bash
# FreeRADIUS no debe correr como root
# Verificar usuario de servicio
ps aux | grep radiusd

# Debe mostrar: freerad (no root)

# Verificar permisos de archivos
ls -la /etc/freeradius/3.0/
# Debe ser: drwxr-x--- freerad freerad

# Verificar permisos de certificados
ls -la /etc/freeradius/3.0/certs/
# Claves privadas: -rw------- freerad freerad (600)
# Certificados públicos: -rw-r--r-- freerad freerad (644)
```

---

## 7. Cumplimiento y Auditoría

### 7.1 Retención de logs

```bash
# Configurar logrotate para RADIUS
sudo nano /etc/logrotate.d/freeradius
```

```conf
/var/log/freeradius/*.log {
    daily
    rotate 90        # Mantener 90 días (ajustar según requerimientos legales)
    compress
    delaycompress
    missingok
    notifempty
    create 640 freerad freerad
    sharedscripts
    postrotate
        /bin/kill -HUP `cat /var/run/freeradius/freeradius.pid 2>/dev/null` 2>/dev/null || true
    endscript
}
```

### 7.2 Reportes de cumplimiento

```bash
#!/bin/bash
# compliance-report.sh

REPORT_FILE="/var/reports/radius-compliance-$(date +%Y%m).txt"
mkdir -p /var/reports

cat > "$REPORT_FILE" <<EOF
=== REPORTE DE CUMPLIMIENTO RADIUS ===
Fecha: $(date)
Período: $(date +%Y-%m)

1. AUTENTICACIONES
EOF

# Estadísticas de autenticación
grep "Access-Accept" /var/log/freeradius/radius.log.* | wc -l >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

2. INTENTOS FALLIDOS DE AUTENTICACIÓN
EOF

grep "Access-Reject" /var/log/freeradius/radius.log.* | \
    grep -oP 'User-Name = "\K[^"]+' | sort | uniq -c | sort -rn >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

3. CERTIFICADOS REVOCADOS ESTE MES
EOF

grep "$(date +%Y-%m)" /var/log/cert-revocations.log >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

4. CERTIFICADOS PRÓXIMOS A EXPIRAR (30 días)
EOF

find /etc/ssl/radius-certs/clients/certs -name "*.pem" -type f | while read cert; do
    expiry=$(openssl x509 -in "$cert" -noout -enddate | cut -d= -f2)
    expiry_epoch=$(date -d "$expiry" +%s)
    now_epoch=$(date +%s)
    days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))

    if [ $days_left -lt 30 ] && [ $days_left -gt 0 ]; then
        echo "$(basename "$cert" .pem): $days_left días" >> "$REPORT_FILE"
    fi
done

cat >> "$REPORT_FILE" <<EOF

5. CONFIGURACIÓN DE SEGURIDAD
EOF

echo "  - FreeRADIUS versión: $(freeradius -v | head -1)" >> "$REPORT_FILE"
echo "  - Firewall activo: $(ufw status | head -1)" >> "$REPORT_FILE"
echo "  - Fail2ban activo: $(systemctl is-active fail2ban)" >> "$REPORT_FILE"
echo "  - Logs centralizados: $(systemctl is-active rsyslog)" >> "$REPORT_FILE"

echo ""
echo "Reporte generado: $REPORT_FILE"

# Enviar por email
mail -s "Reporte de Cumplimiento RADIUS - $(date +%Y-%m)" \
     compliance@empresa.local < "$REPORT_FILE"
```

---

## 8. Disaster Recovery y Business Continuity

### 8.1 Plan de backup

```bash
#!/bin/bash
# backup-radius.sh

BACKUP_DIR="/backup/radius"
DATE=$(date +%Y%m%d-%H%M%S)
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

# 1. Backup de configuración
tar -czf "$BACKUP_DIR/config-$DATE.tar.gz" \
    /etc/freeradius/3.0/ \
    /etc/ssl/radius-certs/

# 2. Backup de logs
tar -czf "$BACKUP_DIR/logs-$DATE.tar.gz" \
    /var/log/freeradius/

# 3. Backup de base de datos (si se usa MySQL/PostgreSQL)
# mysqldump -u radius -p radiusdb > "$BACKUP_DIR/radiusdb-$DATE.sql"

# 4. Verificar integridad
cd "$BACKUP_DIR"
sha256sum config-$DATE.tar.gz > config-$DATE.tar.gz.sha256
sha256sum logs-$DATE.tar.gz > logs-$DATE.tar.gz.sha256

# 5. Copiar a storage remoto
rsync -avz "$BACKUP_DIR/" backup-server:/backups/radius/

# 6. Limpiar backups antiguos
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.sha256" -mtime +$RETENTION_DAYS -delete

echo "Backup completado: $DATE"
```

### 8.2 Procedimiento de recuperación

```markdown
# PROCEDIMIENTO DE DISASTER RECOVERY - RADIUS

## Escenario: Servidor RADIUS caído completamente

### Tiempo objetivo de recuperación (RTO): 2 horas
### Punto objetivo de recuperación (RPO): 24 horas

### Pasos:

1. **Preparar nuevo servidor (30 min)**
   - Instalar Ubuntu 22.04 LTS
   - Configurar red (IP estática 192.168.1.10)
   - Instalar FreeRADIUS y dependencias

2. **Restaurar configuración (15 min)**
   ```bash
   # Copiar backup desde storage
   rsync -avz backup-server:/backups/radius/ /tmp/restore/

   # Extraer último backup
   cd /tmp/restore
   LATEST=$(ls -t config-*.tar.gz | head -1)
   tar -xzf "$LATEST" -C /
   ```

3. **Verificar integridad (10 min)**
   ```bash
   # Verificar checksum
   sha256sum -c config-*.sha256

   # Verificar sintaxis de configuración
   freeradius -CX
   ```

4. **Restaurar certificados (15 min)**
   ```bash
   # Los certificados vienen en el backup de configuración
   chown -R freerad:freerad /etc/freeradius/3.0/certs
   chmod 600 /etc/freeradius/3.0/certs/*.key
   ```

5. **Iniciar servicios (5 min)**
   ```bash
   systemctl start freeradius
   systemctl enable freeradius
   ```

6. **Pruebas (20 min)**
   ```bash
   # Prueba local
   radtest testuser testpass localhost 0 testing123

   # Prueba desde AP
   # Conectar un cliente y verificar autenticación

   # Verificar logs
   tail -f /var/log/freeradius/radius.log
   ```

7. **Notificar restauración (5 min)**
   - Informar a equipo de IT
   - Actualizar documentación de incidentes
   - Verificar monitoreo activo

**Total tiempo estimado: 1 hora 40 minutos**
```

---

## 9. Escalabilidad

### 9.1 Dimensionamiento

| Usuarios | APs | Autenticaciones/hora | Servidor RADIUS | Base de Datos |
|----------|-----|----------------------|-----------------|---------------|
| < 100 | 1-5 | < 500 | VM 2 vCPU, 2GB RAM | Archivos planos |
| 100-500 | 5-20 | 500-2000 | VM 4 vCPU, 4GB RAM | MySQL/PostgreSQL |
| 500-2000 | 20-50 | 2000-10000 | 2x VM 4 vCPU, 8GB RAM | MySQL cluster |
| 2000+ | 50+ | 10000+ | Load Balancer + 3+ servers | MySQL cluster + cache |

### 9.2 Optimización de performance

```bash
# /etc/freeradius/3.0/radiusd.conf

# Aumentar threads
thread pool {
    start_servers = 10
    max_servers = 32
    min_spare_servers = 5
    max_spare_servers = 15
    max_requests_per_server = 1000
}

# Optimizar cache
cache {
    enable = yes
    ttl = 600
    max_entries = 1000
}
```

---

## Checklist de Mejores Prácticas

### Diseño
- [ ] VLANs segmentadas por tipo de usuario
- [ ] ACLs configuradas para cada VLAN
- [ ] Portal cautivo para invitados (si aplica)
- [ ] Redundancia de servidores RADIUS

### Seguridad
- [ ] EAP-TLS implementado (certificados)
- [ ] WPA3 habilitado (o WPA2 mínimo)
- [ ] PMF (802.11w) habilitado
- [ ] Servidor RADIUS hardeneado
- [ ] Firewall configurado estrictamente
- [ ] Fail2ban activo

### Certificados
- [ ] CA privada configurada
- [ ] Proceso de renovación automatizado
- [ ] CRL o OCSP configurado
- [ ] Distribución segura de certificados
- [ ] Proceso de revocación documentado

### Monitoreo
- [ ] Logs centralizados
- [ ] Alertas configuradas
- [ ] Métricas en dashboard
- [ ] Integración con SIEM (si disponible)
- [ ] Health checks automatizados

### Operaciones
- [ ] Backups diarios automatizados
- [ ] Plan de disaster recovery documentado y probado
- [ ] Runbooks de troubleshooting
- [ ] Documentación actualizada
- [ ] Equipo entrenado

### Cumplimiento
- [ ] Retención de logs según normativa
- [ ] Reportes de auditoría mensuales
- [ ] Revisión trimestral de accesos
- [ ] Política de contraseñas/certificados
- [ ] Proceso de onboarding/offboarding

---

**Próximo paso**: Ejercicios prácticos y casos de troubleshooting (archivo 07)
