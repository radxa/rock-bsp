#!/bin/sh

TODAY="`date +"%y-%m-%d"`"
IMG="rock_lite_${TODAY}_sdcard.img"

rkcrc -p parameter parameter.img

rm -rf $IMG
dd if=/dev/zero of=$IMG bs=1M count=1950

export START_SECTOR=65536
sudo fdisk $IMG  << EOF
n
p
1
$START_SECTOR

w
EOF

sudo dd if=u-boot-sd.img of=$IMG conv=notrunc,sync seek=64
sudo dd if=parameter.img of=$IMG conv=notrunc,sync seek=$((0x2000))
sudo dd if=boot/boot-linux.img of=$IMG conv=notrunc,sync seek=$((0x2000+0x2000))
sudo dd if=rootfs.img of=$IMG conv=notrunc,sync seek=65536
