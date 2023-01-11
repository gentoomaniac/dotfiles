#! /usr/bin/env bash

# prompt
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
BLACK="\[$(tput setaf 0)\]"
RED="\[$(tput setaf 196)\]"
GREEN="\[$(tput setaf 2)\]"
GREENB="\[$(tput setaf 118)\]"
BROWN="\[$(tput setaf 3)\]"
YELLOW="\[$(tput setaf 227)\]"
LIGHTBLUE="\[$(tput setaf 033)\]"
BLUE="\[$(tput setaf 4)\]"
DARKBLUE="\[$(tput setaf 021)\]"
MAGENTA="\[$(tput setaf 5)\]"
CYAN="\[$(tput setaf 6)\]"
WHITE="\[$(tput setaf 7)\]"
ORANGE="\[$(tput setaf 202)\]"
RESET="\[$(tput sgr0)\]"
BOLD="\[$(tput bold)\]"
SMUL="\[$(tput smul)\]"
RMUL="\[$(tput rmul)\]"
BLINK="\[$(tput blink)\]"
SMSO="\[$(tput smso)\]"
RMSO="\[$(tput rmso)\]"

parse_kube_ctx() {
  cat ~/.kube/config 2> /dev/null | \
  grep "^current-context:" | \
  sed "s/^current-context: //" | \
  grep -v '""' | \
  sed -E -e "s/tink\.teleport\.sh-//" \
         -e "s/(minikube)/${CYAN}[\1]${RESET} /" \
         -e "s/(.+-testing)/${GREEN}[\1]${RESET} /" \
         -e "s/(.+-(staging|preprod))/${ORANGE}[\1]${RESET} /" \
         -e "s/(.+-production)/${RED}[\1]${RESET} /"
         #-e "s/(.+-production)/$(tput setaf 9)[\1]$(tput sgr0)/"
}

prompt_git() {
    git branch &>/dev/null || return 1
    HEAD="$(git symbolic-ref HEAD 2>/dev/null)"
    BRANCH="${HEAD#refs/heads/}"
    git status -s | grep -q '^ M' && STATUS+="!"
    git status -s | grep -q '^??' && STATUS+="+"
    if [ -z "${STATUS}" ]; then
        GIT_STATUS="${YELLOW}(git:${BRANCH:-unknown}) "
    else
        GIT_STATUS="${YELLOW}(git:${BRANCH:-unknown}:${STATUS}) "
    fi
    echo -n "${GIT_STATUS}"
}

function build_prompt() {
    PS1="${BOLD}"
    PS1+="$([ ! -z "${SSH_ENV_PREFIX}" ] && echo "${RED}(${WHITE}${SSH_ENV_PREFIX}${RED}) ")"    # SSH env prefix
    PS1+="${RED}[${WHITE}\t${RED}] "                                                             # timestamp
    PS1+="$([ "${UID}" -eq 0 ] && echo "${RED}" || echo "${GREEN}")\u${BLUE}@${GREEN}\h "        # user@host
    PS1+="${BLUE}\W/ "                                                                           # cwd
    PS1+="$(prompt_git)"                                                                         # GIT status
    PS1+="$(parse_kube_ctx)"                                                                     # k8s context
    PS1+="${BOLD}${YELLOW}>${RESET} "                                                            # prompt indicator
}

PROMPT_COMMAND=build_prompt

# ssh-agent config
function start_ssh_agent {
    export SSH_ENV_PREFIX=${1:-default}; shift
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
            expect << EOF
  spawn ssh-add ${key}
  expect "Enter passphrase"
  send "$(get_password_from_keepass "${SSH_ENV_PREFIX}-id_rsa")\r"
  expect eof
EOF
        done
        ssh-add -l
    fi
}


# functions to setup seperate environments
function setup-env {
    case ${1} in

        private)
            export GIT_CONFIG=~/.gitconfig-private
            start_ssh_agent private ~/.ssh/id_rsa
            ;;

        *)
            start_ssh_agent default
            ;;
    esac
}

# aliases
alias rsync='rsync --stats --progress'
