source /etc/bash_completion

if [ -d "${HOME}/.bash_completion.d" ]; then
    for file in $(ls "${HOME}/.bash_completion.d"); do
        source "${file}"
    done
fi

