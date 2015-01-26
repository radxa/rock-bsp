#!/bin/sh

TODAY="`date +"%y-%m-%d"`"

TOP=$(pwd)
. $TOP/.config

KERNEL=$TOP/${BOARD}/${KERNEL}
RAMDISK=$TOP/${BOARD}/ramdisk
PACK=$TOP/${BOARD}/package-tools

if [ -d "PACK/Linux" ];then
	mkdir $PACK/Linux
fi

#prepare boot.img
mkbootimg --kernel $KERNEL/arch/arm/boot/Image --ramdisk $RAMDISK/initrd.img --second $KERNEL/resource.img -o $PACK/Linux/boot-linux.img

#pack update.img
cd $(PACK) && ./mkupdate.sh && cd -
