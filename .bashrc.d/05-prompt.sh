# prompt
# Determined once here instead of calling hostnamectl on every prompt.
_HOSTNAME="$(hostnamectl hostname)"

if [[ "${_HOSTNAME}" =~ ^(mbrk-gentoo|gentoobox.clients.gentoomaniac.net)$ ]] && [ -f "${HOME}/.config/gh_token" ]; then
    GH_TOKEN="$(cat "${HOME}/.config/gh_token")"
    export GH_TOKEN
fi

# interactive only, see ~/.bashrc
[[ $- == *i* ]] || return

function _powerline() {
    local exit_code=$?
    if [[ "${_HOSTNAME}" =~ ^(mbrk-gentoo|gentoobox.clients.gentoomaniac.net|bumblebee)$ ]]; then
        MODULES="time,venv,ssh,cwd,perms,git,kube,hg,jobs,exit"
    else
        MODULES="time,user,host,venv,ssh,cwd,perms,git,kube,hg,jobs,exit"
    fi
    PRIORITY="time,root,user,host,cwd,ssh,perms,git-branch,git-status,hg,jobs,githubnotifications,exit,cwd-path"

    #PS1="$(powerline-go --error=$? --jobs=$(jobs -p | wc -l) --newline --theme=gruvbox --modules=${MODULES} --hostname-only-if-ssh --colorize-hostname)"
    PS1="$(powerline-go --prev-error="${exit_code}" --jobs "$(jobs -p | wc -l)" --newline --modules "${MODULES}" --priority "${PRIORITY}" --hostname-only-if-ssh --colorize-hostname --shorten-gke-names)"

    # Uncomment the following line to automatically clear errors after showing
    # them once. This not only clears the error for powerline-go, but also for
    # everything else you run in that shell. Don't enable this if you're not
    # sure this is what you want.

    #set "?"
}

if [ "$TERM" != "linux" ] && [ -n "$(which powerline-go)" ]; then
    PROMPT_COMMAND="_powerline;"
fi
