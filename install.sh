#!/bin/bash

BASE_DIR="$(pwd)"
ROOTFS_DIR="$BASE_DIR/ubuntu"
PROOT_BIN="$BASE_DIR/proot-x86_64"

PROOT_URL="https://github.com/padarham9-ui/Rootfree/raw/refs/heads/main/proot-v5.2.0-alpha-x86_64-static"
UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/resolute/release/ubuntu-base-26.04-base-amd64.tar.gz"

MAX_RETRIES=50
TIMEOUT=15

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

ARCH="$(uname -m)"

# فقط x86_64
if [ "$ARCH" != "x86_64" ]; then
    printf "${RED}Unsupported architecture: %s${RESET}\n" "$ARCH"
    printf "This installer supports x86_64 only.\n"
    exit 1
fi

clear

echo "################################################################################"
echo "#"
echo "#                         Ubuntu 26.04 LTS"
echo "#                         PRoot x86_64"
echo "#"
echo "################################################################################"
echo

# ------------------------------------------------------------------------------
# Download PRoot
# ------------------------------------------------------------------------------

if [ ! -s "$PROOT_BIN" ]; then
    echo "[+] Downloading PRoot v5.2.0-alpha x86_64..."

    rm -f "$PROOT_BIN"

    wget \
        --tries="$MAX_RETRIES" \
        --timeout="$TIMEOUT" \
        --no-hsts \
        -O "$PROOT_BIN" \
        "$PROOT_URL"

    if [ $? -ne 0 ] || [ ! -s "$PROOT_BIN" ]; then
        printf "${RED}[-] Failed to download PRoot.${RESET}\n"
        exit 1
    fi

    chmod 755 "$PROOT_BIN"
fi

# ------------------------------------------------------------------------------
# Validate PRoot
# ------------------------------------------------------------------------------

echo "[+] Checking PRoot..."

if ! "$PROOT_BIN" --version >/dev/null 2>&1; then
    printf "${RED}[-] PRoot failed to execute.${RESET}\n"
    echo
    file "$PROOT_BIN" 2>/dev/null || true
    echo
    "$PROOT_BIN" --version 2>&1 || true
    exit 1
fi

echo "[+] PRoot:"
"$PROOT_BIN" --version
echo

# ------------------------------------------------------------------------------
# Download and install Ubuntu 26.04 Base AMD64
# ------------------------------------------------------------------------------

if [ ! -x "$ROOTFS_DIR/bin/bash" ]; then

    echo "[+] Installing Ubuntu 26.04 LTS Base AMD64..."

    rm -rf "$ROOTFS_DIR"
    mkdir -p "$ROOTFS_DIR"

    rm -f /tmp/ubuntu-base-26.04.tar.gz

    wget \
        --tries="$MAX_RETRIES" \
        --timeout="$TIMEOUT" \
        --no-hsts \
        -O /tmp/ubuntu-base-26.04.tar.gz \
        "$UBUNTU_URL"

    if [ $? -ne 0 ] || [ ! -s /tmp/ubuntu-base-26.04.tar.gz ]; then
        printf "${RED}[-] Failed to download Ubuntu.${RESET}\n"
        exit 1
    fi

    echo "[+] Extracting Ubuntu..."

    tar -xzf /tmp/ubuntu-base-26.04.tar.gz \
        -C "$ROOTFS_DIR"

    if [ $? -ne 0 ] || [ ! -x "$ROOTFS_DIR/bin/bash" ]; then
        printf "${RED}[-] Failed to extract Ubuntu rootfs.${RESET}\n"
        exit 1
    fi

    rm -f /tmp/ubuntu-base-26.04.tar.gz
fi

# ------------------------------------------------------------------------------
# Fix root / home / history
# ------------------------------------------------------------------------------

mkdir -p "$ROOTFS_DIR/root"
mkdir -p "$ROOTFS_DIR/home/user"

touch "$ROOTFS_DIR/root/.bash_history"
touch "$ROOTFS_DIR/home/user/.bash_history"

# ------------------------------------------------------------------------------
# DNS
# ------------------------------------------------------------------------------

rm -f "$ROOTFS_DIR/etc/resolv.conf"

printf '%s\n' \
    "nameserver 1.1.1.1" \
    "nameserver 1.0.0.1" \
    > "$ROOTFS_DIR/etc/resolv.conf"

# ------------------------------------------------------------------------------
# Hostname
# ------------------------------------------------------------------------------

printf 'ubuntu\n' > "$ROOTFS_DIR/etc/hostname"

printf '127.0.0.1 localhost\n127.0.1.1 ubuntu\n' \
    > "$ROOTFS_DIR/etc/hosts"

# ------------------------------------------------------------------------------
# Start Ubuntu
# ------------------------------------------------------------------------------

echo
echo "___________________________________________________"
echo
printf "           ${GREEN}-----> Mission Completed! <----${RESET}\n"
echo
echo "[+] Ubuntu : 26.04 LTS"
echo "[+] Arch   : x86_64"
echo "[+] PRoot  : v5.2.0-alpha"
echo
echo "[+] Starting Ubuntu..."
echo

exec "$PROOT_BIN" \
    --rootfs="$ROOTFS_DIR" \
    -0 \
    -w /root \
    -b /dev \
    -b /sys \
    -b /proc \
    -b /etc/resolv.conf \
    --kill-on-exit \
    /usr/bin/env \
        HOME=/root \
        USER=root \
        LOGNAME=root \
        SHELL=/bin/bash \
        HISTFILE=/root/.bash_history \
        HISTSIZE=10000 \
        HISTFILESIZE=10000 \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        HOSTNAME=ubuntu \
        /bin/bash --noprofile --norc -i \
        -c 'export PS1="root@ubuntu:\w# "; exec /bin/bash --noprofile --norc -i'
