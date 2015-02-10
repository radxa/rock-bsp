#!/bin/sh -e

TOP=$(pwd)
OS_FLG=$(uname -m | cut -d "_" -f 2)

if [ ! -d "$TOP/tools/toolchain" ]; then
	mkdir -p $TOP/tools/toolchain
fi

if [ ! -d "$TOP/tools/toolchain/arm-eabi-4.6" ]; then
	if [ $OS_FLG -eq 32 ]; then
		git clone -b jb-release --depth 1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6 $TOP/tools/toolchain/arm-eabi-4.6
	elif [ $OS_FLG -eq 64 ]; then
		git clone -b kitkat-release --depth 1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6 $TOP/tools/toolchain/arm-eabi-4.6
	else
		echo "unknown system type"
	fi
fi
