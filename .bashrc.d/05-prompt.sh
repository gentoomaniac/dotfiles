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

if [ ! -f "$GOPATH/bin/powerline-go" ]; then
    go install github.com/gentoomaniac/powerline-go/cmd/powerline-go@latest
fi

function _powerline() {
    if [[ "$(hostname)" =~ ^(marco-mbrk-ubuntu|fizzbuzz)$ ]]; then
        MODULES="time,venv,ssh,cwd,perms,git,kube,hg,jobs,exit,root"
    else
        MODULES="time,user,host,venv,ssh,cwd,perms,git,kube,hg,jobs,exit,root"
    fi
    PRIORITY="time,root,user,host,cwd,ssh,perms,git-branch,git-status,hg,jobs,exit,cwd-path"

    #PS1="$(powerline-go --error=$? --jobs=$(jobs -p | wc -l) --newline --theme=gruvbox --modules=${MODULES} --hostname-only-if-ssh --colorize-hostname)"
    PS1="$(powerline-go --prev-error $? --jobs "$(jobs -p | wc -l)" --newline --modules "${MODULES}" --priority "${PRIORITY}"--hostname-only-if-ssh --colorize-hostname)"

    # Uncomment the following line to automatically clear errors after showing
    # them once. This not only clears the error for powerline-go, but also for
    # everything else you run in that shell. Don't enable this if you're not
    # sure this is what you want.

    #set "?"
}

if [ "$TERM" != "linux" ] && [ -f "$GOPATH/bin/powerline-go" ]; then
    PROMPT_COMMAND="_powerline;"
fi
