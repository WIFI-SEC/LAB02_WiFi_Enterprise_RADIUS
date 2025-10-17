# Trabajo Práctico: Configuración de WiFi Empresarial con RADIUS y Certificados

## Descripción General

Este trabajo práctico proporciona una guía completa para implementar, configurar y gestionar una infraestructura WiFi empresarial segura utilizando:

- **WPA2/WPA3-Enterprise** (802.1X)
- **Servidor RADIUS** (FreeRADIUS)
- **Autenticación EAP-TLS** con certificados X.509
- **Segmentación de red** con VLANs dinámicas
- **Análisis de tráfico** con Wireshark

Este material está diseñado para proporcionar comprensión profunda tanto de los fundamentos teóricos como de la implementación práctica de sistemas de autenticación WiFi empresarial.

---

## Objetivos de Aprendizaje

Al completar este trabajo práctico, los alumnos serán capaces de:

1. **Comprender la arquitectura de seguridad WiFi empresarial** incluyendo el estándar 802.1X, el protocolo RADIUS, y los métodos de autenticación EAP
2. **Configurar un servidor RADIUS centralizado** con FreeRADIUS, incluyendo políticas de autenticación, autorización y contabilidad
3. **Implementar una infraestructura PKI completa** generando certificados X.509, cadenas de confianza y gestionando el ciclo de vida de certificados
4. **Configurar Access Points para autenticación 802.1X** en múltiples fabricantes y plataformas
5. **Configurar clientes en múltiples plataformas** comprendiendo las particularidades de cada sistema operativo
6. **Capturar y analizar el tráfico de autenticación** a nivel de paquete para comprender el flujo completo del protocolo
7. **Implementar mejores prácticas de seguridad** aplicables a entornos de producción empresarial
8. **Diagnosticar y resolver problemas comunes** utilizando herramientas de análisis y debugging

---

## Estructura del Trabajo Práctico

### 📚 Archivo 00: Introducción Teórica
**`00_Introduccion_Teorica.md`**

**Contenido:**
- **Fundamentos de 802.1X**: Comprensión del estándar IEEE 802.1X que define el control de acceso basado en puerto para redes cableadas e inalámbricas
- **Protocolo RADIUS**: Análisis detallado del protocolo Remote Authentication Dial-In User Service (RFC 2865), su arquitectura cliente-servidor y flujo de mensajes
- **Métodos EAP**: Estudio de Extensible Authentication Protocol (RFC 3748) y sus variantes (EAP-TLS, PEAP, EAP-TTLS)
- **Diferencias WPA2-Personal vs Enterprise**: Comparación técnica entre autenticación por clave compartida (PSK) y autenticación empresarial centralizada
- **Arquitectura del laboratorio**: Diseño de la topología de red, componentes y flujo de comunicación
- **Fundamentos de criptografía**: Cifrado simétrico vs asimétrico, funciones hash, firmas digitales
- **Infraestructura PKI**: Autoridades certificadoras, cadenas de confianza, certificados X.509

**Prerequisitos:**
- Conocimientos de redes TCP/IP
- Comprensión de conceptos de seguridad básicos
- Familiaridad con Linux/Unix

---

### ⚙️ Archivo 01: Configuración del Servidor RADIUS
**`01_Configuracion_Servidor_RADIUS.md`**

**Contenido:**
- **Instalación de FreeRADIUS en Ubuntu**: Proceso detallado de instalación desde repositorios, incluyendo dependencias y verificación
- **Arquitectura de FreeRADIUS**: Comprensión de módulos, virtual servers, políticas y flujo de procesamiento de paquetes
- **Configuración de clientes RADIUS**: Definición de Access Points como clientes RADIUS con shared secrets y configuración de seguridad
- **Gestión de usuarios y atributos**: Configuración de bases de usuarios, atributos RADIUS estándar y vendor-specific attributes (VSA)
- **Configuración del módulo EAP**: Habilitación y configuración de EAP-TLS, EAP-TTLS, PEAP y otros métodos
- **Virtual servers y sites**: Configuración de sitios virtuales para diferentes contextos de autenticación
- **Políticas de autenticación**: Implementación de políticas condicionales basadas en atributos
- **Accounting y logging**: Configuración de contabilidad RADIUS para auditoría y análisis
- **Pruebas y verificación**: Uso de radtest, eapol_test y herramientas de debugging

**Prerequisitos:**
- VM o servidor con Ubuntu 22.04 LTS
- Conocimientos básicos de Linux y línea de comandos
- Acceso root/sudo
- Comprensión de conceptos de redes

**Conceptos teóricos cubiertos:**
- Protocolo RADIUS (RFC 2865, RFC 2866)
- Formato de paquetes RADIUS
- Atributos RADIUS y diccionarios
- Mecanismos de autenticación PAP, CHAP, MS-CHAP
- Shared secrets y seguridad del protocolo

---

### 🔐 Archivo 02: Gestión de Certificados PKI
**`02_Gestion_Certificados_PKI.md`**

**Contenido:**
- **Fundamentos de PKI**: Teoría de infraestructura de clave pública, componentes y roles
- **Certificados X.509**: Estructura de certificados X.509v3, campos obligatorios y extensiones
- **Creación de CA privada**: Generación de autoridad certificadora raíz y certificados intermedios
- **Generación de certificado del servidor RADIUS**: Creación de certificados para el servidor con campos apropiados (CN, SAN, Key Usage)
- **Generación de certificados de clientes**: Creación de certificados individuales para usuarios con Extended Key Usage apropiado
- **Formatos de certificados**: PEM, DER, PKCS#12, conversión entre formatos
- **Instalación en FreeRADIUS**: Configuración de certificados en el módulo EAP de FreeRADIUS
- **Cadenas de confianza**: Construcción y verificación de cadenas de certificados
- **Distribución segura**: Métodos seguros para distribuir certificados a usuarios
- **Renovación y revocación**: Implementación de CRL (Certificate Revocation Lists) y OCSP
- **Monitoreo de expiración**: Scripts para alertar sobre certificados próximos a expirar
- **Generación de parámetros Diffie-Hellman**: Creación de DH params para Perfect Forward Secrecy

**Prerequisitos:**
- Servidor RADIUS configurado (Archivo 01)
- Conocimientos de OpenSSL
- Comprensión de criptografía asimétrica
- Comprensión de PKI y cadenas de confianza

**Conceptos teóricos cubiertos:**
- Criptografía de clave pública (RSA, ECDSA)
- Funciones hash criptográficas (SHA-256, SHA-384)
- Firmas digitales y verificación
- Certificados X.509 estructura y extensiones
- Certificate Signing Requests (CSR)
- CRL vs OCSP para validación de certificados
- Perfect Forward Secrecy (PFS)

---

### 📡 Archivo 03: Configuración del Access Point
**`03_Configuracion_Access_Point.md`**

