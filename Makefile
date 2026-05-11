# Makefile — Copy Fail Lab v2
# Usa rutas RELATIVAS — funciona con cualquier nombre de repo.

SCRIPTS  := scripts
BUILD    := kernel/build
BZIMAGE  := $(BUILD)/bzImage_vuln
INITRAMFS:= $(BUILD)/initramfs.cpio.gz

STUDENT_ID ?= $(shell git config user.name 2>/dev/null \
                 | tr ' ' '-' | tr -cd '[:alnum:]-' | head -c 20)

.PHONY: all setup fetch-kernel build-kernel rootfs qemu \
        help info clean

all: help

# ── Setup completo: descarga kernel + arma rootfs ─────────────────────────
setup:
	@echo "→ Obteniendo kernel..."
	@bash $(SCRIPTS)/01_fetch_kernel.sh || ( \
		echo "⚠ Descarga falló. Compilando desde fuente (~25 min)..."; \
		bash $(SCRIPTS)/02_build_kernel.sh \
	)
	@echo "→ Construyendo rootfs..."
	@STUDENT_ID="$(STUDENT_ID)" bash $(SCRIPTS)/03_build_rootfs.sh
	@echo ""
	@echo "✓ Listo. Ejecuta: make qemu"

# ── Solo descargar kernel del Release del docente ─────────────────────────
fetch-kernel:
	@bash $(SCRIPTS)/01_fetch_kernel.sh

# ── Compilar kernel desde fuente (fallback lento) ─────────────────────────
build-kernel:
	@bash $(SCRIPTS)/02_build_kernel.sh

# ── Construir rootfs ──────────────────────────────────────────────────────
rootfs:
	@STUDENT_ID="$(STUDENT_ID)" bash $(SCRIPTS)/03_build_rootfs.sh

# ── Arrancar la VM ────────────────────────────────────────────────────────
qemu:
	@bash $(SCRIPTS)/04_run_qemu.sh

# ── Estado actual ─────────────────────────────────────────────────────────
info:
	@echo ""
	@echo "  STUDENT_ID: $(STUDENT_ID)"
	@echo "  bzImage:    $(shell test -f $(BZIMAGE) && echo '✓' || echo '✗ falta')"
	@echo "  initramfs:  $(shell test -f $(INITRAMFS) && echo '✓' || echo '✗ falta')"
	@echo ""

# ── Limpieza ──────────────────────────────────────────────────────────────
clean:
	@rm -rf kernel/build kernel/initramfs 2>/dev/null || true
	@echo "Limpio."

clean-all: clean
	@rm -rf kernel/linux kernel/busybox 2>/dev/null || true
	@echo "Limpieza completa."

help:
	@echo ""
	@echo "  Copy Fail Lab — CVE-2026-31431"
	@echo "  ═══════════════════════════════"
	@echo "  make setup         Descarga kernel + arma rootfs (~5 min)"
	@echo "  make qemu          Arranca la VM vulnerable"
	@echo "  make info          Estado del ambiente"
	@echo "  make clean         Borra builds (mantiene fuentes)"
	@echo "  make clean-all     Borra todo, vuelve a cero"
	@echo ""
	@echo "  Variantes avanzadas:"
	@echo "  make fetch-kernel  Solo descarga el bzImage del Release"
	@echo "  make build-kernel  Compila kernel desde fuente (~25 min)"
	@echo "  make rootfs        Solo reconstruye el initramfs"
	@echo ""
