# Trabajo Práctico: Configuración de WiFi Empresarial con RADIUS y Certificados

## Descripción General

Este trabajo práctico proporciona una guía completa para implementar, configurar y gestionar una infraestructura WiFi empresarial segura utilizando:

- **WPA2/WPA3-Enterprise** (802.1X)
- **Servidor RADIUS** (FreeRADIUS)
- **Autenticación EAP-TLS** con certificados X.509
- **Segmentación de red** con VLANs dinámicas
- **Análisis de tráfico** con Wireshark

---

## Objetivos de Aprendizaje

Al completar este trabajo práctico, los alumnos serán capaces de:

1. Comprender la arquitectura de seguridad WiFi empresarial
2. Configurar un servidor RADIUS centralizado
3. Implementar una infraestructura PKI (certificados)
4. Configurar Access Points para autenticación 802.1X
5. Configurar clientes en múltiples plataformas
6. Capturar y analizar el tráfico de autenticación
7. Implementar mejores prácticas de seguridad
8. Diagnosticar y resolver problemas comunes

---

## Estructura del Trabajo Práctico

### 📚 Archivo 00: Introducción Teórica
**`00_Introduccion_Teorica.md`**

- Fundamentos de 802.1X, RADIUS y EAP
- Diferencias entre WPA2-Personal y Enterprise
- Arquitectura del laboratorio
- Componentes necesarios
- Referencias teóricas

**Duración estimada:** 1-2 horas de lectura

---

### ⚙️ Archivo 01: Configuración del Servidor RADIUS
**`01_Configuracion_Servidor_RADIUS.md`**

- Instalación de FreeRADIUS en Ubuntu
- Configuración de clientes RADIUS (Access Points)
- Gestión de usuarios y atributos
- Configuración del módulo EAP
- Virtual servers y sites
- Pruebas y verificación

**Duración estimada:** 2-3 horas

**Prerequisitos:**
- VM o servidor con Ubuntu 22.04 LTS
- Conocimientos básicos de Linux
- Acceso root/sudo

---

### 🔐 Archivo 02: Gestión de Certificados PKI
**`02_Gestion_Certificados_PKI.md`**

- Creación de CA (Certificate Authority) privada
- Generación de certificado del servidor RADIUS
- Generación de certificados de clientes
- Instalación en FreeRADIUS
- Distribución segura
- Renovación y revocación
- Monitoreo de expiración

**Duración estimada:** 2-3 horas

**Prerequisitos:**
- Servidor RADIUS configurado (Archivo 01)
- Conocimientos de OpenSSL
- Comprensión de PKI

---

### 📡 Archivo 03: Configuración del Access Point
**`03_Configuracion_Access_Point.md`**

- Configuración por fabricante:
  - UniFi (Ubiquiti)
  - TP-Link EAP (Omada)
  - MikroTik
  - Cisco WLC
- VLANs dinámicas
- Protected Management Frames (PMF)
- Fast Roaming (802.11r)
- Troubleshooting del AP

**Duración estimada:** 1-2 horas

**Prerequisitos:**
- Access Point compatible con 802.1X
- Acceso administrativo al AP
- Servidor RADIUS funcionando

---

### 💻 Archivo 04: Configuración de Clientes
**`04_Configuracion_Clientes.md`**

- Configuración detallada para:
  - Windows 10/11
  - Linux (Ubuntu/Debian)
  - Android
  - iOS/iPadOS
  - macOS
- Importación de certificados
- Configuración de WiFi Enterprise
- Troubleshooting por plataforma
- Scripts de instalación automatizada

**Duración estimada:** 2-3 horas

**Prerequisitos:**
- Certificados de cliente generados
- Dispositivos para pruebas
- Red WiFi Enterprise activa

---

### 🔍 Archivo 05: Captura y Análisis con Wireshark
**`05_Captura_Analisis_Wireshark.md`**

- Instalación y configuración de Wireshark
- Captura de tráfico EAPOL (WiFi)
- Captura de tráfico RADIUS (Ethernet)
- Análisis detallado del flujo 802.1X
- Identificación de cada fase de autenticación
- Filtros de Wireshark útiles
- Análisis de casos exitosos y fallidos
- Ejercicios prácticos de análisis

**Duración estimada:** 3-4 horas

**Prerequisitos:**
- Wireshark instalado
- Autenticación WiFi funcionando
- Conocimientos básicos de redes

**⚠️ SECCIÓN CRÍTICA:** Esta es la parte más educativa del TP. Los alumnos verán exactamente cómo funciona el protocolo internamente.

---

### 🏢 Archivo 06: Mejores Prácticas Empresariales
**`06_Mejores_Practicas_Empresariales.md`**

