#!/bin/sh -e

die() {
	echo "$*" >&2
	exit 1
}

[ -s "./.config" ] || die "please run ./config.sh first."

. ./.config

OS_FIGURE=$(uname -m | cut -d "_" -f 2)
TOOLCHAIN_DIR="tools/toolchain"

if [ ! -d "$TOOLCHAIN_DIR" ]; then
	mkdir -p $TOOLCHAIN_DIR
fi

if [ ! -d "tools/toolchain/arm-eabi" ]; then
	if [ $OS_FIGURE -eq 32 ]; then
		git clone -b $TOOLCHAIN32_REV --depth 1 $TOOLCHAIN32_REPO $TOOLCHAIN_DIR
	elif [ $OS_OS_FIGURE= -eq 64 ]; then
		git clone -b $TOOLCHAIN64_REV --depth 1 $TOOLCHAIN64_REPO $TOOLCHAIN_DIR
	else
		echo "unknown system type"
	fi
fi
