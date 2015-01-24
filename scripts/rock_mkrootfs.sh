
TOP=$(pwd)
. $TOP/.config

TARGET=$TOP/target_tmp
IMAGE=rootfs.tar.gz
PACK=$TOP/${BOARD}/package-tools
OUTPUT=$PACK/Linux

cleanup() {
	sudo umount $TARGET || true
	sudo sudo rm -rf $TARGET
}

die() {
	echo "$*" >&2
	cleanup
	exit 1
}

set -e

init() {
	if [ -d "PACK/Linux" ];then
		mkdir $OUTPUT
	fi
	rm -f $OUTPUT/rootfs.img
	echo "$pwd"
	if [ ! -e "$TOP/$IMAGE" ]; then
		wget http://releases.linaro.org/14.10/ubuntu/trusty-images/alip/linaro-trusty-alip-20141024-684.tar.gz
		mv $(LINARO) rootfs.tar.gz
	fi
}

make_rootfs()
{
	echo "Make rootfs"
	local rootfs=$(readlink -f "$1")
	local output=$(readlink -f "$2")
	local fsizeinbytes=$(gzip -lq "$rootfs" | awk -F" " '{print $2}')
	local fsizeMB=$(expr $fsizeinbytes / 1024 / 1024 + 200)
	local d= x=
	local rootfs_copied=

	echo "Make rootfs.img (size="$fsizeMB")"
	mkdir -p $TARGET
	dd if=/dev/zero of=rootfs.img bs=1M count="$fsizeMB"
	mkfs.ext4 rootfs.img
	sudo umount $TARGET || true
	sudo mount rootfs.img $TARGET -o loop=/dev/loop0

	cd $TARGET
	echo "Unpacking $rootfs"
	sudo tar xzpf $rootfs || die "Unable to extract rootfs"

	for x in '' \
		'binary/boot/filesystem.dir' 'binary'; do

		d="$TARGET${x:+/$x}"

		if [ -d "$d/sbin" ]; then
			rootfs_copied=1
			sudo mv "$d"/* $TARGET ||
				die "Failed to copy rootfs data"
			break
		fi
	done
	[ -n "$rootfs_copied" ] || die "Unsupported rootfs"

	cd - > /dev/null

	mv rootfs.img $output
	rm -rf $TARGET
}
init
make_rootfs "$IMAGE" "$OUTPUT"
cleanup
