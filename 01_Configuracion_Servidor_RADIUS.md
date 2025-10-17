# Configuración del Servidor RADIUS (FreeRADIUS)

## Introducción

En esta sección configuraremos un servidor FreeRADIUS que actuará como servidor de autenticación centralizado para nuestra red WiFi empresarial.

---

## 1. Instalación de FreeRADIUS

### 1.1 Preparación del Sistema (Ubuntu 22.04 LTS)

```bash
# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Instalar FreeRADIUS y dependencias
sudo apt install freeradius freeradius-utils freeradius-eap -y

# Verificar versión instalada
freeradius -v
```

**Salida esperada**: FreeRADIUS Version 3.0.26 o superior

### 1.2 Verificación de Instalación

```bash
# Verificar status del servicio
sudo systemctl status freeradius

# Detener el servicio para configuración inicial
sudo systemctl stop freeradius
```

---

## 2. Estructura de Directorios de FreeRADIUS

```
/etc/freeradius/3.0/
├── clients.conf          # Configuración de clientes RADIUS (APs)
├── users                 # Base de datos de usuarios (flat file)
├── radiusd.conf         # Configuración principal del servidor
├── mods-available/      # Módulos disponibles
│   ├── eap              # Configuración EAP
│   └── files            # Autenticación por archivos
├── mods-enabled/        # Módulos activos (symlinks)
├── sites-available/     # Sites virtuales disponibles
│   ├── default          # Site por defecto
│   └── inner-tunnel     # Túnel interno (para PEAP/TTLS)
├── sites-enabled/       # Sites activos (symlinks)
└── certs/               # Certificados SSL/TLS
    ├── ca.pem           # Certificado CA
    ├── server.pem       # Certificado del servidor
    └── dh               # Parámetros Diffie-Hellman
```

---

## 3. Configuración de Clientes RADIUS (Access Points)

### 3.1 Editar `/etc/freeradius/3.0/clients.conf`

Los "clientes" en RADIUS son los dispositivos que envían peticiones de autenticación (los Access Points).

```bash
sudo nano /etc/freeradius/3.0/clients.conf
```

**Agregar configuración del Access Point:**

```conf
#
# Configuración de Access Point Corporativo
#
client access_point_oficina {
    # Dirección IP del Access Point
    ipaddr = 192.168.1.20

    # También se puede usar rango de red
    # ipaddr = 192.168.1.0/24

    # Shared secret (contraseña) entre AP y RADIUS
    # IMPORTANTE: Usar contraseña fuerte en producción
    secret = SuperSecretRADIUS2024!

    # Nombre corto para logs
    shortname = ap-oficina-01

    # Tipo de NAS (Network Access Server)
    nastype = other

    # Puerto virtual (para múltiples contextos)
    virtual_server = default

    # Límite de conexiones simultáneas
    limit {
        max_connections = 100
        lifetime = 0
        idle_timeout = 300
    }
}

# Ejemplo: Múltiples APs por subnet
client red_aps_piso2 {
    ipaddr = 192.168.2.0/24
    secret = OtroSecretSeguro2024!
    shortname = aps-piso2
    nastype = other
}

# Para pruebas locales (solo desarrollo)
client localhost {
    ipaddr = 127.0.0.1
    secret = testing123
    shortname = localhost
    nastype = other
}
```

#### Notas importantes:

- `secret` debe coincidir con la configuración del AP
- Usar secretos diferentes para cada AP o grupo de APs
- El `shortname` aparece en los logs para identificación
- `ipaddr` puede ser una IP única o un rango (CIDR)

---

## 4. Configuración de Usuarios

### 4.1 Archivo de Usuarios `/etc/freeradius/3.0/users`

Para este laboratorio inicial, usaremos autenticación por archivo (luego migraremos a certificados).

```bash
sudo nano /etc/freeradius/3.0/users
```

**Configuración de usuarios de prueba:**

