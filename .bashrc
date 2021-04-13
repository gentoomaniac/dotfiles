#! /usr/bin/env bash

# GIT prompt
prompt_git() {
    git branch &>/dev/null || return 1
    HEAD="$(git symbolic-ref HEAD 2>/dev/null)"
    BRANCH="${HEAD#refs/heads/}"
    git status -s | grep -q '^ M' && STATUS+="!"
    git status -s | grep -q '^??' && STATUS+="+"
    if [ -z "${STATUS}" ]; then
        GIT_STATUS="(git:${BRANCH:-unknown}) "
    else
        GIT_STATUS="(git:${BRANCH:-unknown}:${STATUS}) "
    fi
    echo -n "${GIT_STATUS}"
}

gitprompt() {
    if echo "${PS1}" | grep -q "prompt_git"; then
        PS1="${BASEPROMPT}"
    else
        PS1="${GITPROMPT}"
    fi
}

# shellcheck disable=SC2016
BASEPROMPT='\[\033[1m\]\[\033[38;5;1m\][\[\033[38;5;231m\]\t\[\033[38;5;1m\]] $([ "${UID}" -eq 0 ] && echo "\[\033[38;5;9m\]" || echo "\[\033[38;5;10m\]")\u\[\033[38;5;12m\]@\[\033[38;5;10m\]\h \[\033[38;5;12m\]\W/ \[\033[38;5;11m\]>\[\033[0m\] '
# shellcheck disable=SC2016
GITPROMPT='\[\033[1m\]\[\033[38;5;1m\][\[\033[38;5;231m\]\t\[\033[38;5;1m\]] $([ "${UID}" -eq 0 ] && echo "\[\033[38;5;9m\]" || echo "\[\033[38;5;10m\]")\u\[\033[38;5;12m\]@\[\033[38;5;10m\]\h \[\033[38;5;12m\]\W/ \[\033[38;5;11m\]$(prompt_git)>\[\033[0m\] '
PS1="${GITPROMPT}"

# ssh-agent config
function start_ssh_agent {
    SSH_ENV_PREFIX=${1:-default}; shift
    SSH_ENV="$HOME/.ssh/${SSH_ENV_PREFIX}-env"

    if [ -f "${SSH_ENV}" ]; then
        # shellcheck disable=SC1090
        . "${SSH_ENV}" > /dev/null
    fi

    if [ -z "${SSH_AGENT_PID}" ] || [[ ! "$(pidof ssh-agent)" =~ "${SSH_AGENT_PID}" ]]; then
        echo "Initialising new SSH agent for '${SSH_ENV_PREFIX}' ..."
        ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
        chmod 600 "${SSH_ENV}"
        # shellcheck disable=SC1090
        . "${SSH_ENV}" > /dev/null
        for key in "${@:-${HOME}/.ssh/id_rsa}"; do
            ssh-add "${key}";
        done
        ssh-add -l
    fi
    # shellcheck disable=SC1117
    [ ! -z "${SSH_ENV_PREFIX}" ] && PS1="\[\e[31m\](\[\e[m\]\[\e[37;40m\]${SSH_ENV_PREFIX}\[\e[m\]\[\e[31m\])\[\e[m\] ${GITPROMPT}"
}

# functions to setup seperate environments
function setup-env {
    case ${1} in

        private)
            export GIT_CONFIG=~/.gitconfig-private
            start_ssh_agent private ~/.ssh/id_rsa
            ;;

        trustly)
            start_ssh_agent trustly ~/.ssh/trustly.id_rsa
            ;;

        *)
            start_ssh_agent default
            ;;
    esac
}

# aliases
alias rsync='rsync --stats --progress'


