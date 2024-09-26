if [ "${DISTRIB_ID}" == "Gentoo" ]; then
    function kupgrade {
        eselect kernel list
        echo -n "Select kernel: "; read selected_kernel
        sudo eselect kernel set ${selected_kernel}
        if [ $? -ne 0 ]; then
            return
        fi

        pushd /usr/src/linux
        zcat /proc/config | sudo tee .config >/dev/null
        yes "" | sudo make oldconfig && \
            sudo make && \
            sudo make install && \
            sudo make modules && \
            sudo make modules_install && \
            sudo emerge @module-rebuild && \
            sudo dracut --hostonly --kver "$(eselect kernel show | sed -n 's/^.*linux-\(.*\)$/\1/p')" --force && \
            sudo grub-mkconfig -o /boot/grub/grub.cfg && \
            sudo sed -i 's#root=ZFS=/gentoo/root ##g' /boot/grub/grub.cfg
    }

    function kupdate {
        pushd /usr/src/linux
        sudo make && \
            sudo make install && \
            sudo make modules && \
            sudo make modules_install && \
            sudo emerge @module-rebuild && \
            sudo dracut --hostonly --kver "$(eselect kernel show | sed -n 's/^.*linux-\(.*\)$/\1/p')" --force
    }

    # aliases
    alias update='sudo emerge --sync'
    alias upgrade='sudo emerge --ask --verbose --update --newuse --deep --keep-going --with-bdeps=y @world'
    alias depclean='sudo emerge --ask --verbose --depclean'
fi