```conf
#
# Formato: username [atributos de verificación]
#          [atributos de respuesta]
#

# Usuario administrativo con VLAN específica
admin Cleartext-Password := "Admin123!"
    Reply-Message = "Bienvenido Administrador",
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 10

# Usuario empleado regular
jperez Cleartext-Password := "Empleado2024!"
    Reply-Message = "Acceso concedido",
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 20

# Usuario invitado (red aislada)
invitado Cleartext-Password := "Guest2024!"
    Reply-Message = "Acceso solo a Internet",
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 30,
    Session-Timeout = 3600

# Usuario con restricción de ancho de banda (ejemplo)
mbianchi Cleartext-Password := "Password123!"
    WISPr-Bandwidth-Max-Down = 10000000,
    WISPr-Bandwidth-Max-Up = 5000000,
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = 20

# DEFAULT para usuarios no encontrados
DEFAULT Auth-Type := Reject
    Reply-Message = "Usuario no autorizado"
```

#### Explicación de atributos importantes:

| Atributo | Descripción | Valores |
|----------|-------------|---------|
| `Cleartext-Password` | Contraseña en texto plano | String |
| `Tunnel-Type` | Tipo de túnel | VLAN (13) |
| `Tunnel-Medium-Type` | Medio del túnel | IEEE-802 (6) |
| `Tunnel-Private-Group-Id` | ID de VLAN | 1-4094 |
| `Session-Timeout` | Tiempo máximo de sesión | Segundos |
| `Reply-Message` | Mensaje al usuario | String |

---

## 5. Configuración del Módulo EAP

### 5.1 Editar `/etc/freeradius/3.0/mods-available/eap`

Este es el archivo MÁS IMPORTANTE para autenticación 802.1X.

```bash
sudo nano /etc/freeradius/3.0/mods-available/eap
```

**Configuración EAP completa:**

```conf
eap {
    # Tiempo de espera para respuesta del cliente
    default_eap_type = tls

    # Timer valores
    timer_expire = 60
    ignore_unknown_eap_types = no
    cisco_accounting_username_bug = no
    max_sessions = ${max_requests}

    #
    # EAP-TLS: Autenticación con certificados (MÁS SEGURO)
    #
    tls-config tls-common {
        # Certificado del servidor RADIUS
        private_key_password = whatever
        private_key_file = ${certdir}/server.key
        certificate_file = ${certdir}/server.pem

        # Certificado de la CA (para validar clientes)
        ca_file = ${cadir}/ca.pem

        # Parámetros Diffie-Hellman para Perfect Forward Secrecy
        dh_file = ${certdir}/dh

        # Archivo de estado de sesiones (para session resumption)
        ca_path = ${cadir}
        cipher_list = "HIGH"
        cipher_server_preference = no

        # Versiones TLS permitidas
        tls_min_version = "1.2"
        tls_max_version = "1.3"

        # Validación de certificados de clientes
        verify_client_cert = yes

        # Verificar CN del cliente contra identidad EAP
        check_cert_cn = %{User-Name}

        # Configuración de cache de sesiones (mejora performance)
        cache {
            enable = yes
            lifetime = 24
            max_entries = 255
        }

        # Verificación de certificado
        verify {
            skip_if_ocsp_ok = no
        }

        # OCSP (Online Certificate Status Protocol)
        ocsp {
            enable = no
            override_cert_url = yes
            url = "http://127.0.0.1/ocsp/"
        }
    }

    #
    # EAP-TLS
    #
    tls {
        tls = tls-common

        # Incluir longitud en fragmentos
        include_length = yes

        # Verificar jerarquía de certificados
        auto_chain = yes
    }

    #
    # EAP-TTLS (Tunneled TLS)
    # Solo requiere certificado en el servidor
    #
    ttls {
        tls = tls-common
        default_eap_type = md5
        copy_request_to_tunnel = no
        use_tunneled_reply = no
        virtual_server = "inner-tunnel"
    }

    #
    # PEAP (Protected EAP)
    # Similar a TTLS, popular en Windows
    #
    peap {
        tls = tls-common
        default_eap_type = mschapv2
        copy_request_to_tunnel = no
        use_tunneled_reply = no
        virtual_server = "inner-tunnel"

        # Configuración específica de PEAP
        soh = no
        require_client_cert = no
    }

    #
    # EAP-MSCHAPv2 (usado dentro de túnel PEAP/TTLS)
    #
    mschapv2 {
        send_error = no
        identity = "FreeRADIUS"
    }
}
```

### 5.2 Verificar módulo EAP habilitado

```bash
# Verificar que existe symlink en mods-enabled
ls -la /etc/freeradius/3.0/mods-enabled/eap

# Si no existe, crear el symlink
sudo ln -s /etc/freeradius/3.0/mods-available/eap \
           /etc/freeradius/3.0/mods-enabled/eap
```

