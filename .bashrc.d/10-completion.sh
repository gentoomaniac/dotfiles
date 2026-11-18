# interactive only, see ~/.bashrc
[[ $- == *i* ]] || return

if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

if [ -d "${HOME}/.bash_completion.d" ]; then
    for file in "${HOME}/.bash_completion.d"/*; do
        source "${file}"
    done
fi

# fzf key bindings: Debian path first, then Arch/Gentoo
for file in /usr/share/doc/fzf/examples/key-bindings.bash /usr/share/fzf/key-bindings.bash; do
    if [ -f "${file}" ]; then
        source "${file}"
        break
    fi
done

