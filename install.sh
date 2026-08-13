#!/bin/bash  
  
set -u  
  
BASE_DIR="$(pwd)"  
ROOTFS_DIR="$BASE_DIR/ubuntu"  
PROOT_BIN="$BASE_DIR/proot-x86_64"  
  
MAX_RETRIES=50  
TIMEOUT=10  
  
PROOT_URL="https://raw.githubusercontent.com/padarham9-ui/Rootfree/main/proot-v5.2.0-alpha-x86_64-static"  
UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/resolute/release/ubuntu-base-26.04-base-amd64.tar.gz"  
  
CYAN='\033[0;36m'  
RED='\033[0;31m'  
RESET='\033[0m'  
  
ARCH="$(uname -m)"  
  
# فقط x86_64  
if [ "$ARCH" != "x86_64" ]; then  
    printf "${RED}Unsupported CPU architecture: %s${RESET}\n" "$ARCH"  
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
  
echo "[+] Checking PRoot binary..."  
  
if ! "$PROOT_BIN" --version >/dev/null 2>&1; then  
    printf "${RED}[-] PRoot binary failed validation.${RESET}\n"  
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
# Install Ubuntu 26.04 LTS Base  
# ------------------------------------------------------------------------------  
  
if [ ! -x "$ROOTFS_DIR/bin/bash" ]; then  
  
    echo "[+] Ubuntu rootfs not found or incomplete."  
    echo "[+] Installing Ubuntu 26.04 LTS Base AMD64..."  
    echo  
  
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
        printf "${RED}[-] Failed to download Ubuntu 26.04 LTS.${RESET}\n"  
        exit 1  
    fi  
  
    echo "[+] Extracting Ubuntu..."  
  
    tar -xzf /tmp/ubuntu-base-26.04.tar.gz -C "$ROOTFS_DIR"  
  
    if [ $? -ne 0 ] || [ ! -x "$ROOTFS_DIR/bin/bash" ]; then  
        printf "${RED}[-] Failed to extract a valid Ubuntu rootfs.${RESET}\n"  
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
  
# DNS  
rm -f "$ROOTFS_DIR/etc/resolv.conf"  
  
printf '%s\n' \  
    'nameserver 1.1.1.1' \  
    'nameserver 1.0.0.1' \  
    > "$ROOTFS_DIR/etc/resolv.conf"  
  
# Basic identity files  
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
echo "[+] PRoot  : $("$PROOT_BIN" --version 2>/dev/null)"  
echo  
echo "[+] Starting Ubuntu..."  
echo  
  
exec "$PROOT_BIN" \  
    --rootfs="$ROOTFS_DIR" \  
    --cwd=/root \  
    --change-id \  
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
        HISTFILESIZE=10000 \  
        HISTSIZE=10000 \  
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \  
        PS1='root@ubuntu:\w# ' \  
        HOSTNAME=ubuntu \  
        /bin/bash --noprofile --norc -i
