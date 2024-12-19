if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

if [ -d "${HOME}/.bash_completion.d" ]; then
    for file in $(ls "${HOME}/.bash_completion.d"); do
        source "${file}"
    done
fi

if [ ! -z "$(which fzf)" ]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
else
    echo '!! `fzf` not found'
fi

