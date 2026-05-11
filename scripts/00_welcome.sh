#!/usr/bin/env bash
# scripts/00_welcome.sh
# Detectar workspace dinámicamente (lección aprendida)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Arreglar el "dubious ownership" automáticamente para evitar fricción
git config --global --add safe.directory "$WORKSPACE_ROOT" 2>/dev/null || true

cat << 'BANNER'

  ╔══════════════════════════════════════════════════════════════╗
  ║         Copy Fail Lab — CVE-2026-31431                       ║
  ║         Introducción a UNIX — UIDE                           ║
  ╚══════════════════════════════════════════════════════════════╝

BANNER

cat << EOF
  Workspace: $WORKSPACE_ROOT

  PRIMER PASO — configura git con tu identidad GitHub:

      git config --global user.name "Tu Nombre"
      git config --global user.email "tu@correo.com"

  LUEGO ejecuta:

      make setup    (descarga kernel + arma rootfs, ~5 min)
      make qemu     (arranca la VM vulnerable)

  Para ver todos los comandos:  make help

EOF
