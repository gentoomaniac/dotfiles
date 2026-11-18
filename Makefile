# Shell files maintained here (vendored .bash_completion.d is left out).
SHELL_FILES := .bashrc $(wildcard .bashrc.d/*.sh) etc/portage/bashrc portage.bashrc usr/local/sbin/emerge usr/local/sbin/zfs-snapshots

.PHONY: check lint syntax

check: syntax lint

# bash -n: parse only, catches syntax errors shellcheck may not.
syntax:
	@for f in $(SHELL_FILES); do bash -n "$$f" || exit 1; done

# -s bash: the bashrc files have no shebang.
# SC1090/SC1091: sourced system files (lsb-release, completions) are not in this repo.
lint:
	shellcheck -s bash -e SC1090,SC1091 $(SHELL_FILES)
