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
        yes "" | sudo make oldconfig && \
            sudo make -j12 && \
            sudo make install && \
            sudo make -j12 modules && \
            sudo make modules_install && \
            sudo emerge @module-rebuild && \
            sudo dracut --hostonly --kver "$(eselect kernel show | sed -n 's/^.*linux-\(.*\)$/\1/p')" --force && \
            sudo grub-mkconfig -o /boot/grub/grub.cfg && \
            sudo sed -i 's#root=ZFS=/gentoo/root ##g' /boot/grub/grub.cfg
        popd || exit
    }

    function kupdate {
        pushd /usr/src/linux || exit
        [ -f .config ] && sudo cp .config "../config-$(readlink ../linux)-$(date +"%Y-%m-%d-%H%M%S")"
        sudo make -j12 && \
            sudo make install && \
            sudo make -j12 modules && \
            sudo make modules_install && \
            sudo emerge @module-rebuild && \
            sudo dracut --hostonly --kver "$(eselect kernel show | sed -n 's/^.*linux-\(.*\)$/\1/p')" --force
        popd || exit
    }

    # aliases
    alias update='sudo emerge --sync'
    alias upgrade='sudo emerge --ask --verbose --update --newuse --deep --keep-going --with-bdeps=y --getbinpkg @world'
    alias depclean='sudo emerge --ask --verbose --depclean'

    GH_TOKEN="$(cat "${HOME}/.config/gh_classic_token")"
    export GH_TOKEN

    source /usr/share/bash-completion/completions/fzf
    source /usr/share/fzf/key-bindings.bash

fi