**Contenido:**
- **Fundamentos de 802.11**: Estándares WiFi, canales, frecuencias y modulación
- **Configuración por fabricante**:
  - **UniFi (Ubiquiti)**: Configuración mediante UniFi Controller
  - **TP-Link EAP (Omada)**: Configuración mediante Omada Controller o CLI
  - **MikroTik**: Configuración mediante RouterOS y Winbox
  - **Cisco WLC**: Configuración mediante Wireless LAN Controller
- **VLANs dinámicas**: Configuración de asignación dinámica de VLAN basada en atributos RADIUS
- **Protected Management Frames (PMF/802.11w)**: Implementación de PMF para protección contra ataques de desautenticación
- **Fast Roaming (802.11r)**: Configuración de FT para roaming rápido entre APs
- **Band Steering**: Configuración para balancear clientes entre 2.4GHz y 5GHz
- **Airtime Fairness**: Optimización de tiempo de aire entre clientes
- **RADIUS accounting**: Configuración de contabilidad para tracking de sesiones
- **Troubleshooting del AP**: Análisis de logs, debugging de autenticación

**Prerequisitos:**
- Access Point compatible con 802.1X
- Acceso administrativo al AP
- Servidor RADIUS funcionando y accesible
- Comprensión de VLANs y switching

**Conceptos teóricos cubiertos:**
- Estándar 802.1X y rol del autenticador
- EAPOL (EAP over LAN)
- 4-Way Handshake de WPA2
- PMF (Protected Management Frames) 802.11w
- Fast Roaming 802.11r y 802.11k
- Atributos RADIUS para VLANs (Tunnel-Type, Tunnel-Medium-Type, Tunnel-Private-Group-Id)

---

### 💻 Archivo 04: Configuración de Clientes
**`04_Configuracion_Clientes.md`**

**Contenido:**
- **Configuración detallada por sistema operativo**:
  - **Windows 10/11**: GPO, configuración manual, perfiles XML
  - **Linux (Ubuntu/Debian)**: wpa_supplicant, NetworkManager
  - **Android**: Configuración manual y perfiles de aprovisionamiento
  - **iOS/iPadOS**: Perfiles de configuración (.mobileconfig)
  - **macOS**: Keychain, profiles y configuración manual
- **Importación de certificados**: Procedimientos específicos por plataforma
- **Configuración de WiFi Enterprise**: Parámetros de seguridad, validación de servidor
- **Validación de certificados**: Configuración de validación de servidor y CA pinning
- **Troubleshooting por plataforma**: Logs específicos y herramientas de diagnóstico
- **Scripts de instalación automatizada**: Automatización de despliegue en múltiples clientes
- **Gestión de credenciales**: Almacenamiento seguro en keystores del sistema

**Prerequisitos:**
- Certificados de cliente generados y disponibles
- Dispositivos para pruebas en cada plataforma
- Red WiFi Enterprise activa y configurada
- Comprensión de cada sistema operativo

**Conceptos teóricos cubiertos:**
- Rol del suplicante (supplicant) en 802.1X
- wpa_supplicant en Linux
- Almacenamiento de certificados por plataforma
- Perfiles de configuración empresarial
- Políticas de grupo (GPO) en Windows

---

### 🔍 Archivo 05: Captura y Análisis con Wireshark
**`05_Captura_Analisis_Wireshark.md`**

**Contenido:**
- **Instalación y configuración de Wireshark**: Setup completo incluyendo privilegios y interfaces
- **Fundamentos de análisis de protocolos**: Comprensión de disección de paquetes y capas OSI
- **Captura de tráfico EAPOL (WiFi)**: Configuración de captura en modo monitor, canales y filtros
- **Captura de tráfico RADIUS (Ethernet)**: Captura entre AP y servidor RADIUS
- **Análisis detallado del flujo 802.1X**: Disección paquete por paquete del proceso completo
- **Identificación de cada fase de autenticación**:
  - Association Request/Response
  - EAPOL-Start
  - EAP Identity Request/Response
  - TLS Handshake (ClientHello, ServerHello, Certificate Exchange)
  - Certificate Verify
  - Finished messages
  - EAP-Success
  - 4-Way Handshake (PTK derivation)
  - Group Key Handshake
- **Análisis de paquetes RADIUS**: Access-Request, Access-Challenge, Access-Accept/Reject
- **Filtros de Wireshark útiles**: Display filters y capture filters específicos para 802.1X
- **Análisis de casos exitosos y fallidos**: Comparación de flujos correctos vs errores
- **Extracción de certificados desde capturas**: Obtención de certificados desde tráfico TLS
- **Análisis de tiempos**: Medición de latencias en cada fase
- **Ejercicios prácticos de análisis**: Casos reales para practicar

**Prerequisitos:**
- Wireshark instalado
- Autenticación WiFi funcionando
- Conocimientos de TCP/IP y modelo OSI
- Comprensión de TLS/SSL

**Conceptos teóricos cubiertos:**
- Protocolo EAPOL y sus tipos de mensajes
- TLS 1.2/1.3 Handshake detallado
- Formato de paquetes RADIUS (Code, Identifier, Length, Authenticator, Attributes)
- Message Authentication Code (MAC) en RADIUS
- 4-Way Handshake: derivación de PTK (Pairwise Transient Key)
- Group Key Handshake: distribución de GTK (Group Temporal Key)
- Cipher suites en TLS
- Perfect Forward Secrecy (PFS)

**⚠️ SECCIÓN CRÍTICA:** Esta es la parte más educativa del TP. Los alumnos verán exactamente cómo funciona el protocolo internamente, comprendiendo cada bit transmitido durante la autenticación.

---

### 🏢 Archivo 06: Mejores Prácticas Empresariales
**`06_Mejores_Practicas_Empresariales.md`**

**Contenido:**
- **Arquitectura de seguridad en capas**: Defensa en profundidad para WiFi empresarial
- **Diseño de red con VLANs**: Segmentación efectiva por roles, departamentos y niveles de confianza
- **Alta disponibilidad y redundancia**: Configuración de múltiples servidores RADIUS con failover
- **Load balancing**: Distribución de carga entre servidores RADIUS
- **Gestión de certificados en producción**: Automatización de renovación, alertas de expiración
- **Monitoreo y logging centralizado**: SIEM, syslog, integración con herramientas enterprise
- **Hardening del servidor RADIUS**: Reducción de superficie de ataque, permisos, firewall
- **Cumplimiento y auditoría**: PCI-DSS, ISO 27001, HIPAA requirements para WiFi
- **Disaster Recovery y Business Continuity**: Planes de respaldo y recuperación
- **Escalabilidad**: Diseño para crecimiento (1,000, 10,000, 100,000+ usuarios)
- **Integración con Active Directory**: LDAP backend para autenticación centralizada
- **Gestión de políticas**: Network Access Control (NAC) y políticas dinámicas
- **Separación de tráfico**: Guest networks, BYOD policies
- **Actualización y patching**: Gestión de actualizaciones de seguridad

