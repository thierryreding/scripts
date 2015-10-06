#!/bin/bash

basedir="${0%/*}"
configdir="${basedir}/configs"
outputdir="build/drm"

verbose=no
color=no
force=no
JOBS=1

function usage()
{
	echo "usage: $1 [options] [config...]"
	echo ""
	echo "options:"
	echo "  -c, --color    colorize output"
	echo "  -f, --force    force build from scratch"
	echo "  -h, --help     display help screen and exit"
	echo "  -j, --jobs N   set number of parallel make jobs"
	echo "  -v, --verbose  increase verbosity"
}

while test $# -ne 0; do
	if test -n "$prev"; then
		eval "$prev=$1"
		shift; prev=
		continue
	fi

	case $1 in
		-c | --color)
			color=yes
			shift
			;;

		-f | --force)
			force=yes
			shift
			;;

		-h | --help)
			usage $0
			exit 0
			;;

		-j | --jobs)
			prev=JOBS
			shift
			;;

		-v | --verbose)
			verbose=yes
			shift
			;;

		-*)
			usage $0
			exit 1
			;;

		*)
			configs="$configs $1"
			shift
			;;
	esac
done

if test "x$color" = "xyes"; then
	RED="\033[0;31m"
	GREEN="\033[0;32m"
	YELLOW="\033[0;33m"
	MAGENTA="\033[0;35m"
	CYAN="\033[0;36m"
	RESET="\033[0m"
fi

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

function make()
{
	(
		command make "$@" 3>&1 1>&2 2>&3 | tee -a "$KBUILD_OUTPUT/error.log"
		exit $PIPE_STATUS
	) &>> "$KBUILD_OUTPUT/build.log"
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

function log_action()
{
	echo -en "${CYAN}$@${RESET} ${MAGENTA}${config}${RESET}..."
}

function log_status()
{
	if test "x$1" != "x0"; then
		echo -e "${RED}failed ($1)${RESET}"
		break
	else
		if test -s "$KBUILD_OUTPUT/error.log"; then
			echo -e "${YELLOW}done ($1)${RESET}"
		else
			echo -e "${GREEN}done${RESET}"
		fi
	fi
}

for config in $configs; do
	KBUILD_OUTPUT="${outputdir}/$config"
	CONFIG_FILE="${configdir}/${config}"

	if test "x$force" = "xyes"; then
		if test "x$verbose" = "xyes"; then
			log_action "removing"
		fi

		rm -rf "$KBUILD_OUTPUT"

		if test "x$verbose" = "xyes"; then
			log_status $?
		fi
	fi

	if ! test -d "$KBUILD_OUTPUT"; then
		mkdir -p "$KBUILD_OUTPUT"
	fi

	if test -f "$KBUILD_OUTPUT/build.log"; then
		rm "$KBUILD_OUTPUT/build.log"
	fi

	if test -f "$KBUILD_OUTPUT/error.log"; then
		rm "$KBUILD_OUTPUT/error.log"
	fi

	log_action "configuring"
	source "$CONFIG_FILE"
	log_status $?

	log_action "building"
	cross_compile_prepare

	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O="$KBUILD_OUTPUT" \
		-j $JOBS; rc=$?

	cross_compile_cleanup
	log_status $rc

done
