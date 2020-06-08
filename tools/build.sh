#!/bin/bash

dir=$(cd "$(dirname "$0")/.." && pwd)

function fatal {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

function usage {
	printf 'usage: %s [-f] BOOTSTRAP_VER BUILD_VER\n' "$0" >&2
	exit 2
}

function force {
	[[ "$flag_f" == "true" ]]
}

flag_f=false
while getopts 'f' 'opt'; do
	case "$opt" in
	f)
		flag_f=true
		;;
	?)
		usage
		;;
	esac
done
shift $(( OPTIND - 1 ))
if (( $# != 2 )); then
	usage
fi

oldver=$1
newver=$2


oldgoroot="/opt/go/$oldver"
if [[ ! -x "$oldgoroot/bin/go" ]]; then
	fatal "go version $oldver not at $oldgoroot"
fi

work="$dir/work/$newver"
printf 'workdir: %s\n' "$work"
if [[ -e "$work" ]]; then
	if ! force; then
		fatal "work directory $work exists already"
	fi

	#
	# Clean up carefully, to try and avoid removing something we didn't
	# intend:
	#
	banner clean
	for x in cache path root src; do
		if ! rm -rf "$work/$x"; then
			fatal "cleaning $work/$x failed"
		fi
	done
	if ! rmdir "$work"; then
		fatal "cleanup of $work failed, not empty"
	fi
fi
for x in cache path root src; do
	if ! mkdir -p "$work/$x"; then
		fatal "creating $work failed"
	fi
done

export GOOS=illumos
export GOARCH=amd64
export GOROOT_BOOTSTRAP="$oldgoroot"
export GOROOT="$work/root"
export GOROOT_FINAL="/opt/go/$newver"
export GOPATH="$work/path"
export GOCACHE="$work/cache"

if ! mkdir -p "$dir/output"; then
	fatal "could not create output directory"
fi
finaltar="$dir/output/go$newver.$GOOS-$GOARCH.tar.gz"
if [[ -e "$finaltar" ]] && ! force; then
	fatal "output tar $finaltar already exists"
fi

banner extract
if ! gtar -C "$work/src" --strip-components=1 -xz \
    -f "$dir/src/go$newver.src.tar.gz"; then
	fatal "could not extract go $newver source"
fi

banner build
if ! cd "$work/src/src"; then
	fatal "could not chdir to go src/src"
fi

./all.bash

banner trim
if ! cd "$work/src"; then
	fatal "could not chdir to go src"
fi
if ! "$dir/tools/clean_up.sh"; then
	fatal "could not trim files from go"
fi

banner archive
if ! cd "$work/src"; then
	fatal "could not chdir to go src"
fi
temptar="$dir/output/.tmp.$$"
rm -f "$temptar"
if ! gtar -c -z -f "$temptar" --numeric-owner --owner=0 --group=0 *; then
	fatal "could not create archive"
fi
if ! mv "$temptar" "$finaltar"; then
	fatal "could not move the output archive into place"
fi

banner ok
printf 'output archive: %s\n' "$finaltar"
exit 0
