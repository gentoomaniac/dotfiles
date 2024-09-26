alias ls="ls --color -h --group-directories-first"
alias rsync='rsync --stats --progress'
alias dive="docker run -ti --rm  -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive"

# convenience for neovim
n() {
    if [ -z "$1" ]; then
        nvim .
    else
        nvim "$1"
    fi
}
