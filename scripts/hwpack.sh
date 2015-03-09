#!/bin/sh

die() {
	echo "$*" >&2
	exit 1
}

[ -s "./.config" ] || die "please run ./config.sh first."

. ./.config

HWPACK_DIR="${BOARD}/rockdev/${BOARD}_hwpack"
OUT_DIR=rootfs/$BOARD-rootfs
IMAEGPACK_SRC=$OUT_DIR/$IMAGE_NAME
IMAGE_NAME=

init() {
	mkdir -p $OUT_DIR
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
	local parameter_hwpack="$HWPACK_DIR/parameter"
	local bootimg_hwpack="$HWPACK_DIR/bootimg"
	local bootloader_hwpack="$HWPACK_DIR/bootloader"
	local f=

	rm -rf "$HWPACK_DIR"

	## rootfs
	mkdir -p "$rootfs_hwpack/lib"
	cp_debian_files "$rootfs_hwpack"

	## parameter
	mkdir -p "$parameter_hwpack"
	cp -r $PARAMETER "$parameter_hwpack/"

	## kernel
	mkdir -p "$bootimg_hwpack"
	cp -r "$ROCKDEV_DIR/Image/boot-linux.img" "$bootimg_hwpack/" >/dev/null 2>&1

	## bootloader
	mkdir -p "$bootloader_hwpack"
	cp -r "$UBOOT_SRC/"$U_BOOT_BIN "$bootloader_hwpack/"

	## compress hwpack
	cd "$HWPACK_DIR"
	echo "waiting ..."
	find . ! -type d | cut -c3- | sort -V | tar -jcf "$hwpack" -T -
	cd - > /dev/null
	mv $HWPACK_DIR/$BOARD-hwpack.tar.bz2 $ROCKDEV_DIR
	rm -rf $HWPACK_DIR
	echo "Done."
}

[ $# -lt 1 ] || die "Usage: invalid param <hwpack>"

init
create_hwpack "${BOARD}-hwpack.tar.bz2"
