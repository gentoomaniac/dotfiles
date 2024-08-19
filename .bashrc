if [ -d ~/.bashrc.d ]; then
  for bash_inc in $(ls ~/.bashrc.d/*.sh ); do
    source "${bash_inc}"
  done
fi

