#!/bin/sh

PATH=$HOME/pbs-stage1/bin:$PATH
DIRECTORY="${0%/*}"

function usage()
{
	echo "usage: $1 [options]"
	echo ""
	echo "options:"
	echo "  -h, --help    show this usage information and exit"
	echo "  -j, --jobs N  build using N parallel jobs"
}

while test $# -ne 0; do
	if test -n "$prev"; then
		eval "$prev=$1"
		shift; prev=
		continue
	fi

	case $1 in
		--help | -h)
			usage $0
			exit 0
			;;

		--jobs | -j)
			prev=JOBS
			shift
			;;

		*)
			usage $0
			exit 1;
			;;
	esac
done

if test -z "$JOBS"; then
	JOBS=1
fi

function handle_option()
{
	local ARGS="--file $1"
	local KEY=${2%%=*}
	local VALUE=${2#*=}

	#echo "    $KEY: $VALUE"

	case $VALUE in
		y)
			ARGS="$ARGS --enable $KEY"
			;;

		n)
			ARGS="$ARGS --disable $KEY"
			;;

		m)
			ARGS="$ARGS --module $KEY"
			;;

		*)
			echo "invalid value $VALUE for option $KEY"
			exit 1
			;;
	esac

	scripts/config $ARGS
}

while read NAME ARCH DEFCONFIG OPTIONS; do
	if test "${NAME###}" != "${NAME}"; then
		echo "skipping commented line"
		continue
	fi

	OUTPUT="build/$ARCH/$NAME"

	ARGS="ARCH=$ARCH"

	#echo "name: $NAME"
	#echo "  architecture: $ARCH"
	#echo "  defconfig: $DEFCONFIG"
	#echo "  options:"

	case $ARCH in
		arm)
			CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-
			;;

		mips)
			CROSS_COMPILE=mips-linux-gnu-
			;;

		x86 | x86_64)
			CROSS_COMPILE=
			;;

		*)
			CROSS_COMPILE=
			;;
	esac

	if test -n "$CROSS_COMPILE"; then
		ARGS="$ARGS CROSS_COMPILE=$CROSS_COMPILE"
	fi

	ARGS="$ARGS O=$OUTPUT"

	echo -en "building \033[33;1m$NAME\033[0m (\033[35;1m$ARCH\033[0m)..."

	mkdir -p "$OUTPUT"

	if ! make $ARGS "$DEFCONFIG" > "$OUTPUT/build.log" 2>&1; then
		echo -e "\033[31;1mfailed\033[0m"
		continue
	fi

	for option in $OPTIONS; do
		handle_option "$OUTPUT/.config" $option
	done

	if ! make $ARGS olddefconfig <&- < /dev/tty >> "$OUTPUT/build.log" 2>&1; then
		echo -e "\033[31;1mfailed\033[0m"
		continue
	fi

	if ! make $ARGS C=1 -j $JOBS >> "$OUTPUT/build.log" 2>&1; then
		echo -e "\033[31;1mfailed\033[0m"
		continue
	fi

	echo -e "\033[32;1mdone\033[0m"
done < "$DIRECTORY/configs"
