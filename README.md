# Protección local de `main` con hooks y aprobaciones firmadas (GPG)

Esta guía y los scripts listos para usar bloquean commits/push directos a `main` y exigen **aprobaciones criptográficas** (tags firmados) de personas en una _allow‑list_.

## Instalación rápida
```bash
# dentro de tu repo
mkdir -p .githooks tools approvers
# copia el contenido de esta carpeta al repo (mantén mismas rutas)
# luego:
bash tools/install-hooks.sh           # o: pwsh -File tools/install-hooks.ps1
```

> Verifica: `git config --get core.hooksPath` debe mostrar `.githooks`

## ¿Qué bloquea?
- **pre-commit**: evita commits en `main/master`.
- **pre-push**: evita `push` a `refs/heads/main` si el commit no tiene las aprobaciones requeridas (`REQUIRED_APPROVALS`, default=1).

## ¿Quién puede aprobar?
Edita `approvers/ALLOWLIST.txt` y agrega los **emails** autorizados (uno por línea).

## ¿Cómo se aprueba y se fusiona?

1) Cada aprobador debe tener GPG y una clave configurada en Git (Windows: instala **Gpg4win**).  
2) El aprobador crea un **tag firmado** sobre el commit/branch objetivo:
```bash
tools/make-approval-tag.sh feature/mi-cambio
# PowerShell:
# .\tools\make-approval-tag.ps1 -Branch feature/mi-cambio
```
3) Ejecuta el “merge bendecido” (verifica firmas y hace `--ff-only` a main):
```bash
tools/approve-and-merge.sh feature/mi-cambio
# PowerShell:
# .\tools\approve-and-merge.ps1 -SourceBranch feature/mi-cambio -RequiredApprovals 1
```
4) Sube `main` y los tags de aprobación:
```bash
git push origin main --follow-tags
```

## Requisitos (Windows)
- Instala **Gpg4win** y valida con `gpg --version`.
- Configura Git:
```powershell
git config --global user.email "tu@email"
git config --global user.signingkey <TU_KEY_ID>
git config --global gpg.program "C:\\Program Files\\GnuPG\\bin\\gpg.exe"
git config --global tag.gpgSign true   # opcional
```
- (Opcional) Marca tu propia clave como trusted: `gpg --edit-key <KEY_ID>` → `trust` → `5`

## Prueba E2E
```powershell
git switch -c feature/test
'prueba' | Out-File -Encoding utf8 demo.txt
git add demo.txt && git commit -m "demo"

# crear tag de aprobación firmado
pwsh -File tools/make-approval-tag.ps1 -Branch feature/test

# fusionar con verificación de firmas
pwsh -File tools/approve-and-merge.ps1 -SourceBranch feature/test -RequiredApprovals 1

git push origin main --follow-tags
```

## Solución de problemas
- **“cannot spawn .githooks/pre-commit: No such file or directory”**  
  Asegúrate de: (1) tener `.githooks/pre-commit` (sin extensión) en el repo, (2) ejecutar `git config core.hooksPath .githooks` **dentro del repo** y confirmar con `git config --show-origin core.hooksPath`, (3) guardar los hooks como **UTF‑8 sin BOM** y con **LF**.
- **`pre-push: ... unbound variable`**  
  Actualiza al `pre-push` incluido aquí (maneja entradas vacías y CRLF).
- **`gpg: not recognized`**  
  Instala Gpg4win y configura `git config gpg.program` a la ruta de `gpg.exe`.
- **Firmas “can’t check”**  
  Ejecuta `gpg --edit-key <KEY>` → `trust` → `5` para confiar en tu propia clave.

---

_Ruta del paquete_: `main_protection_hooks/`  
Incluye: `.githooks/`, `tools/`, `approvers/`, y esta **README**.
