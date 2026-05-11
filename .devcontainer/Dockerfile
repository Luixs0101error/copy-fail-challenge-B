# Dockerfile — Copy Fail Lab v2
# Aprendido en debugging:
#   - hexdump NO existe en Ubuntu 24.04, usar bsdextrautils
#   - bzip2 es requerido por BusyBox para compilar
#   - todo en Ubuntu 24.04 (Noble Numbat)

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Compilación del kernel Linux
    git make gcc g++ flex bison bc \
    libncurses-dev libelf-dev libssl-dev \
    libdw-dev libunwind-dev \
    pahole dwarves \
    # Compilación de BusyBox (bzip2 es CRÍTICO)
    musl-tools musl-dev bzip2 xz-utils \
    # QEMU para arrancar la VM
    qemu-system-x86 qemu-utils \
    # Herramientas de red y sistema
    iproute2 net-tools curl wget \
    # Python 3.10+ para el exploit
    python3 python3-pip \
    # Análisis y debugging
    strace ltrace gdb binutils elfutils \
    # bsdextrautils trae hexdump (NO existe como paquete propio en 24.04)
    bsdextrautils xxd \
    # Utilidades varias
    cpio jq vim less \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Verificar Python 3.10+ para os.splice (usado por el PoC)
RUN python3 -c "import sys; assert sys.version_info >= (3,10)"

WORKDIR /workspace
CMD ["/bin/bash"]
