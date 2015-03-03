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
	rm -f "$ROCKDEV_DIR/"*.img "$ROCKDEV_DIR/"*.bin
	[ ! -s "${UBOOT_SRC}/RK3188Loader_miniall.bin" ] || cp -v "${UBOOT_SRC}/"RK3188Loader_miniall.bin $ROCKDEV_DIR
	[ ! -s "${UBOOT_SRC}/uboot.img" ] || cp -v "${UBOOT_SRC}/"uboot.img $ROCKDEV_DIR
	[ ! -s "${UBOOT_SRC}/RK3288UbootLoader_V2.19.06.bin" ] || cp -v "${UBOOT_SRC}/"RK3288UbootLoader_V2.19.06.bin $ROCKDEV_DIR
	if [ ! -e "$ROOTFS_DST/rootfs.ext4" ]; then
		if [ -e "$ROOTFS_SRC/$BOARD-rootfs.ext4" ]; then
			cp $ROOTFS_SRC/$BOARD-rootfs.ext4 $ROOTFS_DST/rootfs.ext4
		else
			echo "rootfs.ext4 does not exist!"
			exit 1
		fi
	fi
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

function clean()
{
	if [ `ls ${ROCKDEV_DIR}/*.img | wc -l` -gt 5 ]; then
		dir_size=`du -sh ${ROCKDEV_DIR} | awk '{print $1}'`
		echo -e "\033[00;41mThe rockdev size: $dir_size\033[0m"
		read -p "Do you want to clean it(y/n)?" result
		if [ "$result" = 'y' ]; then
			ls ${ROCKDEV_DIR}/*.img | grep -v ${IMAGE} | xargs rm -f
			echo "clean done"
		fi
	fi
}
init
pack
clean
