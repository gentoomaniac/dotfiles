### GIT prompt
prompt_git() {
    git branch &>/dev/null || return 1
    HEAD="$(git symbolic-ref HEAD 2>/dev/null)"
    BRANCH="${HEAD#refs/heads/}"
    [[ -n "$(git status 2>/dev/null | \
        grep -E 'working (directory)|(tree) clean')" ]] || STATUS="!"
    printf '(git:%s) ' "${BRANCH:-unknown}${STATUS}"
}

gitprompt() {
    if echo $PS1 | grep -q "prompt_git"; then
        PS1="$BASEPROMPT"
    else
        PS1="$GITPROMPT"
    fi
}

BASEPROMPT='\[\033[1m\]\[\033[38;5;1m\][\[\033[38;5;231m\]\t\[\033[38;5;1m\]] $([ "${UID}" -eq 0 ] && echo "\[\033[38;5;9m\]" || echo "\[\033[38;5;10m\]")\u\[\033[38;5;12m\]@\[\033[38;5;10m\]\h \[\033[38;5;12m\]\W/ \[\033[38;5;11m\]>\[\033[0m\] '
GITPROMPT='\[\033[1m\]\[\033[38;5;1m\][\[\033[38;5;231m\]\t\[\033[38;5;1m\]] $([ "${UID}" -eq 0 ] && echo "\[\033[38;5;9m\]" || echo "\[\033[38;5;10m\]")\u\[\033[38;5;12m\]@\[\033[38;5;10m\]\h \[\033[38;5;12m\]\W/ \[\033[38;5;11m\]$(prompt_git)>\[\033[0m\] '
PS1="$GITPROMPT"

### ssh-agent config

#SSH_ENV="$HOME/.ssh/environment"

#function start_ssh-agent {
#     echo "Initialising new SSH agent..."
#     ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
#     chmod 600 "${SSH_ENV}"
#     . "${SSH_ENV}" > /dev/null
#     ssh-add ~/.ssh/id_rsa;
#     ssh-add -l
#}

#if [ -f "${SSH_ENV}" ]; then
#    . "${SSH_ENV}" > /dev/null
#    if [ ! "$(pidof ssh-agent)" == "${SSH_AGENT_PID}" ]; then
#        killall ssh-agent 2>/dev/null
#        start_agent;
#    fi
#else
#     start_ssh-agent;
#fi

### gpg-agent config

function start_gpg-agent {
    gpg-connect-agent updatestartuptty /bye
    SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    export SSH_AUTH_SOCK
}

# Source SSH settings, if applicable
if [ -z "${SSH_AUTH_SOCK}" ]; then
    start_gpg-agent
    if pidof gpg-agent >/dev/null; then
        ssh-add -l
    fi
else
    if [ ! -z "${SSH_AGENT_PID}" ]; then
        SSH_AUTH_SOCK_INFO="${SSH_AGENT_PID}"
    elif pidof gpg-agent >/dev/null; then
        SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
        export SSH_AUTH_SOCK
    else
       SSH_AUTH_SOCK_INFO="$(basename ${SSH_AUTH_SOCK})"
    fi
    ssh-add -l
fi
[ ! -z "${SSH_AUTH_SOCK_INFO}" ] && PS1="\[\e[31m\](\[\e[m\]\[\e[37;40m\]${SSH_AUTH_SOCK_INFO}\[\e[m\]\[\e[31m\])\[\e[m\] ${PS1}"

function private-env {
    export GIT_CONFIG=~/.gitconfig-private
    agent_wrapper -k ~/.ssh/id_rsa bash
}

# aliases
alias rsync='rsync --stats --progress'
alias update='sudo emerge --sync; sudo layman -S'
alias upgrade='sudo emerge --ask --verbose --newuse --changed-use --deep @world'
alias depclean='sudo emerge --ask --verbose --depclean'

# extra variables
PATH="${PATH}:~/.local/bin:/usr/share/google-cloud-sdk/bin"
export PATH
export INPUTRC="~/.inputrc"

# bash completion
source <(kubectl completion bash)
