#!/bin/sh

die() {
	echo "$*" >&2
	exit 1
}

[ -s "./.config" ] || die "please run ./config.sh first."

. ./.config

TOOLS_DIR=$(pwd)/tools/bin

#prepare boot.img
if [ ! -d "$BOARD/rockdev/Image" ]; then
	mkdir -p $BOARD/rockdev/Image
fi
rm -rf $BOARD/rockdev/Image/boot-linux.img
$TOOLS_DIR/mkbootimg --kernel $KERNEL_SRC/arch/arm/boot/zImage --ramdisk $INITRD_DIR/../initrd.img --second $KERNEL_SRC/$BOOTIMG_TARGET -o $BOARD/rockdev/Image/boot-linux.img

cat parameter/$BOARD-parameter > $BOARD/rockdev/parameter
cat package-file/$BOARD-package-file > $BOARD/rockdev/package-file
rm -rf rockdev
ln -s $BOARD/rockdev rockdev

#pack update.img
./scripts/mkupdate.sh
