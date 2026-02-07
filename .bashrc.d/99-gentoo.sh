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
        pushd /usr/src/linux || exit
        [ -f .config ] && sudo cp .config "../config-$(readlink ../linux)-$(date +"%Y-%m-%d-%H%M%S")"

        local CORES=$(nproc)
        local JOBS=$(( CORES > 2 ? CORES - 2 : 1 ))
        echo ">>> Detected $CORES cores. Building with -j$JOBS..."

        sudo make -j${JOBS} && \
            sudo make install && \
            sudo make modules_install

        REBUILD_MODULES="FALSE"

        if qlist -I sys-fs/zfs > /dev/null 2>&1 || qlist -I sys-fs/zfs-kmod > /dev/null 2>&1; then
            echo ">>> ZFS detected. Rebuilding modules..."
            REBUILD_MODULES="TRUE"
        fi

        DRACUT_NVIDIA=""
        if lspci | grep -qi "nvidia" && qlist -I x11-drivers/nvidia-drivers > /dev/null 2>&1; then
            echo ">>> NVIDIA hardware and driver detected"
            DRACUT_NVIDIA="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
            REBUILD_MODULES="TRUE"
        fi

        if [ "${REBUILD_MODULES}" == "TRUE" ]; then
            sudo emerge @module-rebuild
        fi

        LOCAL_KVER=$(make -s kernelrelease)
        sudo depmod -a "${LOCAL_KVER}"

        echo ">>> Building initramfs for $LOCAL_KVER..."
        sudo dracut --hostonly --kver "$LOCAL_KVER" --force \
            --install "/lib/modules/$LOCAL_KVER/video/*.ko" \
            --add-drivers "${DRACUT_NVIDIA} i915" \
            --omit "nfs"

        popd || exit
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
