export VAULT_ADDR="https://vault.srv.gentoomaniac.net"

# Append only missing dirs, so nested shells (tmux, nvim, bash) don't grow PATH
for dir in "${HOME}/bin" "${HOME}/.go/bin"; do
    case ":${PATH}:" in
        *":${dir}:"*) ;;
        *) PATH="${PATH}:${dir}" ;;
    esac
done
export PATH