**Aplicación:**
- Ambientes de producción empresarial
- Preparación para certificaciones (CWNA, CCNA Security, CISSP)
- Comprensión de operaciones reales en NOC/SOC

**Conceptos teóricos cubiertos:**
- RADIUS Proxy y Realm-based routing
- Fail-over y load balancing algorithms
- SIEM (Security Information and Event Management)
- NAC (Network Access Control)
- Zero Trust Architecture
- Defense in Depth

---

### 🛠️ Archivo 07: Ejercicios y Troubleshooting
**`07_Ejercicios_Troubleshooting.md`**

**Parte I: Ejercicios Prácticos Guiados**
- Implementación completa desde cero (end-to-end)
- Migración de WPA2-PSK a Enterprise en red existente
- Configuración de alta disponibilidad con múltiples servidores
- Segmentación avanzada con VLANs por grupos de usuarios
- Integración con Active Directory/LDAP

**Parte II: Casos de Troubleshooting**
- Cliente no puede conectarse: análisis sistemático de causas
- Intermitencia en conexiones: análisis de roaming y handoff
- VLAN no se asigna correctamente: debugging de atributos RADIUS
- Performance degradada: análisis de latencia y throughput

**Parte III: Escenarios de Seguridad**
- Detección de Rogue AP (Access Points no autorizados)
- Mitigación de ataques de desautenticación (deauth attacks)
- Protección contra credential stuffing y brute force
- Análisis de intentos de autenticación maliciosos

**Parte IV: Ejercicios de Evaluación**
- Auditoría completa de seguridad WiFi
- Disaster recovery drill (simulacro de recuperación)
- Caso de estudio empresarial completo con documentación

**Metodología:**
Cada ejercicio incluye:
- Descripción del problema o escenario
- Objetivos de aprendizaje específicos
- Pasos detallados de resolución
- Conceptos teóricos aplicados
- Verificación de solución
- Variantes avanzadas opcionales

---

## Ruta de Aprendizaje Recomendada

### 🎯 Track 1: Básico (Implementación Fundamental)

**Objetivo**: Implementar un laboratorio WiFi Enterprise funcional con comprensión de componentes básicos.

```
Fase 1: Fundamentos Teóricos
  ├─ Archivo 00: Introducción teórica
  │   • Comprender 802.1X, RADIUS y EAP
  │   • Estudiar diferencias WPA2-Personal vs Enterprise
  │   • Revisar arquitectura del sistema
  │
  └─ Estudio complementario:
      • RFC 2865 (RADIUS)
      • RFC 3748 (EAP)
      • IEEE 802.1X-2020 (introducción)

Fase 2: Servidor RADIUS
  ├─ Archivo 01: Configuración Servidor RADIUS
  │   • Instalar y configurar FreeRADIUS
  │   • Configurar clientes (APs)
  │   • Crear usuarios de prueba
  │   • Ejecutar radtest para verificación
  │
  └─ Ejercicios prácticos:
      • Configurar múltiples APs como clientes
      • Implementar usuarios con diferentes atributos
      • Analizar logs en modo debug

Fase 3: Infraestructura PKI
  ├─ Archivo 02: PKI y certificados
  │   • Crear CA privada
  │   • Generar certificado servidor RADIUS
  │   • Generar certificados de clientes
  │   • Configurar EAP-TLS en FreeRADIUS
  │
  └─ Ejercicios prácticos:
      • Verificar cadenas de certificados
      • Exportar certificados en diferentes formatos
      • Probar renovación de certificados

Fase 4: Access Point y Clientes
  ├─ Archivo 03: Configuración Access Point
  │   • Configurar AP con 802.1X
  │   • Habilitar VLANs dinámicas
  │   • Configurar PMF
  │
  ├─ Archivo 04: Configuración Clientes
  │   • Configurar al menos 2 sistemas operativos diferentes
  │   • Importar certificados
  │   • Conectar y verificar
  │
  └─ Ejercicios prácticos:
      • Conectar clientes Windows y Linux
      • Verificar asignación de VLANs
      • Documentar proceso

Fase 5: Análisis y Verificación
  ├─ Archivo 05: Wireshark
  │   • Capturar autenticación completa
  │   • Identificar cada fase del protocolo
  │   • Analizar paquetes RADIUS y EAPOL
  │
  └─ Ejercicios prácticos:
      • Captura exitosa completa
      • Captura de autenticación fallida
      • Identificar diferencias

Evaluación Track Básico:
  • Servidor RADIUS operacional
  • PKI funcional con CA + servidor + clientes
  • AP configurado y operacional
  • Al menos 2 clientes conectados en diferentes plataformas
  • Captura Wireshark con análisis de fases
```

### 🎯 Track 2: Intermedio (Configuración Empresarial)

**Objetivo**: Implementar configuraciones enterprise-grade con mejores prácticas.

```
Track Básico + Configuración Avanzada

Fase 1: Mejores Prácticas
  ├─ Archivo 06: Mejores prácticas empresariales
  │   • Implementar alta disponibilidad
  │   • Configurar monitoring
  │   • Hardening de servidor RADIUS
  │
  └─ Ejercicios prácticos:
      • Configurar 2 servidores RADIUS con failover
      • Implementar logging centralizado
      • Configurar alertas de certificados

Fase 2: Troubleshooting Avanzado
  ├─ Archivo 07: Ejercicios troubleshooting (Parte I y II)
  │   • Resolver casos complejos
  │   • Análisis de performance
  │   • Optimización de configuraciones
  │
  └─ Ejercicios prácticos:
      • Diagnosticar autenticaciones lentas
      • Resolver problemas de roaming
      • Optimizar configuración para alta densidad

Fase 3: Segmentación y VLANs
  • Implementar múltiples VLANs por rol de usuario
  • Configurar ACLs entre VLANs
  • Implementar guest network aislado
  • Configurar BYOD policies

Evaluación Track Intermedio:
  • Alta disponibilidad funcional
  • Monitoring y alertas configurados
  • Múltiples VLANs operacionales
  • Documentación de arquitectura completa
  • Resolución de al menos 5 casos de troubleshooting
```

### 🎯 Track 3: Avanzado (Integración y Producción)

**Objetivo**: Implementar solución production-ready con integración empresarial.

