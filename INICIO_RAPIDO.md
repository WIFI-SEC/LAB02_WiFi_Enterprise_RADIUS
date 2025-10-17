# 🚀 Inicio Rápido - Laboratorio WiFi Enterprise + RADIUS

## Instalación Automática en 3 Pasos

### Linux (Ubuntu/Debian)

```bash
cd TP_WiFi_Enterprise_RADIUS/scripts
sudo ./install-linux.sh
```

⏱️ **Tiempo:** 15-20 minutos
✅ **Resultado:** FreeRADIUS funcionando + Certificados + 4 usuarios

---

### macOS (Apple Silicon M1/M2/M3/M4)

```bash
cd TP_WiFi_Enterprise_RADIUS/scripts
./install-macos.sh
```

⏱️ **Tiempo:** 45-60 minutos (incluye descarga de ISO)
✅ **Resultado:** VM Ubuntu + FreeRADIUS + Wireshark

**Nota:** Requiere interacción para crear VM en UTM

---

### Windows 10/11

```powershell
# PowerShell como Administrador
cd TP_WiFi_Enterprise_RADIUS\scripts
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\install-windows.ps1
```

⏱️ **Tiempo:** 30-40 minutos (puede requerir reinicio)
✅ **Resultado:** WSL2 + Ubuntu + FreeRADIUS

---

## Verificar Instalación

### Probar autenticación:

**Linux:**
```bash
radtest testuser testpass localhost 0 testing123
```

**macOS:**
```bash
radtest testuser testpass 192.168.64.10 0 testing123
```

**Windows:**
```powershell
wsl radtest testuser testpass localhost 0 testing123
```

**Salida esperada:**
```
Sent Access-Request Id 123...
Received Access-Accept Id 123...  ← ✅ ÉXITO
```

---

## Modo Debug (Ver Autenticaciones)

### Linux:
```bash
sudo systemctl stop freeradius
sudo freeradius -X
```

### macOS:
```bash
ssh admin@192.168.64.10  # Password: admin123
sudo freeradius -X
```

### Windows:
```powershell
wsl
sudo systemctl stop freeradius
sudo freeradius -X
```

En otra terminal, ejecutar:
```bash
radtest alumno1 password1 localhost 0 testing123
```

Verás los logs detallados de la autenticación en tiempo real.

---

## Usuarios Pre-configurados

| Usuario | Password | VLAN | Descripción |
|---------|----------|------|-------------|
| testuser | testpass | - | Usuario de prueba básico |
| alumno1 | password1 | 10 | Empleado regular |
| alumno2 | password2 | 10 | Empleado regular |
| director | password3 | 20 | Gerencia (mayor acceso) |
| invitado | guest123 | 30 | Invitado (1 hora timeout) |

---

## Capturar Tráfico con Wireshark

### Linux:
```bash
sudo tcpdump -i lo port 1812 -w /tmp/radius.pcap
radtest alumno1 password1 localhost 0 testing123
# Ctrl+C para detener
wireshark /tmp/radius.pcap
```

### macOS:
```bash
sudo tcpdump -i bridge100 port 1812 -w ~/Desktop/radius.pcap
radtest alumno1 password1 192.168.64.10 0 testing123
wireshark ~/Desktop/radius.pcap
```

### Windows:
```
1. Abrir Wireshark (como Admin)
2. Interface: Loopback
3. Filter: udp.port == 1812
4. Start
5. En PowerShell: wsl radtest alumno1 password1 localhost 0 testing123
```

---

## Siguientes Pasos

### Para la Clase:

1. **Leer guía de clase:**
   ```bash
   cat GUIA_CLASE_UNICA.md
   ```

2. **Preparar demo:**
   - Terminal 1: RADIUS en modo debug
   - Terminal 2: Ejecutar autenticaciones
   - Wireshark: Capturando tráfico

3. **Material para alumnos:**
   - `00_Introduccion_Teorica.md` - Fundamentos
   - `05_Captura_Analisis_Wireshark.md` - Análisis detallado

### Para Profundizar:

