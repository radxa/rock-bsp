#!/bin/sh -e
# function : make rootfs.ext4
#
# (C) Copyright 2015, Radxa Limited
# support@radxa.com
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.

die() {
	echo "$*" >&2
	exit 1
}

[ -s "./.config" ] || die "please run ./config.sh first."

. ./.config

TARGET=rootfs/target_tmp
OUT_DIR=rootfs/$BOARD-rootfs

cleanup() {
	sudo umount $TARGET || true
	sudo sudo rm -rf $TARGET
}

die() {
	echo "$*" >&2
	cleanup
	exit 1
}

make_rootfs()
{
	echo "Make rootfs"
	local rootfs=$(readlink -f "$1")
	local output=$(readlink -f "$2")
	local fsizeinbytes=$(gzip -lq "$IMAGEPACK_SRC" | awk -F" " '{print $2}')
	local fsizeMB=$(expr $fsizeinbytes / 1024 / 1024 + 200)
	local d= x=
	local rootfs_copied=

	echo "Make rootfs.ext4 (size="$fsizeMB")"
	mkdir -p $TARGET
	dd if=/dev/zero of=$OUT_DIR/rootfs.ext4 bs=1M count="$fsizeMB"
	mkfs.ext4 $OUT_DIR/rootfs.ext4
	sudo umount $TARGET || true
	sudo mount $OUT_DIR/rootfs.ext4 $TARGET -o loop=/dev/loop0

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
}
make_rootfs
cleanup