```
Track Intermedio + Integración Enterprise

Fase 1: Integración con Directorio
  • Integrar FreeRADIUS con Active Directory
  • Configurar LDAP backend
  • Implementar group-based policies
  • Sincronización de usuarios

Fase 2: Seguridad Avanzada
  ├─ Archivo 07: Ejercicios troubleshooting (Parte III)
  │   • Implementar IDS/IPS para WiFi
  │   • Configurar WIPS (Wireless Intrusion Prevention)
  │   • Detección de rogue APs
  │   • Análisis de amenazas
  │
  └─ Ejercicios prácticos:
      • Simular y detectar ataque de deauth
      • Implementar MAC filtering dinámico
      • Configurar rate limiting

Fase 3: Producción Simulada
  • Implementar en infraestructura simulada (1000+ usuarios)
  • Load testing y performance tuning
  • Disaster recovery drill completo
  • Documentación para operaciones

Fase 4: Auditoría y Cumplimiento
  ├─ Archivo 07: Ejercicios troubleshooting (Parte IV)
  │   • Auditoría completa de seguridad
  │   • Verificación de cumplimiento (PCI-DSS, ISO 27001)
  │   • Penetration testing
  │   • Remediación de hallazgos
  │
  └─ Ejercicios prácticos:
      • Ejecutar audit checklist completo
      • Documentar findings y recomendaciones
      • Implementar mejoras

Evaluación Track Avanzado:
  • Integración con AD/LDAP funcional
  • Sistema de detección de amenazas activo
  • Documentación completa para producción
  • Disaster recovery plan probado
  • Auditoría de seguridad completada con remediación
  • Caso de estudio empresarial documentado
```

---

## Requisitos de Hardware y Software

### Servidor RADIUS

| Componente | Especificación Mínima | Recomendado | Producción |
|------------|----------------------|-------------|------------|
| CPU | 2 vCPU | 4 vCPU | 8+ vCPU |
| RAM | 2 GB | 4 GB | 16+ GB |
| Disco | 20 GB | 40 GB | 100+ GB SSD |
| SO | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| Red | 1 NIC Gigabit | 1 NIC Gigabit | 2+ NIC Gigabit (bonding) |

**Notas sobre sizing:**
- Para 100-500 usuarios: especificación mínima suficiente
- Para 500-2000 usuarios: especificación recomendada
- Para 2000+ usuarios: especificación producción + considerar load balancing

### Access Point

**Requisitos mínimos:**
- Soporte para WPA2-Enterprise o WPA3-Enterprise
- Soporte para 802.1X (autenticador)
- Soporte para VLANs (opcional pero recomendado)
- Soporte para RADIUS accounting (recomendado)

**Fabricantes compatibles probados:**
- **Ubiquiti UniFi** (cualquier modelo UAP): Excelente relación precio/rendimiento
- **TP-Link EAP series** (EAP225, EAP245, EAP660): Buena opción económica
- **MikroTik** (con soporte WiFi): Muy configurable, curva de aprendizaje más alta
- **Cisco Aironet / Meraki**: Grado empresarial, más costoso
- **Aruba AP**: Grado empresarial, excelente para grandes despliegues
- **Ruckus**: Grado empresarial, tecnología BeamFlex

### Clientes de prueba

**Recomendado tener al menos 3 plataformas diferentes para testing:**

- **Windows 10/11** (laptop o VM): Prueba de GPO y perfiles empresariales
- **Linux Ubuntu/Debian** (laptop o VM): Prueba de wpa_supplicant
- **Android 8+** (smartphone/tablet): Prueba de mobile devices
- **iOS 12+ / macOS 10.14+** (opcional): Prueba de ecosistema Apple

### Software adicional requerido

| Herramienta | Versión Mínima | Propósito |
|-------------|----------------|-----------|
| **Wireshark** | 3.0+ | Captura y análisis de tráfico |
| **OpenSSL** | 1.1.1+ | Generación y gestión de certificados |
| **SSH client** | Cualquiera | Acceso remoto al servidor (PuTTY, OpenSSH) |
| **Editor de texto** | Cualquiera | Edición de configuraciones (nano, vim, VS Code) |
| **tcpdump** | Incluido en Linux | Captura de tráfico en línea de comandos |
| **radtest** | Incluido con FreeRADIUS | Testing de autenticación RADIUS |
| **eapol_test** | Compilar desde wpa_supplicant | Testing de EAP-TLS |

---

## Instalación Rápida

### Opción 1: Paso a paso (recomendado para aprendizaje profundo)

Seguir los archivos en orden desde el 00 hasta el 07. Este enfoque asegura comprensión completa de cada componente.

**Ventajas:**
- Comprensión profunda de cada componente
- Capacidad de troubleshooting mejorada
- Aprendizaje de fundamentos teóricos

**Proceso:**
1. Leer Archivo 00 (fundamentos teóricos)
2. Implementar Archivo 01 (servidor RADIUS)
3. Implementar Archivo 02 (PKI y certificados)
4. Implementar Archivo 03 (Access Point)
5. Implementar Archivo 04 (clientes)
6. Realizar Archivo 05 (análisis Wireshark)
7. Estudiar Archivo 06 (mejores prácticas)
8. Practicar Archivo 07 (ejercicios y troubleshooting)

### Opción 2: Scripts de instalación automatizada (para laboratorio rápido)

Para un laboratorio de prueba funcional de manera rápida:

```bash
# Clonar el repositorio
git clone https://github.com/WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS.git
cd LAB02_WiFi_Enterprise_RADIUS/scripts

# Linux (Ubuntu/Debian) - instalación nativa
sudo ./install-linux.sh

# macOS (Apple Silicon) - con virtualización UTM
./install-macos.sh

# Windows - con WSL2
# Abrir PowerShell como Administrador
.\install-windows.ps1
```

**Ventajas:**
- Laboratorio funcional en minutos
- Todas las dependencias instaladas automáticamente
- Configuración pre-testeada

**Desventajas:**
- Menos comprensión de detalles de configuración
- Recomendado como complemento, no reemplazo del estudio teórico

**Incluye:**
- FreeRADIUS instalado y configurado
- PKI completa (CA + servidor + 4 clientes)
- 5 usuarios pre-configurados con VLANs
- Wireshark y herramientas de análisis
- Documentación generada

---

## Comandos de Inicio Rápido

### Iniciar FreeRADIUS en modo debug

El modo debug (`-X`) es la herramienta más importante para comprender y troubleshoot RADIUS:

```bash
# Detener servicio para poder ejecutar en modo debug
sudo systemctl stop freeradius

# Iniciar en modo debug (foreground, verbose)
sudo freeradius -X
```

**Qué muestra:**
- Carga de módulos y configuraciones
- Procesamiento de cada paquete RADIUS recibido
- Evaluación de políticas y decisiones
- Atributos enviados y recibidos
- Errores detallados con stack trace

### Probar autenticación local

Prueba básica de autenticación contra localhost:

```bash
radtest <usuario> <password> <servidor> <puerto> <secret>

# Ejemplo:
radtest testuser testpass localhost 0 testing123
```

