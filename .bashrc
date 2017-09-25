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
SSH_ENV="$HOME/.ssh/environment"

function start_agent {
     echo "Initialising new SSH agent..."
     /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
     echo succeeded
     chmod 600 "${SSH_ENV}"
     . "${SSH_ENV}" > /dev/null
     /usr/bin/ssh-add ~/.ssh/id_rsa;
}

# Source SSH settings, if applicable

if [ -f "${SSH_ENV}" ]; then
     . "${SSH_ENV}" > /dev/null
     #ps ${SSH_AGENT_PID} doesn't work under cywgin
     ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
         start_agent;
     }
else
     start_agent;
fi

alias rsync='rsync --stats --progress'