- Arquitectura de seguridad en capas
- Diseño de red con VLANs
- Alta disponibilidad y redundancia
- Gestión de certificados en producción
- Monitoreo y logging centralizado
- Hardening del servidor RADIUS
- Cumplimiento y auditoría
- Disaster Recovery y Business Continuity
- Escalabilidad

**Duración estimada:** 2-3 horas de lectura + implementación variable

**Aplicación:**
- Para ambientes de producción
- Preparación para certificaciones
- Comprensión de operaciones reales

---

### 🛠️ Archivo 07: Ejercicios y Troubleshooting
**`07_Ejercicios_Troubleshooting.md`**

**Parte I: Ejercicios Prácticos Guiados**
- Implementación completa desde cero
- Migración de WPA2-PSK a Enterprise
- Alta disponibilidad
- Segmentación con VLANs
- Integración con Active Directory

**Parte II: Casos de Troubleshooting**
- Cliente no puede conectarse
- Intermitencia en conexiones
- VLAN no se asigna
- Performance degradada

**Parte III: Escenarios de Seguridad**
- Detección de Rogue AP
- Ataque de desautenticación
- Credential stuffing

**Parte IV: Ejercicios de Evaluación**
- Auditoría de seguridad
- Disaster recovery drill
- Caso de estudio completo

**Duración estimada:** 4-8 horas (depende de ejercicios seleccionados)

---

## Ruta de Aprendizaje Recomendada

### 🎯 Track 1: Básico (2-3 días)

```
Día 1: Teoría y configuración inicial
  ├─ Archivo 00: Introducción teórica (2h)
  └─ Archivo 01: Servidor RADIUS (3h)

Día 2: Certificados y conectividad
  ├─ Archivo 02: PKI y certificados (3h)
  ├─ Archivo 03: Access Point (2h)
  └─ Archivo 04: Clientes (2h)

Día 3: Análisis y práctica
  ├─ Archivo 05: Wireshark (4h)
  └─ Archivo 07: Ejercicios básicos (3h)
```

### 🎯 Track 2: Intermedio (4-5 días)

```
Track Básico +
  ├─ Archivo 06: Mejores prácticas (4h)
  ├─ Ejercicios de troubleshooting (4h)
  └─ Implementación de HA (4h)
```

### 🎯 Track 3: Avanzado (1-2 semanas)

```
Track Intermedio +
  ├─ Integración con Active Directory (6h)
  ├─ Implementación en producción simulada (8h)
  ├─ Auditoría de seguridad completa (4h)
  └─ Caso de estudio empresarial (10h)
```

---

## Requisitos de Hardware y Software

### Servidor RADIUS

| Componente | Especificación Mínima | Recomendado |
|------------|----------------------|-------------|
| CPU | 2 vCPU | 4 vCPU |
| RAM | 2 GB | 4 GB |
| Disco | 20 GB | 40 GB |
| SO | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| Red | 1 NIC | 1 NIC |

### Access Point

- Soporte para WPA2-Enterprise o superior
- Soporte para 802.1X
- Marcas compatibles:
  - Ubiquiti UniFi (cualquier modelo)
  - TP-Link EAP series
  - MikroTik (con soporte WiFi)
  - Cisco Aironet / Meraki
  - Aruba AP

### Clientes de prueba

- Windows 10/11 (laptop o VM)
- Linux Ubuntu/Debian (laptop o VM)
- Android 8+ (smartphone/tablet)
- iOS 12+ / macOS 10.14+ (opcional)

### Software adicional

- **Wireshark** 3.0+
- **OpenSSL** 1.1.1+
- **SSH client** (PuTTY, OpenSSH)
- **Editor de texto** (nano, vim, VS Code)

---

## Instalación Rápida

### Opción 1: Paso a paso (recomendado para aprendizaje)

Seguir los archivos en orden desde el 00 hasta el 07.

### Opción 2: Script de instalación rápida

Para un laboratorio de prueba rápido:

```bash
# Clonar o descargar este repositorio
cd TP_WiFi_Enterprise_RADIUS

# Ejecutar script de instalación (próximamente)
# sudo ./quick-install.sh
```

---

## Comandos de Inicio Rápido

### Iniciar FreeRADIUS en modo debug

```bash
sudo systemctl stop freeradius
sudo freeradius -X
```

### Probar autenticación local

```bash
radtest usuario password localhost 0 testing123
```

### Capturar tráfico RADIUS

```bash
sudo tcpdump -i eth0 port 1812 or port 1813 -vv
```

### Ver logs en tiempo real

```bash
sudo tail -f /var/log/freeradius/radius.log
```

### Verificar certificado

```bash
openssl x509 -in certificado.pem -noout -text
```

---

## Evaluación y Criterios de Aprobación

### Componentes evaluables

