#!/bin/sh

die() {
	echo "$*" >&2
	exit 1
}

[ -s "./.config" ] || die "please run ./config.sh first."

. ./.config

HWPACK_DIR="${BOARD}/rockdev/${BOARD}_hwpack"
ROCKDEV_DIR="${BOARD}/rockdev"
OUT_DIR=rootfs/$BOARD-rootfs
IMAEGPACK_SRC=$OUT_DIR/$IMAGE_NAME
IMAGE_NAME=

init() {
	if [ ! -d "$OUT_DIR" ]; then
		mkdir -p $OUT_DIR
	fi
	IMAGE_NAME=$(basename $OUT_DIR/linaro*.tar.gz)
	if [ "$IMAGE_NAME"x = "linaro*.tar.gz"x ]; then
		wget -P $OUT_DIR $ROOTFS_URL
		IMAGE_NAME := $(basename $OUT_DIR/linaro*.tar.gz)
	fi
	#extract rootfs
	if [ ! -d "$OUT_DIR/binary" ]; then
		tar zxf $OUT_DIR/$IMAGE_NAME -C $OUT_DIR >/dev/null 2>&1
	fi
}

cp_debian_files() {
	local rootfs_pack="$1"
	local x= y=

	echo "Debian/Ubuntu hwpack"
	cp -r "rootfs/${BOARD}-rootfs/binary/"* "$rootfs_pack/"
	rm -rf "rootfs/${BOARD}-rootfs/binary"

	## kernel modules
	cp -r "$MODULE_DIR/lib/modules" "$rootfs_pack/lib/"
	rm -f "$rootfs_pack/lib/modules"/*/source
	rm -f "$rootfs_pack/lib/modules"/*/build
}

create_hwpack() {
	local hwpack="$1"
	local rootfs_hwpack="$HWPACK_DIR/rootfs"
	local kernel_hwpack="$HWPACK_DIR/kernel"
	local bootloader_hwpack="$HWPACK_DIR/bootloader"
	local f=

	rm -rf "$HWPACK_DIR"

	mkdir -p "$rootfs_hwpack/lib"
	rm -rf rockdev
	ln -s $ROCKDEV_DIR rockdev

	cp_debian_files "$rootfs_hwpack"

	## kernel
	mkdir -p "$kernel_hwpack"
	cp -r "$KERNEL_SRC/arch/arm/boot/Image" "$kernel_hwpack/" >/dev/null 2>&1
	cp -r "$KERNEL_SRC/arch/arm/boot/zImage" "$kernel_hwpack/" >/dev/null 2>&1

	## bootloader
	mkdir -p "$bootloader_hwpack"
	cp -r "$UBOOT_SRC/"*.bin "$bootloader_hwpack/"
	[ -s "$UBOOT_SRC/uboot.img" ] || cp -r "$UBOOT_SRC/".img "$bootloader_hwpack/" 1> /dev/null

	## compress hwpack
	cd "$HWPACK_DIR"
	echo "waiting ..."
	case "$hwpack" in
	*.7z)
		7z u -up1q0r2x1y2z1w2 -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on "$hwpack" .
		;;
	*.tar.bz2)
		find . ! -type d | cut -c3- | sort -V | tar -jcf "$hwpack" -T -
		;;
	*.tar.xz)
		find . ! -type d | cut -c3- | sort -V | tar -Jcf "$hwpack" -T -
		;;
	*)
		die "Not supported hwpack format"
		;;
	esac
	cd - > /dev/null
	mv $HWPACK_DIR/$BOARD-hwpack.tar.bz2 $ROCKDEV_DIR
	rm -rf $HWPACK_DIR
	echo "Done."
}

[ $# -lt 1 ] || die "Usage: invalid param <hwpack>"

init
create_hwpack "${BOARD}-hwpack.tar.bz2"
