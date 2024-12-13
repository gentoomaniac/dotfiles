if [ -f /etc/lsb-release ]; then
 source /etc/lsb-release
fi

export GOPATH="${HOME}/.go"

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
        for key in "${@:-${HOME}/.ssh/id_ed25519}"; do
            ssh-add ${key}
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

setup-env

stty -ixon