| Componente | Peso | Criterio |
|------------|------|----------|
| Servidor RADIUS funcionando | 20% | Autenticación exitosa |
| Certificados PKI | 15% | CA + servidor + clientes |
| Access Point configurado | 15% | 802.1X habilitado |
| Clientes conectados | 15% | Al menos 2 plataformas |
| Captura Wireshark | 20% | Identificación de fases |
| Documentación | 10% | Arquitectura documentada |
| Troubleshooting | 5% | Resolución de casos |

### Entregables

1. **Informe técnico** (PDF, 15-25 páginas)
   - Arquitectura implementada
   - Configuraciones aplicadas
   - Capturas de pantalla
   - Análisis de Wireshark
   - Problemas encontrados y soluciones

2. **Archivos de configuración**
   - `/etc/freeradius/3.0/` (backup)
   - Certificados generados
   - Configuración de AP (export)
   - Scripts creados

3. **Capturas de tráfico**
   - Autenticación exitosa completa (.pcap)
   - Autenticación fallida (.pcap)
   - Análisis anotado (PDF de Wireshark)

4. **Demostración práctica** (opcional)
   - Mostrar funcionamiento en vivo
   - Explicar flujo de autenticación
   - Resolver problema en tiempo real

---

## Troubleshooting Común

### "RADIUS server not responding"

```bash
# Verificar servicio activo
sudo systemctl status freeradius

# Verificar firewall
sudo ufw status
sudo ufw allow from 192.168.1.0/24 to any port 1812 proto udp

# Verificar logs
sudo tail -f /var/log/freeradius/radius.log
```

### "Unknown CA" en cliente

```bash
# Verificar que ca.pem está instalado en el cliente
# Windows: certmgr.msc > Trusted Root CA
# Linux: verificar ruta en wpa_supplicant.conf
# Android: Settings > Security > Trusted credentials
```

### "Certificate expired"

```bash
# Verificar validez
openssl x509 -in certificado.pem -noout -dates

# Renovar si expiró
cd /etc/ssl/radius-certs
sudo ./generate-client-cert.sh usuario
```

---

## Recursos Adicionales

### Documentación oficial

- [FreeRADIUS Wiki](https://wiki.freeradius.org/)
- [IEEE 802.1X Standard](https://standards.ieee.org/standard/802_1X-2020.html)
- [RFC 2865 - RADIUS](https://tools.ietf.org/html/rfc2865)
- [RFC 3748 - EAP](https://tools.ietf.org/html/rfc3748)
- [RFC 5216 - EAP-TLS](https://tools.ietf.org/html/rfc5216)

### Herramientas

- [Wireshark](https://www.wireshark.org/)
- [Aircrack-ng](https://www.aircrack-ng.org/)
- [wpa_supplicant](https://w1.fi/wpa_supplicant/)
- [FreeRADIUS](https://freeradius.org/)

### Comunidad y soporte

- [FreeRADIUS Mailing List](https://freeradius.org/support/)
- [Stack Overflow - RADIUS tag](https://stackoverflow.com/questions/tagged/radius)
- [Reddit r/networking](https://www.reddit.com/r/networking/)

---

## Changelog y Versiones

### Versión 1.0 (2024)

- ✅ Documentación completa de 8 archivos
- ✅ Ejercicios prácticos y casos de troubleshooting
- ✅ Guías para múltiples plataformas (Windows, Linux, Android, iOS)
- ✅ Análisis detallado con Wireshark
- ✅ Mejores prácticas empresariales
- ✅ Scripts de automatización

### Próximas mejoras (backlog)

- [ ] Scripts de instalación automatizada
- [ ] Laboratorio con Docker/Vagrant
- [ ] Videos tutoriales complementarios
- [ ] Casos de estudio adicionales
- [ ] Integración con proveedores cloud (AWS, Azure)

---

## Licencia y Uso

Este material educativo es proporcionado con fines didácticos.

**Uso permitido:**
- Educación y entrenamiento
- Laboratorios de prueba
- Práctica personal

**Restricciones:**
- Las técnicas de ataque (deauth, etc.) solo deben usarse en redes propias
- No realizar pruebas en redes de producción sin autorización
- Respetar normativas de seguridad y privacidad

---

## Contacto y Contribuciones

Para preguntas, sugerencias o correcciones, contactar al instructor.

---

## Agradecimientos

Material creado para la formación en seguridad informática con foco en autenticación WiFi empresarial y RADIUS.

Basado en estándares de la industria y mejores prácticas de seguridad.

---

**¡Éxito con el trabajo práctico!**

Recuerda: la seguridad es un proceso continuo, no un producto. Este TP te da las bases para implementar y mantener infraestructuras WiFi seguras en entornos empresariales reales.
