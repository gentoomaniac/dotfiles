if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

if [ -d "${HOME}/.bash_completion.d" ]; then
    for file in "${HOME}/.bash_completion.d"/*; do
        source "${file}"
    done
fi

if [ -f "/usr/share/doc/fzf/examples/key-bindings.bash" ]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
fi

