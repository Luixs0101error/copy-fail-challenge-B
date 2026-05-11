#!/usr/bin/env bash
# scripts/02_build_kernel.sh
# Compila el kernel Linux vulnerable a CVE-2026-31431 DESDE FUENTE
# Solo usar si fetch-kernel falla. Toma ~20-25 min.
#
# Lecciones aprendidas:
#   - tinyconfig NO incluye BINFMT_ELF, BINFMT_SCRIPT ni RD_GZIP
#   - CRYPTO_AEAD debe habilitarse antes que CRYPTO_AUTHENCESN
#   - Los grep de verificación deben tolerar "no encontrado" con || true
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KERNEL_SRC="$WORKSPACE_ROOT/kernel/linux"
BUILD_DIR="$WORKSPACE_ROOT/kernel/build"
KERNEL_TAG="${KERNEL_TAG:-v6.12}"
JOBS="$(nproc)"

CYAN='\033[1;36m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${CYAN}[1/4] Clonando kernel ${KERNEL_TAG}...${NC}"
if [ ! -d "$KERNEL_SRC" ]; then
  git clone --depth 1 --branch "$KERNEL_TAG" \
    https://github.com/torvalds/linux.git "$KERNEL_SRC"
fi

cd "$KERNEL_SRC"

echo -e "${CYAN}[2/4] Configurando kernel mínimo funcional...${NC}"
make tinyconfig

# ── Soporte 64-bit y arranque ──────────────────────────────────────────────
./scripts/config --enable 64BIT
./scripts/config --enable SERIAL_8250
./scripts/config --enable SERIAL_8250_CONSOLE
./scripts/config --enable TTY
./scripts/config --enable PRINTK
./scripts/config --enable EARLY_PRINTK

# ── CRÍTICO: ejecución de binarios y scripts ───────────────────────────────
# Sin esto el kernel arranca pero NO ejecuta NADA. Aprendido a las malas.
./scripts/config --enable BINFMT_ELF      # ejecutar ELFs (BusyBox)
./scripts/config --enable BINFMT_SCRIPT   # ejecutar scripts shell (/init)

# ── initramfs y descompresión ──────────────────────────────────────────────
./scripts/config --enable BLK_DEV_INITRD
./scripts/config --enable INITRAMFS_SOURCE
./scripts/config --enable RD_GZIP         # descomprimir initramfs.cpio.gz
./scripts/config --enable TMPFS

# ── Filesystems mínimos ────────────────────────────────────────────────────
./scripts/config --enable PROC_FS
./scripts/config --enable SYSFS
./scripts/config --enable DEVTMPFS
./scripts/config --enable DEVTMPFS_MOUNT

# ── Red y sockets (AF_ALG vive aquí) ───────────────────────────────────────
./scripts/config --enable NET
./scripts/config --enable UNIX
./scripts/config --enable INET

# ── Subsistema CRYPTO (la parte vulnerable) ────────────────────────────────
./scripts/config --enable CRYPTO
./scripts/config --enable CRYPTO_AEAD              # dep de AUTHENCESN
./scripts/config --enable CRYPTO_AUTHENC           # dep de AUTHENCESN
./scripts/config --enable CRYPTO_USER_API          # AF_ALG base
./scripts/config --enable CRYPTO_USER_API_AEAD     # algif_aead ← VULNERABLE
./scripts/config --enable CRYPTO_USER_API_SKCIPHER
./scripts/config --enable CRYPTO_AUTHENCESN        # ← bug de scratch-write
./scripts/config --enable CRYPTO_AES
./scripts/config --enable CRYPTO_CBC
./scripts/config --enable CRYPTO_HMAC
./scripts/config --enable CRYPTO_SHA256

# ── Usuarios (setuid binaries para LPE) ────────────────────────────────────
./scripts/config --enable MULTIUSER

make olddefconfig

echo -e "${CYAN}[3/4] Compilando bzImage con ${JOBS} cores (~20-25 min)...${NC}"
make -j"$JOBS" bzImage 2>&1 | tail -5

mkdir -p "$BUILD_DIR"
cp arch/x86/boot/bzImage "$BUILD_DIR/bzImage_vuln"

echo -e "${CYAN}[4/4] Verificando opciones críticas...${NC}"
# Lección: grep que no encuentra falla con set -e → usar || true
for OPT in BINFMT_ELF BINFMT_SCRIPT RD_GZIP CRYPTO_USER_API_AEAD CRYPTO_AUTHENCESN; do
  if grep -q "CONFIG_${OPT}=y" .config 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} CONFIG_${OPT}=y"
  else
    echo -e "  ${YELLOW}⚠${NC} CONFIG_${OPT} NO está habilitado"
  fi
done

echo ""
echo -e "${GREEN}✓ Kernel listo en: $BUILD_DIR/bzImage_vuln${NC}"
