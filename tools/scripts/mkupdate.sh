#!/bin/bash -e

die() {
	echo "$*" >&2
	exit 1
}

[ -s "./.config" ] || die "please run ./config.sh first."

. ./.config

DATE=$(date +"%y-%m-%d-%H%M%S")
IMAGE=${BOARD}_${DATE}.img
ROCKDEV_DIR=${BOARD}/rockdev
ROOTFS_DST=${ROCKDEV_DIR}/Image
ROOTFS_SRC=rootfs/$BOARD-rootfs
TOOLS_DIR=$(pwd)/tools/bin
U_BOOT_BIN=

function init()
{
	[ ! -s "${UBOOT_SRC}/RK3188Loader_miniall.bin" ] || cp -v "${UBOOT_SRC}/"RK3188Loader_miniall.bin $ROCKDEV_DIR
	[ ! -s "${UBOOT_SRC}/uboot.img" ] || cp -v "${UBOOT_SRC}/"uboot.img $ROCKDEV_DIR
	[ ! -s "${UBOOT_SRC}/RK3288UbootLoader_V2.19.06.bin" ] || cp -v "${UBOOT_SRC}/"RK3288UbootLoader_V2.19.06.bin $ROCKDEV_DIR
}

function pack()
{
	echo "start to make update.img..."
	cd ${ROCKDEV_DIR}
	if [ "$U_BOOT_BIN"x = ""x  ]; then
		U_BOOT_BIN="$(basename RK3*.bin)"
	fi
	rm -rf update_tmp.img
	$TOOLS_DIR/afptool -pack ./ update_tmp.img
	$TOOLS_DIR/img_maker -${TYPECHIP} ${U_BOOT_BIN} 1 0 0 update_tmp.img ${IMAGE}
	echo -e "Image is at \033[1;36m${ROCKDEV_DIR}/${IMAGE}\033[00m"
	cd - > /dev/null
}
init
pack
