#!/bin/bash

set -e

BASE_DIR="$(pwd)"
ROOTFS_DIR="$BASE_DIR/ubuntu"
PROOT_BIN="$BASE_DIR/proot-x86_64"

PROOT_URL="https://proot.gitlab.io/proot/bin/proot"
UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/resolute/release/ubuntu-base-26.04-base-amd64.tar.gz"

MAX_RETRIES=50
TIMEOUT=15

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

ARCH="$(uname -m)"

if [ "$ARCH" != "x86_64" ]; then
    printf "${RED}Unsupported architecture: %s${RESET}\n" "$ARCH"
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

# Download latest official PRoot x86_64
echo "[+] Downloading latest official PRoot x86_64..."

rm -f "$PROOT_BIN"

wget \
    --tries="$MAX_RETRIES" \
    --timeout="$TIMEOUT" \
    --no-hsts \
    -O "$PROOT_BIN" \
    "$PROOT_URL"

if [ ! -s "$PROOT_BIN" ]; then
    echo "[-] Failed to download PRoot."
    exit 1
fi

chmod 755 "$PROOT_BIN"

echo "[+] PRoot version:"
"$PROOT_BIN" --version
echo

# Install Ubuntu 26.04
if [ ! -x "$ROOTFS_DIR/bin/bash" ]; then

    echo "[+] Installing Ubuntu 26.04 LTS Base AMD64..."

    rm -rf "$ROOTFS_DIR"
    mkdir -p "$ROOTFS_DIR"

    rm -f /tmp/ubuntu-base.tar.gz

    wget \
        --tries="$MAX_RETRIES" \
        --timeout="$TIMEOUT" \
        --no-hsts \
        -O /tmp/ubuntu-base.tar.gz \
        "$UBUNTU_URL"

    if [ ! -s /tmp/ubuntu-base.tar.gz ]; then
        echo "[-] Failed to download Ubuntu."
        exit 1
    fi

    echo "[+] Extracting Ubuntu..."

    tar -xzf /tmp/ubuntu-base.tar.gz \
        -C "$ROOTFS_DIR"

    rm -f /tmp/ubuntu-base.tar.gz
fi

# Fix root/home/history
mkdir -p "$ROOTFS_DIR/root"
mkdir -p "$ROOTFS_DIR/home/user"

touch "$ROOTFS_DIR/root/.bash_history"
touch "$ROOTFS_DIR/home/user/.bash_history"

# DNS
rm -f "$ROOTFS_DIR/etc/resolv.conf"

printf '%s\n' \
    "nameserver 1.1.1.1" \
    "nameserver 1.0.0.1" \
    > "$ROOTFS_DIR/etc/resolv.conf"

# Hostname
printf 'ubuntu\n' > "$ROOTFS_DIR/etc/hostname"

printf '127.0.0.1 localhost\n127.0.1.1 ubuntu\n' \
    > "$ROOTFS_DIR/etc/hosts"

echo
echo "___________________________________________________"
echo
printf "           ${GREEN}-----> Mission Completed! <----${RESET}\n"
echo
echo "[+] Ubuntu : 26.04 LTS"
echo "[+] Arch   : x86_64"
echo "[+] PRoot  : Latest official build"
echo
echo "[+] Starting Ubuntu..."
echo

# Enter Ubuntu
exec "$PROOT_BIN" \
    --rootfs="$ROOTFS_DIR" \
    --change-id \
    --cwd=/root \
    --bind=/dev \
    --bind=/proc \
    --bind=/sys \
    --bind=/etc/resolv.conf \
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
        /bin/bash --login
