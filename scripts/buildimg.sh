#!/bin/sh

die() {
	echo "$*" >&2
	exit 1
}

[ -s "./.config" ] || die "please run ./config.sh first."

. ./.config

#prepare boot.img
generate_bootimg()
{
	mkdir -p $BOARD/rockdev/Image
	rm -rf $BOARD/rockdev/Image/boot-linux.img
	if [ "$BOOTIMG_TARGET"x = ""x ]; then
		$TOOLS_DIR/bin/mkbootimg --kernel $KERNEL_SRC/arch/arm/boot/zImage --ramdisk $INITRD_DIR/../initrd.img -o $BOARD/rockdev/Image/boot-linux.img
	else
		$TOOLS_DIR/bin/mkbootimg --kernel $KERNEL_SRC/arch/arm/boot/zImage --ramdisk $INITRD_DIR/../initrd.img --second $KERNEL_SRC/$BOOTIMG_TARGET -o $BOARD/rockdev/Image/boot-linux.img
	fi
	cat parameter/$BOARD-parameter > $BOARD/rockdev/parameter
	cat package-file/$BOARD-package-file > $BOARD/rockdev/package-file
}

generate_bootimg
rm -rf rockdev
ln -s $BOARD/rockdev rockdev

#pack update.img
./scripts/mkupdate.sh
