if [ "${DISTRIB_ID}" == "Gentoo" ]; then
    # kupgrade and kupdate run as root in a separate bash: sudo asks once at
    # the start, so a long build can't outlive the sudo timeout. declare -f
    # hands the function definitions over to that shell. Being its own
    # process, its cd can't leak into this shell and a failing step can
    # simply exit 1. So only call _kupgrade/_kupdate via _kernel_as_root:
    # run directly, their exit would close the interactive shell.
    function _kernel_as_root {
        sudo bash -c "$(declare -f _kupgrade _kupdate update-initrd); $1"
    }

    function kupgrade { _kernel_as_root _kupgrade; }
    function kupdate { _kernel_as_root _kupdate; }

    function _kupgrade {
        eselect kernel list
        echo -n "Select kernel: "; read -r selected_kernel
        eselect kernel set "${selected_kernel}" || exit 1

        cd /usr/src/linux || exit 1
        zcat /proc/config.gz > .config || exit 1
        make olddefconfig || exit 1

        _kupdate || exit 1

        grub-mkconfig -o /boot/grub/grub.cfg || exit 1
        sed -i 's#root=ZFS=/gentoo/root ##g' /boot/grub/grub.cfg
    }

    function _kupdate {
        local BOOT_SNAP_NAME
        BOOT_SNAP_NAME="pre-kupdate-$(date +"%Y%m%d-%H%M%S")"
        if zfs list bootpool >/dev/null 2>&1; then
            echo ">>> ZFS: Snapshotting bootpool: bootpool@${BOOT_SNAP_NAME}"
            zfs snapshot -r -o "com.gentoo:command=kupdate (manual)" "bootpool@${BOOT_SNAP_NAME}" || exit 1
        fi

        cd /usr/src/linux || exit 1

        local KVER DATESTAMP
        KVER=$(make -s kernelrelease) || exit 1
        DATESTAMP=$(date +"%Y-%m-%d-%H%M%S")
        local CONFIG_ARCHIVE="/boot/config-${KVER}-${DATESTAMP}"

        if [ -f .config ]; then
            echo ">>> Archiving kernel config to ${CONFIG_ARCHIVE}..."
            cp .config "${CONFIG_ARCHIVE}" || exit 1

            echo ">>> Linking /boot/config-${KVER} to archive..."
            ln -sf "${CONFIG_ARCHIVE}" "/boot/config-${KVER}" || exit 1

            cp .config "../config-$(readlink ../linux)-${DATESTAMP}" || exit 1
        fi

        local CORES
        CORES=$(nproc)
        local JOBS=$(( CORES > 2 ? CORES - 2 : 1 ))
        echo ">>> Detected $CORES cores. Building with -j$JOBS..."

        make -j"${JOBS}" || exit 1
        make modules_install || exit 1

        local REBUILD_MODULES="FALSE"
        if qlist -I sys-fs/zfs > /dev/null 2>&1 || qlist -I sys-fs/zfs-kmod > /dev/null 2>&1; then
            echo ">>> ZFS detected..."
            REBUILD_MODULES="TRUE"
        fi

        if lspci | grep -qi "nvidia" && qlist -I x11-drivers/nvidia-drivers > /dev/null 2>&1; then
            echo ">>> nvidia-drivers detected..."
            REBUILD_MODULES="TRUE"
        fi

        if [ "${REBUILD_MODULES}" == "TRUE" ]; then
            echo ">>> Rebuilding modules..."
            emerge @module-rebuild || exit 1
        fi

        update-initrd "${KVER}" || exit 1

        # install the kernel last, after its initramfs exists
        make install || exit 1
    }

    # Also usable on its own as a normal user, hence the sudo calls (as root,
    # from _kupdate, they run without asking).
    function update-initrd () {
        local KVER=${1}

        if [ -z "${KVER}" ]; then
            echo "Error: You must specify a kernel version."
            return 1
        fi

        if [ ! -d "/lib/modules/${KVER}" ]; then
            echo "Error: Kernel version ${KVER} doesn't seem to exist in /lib/modules."
            return 1
        fi

        # Ensure module dependencies are up to date before building
        echo ">>> Refreshing module dependencies..."
        sudo depmod -a "${KVER}" || return 1

        echo ">>> Building initramfs for ${KVER}..."
        # --force: Overwrite existing images
        # --hostonly: precise image for this machine
        # --omit: Strip networking and NVIDIA to keep it small (~30MB)
        local DRACUT_ARGS=(--hostonly --kver "${KVER}" --force)
        # i915 is only needed (and only available) on hosts with an Intel GPU:
        # vendor 8086 (Intel) with PCI class 03xx (display controller)
        if lspci -nn -d 8086: | grep -Eq '\[03[0-9a-f]{2}\]'; then
            DRACUT_ARGS+=(--add-drivers "i915")
        fi
        # Explicit output path: without it, dracut only writes to /boot if
        # /boot/kernel-${KVER} already exists, else to /lib/modules/${KVER}/
        # or /efi, where grub-mkconfig doesn't find it and drops the initrd.
        sudo dracut "${DRACUT_ARGS[@]}" \
            --omit "nfs nvidia nvidia_modeset nvidia_uvm nvidia_drm" \
            "/boot/initramfs-${KVER}.img"
    }

    # aliases
    alias update='sudo emerge --sync'
    alias upgrade='sudo emerge --ask --verbose --update --newuse --deep --keep-going --with-bdeps=y --getbinpkg @world'
    alias depclean='sudo emerge --ask --verbose --depclean'
    alias snaps='zfs list -t snapshot -o name,used,refer,creation,com.gentoo:command'
    alias zlock-clear="sudo rm -f /var/lock/portage_zfs_*.lock /var/tmp/.emerge_cmd_metadata"

    if [[ $- == *i* ]]; then
        source /usr/share/bash-completion/completions/fzf
    fi

fi
