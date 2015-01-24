#!/bin/sh

TOP=$(pwd)
. $TOP/.config

echo $TOP
KERNEL=$TOP/${BOARD}/${KERNEL}
RAMDISK=$TOP/${BOARD}/ramdisk
PACK=$TOP/${BOARD}/package-tools

if [ -d "PACK/Linux" ];then
	mkdir $PACK/Linux
fi

#prepare boot.img
mkbootimg --kernel $KERNEL/arch/arm/boot/Image --ramdisk $RAMDISK/initrd.img -o $PACK/Linux/boot-linux.img

#pack update.img
cd $(PACK) && ./mkupdate.sh
