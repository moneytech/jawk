#!/bin/sh

set -eu

name=`basename $0`

usage() {
	echo "usage: $name [-v var=value] [-f progfile | 'prog'] [file]" >&2
	exit 1
}

p=
prog=
while getopts :v:f: opt; do
	case $opt in
	f) prog="$prog`cat "$OPTARG"`"; p=1 ;;
	v) ;;
	?) usage
	esac
done

i=0
skip=
f=
file=
for arg do
	i=$((i+1))
	shift
	# Skip -f options
	if [ "$i" -lt "$OPTIND" ]; then
		if [ "$skip" ]; then skip=; continue; fi
		# If starts with -f
		if [ "$arg" != "${arg#-f}" ]; then
			if [ "$arg" = "-f" ]; then skip=1; fi
			continue
		fi
	# Get prog and file
	else
		if [ ! "$p" ]; then prog=$arg; p=1
		elif [ ! "$f" ]; then file=$arg; f=1
		else usage; fi
		continue
	fi
	set -- "$@" "$arg"
done

if [ ! "$p" ]; then usage; fi
if [ ! "$f" ]; then file=-; fi

cbs="`cat callbacks.awk`"
parser="`cat JSON.awk`"
jawk="`cat jawk.awk`"

awk -v BRIEF=0 -v STREAM=0 -v KEYS="\3" "$cbs""$parser" "$file" | \
awk "$@" "$jawk""$prog"
