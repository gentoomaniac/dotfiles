if [ "${DISTRIB_ID}" == "Gentoo" ]; then
    function kupgrade {
        eselect kernel list
        echo -n "Select kernel: "; read selected_kernel
        sudo eselect kernel set "${selected_kernel}"
        if [ $? -ne 0 ]; then
            return
        fi

        pushd /usr/src/linux || exit
        zcat /proc/config | sudo tee .config >/dev/null
        sudo make olddeconfig

        kupdate

        sudo grub-mkconfig -o /boot/grub/grub.cfg && \
            sudo sed -i 's#root=ZFS=/gentoo/root ##g' /boot/grub/grub.cfg
        popd || exit
    }

    function kupdate {
        local BOOT_SNAP_NAME="pre-kupdate-$(date +"%Y-%m-%d-%H%M%S")"
        if zfs list bootpool >/dev/null 2>&1; then
            echo ">>> ZFS: Snapshotting bootpool: bootpool@${BOOT_SNAP_NAME}"
            sudo zfs snapshot -r -o "com.gentoo:command=kupdate (manual)" "bootpool@${BOOT_SNAP_NAME}"
        fi

        pushd /usr/src/linux || exit

        local KVER=$(make -s kernelrelease)
        local DATESTAMP=$(date +"%Y-%m-%d-%H%M%S")
        local CONFIG_ARCHIVE="/boot/config-${KVER}-${DATESTAMP}"

        if [ -f .config ]; then
            echo ">>> Archiving kernel config to ${CONFIG_ARCHIVE}..."
            sudo cp .config "${CONFIG_ARCHIVE}"

            echo ">>> Linking /boot/config-${KVER} to archive..."
            sudo ln -sf "${CONFIG_ARCHIVE}" "/boot/config-${KVER}"

            sudo cp .config "../config-$(readlink ../linux)-${DATESTAMP}"
        fi

        local CORES=$(nproc)
        local JOBS=$(( CORES > 2 ? CORES - 2 : 1 ))
        echo ">>> Detected $CORES cores. Building with -j$JOBS..."

        sudo make -j${JOBS} && \
            sudo make install && \
            sudo make modules_install

        REBUILD_MODULES="FALSE"
        if qlist -I sys-fs/zfs > /dev/null 2>&1 || qlist -I sys-fs/zfs-kmod > /dev/null 2>&1; then
            echo ">>> ZFS detected..."
            REBUILD_MODULES="TRUE"
        fi

        DRACUT_NVIDIA=""
        if lspci | grep -qi "nvidia" && qlist -I x11-drivers/nvidia-drivers > /dev/null 2>&1; then
            echo ">>> nvidia-drivers detected..."
            REBUILD_MODULES="TRUE"
        fi

        if [ "${REBUILD_MODULES}" == "TRUE" ]; then
            echo ">>> Rebuilding modules..."
            sudo emerge @module-rebuild
        fi

        update-initrd "${KVER}"

        popd || exit
    }

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
        sudo depmod -a "${KVER}"

        echo ">>> Building initramfs for ${KVER}..."
        # --force: Overwrite existing images
        # --hostonly: precise image for this machine
        # --omit: Strip networking and NVIDIA to keep it small (~30MB)
        sudo dracut --hostonly --kver "${KVER}" --force \
            --add-drivers "i915" \
            --omit "nfs nvidia nvidia_modeset nvidia_uvm nvidia_drm"
    }

    # aliases
    alias update='sudo emerge --sync'
    alias upgrade='sudo emerge --ask --verbose --update --newuse --deep --keep-going --with-bdeps=y --getbinpkg @world'
    alias depclean='sudo emerge --ask --verbose --depclean'
    alias snaps='zfs list -t snapshot -o name,used,refer,creation,com.gentoo:command'
    alias zlock-clear="sudo rm -f /var/lock/portage_zfs_*.lock /var/tmp/.emerge_cmd_metadata"

    source /usr/share/bash-completion/completions/fzf
    source /usr/share/fzf/key-bindings.bash

fi
