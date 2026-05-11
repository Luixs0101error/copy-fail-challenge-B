#!/usr/bin/env bash
# scripts/04_run_qemu.sh
# Arranca la VM vulnerable
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$WORKSPACE_ROOT/kernel/build"

BZIMAGE="${BZIMAGE:-$BUILD_DIR/bzImage_vuln}"
INITRAMFS="${INITRAMFS:-$BUILD_DIR/initramfs.cpio.gz}"

GREEN='\033[1;32m'; RED='\033[1;31m'; CYAN='\033[1;36m'; NC='\033[0m'

if [ ! -f "$BZIMAGE" ]; then
  echo -e "${RED}Error: $BZIMAGE no existe.${NC}"
  echo "Ejecuta: make setup"
  exit 1
fi

if [ ! -f "$INITRAMFS" ]; then
  echo -e "${RED}Error: $INITRAMFS no existe.${NC}"
  echo "Ejecuta: make rootfs"
  exit 1
fi

cat << BANNER
${GREEN}════════════════════════════════════════════════════════${NC}
  Arrancando VM vulnerable — CVE-2026-31431
  Para salir de QEMU:  Ctrl+A  luego  X
${GREEN}════════════════════════════════════════════════════════${NC}

  Kernel:    $BZIMAGE
  Initramfs: $INITRAMFS

BANNER

exec qemu-system-x86_64 \
  -nographic \
  -no-reboot \
  -kernel "$BZIMAGE" \
  -initrd "$INITRAMFS" \
  -append "console=ttyS0 quiet" \
  -m 512M \
  -smp 2