---

## 6. Configuración de Virtual Server

### 6.1 Site por Defecto `/etc/freeradius/3.0/sites-available/default`

```bash
sudo nano /etc/freeradius/3.0/sites-available/default
```

**Secciones importantes a verificar:**

```conf
server default {
    # Puerto de escucha (authentication)
    listen {
        type = auth
        ipaddr = *
        port = 1812
        limit {
            max_connections = 100
            lifetime = 0
            idle_timeout = 30
        }
    }

    # Puerto de escucha (accounting)
    listen {
        type = acct
        ipaddr = *
        port = 1813
        limit {
            max_connections = 100
            lifetime = 0
            idle_timeout = 30
        }
    }

    #
    # Sección AUTHORIZE: Determina método de autenticación
    #
    authorize {
        # Filtrar nombres de usuario
        filter_username

        # Preprocesamiento
        preprocess

        # IMPORTANTE: Habilitar EAP
        eap {
            ok = return
        }

        # Buscar usuario en archivo
        files

        # Expiración de contraseñas
        expiration

        # Login time restrictions
        logintime

        # PAP/CHAP authentication
        pap
    }

    #
    # Sección AUTHENTICATE: Realiza la autenticación
    #
    authenticate {
        # EAP authentication
        eap

        # PAP authentication
        Auth-Type PAP {
            pap
        }

        # MS-CHAP authentication
        Auth-Type MS-CHAP {
            mschap
        }
    }

    #
    # Sección POST-AUTH: Después de autenticación exitosa
    #
    post-auth {
        # Actualizar contadores
        update {
            &reply:Reply-Message += " - Autenticación exitosa"
        }

        # Logging
        exec

        # Remover contraseñas de los logs
        remove_reply_message_if_eap

        # Post-Auth-Type REJECT (cuando falla)
        Post-Auth-Type REJECT {
            attr_filter.access_reject

            # Log de rechazos
            update outer.session-state {
                &Module-Failure-Message := &request:Module-Failure-Message
            }
        }
    }

    #
    # Sección ACCOUNTING: Registro de conexiones
    #
    accounting {
        detail
        unix
        radutmp
        exec
        attr_filter.accounting_response
    }
}
```

### 6.2 Inner Tunnel (para PEAP/TTLS)

```bash
sudo nano /etc/freeradius/3.0/sites-available/inner-tunnel
```

Verificar que las secciones `authorize` y `authenticate` incluyan:

```conf
server inner-tunnel {
    authorize {
        filter_username
        eap {
            ok = return
        }
        files
        mschap
        pap
    }

    authenticate {
        eap
        mschap
        pap
    }

    post-auth {
        Post-Auth-Type REJECT {
            attr_filter.access_reject
        }
    }
}
```

---

## 7. Pruebas y Verificación

### 7.1 Probar configuración en modo debug

```bash
# Verificar sintaxis de configuración
sudo freeradius -CX

# Si hay errores, mostrarán aquí
# "Configuration appears to be OK" = éxito
```

### 7.2 Ejecutar FreeRADIUS en modo debug

```bash
# Detener servicio si está corriendo
sudo systemctl stop freeradius

# Ejecutar en foreground con debug
sudo freeradius -X
```

**Salida esperada (sin errores):**

```
...
Listening on auth address * port 1812 bound to server default
Listening on acct address * port 1813 bound to server default
Listening on auth address :: port 1812 bound to server default
Listening on acct address :: port 1813 bound to server default
Ready to process requests
```

### 7.3 Prueba local con radtest

Desde otra terminal (dejando FreeRADIUS en debug):

```bash
# Probar usuario "jperez"
radtest jperez "Empleado2024!" localhost 0 testing123

# Salida esperada:
# Sent Access-Request Id 123 from 0.0.0.0:56789 to 127.0.0.1:1812 length 77
# Received Access-Accept Id 123 from 127.0.0.1:1812 to 0.0.0.0:0 length 95
```

En la terminal de FreeRADIUS debug verás:

```
(0) Received Access-Request Id 123 from 127.0.0.1:56789 to 127.0.0.1:1812 length 77
(0)   User-Name = "jperez"
(0)   User-Password = "Empleado2024!"
...
(0) files: users: Matched entry jperez at line 12
(0)     [files] = ok
...
(0) Sent Access-Accept Id 123 from 127.0.0.1:1812 to 127.0.0.1:56789 length 95
```