- `01_Configuracion_Servidor_RADIUS.md` - Setup completo
- `02_Gestion_Certificados_PKI.md` - PKI y certificados
- `03_Configuracion_Access_Point.md` - Configurar APs reales
- `06_Mejores_Practicas_Empresariales.md` - Producción
- `07_Ejercicios_Troubleshooting.md` - Casos prácticos

---

## Documentación Generada

Cada script genera documentación específica:

**Linux:** `/root/LABORATORIO_README.txt`
```bash
cat /root/LABORATORIO_README.txt
```

**macOS:** `~/LABORATORIO_MACOS_README.txt`
```bash
cat ~/LABORATORIO_MACOS_README.txt
```

**Windows:** `%USERPROFILE%\LABORATORIO_WINDOWS_README.txt`
```powershell
notepad $env:USERPROFILE\LABORATORIO_WINDOWS_README.txt
```

---

## Troubleshooting Rápido

### FreeRADIUS no inicia

```bash
# Ver qué pasó
sudo journalctl -u freeradius -n 50

# Verificar configuración
sudo freeradius -CX
```

### Autenticación falla (Access-Reject)

```bash
# Modo debug para ver el error
sudo freeradius -X

# Ejecutar autenticación y ver logs
```

### No puedo conectar a la VM (macOS)

```bash
# Verificar IP de la VM
# En UTM, abrir consola de VM
ip addr show

# Intentar ping
ping 192.168.64.10
```

---

## Arquitectura Instalada

```
┌────────────────────────────────────────────┐
│         Tu Computadora (Host)              │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  FreeRADIUS (Nativo o VM/WSL)        │ │
│  │                                      │ │
│  │  • Puerto: 1812/1813                │ │
│  │  • CA + Certificados generados      │ │
│  │  • 5 usuarios configurados          │ │
│  │  • VLANs dinámicas (10, 20, 30)     │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  Wireshark                           │ │
│  │  • Captura tráfico RADIUS            │ │
│  │  • Análisis de paquetes              │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  Herramientas Cliente                │ │
│  │  • radtest                           │ │
│  │  • wpa_supplicant (configs)          │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

---

## Comandos Más Usados

```bash
# Ver estado
systemctl status freeradius  # Linux/WSL

# Reiniciar
systemctl restart freeradius

# Logs en tiempo real
tail -f /var/log/freeradius/radius.log

# Ver usuarios conectados
radwho

# Probar autenticación
radtest <usuario> <password> <servidor> 0 <secret>

# Modo debug (MÁS IMPORTANTE)
systemctl stop freeradius
freeradius -X
```

---

## Material del Curso

| Archivo | Contenido | Duración |
|---------|-----------|----------|
| `00_Introduccion_Teorica.md` | Fundamentos 802.1X, RADIUS, EAP | 1-2h lectura |
| `GUIA_CLASE_UNICA.md` | Clase práctica de 3-4 horas | 3-4h |
| `LABORATORIO_MACBOOK_M4.md` | Setup en Apple Silicon | Referencia |
| `05_Captura_Analisis_Wireshark.md` | Análisis profundo de paquetes | 3-4h práctica |
| `scripts/README.md` | Guía de scripts de instalación | Referencia |

---

## ¿Necesitas Ayuda?

1. **Revisar documentación específica de tu plataforma** en `scripts/README.md`
2. **Ver troubleshooting** en la guía de clase
3. **Ejecutar en modo debug** para ver qué está pasando
4. **Revisar logs** del sistema

---

## ✅ Checklist de "Está Funcionando"

```
[ ] Script de instalación terminó sin errores
[ ] radtest muestra "Access-Accept"
[ ] Puedo ejecutar freeradius -X
[ ] Wireshark captura tráfico en puerto 1812
[ ] Veo 5 usuarios en /etc/freeradius/3.0/users
[ ] Certificados existen en /etc/ssl/radius-certs/ (o equivalente)
```

Si todos tienen ✅, ¡estás listo para la clase! 🎉

---

**Próximo paso:** Leer `GUIA_CLASE_UNICA.md` para preparar la clase práctica.
