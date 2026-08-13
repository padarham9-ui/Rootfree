#!/bin/sh

set -u

ROOTFS_DIR="$(pwd)/ubuntu"
PROOT_BIN="$(pwd)/proot-x86_64"
MAX_RETRIES=50
TIMEOUT=10

PROOT_URL="https://raw.githubusercontent.com/padarham9-ui/Rootfree/main/proot-v5.2.0-alpha-x86_64-static"
UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/26.04/release/ubuntu-base-26.04-base-amd64.tar.gz"

CYAN='\033[0;36m'
WHITE='\033[0;37m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

ARCH="$(uname -m)"

# فقط x86_64
if [ "$ARCH" != "x86_64" ]; then
    printf "${RED}Unsupported CPU architecture: %s${RESET}\n" "$ARCH"
    printf "This installer supports x86_64 only.\n"
    exit 1
fi

echo "################################################################################"
echo "#"
echo "#                         Ubuntu 26.04 LTS"
echo "#                         PRoot x86_64"
echo "#"
echo "################################################################################"
echo

# ------------------------------------------------------------------------------
# Download PRoot OUTSIDE the rootfs
# ------------------------------------------------------------------------------

if [ ! -x "$PROOT_BIN" ]; then

    echo "[+] Downloading PRoot v5.2.0-alpha x86_64..."

    rm -f "$PROOT_BIN"

    wget \
        --tries="$MAX_RETRIES" \
        --timeout="$TIMEOUT" \
        --no-hsts \
        -O "$PROOT_BIN" \
        "$PROOT_URL"

    if [ $? -ne 0 ] || [ ! -s "$PROOT_BIN" ]; then
        echo
        printf "${RED}[-] Failed to download PRoot.${RESET}\n"
        exit 1
    fi

    chmod 755 "$PROOT_BIN"
fi

# ------------------------------------------------------------------------------
# Validate PRoot binary
# ------------------------------------------------------------------------------

echo "[+] Checking PRoot binary..."

if ! "$PROOT_BIN" --version >/dev/null 2>&1; then
    echo
    printf "${RED}[-] PRoot binary failed the basic test.${RESET}\n"
    echo
    echo "Binary:"
    file "$PROOT_BIN" 2>/dev/null || true
    echo
    echo "Trying to execute:"
    "$PROOT_BIN" --version 2>&1 || true
    exit 1
fi

echo "[+] PRoot:"
"$PROOT_BIN" --version

echo

# ------------------------------------------------------------------------------
# Install Ubuntu 26.04 Base
# ------------------------------------------------------------------------------

if [ ! -f "$ROOTFS_DIR/.installed" ]; then

    printf "Do you want to install Ubuntu 26.04 LTS? (YES/no): "
    read install_ubuntu

    case "$install_ubuntu" in
        [yY][eE][sS])

            mkdir -p "$ROOTFS_DIR"

            echo
            echo "[+] Downloading Ubuntu 26.04 LTS Base AMD64..."
            echo

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

            echo
            echo "[+] Extracting Ubuntu 26.04..."

            tar -xzf /tmp/ubuntu-base-26.04.tar.gz -C "$ROOTFS_DIR"

            if [ $? -ne 0 ]; then
                printf "${RED}[-] Failed to extract Ubuntu rootfs.${RESET}\n"
                exit 1
            fi

            rm -f /tmp/ubuntu-base-26.04.tar.gz

            ;;

        *)
            echo "Skipping Ubuntu installation."
            exit 0
            ;;
    esac

    # --------------------------------------------------------------------------
    # Configure DNS
    # --------------------------------------------------------------------------

    if [ -d "$ROOTFS_DIR/etc" ]; then
        rm -f "$ROOTFS_DIR/etc/resolv.conf"

        printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" \
            > "$ROOTFS_DIR/etc/resolv.conf"
    fi

    touch "$ROOTFS_DIR/.installed"
fi

# ------------------------------------------------------------------------------
# Check rootfs
# ------------------------------------------------------------------------------

if [ ! -d "$ROOTFS_DIR/bin" ] && [ ! -d "$ROOTFS_DIR/usr/bin" ]; then
    printf "${RED}[-] Ubuntu rootfs appears to be invalid.${RESET}\n"
    exit 1
fi

# ------------------------------------------------------------------------------
# Start
# ------------------------------------------------------------------------------

echo
printf "${WHITE}___________________________________________________${RESET}\n"
echo
printf "           ${CYAN}-----> Mission Completed! <----${RESET}\n"
echo
echo
echo "[+] Rootfs : $ROOTFS_DIR"
echo "[+] PRoot  : $PROOT_BIN"
echo "[+] Arch   : $ARCH"
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
    /bin/bash
