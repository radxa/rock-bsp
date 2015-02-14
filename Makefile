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
.PHONY: tools ramdisk toolchain
.PHONY: uboot kernel nand.img emmc.img sdcard.img rootfs

include .config

OUTPUT_DIR=$(CURDIR)/output/$(BOARD)-modules
KERNEL_SRC=$(CURDIR)/$(BOARD)/$(KERNEL)
UBOOT_SRC=$(CURDIR)/$(BOARD)/$(UBOOT)
TOOLS_DIR=$(CURDIR)/tools
TOOLS_INSTALL=$(CURDIR)/tools
INITRD_DIR=$(CURDIR)/$(BOARD)/initrd
ROCKDEV_DIR=$(CURDIR)/$(BOARD)/rockdev
U_CONFIG_H=$(UBOOT_SRC)/include/config.h
K_BLD_CONFIG=$(KERNEL_SRC)/.config

export KERNEL_SRC UBOOT_SRC OUTPUT_DIR ROCKDEV_DIR INITRD_DIR

CROSS_COMPILE=$(CURDIR)/tools/toolchain/arm-eabi/bin/arm-eabi-
#J=$(shell expr `grep ^processor /proc/cpuinfo  | wc -l` \* 2)
J=12
Q=@

#all: attention kernel tools rootfs uboot ramdisk mkbootimg linux-pack
all: tools toolchain ramdisk kernel uboot

$(KERNEL_SRC)/.git:
	$(Q)mkdir -p $(KERNEL_SRC)
	$(Q)git clone -n $(KERNEL_REPO) $(KERNEL_SRC)
	$(Q)cd $(KERNEL_SRC) && git checkout $(KERNEL_REV) && cd - > /dev/null

$(K_BLD_CONFIG): $(KERNEL_SRC)/.git
	$(Q)mkdir -p $(KERNEL_SRC)/modules
	$(Q)$(MAKE) -C $(KERNEL_SRC) ARCH=arm $(KERNEL_DEFCONFIG)

kernel: $(K_BLD_CONFIG)
	$(Q)$(MAKE) -C $(KERNEL_SRC) ARCH=arm oldconfig
	$(Q)$(MAKE) -C $(KERNEL_SRC) $(KERNEL_TARGET) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm -j$J
	$(Q)$(MAKE) -C $(KERNEL_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm INSTALL_MOD_PATH=$(OUTPUT_DIR) modules
	$(Q)$(MAKE) -C $(KERNEL_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm INSTALL_MOD_PATH=$(OUTPUT_DIR) modules_install

linux-config: $(K_BLD_CONFIG)
	$(Q)$(MAKE) -C $(KERNEL_SRC) ARCH=arm menuconfig

rootfs:
	$(Q)scripts/mkrootfs.sh

$(UBOOT_SRC)/.git:
	$(Q)mkdir -p $(UBOOT_SRC)
	$(Q)git clone -n $(UBOOT_REPO) $(UBOOT_SRC)
	$(Q)cd $(UBOOT_SRC) && git checkout $(UBOOT_REV) && cd - > /dev/null

$(U_CONFIG_H): $(UBOOT_SRC)/.git
	$(Q)mkdir -p $(UBOOT_SRC)
	$(Q)$(MAKE) -C $(UBOOT_SRC) mrproper
	$(Q)$(MAKE) -C $(UBOOT_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm $(UBOOT_DEFCONFIG)

uboot: $(U_CONFIG_H)
	$(Q)$(MAKE) -C $(UBOOT_SRC) all CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm -j$J

$(INITRD_DIR)/.git:
	$(Q)mkdir -p $(INITRD_DIR)
	$(Q)git clone $(INITRD_REPO) $(INITRD_DIR)
	$(Q)$(MAKE) -C $(INITRD_DIR)

#initrd.img
ramdisk: $(INITRD_DIR)/.git

tools/rockchip-mkbootimg/.git:
	$(Q)mkdir -p $(TOOLS_DIR)/rockchip-mkbootimg
	$(Q)git clone $(MKBOOTIMG_REPO) $(TOOLS_DIR)/rockchip-mkbootimg
	$(Q)$(MAKE) -C $(TOOLS_DIR)/rockchip-mkbootimg install PREFIX=$(TOOLS_INSTALL)

tools/rkflashtool/.git:
	$(Q)mkdir -p $(TOOLS_DIR)/rkflashtool
	$(Q)git clone $(RKFLASHTOOL_REPO) $(TOOLS_DIR)/rkflashtool
	$(Q)$(MAKE) -C $(TOOLS_DIR)/rkflashtool install PREFIX=$(TOOLS_INSTALL)

tools/toolchain/arm-eabi:
	$(Q)scripts/toolchain.sh

#rock tools
tools: tools/toolchain/arm-eabi tools/rockchip-mkbootimg/.git tools/rkflashtool/.git

nand.img emmc.img: tools ramdisk kernel uboot
	$(Q)scripts/buildimg.sh

sdcard.img : tools ramdisk kernel uboot
	$(Q)scripts/hwpack.sh

update:
	$(Q)cd $(KERNEL_SRC) && git checkout $(KERNEL_REV) && cd - > /dev/null
	$(Q)cd $(UBOOT_SRC) && git checkout $(UBOOT_REV) && cd - > /dev/null

distclean:
	$(Q)$(MAKE) -C $(KERNEL_SRC) distclean
	$(Q)$(MAKE) -C $(UBOOT_SRC) distclean
clean:
	$(Q)$(MAKE) -C $(KERNEL_SRC) clean
	$(Q)$(MAKE) -C $(UBOOT_SRC) clean
mrproper:
	$(Q)$(MAKE) -C $(KERNEL_SRC) mrproper
	$(Q)$(MAKE) -C $(UBOOT_SRC) mrproper

help:
	@echo ""
	@echo "		rockchip linux bsp"
	@echo " ------------------------------------------- "
	@echo "| error:                                    |"
	@echo "| No such file or directory                 |"
	@echo "| No rule to make target                    |"
	@echo "| '/build3/jim/rock-bsp/.config'. stop      |"
	@echo "| solutions : ***  'reference README'  ***  |"
	@echo " ------------------------------------------- "
	@echo " Usage:"
	@echo "  make			- Default 'make' pack all"
	@echo "  make	tools		- Builds open source tools,then install"
	@echo "  make	flash tools	- install flash tools to flash image"
	@echo ""
	@echo "  Optional targets:"
	@echo "  make	linux-config	- make menuconfig"
	@echo "  make	uboot		- compile uboot"
	@echo "  make	kernel		- compile kernel"
	@echo "  make	ramdisk		- prepare initrd.img"
	@echo "  make	rootfs		- prepare rootfs.img"
	@echo ""
	@echo "Packages:"
	@echo "  make	mkbootimg	- prepare linux-boot.img"
	@echo "  make	linux-pack	- generate update.img"
	@echo ""
	@echo "  make	clean		- delete some useless files"
	@echo "  make	update		- update the project"
	@echo ""