**Parámetros:**
- `usuario`: nombre de usuario configurado en FreeRADIUS
- `password`: contraseña del usuario
- `servidor`: IP o hostname del servidor RADIUS
- `puerto`: 0 significa usar puerto default (1812)
- `secret`: shared secret configurado para este cliente

**Salida esperada:**
- `Access-Accept`: autenticación exitosa
- `Access-Reject`: credenciales incorrectas o usuario no existe
- `no response`: servidor no responde (firewall, servicio caído)

### Capturar tráfico RADIUS

Captura de tráfico entre AP y servidor RADIUS:

```bash
# Captura simple en pantalla
sudo tcpdump -i eth0 port 1812 or port 1813 -vv

# Captura guardada en archivo para análisis posterior
sudo tcpdump -i eth0 port 1812 or port 1813 -w radius_capture.pcap

# Captura con timestamp y hex dump
sudo tcpdump -i eth0 port 1812 or port 1813 -tttt -X
```

**Puertos:**
- `1812`: Authentication (Access-Request, Access-Accept, Access-Reject)
- `1813`: Accounting (Accounting-Request, Accounting-Response)

### Ver logs en tiempo real

Monitoreo de logs para troubleshooting:

```bash
# Logs principales de FreeRADIUS
sudo tail -f /var/log/freeradius/radius.log

# Todos los logs de FreeRADIUS
sudo tail -f /var/log/freeradius/*.log

# Logs del sistema (journald)
sudo journalctl -u freeradius -f

# Filtrar solo errores
sudo journalctl -u freeradius -p err -f
```

### Verificar certificado

Inspección detallada de certificados X.509:

```bash
# Ver contenido completo del certificado
openssl x509 -in certificado.pem -noout -text

# Ver solo fechas de validez
openssl x509 -in certificado.pem -noout -dates

# Ver solo subject y issuer
openssl x509 -in certificado.pem -noout -subject -issuer

# Verificar certificado contra CA
openssl verify -CAfile ca.pem certificado.pem

# Ver certificado en formato PKCS#12
openssl pkcs12 -info -in certificado.p12
```

### Verificar configuración de FreeRADIUS

Chequeo de sintaxis sin iniciar el servidor:

```bash
# Verificar configuración completa
sudo freeradius -CX

# Verificar y mostrar configuración
sudo freeradius -Cx

# Test de configuración detallado
sudo freeradius -XC
```

---

## Evaluación y Criterios de Aprobación

### Componentes evaluables

| Componente | Peso | Criterio de Éxito | Verificación |
|------------|------|-------------------|--------------|
| **Servidor RADIUS funcionando** | 20% | Autenticación exitosa con radtest<br>Logs sin errores<br>Servicio estable | radtest exitoso<br>freeradius -X sin errores<br>systemctl status freeradius |
| **Certificados PKI** | 15% | CA válida<br>Certificado servidor<br>Al menos 2 certificados cliente<br>Cadena de confianza verificada | openssl verify<br>Certificados instalados<br>EAP-TLS funcional |
| **Access Point configurado** | 15% | 802.1X habilitado<br>Comunicación con RADIUS exitosa<br>VLANs configuradas | Logs de AP<br>Autenticación desde cliente<br>Captura RADIUS |
| **Clientes conectados** | 15% | Al menos 2 plataformas diferentes<br>Certificados instalados<br>Conexión exitosa | Windows + Linux mínimo<br>ifconfig/ipconfig<br>Ping a gateway |
| **Captura Wireshark** | 20% | Captura completa de autenticación<br>Identificación de fases<br>Análisis de atributos RADIUS | .pcap entregado<br>Anotaciones de fases<br>Display filters aplicados |
| **Documentación** | 10% | Arquitectura documentada<br>Diagrama de red<br>Configuraciones explicadas | Documento técnico<br>Diagramas claros<br>Explicación de decisiones |
| **Troubleshooting** | 5% | Resolución de al menos 1 caso<br>Metodología aplicada<br>Documentación de solución | Caso documentado<br>Pasos de resolución<br>Causa raíz identificada |

**Total: 100%**

### Entregables requeridos

#### 1. Informe técnico (PDF)

**Contenido mínimo:**
- **Portada**: Título, autor, fecha, institución
- **Índice**: Con números de página
- **Resumen ejecutivo**: Descripción general del trabajo realizado
- **Arquitectura implementada**:
  - Diagrama de topología de red
  - Direccionamiento IP
  - VLANs configuradas
  - Flujo de autenticación
- **Configuraciones aplicadas**:
  - Configuración relevante de FreeRADIUS (con explicación)
  - Configuración de Access Point
  - Configuración de al menos 2 clientes
- **Certificados y PKI**:
  - Estructura de CA
  - Certificados generados
  - Políticas de renovación
- **Capturas de pantalla**:
  - FreeRADIUS en modo debug durante autenticación exitosa
  - Cliente conectado con IP asignada
  - Wireshark mostrando flujo de autenticación
  - Verificación de certificados
- **Análisis de Wireshark**:
  - Descripción de cada fase identificada
  - Tiempos de cada etapa
  - Atributos RADIUS relevantes
  - Comparación éxito vs fallo
- **Problemas encontrados y soluciones**:
  - Al menos 3 problemas documentados
  - Causa raíz de cada problema
  - Solución aplicada
  - Lecciones aprendidas
- **Conclusiones**:
  - Objetivos cumplidos
  - Conocimientos adquiridos
  - Aplicabilidad en producción
- **Referencias bibliográficas**:
  - RFCs consultadas
  - Documentación utilizada
  - Recursos online

#### 2. Archivos de configuración

**Estructura de entrega:**
```
configuraciones/
├── freeradius/
│   ├── radiusd.conf
│   ├── clients.conf
│   ├── users
│   ├── mods-enabled/eap
│   └── sites-enabled/default
├── certificados/
│   ├── ca/ca.pem
│   ├── server/server.pem
│   └── clients/
│       ├── usuario1.p12
│       └── usuario2.p12
├── access-point/
│   └── configuracion-export.txt
├── clientes/
│   ├── windows/perfil.xml
│   ├── linux/wpa_supplicant.conf
│   └── android/documentacion.txt
└── scripts/
    └── cualquier script creado
```

#### 3. Capturas de tráfico

**Archivos requeridos:**
- `autenticacion_exitosa.pcap`: Captura completa de autenticación exitosa
- `autenticacion_fallida.pcap`: Captura de intento fallido (credenciales incorrectas)
- `analisis_wireshark.pdf`: PDF con capturas de pantalla de Wireshark mostrando:
  - Paquetes EAPOL identificados
  - Paquetes RADIUS con atributos visibles
  - Handshake TLS
  - 4-Way Handshake
  - Aplicación de display filters relevantes

#### 4. Demostración práctica (opcional pero valorada)

