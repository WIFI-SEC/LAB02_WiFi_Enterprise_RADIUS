# Trabajo Práctico: Configuración de WiFi Empresarial con RADIUS y Certificados

## Objetivos del Trabajo Práctico

Al finalizar este trabajo práctico, los alumnos serán capaces de:

1. Comprender la arquitectura de seguridad WiFi empresarial (WPA2/3-Enterprise)
2. Configurar un servidor RADIUS (FreeRADIUS) con autenticación basada en certificados
3. Implementar una infraestructura de PKI (Public Key Infrastructure) básica
4. Configurar Access Points con autenticación 802.1X
5. Analizar el proceso de autenticación mediante captura de paquetes
6. Aplicar mejores prácticas de seguridad para ambientes corporativos

---

## 1. Fundamentos Teóricos

### 1.1 WPA2/WPA3-Enterprise vs Personal

#### WPA2/3-Personal (PSK - Pre-Shared Key)
- **Uso**: Hogares, pequeñas oficinas
- **Autenticación**: Contraseña compartida (PSK)
- **Problemas**:
  - Misma clave para todos los usuarios
  - Difícil rotación de credenciales
  - Sin auditoría individual de usuarios
  - Vulnerable a ataques de diccionario offline

#### WPA2/3-Enterprise (802.1X)
- **Uso**: Ambientes corporativos, instituciones educativas
- **Autenticación**: Servidor RADIUS centralizado
- **Ventajas**:
  - Credenciales únicas por usuario
  - Gestión centralizada de accesos
  - Auditoría y trazabilidad completa
  - Soporte para múltiples métodos de autenticación (EAP)
  - Revocación granular de accesos

---

### 1.2 Componente: 802.1X Framework

El estándar **IEEE 802.1X** define un framework de control de acceso a nivel de puerto que utiliza tres componentes:

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│             │         │             │         │             │
│  Suplicante │◄───────►│ Autenticador│◄───────►│   Servidor  │
│  (Cliente)  │  EAPOL  │    (AP)     │ RADIUS  │   RADIUS    │
│             │         │             │         │             │
└─────────────┘         └─────────────┘         └─────────────┘
```

1. **Suplicante (Supplicant)**: Cliente WiFi (laptop, smartphone, tablet)
2. **Autenticador (Authenticator)**: Access Point que controla el acceso
3. **Servidor de Autenticación**: Servidor RADIUS que valida credenciales

---

### 1.3 Protocolo RADIUS

**RADIUS** (Remote Authentication Dial-In User Service) es un protocolo AAA:

- **Authentication**: ¿Quién eres?
- **Authorization**: ¿Qué puedes hacer?
- **Accounting**: ¿Qué hiciste?

#### Características:
- Puerto UDP 1812 (autenticación) y 1813 (accounting)
- Comunicación cifrada con "shared secret" entre AP y RADIUS
- Extensible mediante atributos (VSA - Vendor Specific Attributes)
- Soporta múltiples métodos EAP

---

### 1.4 EAP (Extensible Authentication Protocol)

**EAP** es un framework de autenticación que soporta múltiples métodos:

#### Métodos EAP comunes:

| Método | Descripción | Seguridad | Certificados |
|--------|-------------|-----------|--------------|
| **EAP-TLS** | Transport Layer Security | ✓✓✓ Muy alta | Servidor + Cliente |
| **EAP-TTLS** | Tunneled TLS | ✓✓ Alta | Solo Servidor |
| **PEAP** | Protected EAP | ✓✓ Alta | Solo Servidor |
| **EAP-MD5** | Message Digest 5 | ✗ Obsoleto | No |

#### EAP-TLS (Recomendado para este TP)
- Autenticación mutua basada en certificados X.509
- El servidor presenta certificado al cliente
- El cliente presenta certificado al servidor
- Máxima seguridad, no vulnerable a ataques de credenciales
- Requiere PKI (infraestructura de certificados)

---

### 1.5 Flujo de Autenticación 802.1X con EAP-TLS

```
Cliente (Suplicante)    Access Point       Servidor RADIUS
       │                     │                    │
       │──1. Association──►│                    │
       │                     │                    │
       │◄─2. EAP Request Identity              │
       │                     │                    │
       │──3. EAP Response (Identity)──►         │
       │                     │──4. RADIUS Access-Request──►│
       │                     │                    │
       │                     │◄─5. RADIUS Access-Challenge─│
       │◄─6. EAP-TLS Start──│                    │
       │                     │                    │
       │──7. TLS Client Hello──────────────────►│
       │◄─8. TLS Server Hello + Certificate────│
       │                     │                    │
       │──9. TLS Certificate + Key Exchange────►│
       │                     │                    │
       │◄─10. TLS Finished─────────────────────│
       │                     │                    │
       │                     │◄─11. RADIUS Access-Accept──│
       │◄─12. EAP Success───│                    │
       │                     │                    │
       │──13. 4-Way Handshake (PMK derivation)─►│
       │                     │                    │
       │◄─14. Acceso Concedido                  │
