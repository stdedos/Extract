#!/bin/sh

# # command -V _tar | bat -lsh
#
# /snap/core/7713/usr/share/bash-completion/completions/tar
# /usr/share/bash-completion/completions/tar

. ./extract.sh

_extract() {
	# local extractables
	extractables="$(extractable_extesions)"
	extractables="@(${extractables%?})"
}
