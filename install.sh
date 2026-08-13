#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH="$PATH:$HOME/.local/usr/bin"

max_retries=50
timeout=5
ARCH=$(uname -m)

# فقط x86_64
if [ "$ARCH" != "x86_64" ]; then
  printf "Unsupported CPU architecture: %s\n" "$ARCH"
  exit 1
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                              Ubuntu 26.04 LTS"
  echo "#                              PRoot x86_64"
  echo "#"
  echo "#######################################################################################"

  printf "Do you want to install Ubuntu 26.04 LTS? (YES/no): "
  read install_ubuntu
fi

case "$install_ubuntu" in
  [yY][eE][sS])
    echo "[+] Downloading Ubuntu 26.04 LTS Base (AMD64)..."

    wget \
      --tries="$max_retries" \
      --timeout="$timeout" \
      --no-hsts \
      -O /tmp/rootfs.tar.gz \
      "https://cdimage.ubuntu.com/ubuntu-base/releases/26.04/release/ubuntu-base-26.04-base-amd64.tar.gz"

    if [ $? -ne 0 ] || [ ! -s /tmp/rootfs.tar.gz ]; then
      echo "[-] Failed to download Ubuntu 26.04 LTS."
      exit 1
    fi

    echo "[+] Extracting Ubuntu 26.04 LTS..."
    tar -xzf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"

    if [ $? -ne 0 ]; then
      echo "[-] Failed to extract Ubuntu rootfs."
      exit 1
    fi
    ;;
  *)
    echo "Skipping Ubuntu installation."
    ;;
esac

if [ ! -e "$ROOTFS_DIR/.installed" ]; then

  mkdir -p "$ROOTFS_DIR/usr/local/bin"

  echo "[+] Downloading PRoot v5.2.0-alpha x86_64 static..."

  wget \
    --tries="$max_retries" \
    --timeout="$timeout" \
    --no-hsts \
    -O "$ROOTFS_DIR/usr/local/bin/proot" \
    "https://raw.githubusercontent.com/padarham9-ui/Rootfree/main/proot-v5.2.0-alpha-x86_64-static"

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm -f "$ROOTFS_DIR/usr/local/bin/proot"

    wget \
      --tries="$max_retries" \
      --timeout="$timeout" \
      --no-hsts \
      -O "$ROOTFS_DIR/usr/local/bin/proot" \
      "https://raw.githubusercontent.com/padarham9-ui/Rootfree/main/proot-v5.2.0-alpha-x86_64-static"

    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      break
    fi

    sleep 1
  done

  chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"

  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" \
    > "$ROOTFS_DIR/etc/resolv.conf"

  rm -f /tmp/rootfs.tar.gz

  touch "$ROOTFS_DIR/.installed"
fi

CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET_COLOR='\033[0m'

display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
}

clear
display_gg

"$ROOTFS_DIR/usr/local/bin/proot" \
  --rootfs="$ROOTFS_DIR" \
  -0 \
  -w "/root" \
  -b /dev \
  -b /sys \
  -b /proc \
  -b /etc/resolv.conf \
  --kill-on-exit
