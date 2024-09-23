alias rsync='rsync --stats --progress'

# convenience for neovim
n() {
    if [ -z "$1" ]; then
        nvim .
    else
        nvim "$1"
    fi
}
