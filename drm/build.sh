#!/bin/bash

basedir="${0%/*}"
configdir="${basedir}/configs"
outputdir="build/drm"

verbose=no
force=no
JOBS=1

while test $# -ne 0; do
	if test -n "$prev"; then
		eval "$prev=$1"
		shift; prev=
		continue
	fi

	case $1 in
		-j | --jobs)
			prev=JOBS
			shift
			;;

		-f | --force)
			force=yes
			shift
			;;

		-v | --verbose)
			verbose=yes
			shift
			;;

		*)
			configs="$configs $1"
			shift
			;;
	esac
done

function cross_compile_prepare()
{
	local path key value

	if test -f "$HOME/.cross-compile"; then
		while read key value; do
			key="${key%:}"

			if test "$key" = "path"; then
				eval "value=$value"

				if test -n "$path"; then
					path="$path:$value"
				else
					path="$value"
				fi
			elif test "$key" = "$ARCH"; then
				CROSS_COMPILE="$value"
			fi
		done < "$HOME/.cross-compile"
	fi

	if test -n "$path"; then
		saved_PATH="$PATH"
		PATH="$path:$PATH"
	fi

	if test "x$verbose" = "xyes"; then
		echo "CROSS_COMPILE: $CROSS_COMPILE"
		echo "PATH: $PATH"
	fi
}

function cross_compile_cleanup()
{
	if test -n "$saved_PATH"; then
		PATH="$saved_PATH"
	fi

	unset CROSS_COMPILE
}

function kconfig()
{
	case $1 in
		architecture)
			ARCH=$2
			;;

		*config)
			make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE \
				O=$KBUILD_OUTPUT -j $JOBS $1
			;;

		enable)
			scripts/config --file $KBUILD_OUTPUT/.config \
				--enable $2
			;;

		module)
			scripts/config --file $KBUILD_OUTPUT/.config \
				--module $2
			;;

		disable)
			scripts/config --file $KBUILD_OUTPUT/.config \
				--disable $2
			;;
	esac
}

if test -z "$configs"; then
	for config in "${configdir}"/*; do
		configs="$configs ${config##${configdir}/}"
	done
fi

for config in $configs; do
	KBUILD_OUTPUT="${outputdir}/$config"
	CONFIG_FILE="${configdir}/${config}"

	if test "x$force" = "xyes"; then
		rm -rf "$KBUILD_OUTPUT"
	fi

	if ! test -d "$KBUILD_OUTPUT"; then
		mkdir -p "$KBUILD_OUTPUT"
	fi

	source "$CONFIG_FILE"

	cross_compile_prepare

	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O="$KBUILD_OUTPUT" \
		-j $JOBS #2>&1 | tee "$directory/build-$(git describe).log"

	cross_compile_cleanup
done
