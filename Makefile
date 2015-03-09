# rock bsp
# (C) Copyright 2015, Radxa Limited
# support@radxa.com
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#

.PHONY: all clean help
.PHONY: tools ramdisk boot.img
.PHONY: uboot kernel rootfs.ext4 nand.img emmc.img sdcard.img

include .config

OUTPUT_DIR=$(CURDIR)/output
MODULE_DIR=$(OUTPUT_DIR)/$(BOARD)-modules
KERNEL_SRC=$(CURDIR)/$(BOARD)/linux-rockchip
UBOOT_SRC=$(CURDIR)/$(BOARD)/u-boot-rockchip
TOOLS_DIR=$(CURDIR)/tools
INITRD_DIR=$(CURDIR)/$(BOARD)/initrd
ROCKDEV_DIR=$(CURDIR)/$(BOARD)/rockdev

export TOOLS_DIR ROCKDEV_DIR MODULE_DIR
export KERNEL_SRC UBOOT_SRC OUTPUT_DIR INITRD_DIR

U_CONFIG_H=$(UBOOT_SRC)/include/config.h
K_BLD_CONFIG=$(KERNEL_SRC)/.config

U_BOOT_BIN=$(shell sed '/bootloader/!d' $(PACKAGE_FILE) | cut -f 2)
PARAMETER=$(CURDIR)/parameter/$(BOARD)-parameter
PACKAGE_FILE=$(CURDIR)/package-file/$(BOARD)-package-file
IMAGE_NAME=$(BOARD)_$(DATE)
CROSS_COMPILE=$(TOOLS_DIR)/toolchain/bin/arm-eabi-

export PARAMETER PACKAGE_FILE U_BOOT_BIN

HOST_ARCH:=$(shell uname -m )
DATE=$(shell date +"%y-%m-%d-%H%M%S")
J=$(shell expr `grep ^processor /proc/cpuinfo  | wc -l`)
Q=

all: tools uboot kernel ramdisk rootfs.ext4 boot.img nand.img emmc.img sdcard.img

clean:
	rm -f .config
	rm -rf $(OUTPUT_DIR)
	$(Q)$(MAKE) -C $(KERNEL_SRC) clean
	$(Q)$(MAKE) -C $(UBOOT_SRC) clean

$(KERNEL_SRC)/.git:
	$(Q)mkdir -p $(KERNEL_SRC)
	$(Q)git clone -n $(KERNEL_REPO) $(KERNEL_SRC)
	$(Q)cd $(KERNEL_SRC) && git checkout $(KERNEL_REV) && cd - > /dev/null

$(K_BLD_CONFIG): $(KERNEL_SRC)/.git
	$(Q)mkdir -p $(KERNEL_SRC)/modules
	$(Q)$(MAKE) -C $(KERNEL_SRC) ARCH=arm $(KERNEL_DEFCONFIG)

