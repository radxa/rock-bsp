#!/bin/bash -e

TOP="$(cd .. && pwd)"

DATE=$(date +"%y-%m-%d-%H%M%S")
IMAGE="rock2_android_kitkat_${DATE}.img"
partitions=("parameter" "misc" "kernel" "resource" "boot" "recovery" "system")

function init()
{
	if [ "$U_BOOT_BIN"x = ""x  ]; then
		U_BOOT_BIN="$(basename $TOP/u-boot/RK3288*boot*.bin)"
	fi

	if [ ! -e $U_BOOT_BIN ]; then
		cp -v $TOP/u-boot/$U_BOOT_BIN .
	fi
	old_uboot=`sed '/bootloader/!d' package-file | cut -f 2`
	if [ "$old_uboot" != "$U_BOOT_BIN" ]; then
		sed -i 's/'${old_uboot}'/'${U_BOOT_BIN}'/g' package-file
	fi
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
	./afptool -pack ./ Image/update_tmp.img
#	./rkImageMaker -RK32 $U_BOOT_BIN  Image/update_tmp.img ${IMAGE} -os_type:androidos
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
