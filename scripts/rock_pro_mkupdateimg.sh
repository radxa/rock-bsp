#!/bin/sh

TOP=$(pwd)
. $TOP/.config

KERNEL_OUT=$TOP/output/$BOARD/$KERNEL
RAMDISK=$TOP/rockdev/ramdisk
TOOL_PATH=$TOP/rockdev/package-tools

mkdir -p rockdev/Image/$BOARD-linux
rm -rf rockdev/Image/$BOARD-linux/boot-linux.img

#prepare boot.img
mkbootimg --kernel $KERNEL_OUT/arch/arm/boot/Image --ramdisk $RAMDISK/initrd.img -o rockdev/Image/$BOARD-linux/boot-linux.img

if [ ! -d "$TOOL_PATH"]; then
	ln -s $TOP/rockdev/RKTools/linux/Linux_Upgrade_Tool_v1.2/rockdev rockdev/package-tools
fi
cat $TOP/parameter/$BOARD-parameter > $TOP/rockdev/parameter
cat $TOP/package-file/$BOARD-package-file >$TOP/rockdev/package-file

#pack update.img
cd $(PACK) && ./mkupdate.sh && cd -