kernel: $(K_BLD_CONFIG)
	$(Q)$(MAKE) -C $(KERNEL_SRC) ARCH=arm oldconfig
	$(Q)$(MAKE) -C $(KERNEL_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm -j$J
	$(Q)$(MAKE) -C $(KERNEL_SRC) $(KERNEL_EXTRA) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm -j$J
	$(Q)$(MAKE) -C $(KERNEL_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm INSTALL_MOD_PATH=$(MODULE_DIR) modules
	$(Q)$(MAKE) -C $(KERNEL_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm INSTALL_MOD_PATH=$(MODULE_DIR) modules_install

linux-config: $(K_BLD_CONFIG)
	$(Q)$(MAKE) -C $(KERNEL_SRC) ARCH=arm menuconfig

rootfs.ext4:
	$(Q)mkdir -p $(ROCKDEV_DIR)/Image
	$(Q)touch $(ROCKDEV_DIR)/Image/rootfs.ext4
#ifneq ($(wildcard $(ROCKDEV_DIR)/rootfs.ext4),)
#	$(Q)wget -P $(ROCKDEV_DIR) $(ROOTFSEXT4_URL)
#endif
#$(Q)scripts/mkrootfs.sh

$(UBOOT_SRC)/.git:
	$(Q)mkdir -p $(UBOOT_SRC)
	$(Q)git clone -n $(UBOOT_REPO) $(UBOOT_SRC)
	$(Q)cd $(UBOOT_SRC) && git checkout $(UBOOT_REV) && cd - > /dev/null

$(U_CONFIG_H): $(UBOOT_SRC)/.git
	$(Q)mkdir -p $(UBOOT_SRC)
	$(Q)$(MAKE) -C $(UBOOT_SRC) mrproper
	$(Q)$(MAKE) -C $(UBOOT_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm $(UBOOT_DEFCONFIG)
	$(Q)$(MAKE) -C $(UBOOT_SRC) $(UBOOT_EXTRA) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm $(UBOOT_DEFCONFIG)

uboot: $(U_CONFIG_H)
	$(Q)$(MAKE) -C $(UBOOT_SRC) all CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm -j$J

$(INITRD_DIR)/.git:
	$(Q)mkdir -p $(INITRD_DIR)
	$(Q)git clone $(INITRD_REPO) $(INITRD_DIR)
	$(Q)cd $(INITRD_DIR) && git checkout $(INITRD_REV) && cd - > /dev/null
	$(Q)$(MAKE) -C $(INITRD_DIR)

#initrd.img
ramdisk: $(INITRD_DIR)/.git

tools/rockchip-mkbootimg/.git:
	$(Q)mkdir -p $(TOOLS_DIR)/rockchip-mkbootimg
	$(Q)git clone $(MKBOOTIMG_REPO) $(TOOLS_DIR)/rockchip-mkbootimg
	$(Q)cd $(TOOLS_DIR)/rockchip-mkbootimg && git checkout $(MKBOOTIMG_REV) && cd - > /dev/null
	$(Q)$(MAKE) -C $(TOOLS_DIR)/rockchip-mkbootimg install PREFIX=$(TOOLS_DIR)

tools/rkflashtool/.git:
	$(Q)mkdir -p $(TOOLS_DIR)/rkflashtool
	$(Q)git clone $(RKFLASHTOOL_REPO) $(TOOLS_DIR)/rkflashtool
	$(Q)cd $(TOOLS_DIR)/rkflashtool && git checkout $(RKFLASHTOOL_REV) && cd - > /dev/null
	$(Q)$(MAKE) -C $(TOOLS_DIR)/rkflashtool install PREFIX=$(TOOLS_DIR)

tools/toolchain/.git:
	$(Q)mkdir -p $(TOOLS_DIR)/toolchain
	$(Q)git clone -n --depth 1 $(TOOLCHAIN_REPO_$(HOST_ARCH)) $(TOOLS_DIR)/toolchain
	$(Q)cd $(TOOLS_DIR)/toolchain && git checkout $(TOOLCHAIN_REV_$(HOST_ARCH)) && cd - > /dev/null

#rock tools
tools: tools/toolchain/.git tools/rockchip-mkbootimg/.git tools/rkflashtool/.git

boot.img: tools kernel ramdisk
	$(Q)mkdir -p $(BOARD)/rockdev/Image
	$(Q)rm -f $(BOARD)/rockdev/Image/boot-linux.img
	$(Q)cd $(BOARD)/rockdev
	$(Q)cp -v $(KERNEL_SRC)/arch/arm/boot/zImage $(BOARD)/rockdev
	$(Q)cp -v $(INITRD_DIR)/../initrd.img $(BOARD)/rockdev
ifneq ($(wildcard $(KERNEL_SRC)/resource.img),)
	$(Q)cp -v $(KERNEL_SRC)/resource.img $(BOARD)/rockdev
endif
	$(Q)cd $(BOARD)/rockdev && $(TOOLS_DIR)/bin/mkbootimg --kernel zImage --ramdisk initrd.img --second $(BOOTIMG_TARGET) -o Image/boot-linux.img && cd - > /dev/null
	$(Q)rm -rf rockdev
	$(Q)ln -s $(BOARD)/rockdev rockdev

package-file: $(PACKAGE_FILE) uboot boot.img parameter rootfs.ext4

parameter: $(PARAMETER)

nand.img emmc.img: tools package-file
	$(Q)cp -v $(PARAMETER) $(ROCKDEV_DIR)/parameter
	$(Q)cp -v $(PACKAGE_FILE) $(ROCKDEV_DIR)/package-file
	$(Q)rm -f "$(ROCKDEV_DIR)/"*.bin
	$(Q)cp -v $(UBOOT_SRC)/$(U_BOOT_BIN) ${BOARD}/rockdev
	$(Q)rm -f update_tmp.img
	$(Q)cd $(BOARD)/rockdev && $(TOOLS_DIR)/bin/afptool -pack ./ update_tmp.img && cd - > /dev/null
	$(Q)cd $(BOARD)/rockdev && $(TOOLS_DIR)/bin/img_maker -$(TYPECHIP) $(U_BOOT_BIN) 1 0 0 update_tmp.img $(IMAGE_NAME)_$@ && cd - > /dev/null
	$(Q)echo "Image is at \033[1;36m$(ROCKDEV_DIR)/$(IMAGE_NAME)_$@\033[00m"

sdcard.img : uboot boot.img rootfs.ext4 parameter
	$(Q)scripts/hwpack.sh

update:
	$(Q)cd $(KERNEL_SRC) && git checkout $(KERNEL_REV) && cd - > /dev/null
	$(Q)cd $(UBOOT_SRC) && git checkout $(UBOOT_REV) && cd - > /dev/null

distclean:
	$(Q)$(MAKE) -C $(KERNEL_SRC) distclean
	$(Q)$(MAKE) -C $(UBOOT_SRC) distclean

mrproper:
	$(Q)$(MAKE) -C $(KERNEL_SRC) mrproper
	$(Q)$(MAKE) -C $(UBOOT_SRC) mrproper

help:
	@echo " ------------------------------------------- "
	@echo "		rockchip linux bsp"
	@echo " ------------------------------------------- "
	@echo " Usage:"
	@echo "  make			- Default 'make' pack all"
	@echo "  make	tools		- Builds open source tools,then install"
	@echo ""
	@echo "  Optional targets:"
	@echo "  make	linux-config	- make menuconfig"
	@echo "  make	uboot		- compile uboot"
	@echo "  make	kernel		- compile kernel"
	@echo "  make	ramdisk		- prepare initrd.img"
	@echo "  make	rootfs.ext4	- prepare rootfs.ext4"
	@echo ""
	@echo "Packages:"
	@echo "  make	boot.img	- prepare linux-boot.img"
	@echo "  make	nand.img	- generate nand.img"
	@echo "  make	emmc.img	- generate emmc.img"
	@echo "  make	sdcard.img	- generate sdcard.img"
	@echo "  make	linux-pack	- generate update.img"
	@echo ""
	@echo "  make	clean		- delete some compiled files"
	@echo "  make	distclean	- reply to original state"
	@echo "  make	update		- update the project"
	@echo ""