**Si se realiza demostración en vivo:**
- Mostrar funcionamiento del sistema completo
- Explicar flujo de autenticación mientras ocurre
- Resolver un problema en tiempo real
- Responder preguntas técnicas del evaluador

**Valoración adicional: +10% sobre nota final**

---

## Troubleshooting Común

### Problema: "RADIUS server not responding"

**Síntomas:**
- Cliente no puede conectarse
- AP reporta timeout
- No hay respuesta de servidor RADIUS

**Diagnóstico:**

```bash
# 1. Verificar que servicio está activo
sudo systemctl status freeradius

# 2. Verificar que está escuchando en puerto correcto
sudo netstat -ulnp | grep 1812

# 3. Verificar conectividad desde AP
ping <IP-servidor-RADIUS>

# 4. Verificar firewall no está bloqueando
sudo ufw status
sudo iptables -L -n | grep 1812

# 5. Ver logs del servidor
sudo tail -100 /var/log/freeradius/radius.log
```

**Soluciones comunes:**

```bash
# Servicio no está corriendo - iniciar
sudo systemctl start freeradius
sudo systemctl enable freeradius

# Firewall bloqueando - abrir puertos
sudo ufw allow from 192.168.1.0/24 to any port 1812 proto udp
sudo ufw allow from 192.168.1.0/24 to any port 1813 proto udp

# Configuración incorrecta - verificar y reiniciar
sudo freeradius -CX
sudo systemctl restart freeradius
```

### Problema: "Unknown CA" en cliente

**Síntomas:**
- Cliente rechaza conexión
- Error de certificado no confiable
- "Unable to verify server certificate"

**Diagnóstico:**

```bash
# Verificar certificado del servidor
openssl x509 -in /etc/freeradius/3.0/certs/server.pem -noout -text

# Verificar CA
openssl x509 -in /etc/freeradius/3.0/certs/ca.pem -noout -text

# Verificar cadena
openssl verify -CAfile /etc/freeradius/3.0/certs/ca.pem \
               /etc/freeradius/3.0/certs/server.pem
```

**Soluciones por plataforma:**

**Windows:**
```
1. Abrir certmgr.msc
2. Trusted Root Certification Authorities > Certificates
3. Importar ca.pem
4. Verificar que aparece en la lista
```

**Linux:**
```bash
# Copiar CA al directorio de certificados del sistema
sudo cp ca.pem /usr/local/share/ca-certificates/radius-ca.crt
sudo update-ca-certificates

# En wpa_supplicant.conf verificar ruta correcta
ca_cert="/etc/ssl/certs/radius-ca.pem"
```

**Android:**
```
Settings > Security > Install certificates > CA certificate
Seleccionar archivo ca.pem
```

### Problema: "Certificate expired"

**Síntomas:**
- Autenticación falla con error de certificado
- Logs muestran "certificate has expired"

**Diagnóstico:**

```bash
# Verificar validez de todos los certificados
openssl x509 -in ca.pem -noout -dates
openssl x509 -in server.pem -noout -dates
openssl x509 -in client.pem -noout -dates

# Script para verificar todos los certificados
for cert in /etc/freeradius/3.0/certs/*.pem; do
    echo "Verificando: $cert"
    openssl x509 -in "$cert" -noout -dates
    echo "---"
done
```

**Solución - Renovar certificado:**

```bash
# Ir al directorio de certificados
cd /etc/ssl/radius-certs

# Generar nuevo certificado de servidor
openssl req -new -key server.key -out server.csr
openssl ca -config ca.cnf -in server.csr -out server.pem -days 365

# Copiar a FreeRADIUS
sudo cp server.pem /etc/freeradius/3.0/certs/
sudo systemctl restart freeradius

# Para clientes, regenerar certificados individuales
./generate-client-cert.sh usuario
```

### Problema: "Access-Reject" constante

**Síntomas:**
- Autenticación siempre falla
- Logs muestran Access-Reject
- Usuario existe en configuración

**Diagnóstico:**

```bash
# Ejecutar FreeRADIUS en modo debug
sudo systemctl stop freeradius
sudo freeradius -X

# En otra terminal, probar autenticación
radtest usuario password localhost 0 testing123

# Analizar output de freeradius -X para ver causa exacta
```

**Causas comunes y soluciones:**

1. **Password incorrecto**:
   - Verificar en `/etc/freeradius/3.0/users`
   - Verificar no hay caracteres especiales mal escapados

2. **Usuario no existe**:
```bash
# Verificar usuario está en archivo users
grep "^usuario" /etc/freeradius/3.0/users
```

3. **EAP method no soportado**:
```bash
# Verificar módulo EAP está habilitado
ls -la /etc/freeradius/3.0/mods-enabled/eap

# Verificar configuración EAP
sudo nano /etc/freeradius/3.0/mods-enabled/eap
```

4. **Certificado de cliente no válido**:
```bash
# Verificar certificado del cliente
openssl verify -CAfile ca.pem client.pem

# Verificar el certificado no está revocado si se usa CRL
```

### Problema: "VLAN no se asigna"

**Síntomas:**
- Cliente se conecta
- No obtiene IP de VLAN esperada
- Está en VLAN default/nativa

**Diagnóstico:**

```bash
# Verificar atributos RADIUS en modo debug
sudo freeradius -X
# Buscar en output:
#   Tunnel-Type
#   Tunnel-Medium-Type
#   Tunnel-Private-Group-Id

# Capturar RADIUS Access-Accept con tcpdump
sudo tcpdump -i eth0 port 1812 -vv -X
```

**Solución:**

```bash
# Verificar configuración de usuario incluye atributos de VLAN
sudo nano /etc/freeradius/3.0/users

# Debe tener:
usuario Cleartext-Password := "password"
    Tunnel-Type = VLAN,
    Tunnel-Medium-Type = IEEE-802,
    Tunnel-Private-Group-Id = "10"

# Verificar AP está configurado para VLANs dinámicas
# Verificar trunking está habilitado en puerto del switch
```

### Problema: "Performance degradada / autenticación lenta"

**Síntomas:**
- Autenticación tarda mucho tiempo
- Timeouts ocasionales
- Sistema lento en general

**Diagnóstico:**

```bash
# Verificar carga del servidor
top
htop

# Verificar logs de FreeRADIUS por errores de timeout
sudo grep timeout /var/log/freeradius/radius.log

# Verificar latencia de red
ping <IP-AP>
mtr <IP-AP>

# Medir tiempo de autenticación
time radtest usuario password localhost 0 testing123
```

**Soluciones:**

1. **Deshabilitar resolución DNS inversa:**
```bash
# En clients.conf
client 192.168.1.10 {
    ipaddr = 192.168.1.10
    secret = testing123
    # Agregar:
    nas_type = other
    require_message_authenticator = no
}

# En radiusd.conf
hostname_lookups = no
```

