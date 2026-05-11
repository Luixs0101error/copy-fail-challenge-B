#!/usr/bin/env bash
# scripts/01_fetch_kernel.sh
# Descarga el bzImage pre-compilado del Release del docente
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$WORKSPACE_ROOT/kernel/build"

# KERNEL_REPO debe venir del devcontainer.json (no auto-detectar del fork del estudiante)
REPO="${KERNEL_REPO:-}"
RELEASE_TAG="${KERNEL_RELEASE_TAG:-kernel-v6.12-vuln}"
ASSET="bzImage_vuln"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

mkdir -p "$BUILD_DIR"

if [ -f "$BUILD_DIR/$ASSET" ]; then
  echo -e "${GREEN}✓ bzImage ya presente. Omitiendo descarga.${NC}"
  exit 0
fi

if [ -z "$REPO" ] || [[ "$REPO" == *"DOCENTE-USUARIO"* ]]; then
  echo -e "${RED}Error: KERNEL_REPO no está configurado.${NC}"
  echo "Pídele al docente que actualice .devcontainer/devcontainer.json"
  echo "con la variable KERNEL_REPO=usuario/repo-template"
  exit 1
fi

URL="https://github.com/${REPO}/releases/download/${RELEASE_TAG}/${ASSET}"
echo -e "${YELLOW}Descargando kernel desde:${NC}"
echo "  $URL"

if curl -fL --progress-bar -o "$BUILD_DIR/$ASSET" "$URL"; then
  SIZE=$(du -sh "$BUILD_DIR/$ASSET" | cut -f1)
  echo -e "${GREEN}✓ Kernel descargado (${SIZE})${NC}"
else
  echo -e "${RED}✗ Falló la descarga. Verifica que el Release exista en ${REPO}.${NC}"
  exit 1
fi
