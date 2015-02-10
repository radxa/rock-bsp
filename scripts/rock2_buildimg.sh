#!/bin/sh

TOP=$(pwd)
. $TOP/.config

if [ ! -d "$BOARD/rockdev/Image" ]; then
	mkdir -p $BOARD/rockdev/Image
fi
rm -rf $BOARD/rockdev/Image/boot-linux.img

#prepare boot.img
mkbootimg --kernel $LINUX_SRC/arch/arm/boot/zImage --ramdisk $INITRD_DIR/initrd.img $(BOOTIMG_TARGET) -o $BOARD/rockdev/Image/boot-linux.img

cat $TOP/parameter/$BOARD-parameter > $BOARD/rockdev/parameter
cat $TOP/package-file/$BOARD-package-file > $BOARD/rockdev/package-file
rm -rf $TOP/rockdev
ln -s $TOP/$BOARD/rockdev $TOP/rockdev

#pack update.img
cd $TOP/$BOARD/rockdev && ../../scripts/mkupdate.sh && cd - > /dev/null
