#!/bin/sh -e

OS_FLG=$(uname -m | cut -d "_" -f 2)
TOOLCHAIN_DIR="tools/toolchain/arm-eabi"

if [ ! -d "tools/toolchain" ]; then
	mkdir -p tools/toolchain
fi

if [ ! -d "tools/toolchain/arm-eabi" ]; then
	if [ $OS_FLG -eq 32 ]; then
		git clone -b $TOOLCHAIN32_REV --depth 1 $TOOLCHAIN32_REPO $TOOLCHAIN_DIR
	elif [ $OS_FLG -eq 64 ]; then
		git clone -b $TOOLCHAIN64_REV --depth 1 $TOOLCHAIN64_REPO $TOOLCHAIN_DIR
	else
		echo "unknown system type"
	fi
fi
