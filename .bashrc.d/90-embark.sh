# Embark work setup, only on the work machine.
[[ $HOSTNAME == mbrk-gentoo ]] || return 0

export KUBECONFIG="$KUBECONFIG:/home/marco/.kube/embark"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/marco/bin/google-cloud-sdk/path.bash.inc' ]; then . '/home/marco/bin/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/marco/bin/google-cloud-sdk/completion.bash.inc' ]; then . '/home/marco/bin/google-cloud-sdk/completion.bash.inc'; fi

eval "$(direnv hook bash)"

source <(kubectl completion bash)

