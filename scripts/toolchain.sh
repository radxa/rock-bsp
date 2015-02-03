#!/bin/sh -e

TOP=$(pwd)
OS_FLG=$(uname -m | cut -d "_" -f 2)

if [ ! -d "$TOP/available-tools" ]; then
	mkdir -p $TOP/available-tools
fi

if [ ! -d "$TOP/available-tools/arm-eabi-4.6" ]; then
	if [ $OS_FLG -eq 32 ]; then
		git clone -b jb-release --depth 1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6 $TOP/available-tools/arm-eabi-4.6
	elif [ $OS_FLG -eq 64 ]; then
		git clone -b kitkat-release --depth 1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6 $TOP/available-tools/arm-eabi-4.6
	else
		echo "unknown system type"
	fi
fi
