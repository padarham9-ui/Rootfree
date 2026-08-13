exec "$PROOT_BIN" \
    --rootfs="$ROOTFS_DIR" \
    --cwd=/root \
    --change-id=1 \
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
