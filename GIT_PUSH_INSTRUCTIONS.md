# Instrucciones para Subir al Repositorio GitHub

## Repositorio Configurado

✅ **Repositorio:** https://github.com/WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS.git
✅ **Autor:** fboiero (fboiero@frvm.utn.edu.ar)
✅ **Branch:** main
✅ **Commit inicial:** Creado con 17 archivos

---

## Estado Actual

```bash
# Ver configuración
git config --list | grep -E "user\.|remote"
```

Debería mostrar:
```
user.name=fboiero
user.email=fboiero@frvm.utn.edu.ar
remote.origin.url=https://github.com/WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS.git
```

---

## Para Subir al Repositorio

### Opción 1: Con HTTPS (Recomendado)

```bash
# Navegar al directorio
cd /Users/fboiero/TP_WiFi_Enterprise_RADIUS

# Hacer push
git push -u origin main
```

GitHub te pedirá credenciales:
- **Username:** fboiero
- **Password:** Tu Personal Access Token (PAT)

**Nota:** GitHub ya no acepta contraseñas. Necesitas un Personal Access Token:

1. Ir a: https://github.com/settings/tokens
2. Click en "Generate new token (classic)"
3. Scopes necesarios:
   - `repo` (acceso completo a repositorios)
4. Copiar el token generado
5. Usarlo como password cuando hagas `git push`

### Opción 2: Con SSH (Más seguro)

Si tienes SSH configurado:

```bash
# Cambiar remote a SSH
git remote set-url origin git@github.com:WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS.git

# Push
git push -u origin main
```

---

## Verificar que Subió Correctamente

Después del push exitoso:

1. Visitar: https://github.com/WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS
2. Deberías ver:
   - 17 archivos
   - Commit inicial con mensaje descriptivo
   - README.md renderizado en la página principal

---

## Actualizar Repositorio en el Futuro

### Agregar cambios nuevos:

```bash
# Ver archivos modificados
git status

# Agregar todos los cambios
git add .

# O agregar archivos específicos
git add archivo1.md archivo2.md

# Crear commit
git commit -m "Descripción de los cambios"

# Subir a GitHub
git push origin main
```

### Ver historial:

```bash
# Ver commits
git log --oneline

# Ver cambios en último commit
git show
```

---

## Contenido del Repositorio

```
LAB02_WiFi_Enterprise_RADIUS/
├── README.md                              # Índice principal
├── INICIO_RAPIDO.md                       # Guía de inicio rápido
├── GUIA_CLASE_UNICA.md                    # Clase de 3-4 horas
├── LABORATORIO_MACBOOK_M4.md             # Setup en Apple Silicon
│
├── 00_Introduccion_Teorica.md            # Fundamentos
├── 01_Configuracion_Servidor_RADIUS.md   # FreeRADIUS
├── 02_Gestion_Certificados_PKI.md        # Certificados
├── 03_Configuracion_Access_Point.md      # APs
├── 04_Configuracion_Clientes.md          # Clientes
├── 05_Captura_Analisis_Wireshark.md      # Wireshark
├── 06_Mejores_Practicas_Empresariales.md # Producción
├── 07_Ejercicios_Troubleshooting.md      # Ejercicios
│
└── scripts/
    ├── README.md                          # Guía de scripts
    ├── install-linux.sh                   # Instalador Linux
    ├── install-macos.sh                   # Instalador macOS
    └── install-windows.ps1                # Instalador Windows
```

**Total:** ~344 KB de documentación + scripts

---

## Comandos Útiles de Git

```bash
# Ver estado del repositorio
git status

# Ver diferencias antes de commit
git diff

# Ver log bonito
git log --oneline --graph --all

# Ver archivos en el último commit
git ls-tree -r main --name-only

# Ver tamaño del repo
du -sh .git

# Ver autor del último commit
git log -1 --pretty=format:"%an <%ae>"
```

---

## Clonar el Repositorio (Para Otros Usuarios)

Otros usuarios pueden clonar el repositorio con:

```bash
# HTTPS
git clone https://github.com/WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS.git

# SSH
git clone git@github.com:WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS.git

# Entrar al directorio
cd LAB02_WiFi_Enterprise_RADIUS

# Ejecutar instalador
cd scripts
./install-linux.sh  # o install-macos.sh / install-windows.ps1
```

---

## Colaboración (Si Aplica)

Si otros van a contribuir:

### Proteger branch main:

1. En GitHub: Settings > Branches
2. Add rule: `main`
3. Require pull request reviews
4. Require status checks

### Workflow de colaboración:

```bash
# Crear branch para feature
git checkout -b feature/nueva-caracteristica

# Hacer cambios
# ...

# Commit
git commit -m "Agregar nueva característica"

# Push de branch
git push origin feature/nueva-caracteristica

# Crear Pull Request en GitHub
# Después de revisión, hacer merge
```

---

## Licencia

Revisar si quieres agregar LICENSE file:

```bash
# Crear LICENSE (ejemplo: MIT)
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 Federico Boiero

Permission is hereby granted, free of charge...
EOF

git add LICENSE
git commit -m "Add MIT license"
git push origin main
```

---

## Badge para README (Opcional)

Agregar badges al README.md:

```markdown
# LAB02 - WiFi Enterprise + RADIUS

![GitHub last commit](https://img.shields.io/github/last-commit/WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS)
![GitHub repo size](https://img.shields.io/github/repo-size/WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS)
![GitHub](https://img.shields.io/github/license/WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS)
```

---

## Resumen de Comandos para Push Inicial

```bash
# 1. Verificar todo está OK
cd /Users/fboiero/TP_WiFi_Enterprise_RADIUS
git status

# 2. Verificar autor
git config user.name
git config user.email

# 3. Push a GitHub
git push -u origin main

# 4. Ingresar credenciales cuando se solicite
# Username: fboiero
# Password: <Personal Access Token>
```

---

## ¿Necesitas Personal Access Token?

### Generar PAT en GitHub:

1. Login en GitHub
2. Settings (esquina superior derecha) > Developer settings
3. Personal access tokens > Tokens (classic)
4. Generate new token (classic)
5. Note: "LAB02 WiFi RADIUS Access"
6. Expiration: 90 days (o custom)
7. Scopes: ✅ repo (full control of private repositories)
8. Generate token
9. **COPIAR TOKEN** (no se mostrará de nuevo)
10. Usar como password en `git push`

---

## Verificación Final

Después del push, verificar:

```bash
# Ver remote tracking
git branch -vv

# Debería mostrar:
# * main 2ac0da8 [origin/main] Initial commit...
```

En GitHub:
- Ver commits: https://github.com/WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS/commits/main
- Ver archivos: https://github.com/WIFI-SEC/LAB02_WiFi_Enterprise_RADIUS

---

**¡Todo listo para hacer push!** 🚀

Ejecuta: `git push -u origin main`
