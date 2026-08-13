#!/bin/bash

set -u

BASE_DIR="$(pwd)"
ROOTFS_DIR="$BASE_DIR/ubuntu"
PROOT_BIN="$BASE_DIR/proot-x86_64"

MAX_RETRIES=50
TIMEOUT=10

PROOT_URL="https://proot.gitlab.io/proot/bin/proot"
UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/resolute/release/ubuntu-base-26.04-base-amd64.tar.gz"

CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

ARCH="$(uname -m)"

if [ "$ARCH" != "x86_64" ]; then
    printf "${RED}Unsupported CPU architecture: %s${RESET}\n" "$ARCH"
    exit 1
fi

clear

echo "################################################################################"
echo "#"
echo "#                         Ubuntu 26.04 LTS"
echo "#                         Official PRoot x86_64"
echo "#"
echo "################################################################################"
echo

# ------------------------------------------------------------------------------
# Download latest official PRoot
# ------------------------------------------------------------------------------

echo "[+] Checking official PRoot..."

if [ -s "$PROOT_BIN" ] && "$PROOT_BIN" --version >/dev/null 2>&1; then
    echo "[+] Existing PRoot binary is valid."
else
    echo "[+] Downloading latest official PRoot x86_64..."

    rm -f "$PROOT_BIN"

    if command -v curl >/dev/null 2>&1; then
        curl \
            -fL \
            --retry "$MAX_RETRIES" \
            --retry-delay 1 \
            --connect-timeout "$TIMEOUT" \
            --max-time 300 \
            -o "$PROOT_BIN" \
            "$PROOT_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget \
            --tries="$MAX_RETRIES" \
            --timeout="$TIMEOUT" \
            --no-hsts \
            -O "$PROOT_BIN" \
            "$PROOT_URL"
    else
        printf "${RED}[-] Neither curl nor wget is installed.${RESET}\n"
        exit 1
    fi

    if [ $? -ne 0 ] || [ ! -s "$PROOT_BIN" ]; then
        printf "${RED}[-] Failed to download official PRoot.${RESET}\n"
        rm -f "$PROOT_BIN"
        exit 1
    fi

    chmod 755 "$PROOT_BIN"
fi

# ------------------------------------------------------------------------------
# Validate PRoot
# ------------------------------------------------------------------------------

echo "[+] Checking PRoot binary..."

if ! "$PROOT_BIN" --version >/dev/null 2>&1; then
    printf "${RED}[-] PRoot binary failed validation.${RESET}\n"
    file "$PROOT_BIN" 2>/dev/null || true
    "$PROOT_BIN" --version 2>&1 || true
    exit 1
fi

PROOT_VERSION="$("$PROOT_BIN" --version 2>/dev/null)"

echo "[+] PRoot:"
echo "$PROOT_VERSION"
echo

# ------------------------------------------------------------------------------
# Install Ubuntu 26.04 LTS Base
# ------------------------------------------------------------------------------

if [ ! -x "$ROOTFS_DIR/bin/bash" ]; then

    echo "[+] Ubuntu rootfs not found or incomplete."
    echo "[+] Installing Ubuntu 26.04 LTS Base AMD64..."
    echo

    rm -rf "$ROOTFS_DIR"
    mkdir -p "$ROOTFS_DIR"

    rm -f /tmp/ubuntu-base-26.04.tar.gz

    if command -v curl >/dev/null 2>&1; then
        curl \
            -fL \
            --retry "$MAX_RETRIES" \
            --retry-delay 1 \
            --connect-timeout "$TIMEOUT" \
            --max-time 900 \
            -o /tmp/ubuntu-base-26.04.tar.gz \
            "$UBUNTU_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget \
            --tries="$MAX_RETRIES" \
            --timeout="$TIMEOUT" \
            --no-hsts \
            -O /tmp/ubuntu-base-26.04.tar.gz \
            "$UBUNTU_URL"
    else
        printf "${RED}[-] Neither curl nor wget is installed.${RESET}\n"
        exit 1
    fi

    if [ $? -ne 0 ] || [ ! -s /tmp/ubuntu-base-26.04.tar.gz ]; then
        printf "${RED}[-] Failed to download Ubuntu 26.04 LTS.${RESET}\n"
        exit 1
    fi

    echo "[+] Extracting Ubuntu..."

    if ! tar -xzf /tmp/ubuntu-base-26.04.tar.gz -C "$ROOTFS_DIR"; then
        printf "${RED}[-] Failed to extract Ubuntu rootfs.${RESET}\n"
        exit 1
    fi

    if [ ! -x "$ROOTFS_DIR/bin/bash" ]; then
        printf "${RED}[-] Extracted rootfs is invalid.${RESET}\n"
        exit 1
    fi

    rm -f /tmp/ubuntu-base-26.04.tar.gz
fi

# ------------------------------------------------------------------------------
# Prepare rootfs
# ------------------------------------------------------------------------------

mkdir -p "$ROOTFS_DIR/root"
mkdir -p "$ROOTFS_DIR/home/user"

touch "$ROOTFS_DIR/root/.bash_history"
touch "$ROOTFS_DIR/home/user/.bash_history"

rm -f "$ROOTFS_DIR/etc/resolv.conf"

printf '%s\n' \
    'nameserver 1.1.1.1' \
    'nameserver 1.0.0.1' \
    > "$ROOTFS_DIR/etc/resolv.conf"

printf '127.0.0.1\tlocalhost\n127.0.1.1\tubuntu\n' \
    > "$ROOTFS_DIR/etc/hosts"

printf 'ubuntu\n' > "$ROOTFS_DIR/etc/hostname"

# ------------------------------------------------------------------------------
# Start Ubuntu
# ------------------------------------------------------------------------------

echo
echo "___________________________________________________"
echo
printf "           ${CYAN}-----> Mission Completed! <----${RESET}\n"
echo
echo "[+] Ubuntu : 26.04 LTS"
echo "[+] Arch   : x86_64"
echo "[+] PRoot  : $PROOT_VERSION"
echo
echo "[+] Starting Ubuntu..."
echo

exec "$PROOT_BIN" \
    --rootfs="$ROOTFS_DIR" \
    --cwd=/root \
    --change-id=1 \
    --bind=/dev \
    --bind=/proc \
    --bind=/sys \
    --bind=/etc/resolv.conf \
    --kill-on-exit=1 \
    /usr/bin/env \
        HOME=/root \
        USER=root \
        LOGNAME=root \
        SHELL=/bin/bash \
        HISTFILE=/root/.bash_history \
        HISTFILESIZE=10000 \
        HISTSIZE=10000 \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        PS1='root@ubuntu:\w# ' \
        HOSTNAME=ubuntu \
        /bin/bash --noprofile --norc -i
