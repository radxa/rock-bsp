#!/bin/bash -e

TOP="$(cd .. && pwd)
. $TOP/.config

DATE=$(date +"%y-%m-%d-%H%M%S")
IMAGE="$(BOARD)_${DATE}.img"
partitions=("parameter" "boot" "linuxroot")
U_BOOT_BIN="$(basename $U_O_PATH/RK3288*boot*.bin)"
echo "--------------$(U_BOOT_BIN)---------------------"

function init()
{
	if [ "$U_BOOT_BIN"x = ""x  ]; then
		U_BOOT_BIN="$(basename $TOP/rockdev/RK3288*boot*.bin)"
	fi

	if [ ! -e $U_BOOT_BIN ]; then
		cp -v $U_O_PATH/$U_BOOT_BIN .
	fi

	old_uboot=`sed '/bootloader/!d' package-file | cut -f 2`
	if [ "$old_uboot" != "$U_BOOT_BIN" ]; then
		sed -i 's/'${old_uboot}'/'${U_BOOT_BIN}'/g' package-file
	fi

	sed -i 's/Image/boot-linux.img/'Image/${BOARD}/boot-linux.img'/g' package-file	

	for part in ${partitions[@]}
	do
		img=`sed -e '/#/d' -e '/'$part'/!d' -e '/bootloader/d' package-file | awk '{print substr($2,0)}'`
		if [ "$img"x = ""x ]; then
			echo "partitions: [$part] does not have name"
			exit 1
		fi
		if [ ! -e "$img" ]; then
			echo "partitions: [$part] $img does not exist"
			exit 1
		fi
	done
}
function pack()
{
	echo "start to make update.img..."
	rm -f update_tmp.img update.img
	afptool -pack ./ update_tmp.img
	img_maker -$(SERIAL) $U_BOOT_BIN 1 0 0 update_tmp.img ${IMAGE}
	echo -e "Image is at \033[1;36m$TOP/rockdev/${IMAGE}\033[00m"
}
function clean()
{
	if [ `ls *.img | wc -l` -gt 7 ]; then
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
