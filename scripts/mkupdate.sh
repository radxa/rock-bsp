#!/bin/bash -e

TOP=$(cd ../.. && pwd)
. $TOP/.config

DATE=$(date +"%y-%m-%d-%H%M%S")
IMAGE=${BOARD}_${DATE}.img
U_BOOT_BIN=
ROCKDEV_DIR=${BOARD}/rockdev
ROOTFS_DST=${ROCKDEV_DIR}/Image
ROOTFS_SRC=rootfs/$BOARD-rootfs
ROOTFS_BIN=

show_usage()
{
	echo "Usage ($1): $1 does not exit!"
	exit 1
}

function init()
{
	if [ "$U_BOOT_BIN"x = ""x  ]; then
		U_BOOT_BIN="$(basename ${UBOOT_SRC}/RK*Loader*.bin)"
	fi
	
	if [ ! -e ${BOARD}/rockdev/$U_BOOT_BIN ]; then
		cp -v ${UBOOT_SRC}/$U_BOOT_BIN $TOP/${BOARD}/rockdev
	fi
	old_uboot=`sed '/bootloader/!d' $TOP/${BOARD}/rockdev/package-file | cut -f 2`
	if [ "$old_uboot" != "$U_BOOT_BIN" ]; then
		sed -i 's/'${old_uboot}'/'${U_BOOT_BIN}'/g' $TOP/${BOARD}/rockdev/package-file
	fi

	[ -e "${ROOTFS_DST}/rootfs.ext4" ] || show_usage "rootfs.ext4"
	[ -e "${ROOTFS_DST}/boot-linux.img" ] || show_usage "boot-linux.img"

}
function pack()
{
	echo "start to make update.img..."
	rm -rf update_tmp.img
	afptool -pack ./ update_tmp.img
	img_maker -$SERIAL ${U_BOOT_BIN} 1 0 0 update_tmp.img ${IMAGE}
	echo -e "Image is at \033[1;36m$TOP/rockdev/${IMAGE}\033[00m"
}
function clean()
{
	if [ `ls *.img | wc -l` -gt 5 ]; then
		dir_size=`du -sh . | awk '{print $1}'`
		echo -e "\033[00;41mThe rockdev size: $dir_size\033[0m"
		read -p "Do you want to clean it(y/n)?" result
		if [ "$result" = 'y' ]; then
			ls *.img | grep -v ${IMAGE} | xargs rm -f
			echo "clean done"
		fi
	fi
}
init
pack
clean
