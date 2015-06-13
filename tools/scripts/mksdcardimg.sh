#!/bin/sh

IMG="${1}_sdcard.img"

${TOOLS_DIR}/bin/rkcrc -p parameter parameter.img

rm -rf $IMG
dd if=/dev/zero of=$IMG bs=1M count=1950

export ROOTFS_SECTOR=65536
sudo fdisk $IMG  << EOF
n
p
1
$ROOTFS_SECTOR

w
EOF

sudo dd if=u-boot-sd.img of=$IMG conv=notrunc,sync seek=64
sudo dd if=parameter.img of=$IMG conv=notrunc,sync seek=$((0x2000))
sudo dd if=boot/boot-linux.img of=$IMG conv=notrunc,sync seek=$((0x2000+0x2000))
sudo dd if=rootfs.img of=$IMG conv=notrunc,sync seek=$ROOTFS_SECTOR
echo -e "Image is at \033[1;36m$(pwd)/${IMG}\033[00m"