### 7.4 Probar desde Access Point (simulación con eapol_test)

```bash
# Instalar herramienta eapol_test
sudo apt install libnl-3-dev libnl-genl-3-dev -y
wget http://w1.fi/cgit/hostap/plain/wpa_supplicant/eapol_test.c

# O usar desde repositorio
sudo apt install wpasupplicant -y
```

Crear archivo de configuración `test-eap-tls.conf`:

```conf
network={
    ssid="test"
    key_mgmt=WPA-EAP
    eap=TLS
    identity="jperez"
    ca_cert="/etc/freeradius/3.0/certs/ca.pem"
    client_cert="/etc/freeradius/3.0/certs/client.pem"
    private_key="/etc/freeradius/3.0/certs/client.key"
    private_key_passwd="whatever"
}
```

Ejecutar prueba:

```bash
eapol_test -c test-eap-tls.conf -a 127.0.0.1 -s testing123
```

---

## 8. Habilitación del Servicio

### 8.1 Iniciar y habilitar FreeRADIUS

Una vez verificado todo:

```bash
# Detener modo debug (Ctrl+C)

# Iniciar servicio
sudo systemctl start freeradius

# Habilitar inicio automático
sudo systemctl enable freeradius

# Verificar status
sudo systemctl status freeradius
```

### 8.2 Verificar puertos abiertos

```bash
# Verificar puertos RADIUS
sudo netstat -tulpn | grep radius

# O con ss
sudo ss -tulpn | grep 181
```

**Salida esperada:**

```
udp   0.0.0.0:1812   0.0.0.0:*   LISTEN   12345/freeradius
udp   0.0.0.0:1813   0.0.0.0:*   LISTEN   12345/freeradius
```

---

## 9. Firewall Configuration

### 9.1 Abrir puertos en firewall (UFW)

```bash
# Permitir tráfico RADIUS desde red de APs
sudo ufw allow from 192.168.1.0/24 to any port 1812 proto udp
sudo ufw allow from 192.168.1.0/24 to any port 1813 proto udp

# Verificar reglas
sudo ufw status
```

### 9.2 Iptables (alternativa)

```bash
# Permitir RADIUS authentication
sudo iptables -A INPUT -p udp --dport 1812 -s 192.168.1.0/24 -j ACCEPT

# Permitir RADIUS accounting
sudo iptables -A INPUT -p udp --dport 1813 -s 192.168.1.0/24 -j ACCEPT

# Guardar reglas
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

---

## 10. Logs y Monitoreo

### 10.1 Ubicación de logs

```bash
# Log principal de FreeRADIUS
tail -f /var/log/freeradius/radius.log

# Autenticaciones exitosas
tail -f /var/log/freeradius/radacct/*/auth-detail*

# Sesiones activas
tail -f /var/log/freeradius/radwtmp
```

### 10.2 Comandos útiles de diagnóstico

```bash
# Ver usuarios conectados actualmente
radwho

# Estadísticas del servidor
radmin -e "stats"

# Ver configuración cargada
radiusd -Cx | grep -A 10 "client "
```

---

## Ejercicios Prácticos

### Ejercicio 1: Agregar nuevo Access Point
Configurar un segundo AP con IP `192.168.1.21` y un nuevo shared secret.

### Ejercicio 2: Crear usuarios con diferentes VLANs
Crear 3 usuarios que se autentiquen en diferentes VLANs (10, 20, 30).

### Ejercicio 3: Configurar límite de sesión
Configurar un usuario que solo pueda estar conectado 2 horas (7200 segundos).

### Ejercicio 4: Debug de fallos de autenticación
Provocar un fallo de autenticación (contraseña incorrecta) y analizar los logs en modo debug.

---

## Checklist de Configuración

- [ ] FreeRADIUS instalado y versión verificada
- [ ] Clientes (APs) configurados en `clients.conf`
- [ ] Usuarios de prueba creados en archivo `users`
- [ ] Módulo EAP configurado y habilitado
- [ ] Virtual server `default` revisado
- [ ] Prueba con `radtest` exitosa
- [ ] Servicio iniciado y habilitado
- [ ] Puertos 1812/1813 UDP abiertos en firewall
- [ ] Logs accesibles y monitoreables

---

**Próximo paso**: Generación y configuración de certificados X.509 (archivo 02)