2. **Optimizar base de datos:**
```bash
# Si se usa SQL backend
# Agregar índices
# Optimizar queries
```

3. **Aumentar recursos:**
```bash
# Si es VM, agregar más CPU/RAM
# Verificar I/O de disco no es bottleneck
iostat -x 1
```

---

## Recursos Adicionales

### Documentación oficial estándar

#### RFCs (Request for Comments)

Documentos estándar que definen los protocolos:

- **[RFC 2865 - RADIUS](https://tools.ietf.org/html/rfc2865)**: Especificación base del protocolo RADIUS, formato de paquetes, atributos estándar
- **[RFC 2866 - RADIUS Accounting](https://tools.ietf.org/html/rfc2866)**: Extensión para accounting (contabilidad)
- **[RFC 3748 - EAP](https://tools.ietf.org/html/rfc3748)**: Extensible Authentication Protocol, framework base
- **[RFC 5216 - EAP-TLS](https://tools.ietf.org/html/rfc5216)**: EAP con TLS, método más seguro
- **[RFC 2869 - RADIUS Extensions](https://tools.ietf.org/html/rfc2869)**: Extensiones incluyendo atributos de túnel (VLANs)
- **[RFC 3579 - RADIUS Support for EAP](https://tools.ietf.org/html/rfc3579)**: Cómo RADIUS transporta EAP

#### Estándares IEEE

- **[IEEE 802.1X-2020](https://standards.ieee.org/standard/802_1X-2020.html)**: Port-Based Network Access Control
- **[IEEE 802.11-2020](https://standards.ieee.org/standard/802_11-2020.html)**: Wireless LAN Medium Access Control (MAC) and Physical Layer (PHY)
- **[IEEE 802.11i](https://standards.ieee.org/standard/802_11i-2004.html)**: Security enhancements (WPA2)
- **[IEEE 802.11w](https://standards.ieee.org/standard/802_11w-2009.html)**: Protected Management Frames
- **[IEEE 802.11r](https://standards.ieee.org/standard/802_11r-2008.html)**: Fast BSS Transition (Fast Roaming)

### Documentación de FreeRADIUS

- **[FreeRADIUS Wiki](https://wiki.freeradius.org/)**: Documentación oficial, guías, ejemplos
- **[FreeRADIUS Documentation](https://freeradius.org/documentation/)**: Docs oficiales por versión
- **[FreeRADIUS Technical Guide](https://networkradius.com/doc/)**: Guía técnica detallada

### Herramientas y Software

#### Análisis de Red
- **[Wireshark](https://www.wireshark.org/)**: Analizador de protocolos de red #1
- **[tcpdump](https://www.tcpdump.org/)**: Captura de tráfico en línea de comandos
- **[tshark](https://www.wireshark.org/docs/man-pages/tshark.html)**: Wireshark CLI

#### WiFi y Seguridad
- **[Aircrack-ng](https://www.aircrack-ng.org/)**: Suite de seguridad WiFi para testing
- **[wpa_supplicant](https://w1.fi/wpa_supplicant/)**: Supplicant 802.1X para Linux
- **[hostapd](https://w1.fi/hostapd/)**: Access Point software para Linux

#### PKI y Certificados
- **[OpenSSL](https://www.openssl.org/)**: Toolkit criptográfico
- **[Easy-RSA](https://github.com/OpenVPN/easy-rsa)**: Utilidad para gestión de PKI simplificada
- **[XCA](https://hohnstaedt.de/xca/)**: GUI para gestión de certificados

### Comunidad y Soporte

#### Listas de correo y foros
- **[FreeRADIUS Mailing List](https://freeradius.org/support/)**: Lista oficial, muy activa
- **[FreeRADIUS Users List Archive](https://lists.freeradius.org/pipermail/freeradius-users/)**: Archivo de discusiones

#### Q&A y Discusiones
- **[Stack Overflow - RADIUS tag](https://stackoverflow.com/questions/tagged/radius)**: Preguntas técnicas
- **[Server Fault - RADIUS tag](https://serverfault.com/questions/tagged/radius)**: Enfoque sysadmin
- **[Reddit r/networking](https://www.reddit.com/r/networking/)**: Discusiones generales de networking
- **[Reddit r/wireless](https://www.reddit.com/r/wireless/)**: Específico para WiFi

### Libros Recomendados

- **"RADIUS" by Jonathan Hassell** (O'Reilly): Guía completa de RADIUS
- **"802.11 Wireless Networks: The Definitive Guide" by Matthew Gast**: WiFi en profundidad
- **"Certified Wireless Network Professional Official Study Guide" (CWNP)**: Preparación para certificación
- **"Network Security Assessment" by Chris McNab**: Incluye testing de 802.1X

### Cursos y Certificaciones

#### Certificaciones WiFi
- **CWNA (Certified Wireless Network Administrator)**: Fundamentos WiFi
- **CWSP (Certified Wireless Security Professional)**: Seguridad WiFi avanzada
- **CWDP (Certified Wireless Design Professional)**: Diseño de redes WiFi

#### Certificaciones de Seguridad
- **CISSP**: Certified Information Systems Security Professional
- **Security+**: CompTIA Security+ (incluye wireless security)
- **CCNA Security**: Cisco Certified Network Associate Security

### Blogs y Sitios Técnicos

- **[Network RADIUS Blog](https://networkradius.com/blog/)**: Artículos técnicos de FreeRADIUS
- **[Revolution WiFi](https://www.revolutionwifi.net/)**: Blog sobre WiFi enterprise
- **[WirelessLAN Professionals](https://www.wlanpros.com/resources/)**: Recursos WiFi

---

## Metodología de Trabajo

### Enfoque Recomendado

Este trabajo práctico está diseñado para seguir una metodología de aprendizaje práctica y progresiva:

1. **Teoría primero**: Comprender conceptos antes de implementar
2. **Implementación incremental**: Construir componente por componente
3. **Validación continua**: Probar cada paso antes de avanzar
4. **Análisis profundo**: Usar Wireshark para ver qué ocurre internamente
5. **Troubleshooting real**: Aprender de errores y problemas encontrados
6. **Documentación paralela**: Documentar mientras se implementa

### Ciclo de Trabajo por Componente

Para cada componente (RADIUS, PKI, AP, Clientes):

```
1. ESTUDIAR
   ├─ Leer teoría del archivo correspondiente
   ├─ Revisar RFCs relevantes
   └─ Comprender arquitectura y flujo

2. PLANIFICAR
   ├─ Diseñar configuración específica
   ├─ Identificar requisitos
   └─ Preparar entorno

3. IMPLEMENTAR
   ├─ Seguir pasos documentados
   ├─ Adaptar a entorno específico
   └─ Tomar notas de cambios

4. VALIDAR
   ├─ Ejecutar pruebas funcionales
   ├─ Verificar con herramientas (radtest, ping, etc.)
   └─ Capturar tráfico con Wireshark

5. ANALIZAR
   ├─ Revisar logs
   ├─ Analizar capturas de tráfico
   └─ Comprender qué ocurrió

6. DOCUMENTAR
   ├─ Capturar pantalla de configuraciones
   ├─ Documentar problemas y soluciones
   └─ Actualizar diagrama de arquitectura

7. ITERAR
   └─ Si algo no funciona, volver a paso relevante
```

### Tips para el Éxito

1. **No saltear la teoría**: La comprensión teórica es fundamental para troubleshooting efectivo

2. **Usar modo debug siempre**: `freeradius -X` es tu mejor amigo

3. **Capturar todo con Wireshark**: Ver el tráfico real ayuda enormemente a comprender

4. **Documentar mientras trabajas**: No dejar la documentación para el final

5. **Hacer backups**: Antes de cambios importantes:
   ```bash
   sudo cp -r /etc/freeradius/3.0 /etc/freeradius/3.0.backup-$(date +%Y%m%d)
   ```

6. **Verificar paso a paso**: No avanzar si algo no funciona

7. **Leer logs completos**: No asumir, verificar en logs qué está pasando

8. **Preguntar cuando sea necesario**: Usar recursos de comunidad

---

## Seguridad y Consideraciones Éticas

### Uso Apropiado del Material

Este material es para **fines educativos** en entornos controlados:

**✅ Uso Permitido:**
- Laboratorios educativos propios
- Redes de prueba con autorización
- Ambiente de práctica personal
- Preparación para certificaciones
- Investigación académica

**❌ Uso NO Permitido:**
- Pruebas en redes ajenas sin autorización
- Ataques a redes de producción
- Interceptación no autorizada de tráfico
- Uso malicioso de técnicas aprendidas

### Consideraciones de Seguridad

**Para el laboratorio:**
- Usar contraseñas fuertes (aunque sea laboratorio)
- No exponer servidor RADIUS a Internet
- Cambiar shared secrets default
- Usar certificados únicos (no reusar)

**Para producción:**
Este laboratorio NO está listo para producción sin:
- Cambiar todas las contraseñas
- Generar certificados con CA privada segura
- Implementar políticas de seguridad empresarial
- Configurar firewall y segmentación apropiada
- Implementar monitoring y alertas
- Seguir compliance requirements (PCI-DSS, etc.)

### Privacidad y Datos

- RADIUS contiene información sensible (credenciales, ubicaciones)
- Logs deben protegerse adecuadamente
- Cumplir con regulaciones locales (GDPR, etc.)
- No compartir capturas Wireshark con datos reales sin sanitizar

---

## Licencia y Uso

Este material educativo es proporcionado con fines didácticos para la enseñanza de seguridad WiFi empresarial.

**Uso permitido:**
- Educación y entrenamiento en instituciones educativas
- Laboratorios de prueba y práctica
- Aprendizaje personal y profesional
- Preparación para certificaciones

**Atribución:**
Al utilizar este material, se agradece mencionar la fuente original.

**Restricciones:**
- Las técnicas de ataque demostradas (deauth, etc.) solo deben usarse en redes propias con autorización
- No realizar pruebas de penetración en redes de producción sin autorización explícita y escrita
- Respetar normativas de seguridad, privacidad y compliance

---

## Changelog y Versiones

### Versión 1.0 (Octubre 2024)

**Contenido Inicial:**
- ✅ Documentación completa en 8 archivos principales
- ✅ Ejercicios prácticos guiados
- ✅ Casos de troubleshooting reales
- ✅ Guías para múltiples plataformas (Windows, Linux, Android, iOS, macOS)
- ✅ Análisis detallado con Wireshark
- ✅ Mejores prácticas empresariales
- ✅ Scripts de instalación automatizada (Linux, macOS, Windows)
- ✅ 3 tracks de aprendizaje (Básico, Intermedio, Avanzado)

**Cobertura:**
- 📄 360 KB de documentación
- 🔧 3 scripts de instalación multiplataforma
- 📊 100+ filtros de Wireshark documentados
- 🏢 4 fabricantes de AP con guías de configuración
- 💻 6 sistemas operativos cliente documentados
- 🔐 Infraestructura PKI completa

---

## Contacto y Contribuciones

### Para Estudiantes

**Consultas sobre el material:**
- Revisar primero la sección de Troubleshooting
- Consultar en foros de la comunidad
- Contactar al instructor del curso

### Para Instructores

Este material puede ser adaptado para diferentes contextos educativos:
- Cursos universitarios de seguridad
- Capacitaciones corporativas
- Certificaciones profesionales
- Workshops y seminarios

### Contribuciones

Se aceptan contribuciones para mejorar el material:
- Correcciones de errores
- Mejoras en explicaciones
- Casos de troubleshooting adicionales
- Soporte para más plataformas
- Traducciones

---

## Agradecimientos

Material creado para la formación integral en seguridad informática con foco específico en:
- Autenticación WiFi empresarial
- Protocolo RADIUS y AAA
- Infraestructura PKI
- Análisis de protocolos de red
- Mejores prácticas de seguridad

Basado en:
- Estándares de la industria (IEEE, IETF)
- Mejores prácticas de seguridad (NIST, CIS)
- Documentación oficial de FreeRADIUS
- Experiencia en implementaciones reales

---

## Conclusión

Este trabajo práctico proporciona una base sólida para comprender e implementar autenticación WiFi empresarial con RADIUS. Los conocimientos adquiridos son directamente aplicables a entornos de producción y constituyen habilidades valiosas para profesionales de seguridad y networking.

**Objetivos logrados al completar el TP:**
- ✅ Comprensión profunda de 802.1X, RADIUS y EAP
- ✅ Capacidad de implementar infraestructura WiFi Enterprise
- ✅ Habilidad de troubleshooting avanzado
- ✅ Experiencia con análisis de protocolos
- ✅ Conocimiento de mejores prácticas empresariales

**Próximos pasos sugeridos:**
1. Implementar en entorno de mayor escala
2. Integrar con Active Directory
3. Configurar alta disponibilidad
4. Obtener certificaciones WiFi (CWNA, CWSP)
5. Aplicar en entornos de producción con supervisión

---

**¡Éxito con el trabajo práctico!**

Recuerda: **La seguridad es un proceso continuo, no un producto.** Este TP te da las bases teóricas y prácticas para implementar y mantener infraestructuras WiFi seguras en entornos empresariales reales. El aprendizaje continúa con cada implementación y cada problema resuelto.

*"In God we trust, all others must bring data"* - W. Edwards Deming

Aplica esta filosofía: verifica todo, captura tráfico, analiza logs, comprende profundamente.
