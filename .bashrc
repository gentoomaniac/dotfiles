# Every file is sourced, also by non-interactive shells (ssh host cmd, scp),
# so the environment is the same there. Interactive-only parts (prompt,
# completion, key bindings, stty) check [[ $- == *i* ]] themselves: whole
# files return early, single lines sit in an if.
if [ -d ~/.bashrc.d ]; then
  for bash_inc in ~/.bashrc.d/*.sh; do
    source "${bash_inc}"
  done
fi
