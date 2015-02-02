#!/bin/sh -e
# function : make rootfs.ext4
#
# (C) Copyright 2015, Radxa Limited
# support@radxa.com
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.

TOP=$(pwd)

TARGET=/build3/jim/rock-bsp/rootfs/target_tmp
IMAGE=rootfs.tar.gz
OUT_DIR=/build3/jim/rock-bsp/rootfs
LINARO=linaro-trusty-alip-20141024-684.tar.gz

cleanup() {
	sudo umount $(TARGET) || true
	sudo sudo rm -rf $(TARGET)
}

die() {
	echo "$*" >&2
	cleanup
	exit 1
}

init() {
	rm -f $(OUT_DIR)/rootfs.ext4
	if [ ! -e "$(OUT_DIR)/$(IMAGE)" ]; then
		wget -P $(OUT_DIR) http://releases.linaro.org/14.10/ubuntu/trusty-images/alip/linaro-trusty-alip-20141024-684.tar.gz
		mv $(OUT_DIR)/$(LINARO) $(OUT_DIR)/rootfs.tar.gz
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

	echo "Make rootfs.ext4 (size="$fsizeMB")"
	mkdir -p $TARGET
	dd if=/dev/zero of=rootfs.ext4 bs=1M count="$fsizeMB"
	mkfs.ext4 rootfs.ext4
	sudo umount $TARGET || true
	sudo mount rootfs.ext4 $TARGET -o loop=/dev/loop0

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

	mv rootfs.ext4 $output
	rm -rf $TARGET
}
init
make_rootfs "$IMAGE" "$OUT_DIR"
cleanup