```

#### Explicación de las fases:

1. **Asociación inicial**: Cliente se conecta al AP (sin acceso a red)
2-3. **Identificación**: AP solicita identidad del usuario
4-5. **Inicio RADIUS**: AP reenvía petición al servidor RADIUS
6-10. **Túnel TLS**: Se establece canal cifrado y validación de certificados
11-12. **Aprobación**: RADIUS acepta y deriva claves de sesión
13-14. **Conexión**: Se genera PMK (Pairwise Master Key) y se otorga acceso

---

### 1.6 Certificados X.509 y PKI

#### Infraestructura de Clave Pública (PKI)

```
                    ┌─────────────────────┐
                    │   CA Root (Raíz)    │
                    │  Autoridad Certif.  │
                    └──────────┬──────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
          ┌─────────▼────────┐  ┌────────▼─────────┐
          │  Cert. Servidor  │  │  Cert. Clientes  │
          │     RADIUS       │  │   (usuarios)     │
          └──────────────────┘  └──────────────────┘
```

#### Componentes necesarios:

1. **Certificado CA (Certificate Authority)**
   - Auto-firmado (para este laboratorio)
   - Firma todos los demás certificados
   - Debe instalarse en clientes para validar servidor

2. **Certificado del Servidor RADIUS**
   - Firmado por la CA
   - Contiene FQDN del servidor RADIUS
   - Presentado a clientes durante autenticación

3. **Certificados de Cliente** (para EAP-TLS)
   - Uno por cada usuario/dispositivo
   - Firmados por la CA
   - Incluyen CN (Common Name) con identidad del usuario

---

## 2. Arquitectura del Laboratorio

### 2.1 Topología de Red

```
                         Internet
                            │
                    ┌───────▼────────┐
                    │   Router/FW    │
                    └───────┬────────┘
                            │
                ┌───────────┴───────────┐
                │    Switch Core         │
                └───┬────────────────┬───┘
                    │                │
         ┌──────────▼──────┐   ┌────▼──────────────┐
         │  Servidor RADIUS │   │   Access Point    │
         │   (FreeRADIUS)   │   │  (WPA2-Enterprise)│
         │  192.168.1.10    │   │   192.168.1.20    │
         └──────────────────┘   └────────┬──────────┘
                                         │
                                    (WiFi 802.1X)
                                         │
                               ┌─────────┴─────────┐
                               │                   │
                         ┌─────▼─────┐      ┌─────▼─────┐
                         │  Cliente1 │      │  Cliente2 │
                         │  (Laptop) │      │  (Mobile) │
                         └───────────┘      └───────────┘
```

### 2.2 Especificaciones del Laboratorio

#### Hardware/Software necesario:

| Componente | Especificaciones |
|------------|------------------|
| **Servidor RADIUS** | VM Ubuntu 22.04 LTS, 2GB RAM, 20GB disco |
| **Access Point** | Soporte 802.1X (Ubiquiti, TP-Link EAP, MikroTik) |
| **Clientes** | Windows 10/11, Ubuntu, Android |
| **Software** | FreeRADIUS 3.x, OpenSSL, Wireshark |

---

## 3. Consideraciones de Seguridad Empresarial

### 3.1 Segmentación de Red (VLANs)

```
┌─────────────────────────────────────────┐
│         Access Point (802.1X)           │
└────┬────────────────────────────────┬───┘
     │                                │
     │ VLAN 10                        │ VLAN 20
     │ (Empleados)                    │ (Invitados)
     │                                │
┌────▼─────────────┐         ┌────────▼─────────┐
│ Red Corporativa  │         │   Red Aislada    │
│ 192.168.10.0/24  │         │  192.168.20.0/24 │
│ Acceso a recursos│         │ Solo Internet     │
└──────────────────┘         └──────────────────┘
```

**RADIUS puede asignar VLANs dinámicamente** mediante atributos:
- `Tunnel-Type = VLAN`
- `Tunnel-Medium-Type = IEEE-802`
- `Tunnel-Private-Group-Id = 10` (VLAN ID)

### 3.2 Mejores Prácticas Empresariales

1. **Gestión de Certificados**
   - Usar CA privada (Windows CA Server, OpenSSL CA)
   - Certificados con validez limitada (1-2 años)
   - Proceso de renovación automatizado
   - Lista de revocación (CRL) o OCSP

2. **Políticas de Seguridad**
   - Forzar WPA3 donde sea posible (backward compatible con WPA2)
   - Usar EAP-TLS para máxima seguridad
   - Deshabilitar métodos EAP débiles (LEAP, MD5)
   - Implementar 802.11w (Protected Management Frames)

3. **Monitoreo y Auditoría**
   - Logs centralizados de RADIUS
   - Alertas de intentos fallidos de autenticación
   - Revisión periódica de dispositivos autorizados
   - Detección de Rogue APs

4. **Alta Disponibilidad**
   - Múltiples servidores RADIUS (primario/secundario)
   - APs configurados con failover RADIUS
   - Backup regular de configuraciones y certificados

---

## Estructura del Trabajo Práctico

Este TP está dividido en las siguientes secciones:

1. **Configuración del Servidor RADIUS** (archivo 01)
2. **Generación y Gestión de Certificados** (archivo 02)
3. **Configuración del Access Point** (archivo 03)
4. **Configuración de Clientes** (archivo 04)
5. **Captura y Análisis de Tráfico con Wireshark** (archivo 05)
6. **Mejores Prácticas y Troubleshooting** (archivo 06)
7. **Ejercicios Prácticos y Evaluación** (archivo 07)

---

## Referencias

- RFC 2865 - Remote Authentication Dial In User Service (RADIUS)
- RFC 3748 - Extensible Authentication Protocol (EAP)
- RFC 5216 - EAP-TLS Authentication Protocol
- IEEE 802.1X - Port-Based Network Access Control
- IEEE 802.11i - Wireless Network Security (WPA2)
- IEEE 802.11w - Protected Management Frames
