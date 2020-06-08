#!/bin/bash
#
# This file attempts to remove superfluous files to reduce the size of the
# Golang toolchain archive.  It's based on code and comments in:
#
#    https://github.com/golang/build/blob/master/cmd/release/release.go
#

if [[ ! -f VERSION ]]; then
	printf 'are you in a go release directory?\n' >&2
	exit 1
fi

set -o xtrace

#
# Remove the bootstrap compiler files.
#
rm -rf "pkg/bootstrap"

#
# Remove the obj build cache, which is _huge_.
#
rm -rf "pkg/obj"

#
# Remove the libraries used to build the toolchain commands.
#
rm -rf "pkg/solaris_amd64/cmd"
