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
.PHONY: uboot kernel rootfs linux-pack

include $(CURDIR)/.config

OUTPUT_DIR=$(CURDIR)/output
LINUX_SRC=$(BOARD)/$(KERNEL)
export UBOOT_SRC=$(CURDIR)/$(BOARD)/$(UBOOT)
RAMDISK=$(CURDIR)/rockdev/ramdisk
INITRD=$(RAMDISK)/initrd
K_O_PATH=$(OUTPUT_DIR)/$(BOARD)/$(BOARD)-linux
export U_O_PATH=$(OUTPUT_DIR)/$(BOARD)/$(BOARD)-uboot
U_CONFIG_H=$(UBOOT_SRC)/include/config.h
K_BLD_CONFIG=$(LINUX_SRC)/.config

CROSS_COMPILE=$(CURDIR)/available-tools/arm-eabi-4.6/bin/arm-eabi-
#J=$(shell expr `grep ^processor /proc/cpuinfo  | wc -l` \* 2)
J=12
Q=@

#all: attention kernel tools rootfs uboot ramdisk mkbootimg linux-pack
all: rootfs tools toolchain ramdisk kernel uboot linux-pack

$(LINUX_SRC)/.git:
	$(Q)mkdir -p $(LINUX_SRC)
	$(Q)git clone -n $(KERNEL_REPO) $(LINUX_SRC)
	$(Q)cd $(LINUX_SRC) && git checkout $(KERNEL_REV)

$(K_BLD_CONFIG): $(LINUX_SRC)/.git
	$(Q)mkdir -p $(K_O_PATH)/modules
	$(Q)$(MAKE) -C $(LINUX_SRC) ARCH=arm $(KERNEL_DEFCONFIG)

kernel: $(K_BLD_CONFIG)
	$(Q)$(MAKE) -C $(LINUX_SRC) ARCH=arm oldconfig
	$(Q)$(MAKE) -C $(LINUX_SRC) $(MAKE_ARG) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm -j$J
	$(Q)$(MAKE) -C $(LINUX_SRC) $(MAKE_ARG) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -j$J

linux-config: $(K_BLD_CONFIG)
	$(Q)$(MAKE) -C $(LINUX_SRC) ARCH=arm menuconfig

rootfs: tools
	$(Q)scripts/mkrootfs.sh

$(UBOOT_SRC)/.git:
	$(Q)mkdir -p $(UBOOT_SRC)
	$(Q)git clone -n $(UBOOT_REPO) $(UBOOT_SRC)
	$(Q)cd $(UBOOT_SRC) && git checkout $(UBOOT_REV)

$(U_CONFIG_H): $(UBOOT_SRC)/.git
	$(Q)mkdir -p $(K_O_PATH)
	$(Q)$(MAKE) -C $(UBOOT_SRC) mrproper
	$(Q)$(MAKE) -C $(UBOOT_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm $(UBOOT_DEFCONFIG)

uboot: $(U_CONFIG_H)
	$(Q)$(MAKE) -C $(UBOOT_SRC) all CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm -j$J

$(INITRD)/.git:
	$(Q)mkdir -p $(INITRD)
	$(Q)git clone $(RAMDISK_REPO) $(INITRD)
	$(Q)$(MAKE) -C $(INITRD)

#initrd.img
ramdisk: $(INITRD)/.git

$(RAMDISK)/rockchip-mkbootimg/.git:
	$(Q)mkdir -p $(RAMDISK)/rockchip-mkbootimg
	$(Q)git clone $(MKBOOTIMG_REPO) $(RAMDISK)/rockchip-mkbootimg
	$(Q)$(MAKE) -C $(RAMDISK)/rockchip-mkbootimg
	$(Q)$(MAKE) -C $(RAMDISK)/rockchip-mkbootimg install

#tools
tools: $(RAMDISK)/rockchip-mkbootimg/.git

available-tools/arm-eabi-4.6/.git:
	$(Q)scripts/toolchain.sh

#toolchain
toolchain: available-tools/arm-eabi-4.6/.git

#linux-pack: tools mkbootimg ramdisk rootfs kernel uboot
linux-pack:
	$(Q)scripts/$(BOARD)_mkupdateimg.sh

update:
	$(Q)cd $(LINUX_SRC) && git checkout $(KERNEL_REV)
	$(Q)cd $(UBOOT_SRC) && git checkout $(UBOOT_REV)

distclean:
	rm -rf $(OUTPUT_DIR)/*
	rm $(CURDIR)/.config
clean:
	$(Q)$(MAKE) -C $(K_O_PATH) clean
	$(Q)$(MAKE) -C $(U_O_PATH) clean
mrproper:
	$(Q)$(MAKE) -C $(K_O_PATH) mrproper
	$(Q)$(MAKE) -C $(U_O_PATH) mrproper

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
