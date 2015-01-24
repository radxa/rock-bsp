.PHONY: all clean help
.PHONY: tools flash-tools uboot kernel ramdisk mkbootimg
.PHONY: rootfs linux-pack

include $(CURDIR)/.config

RAMDISK=$(BOARD)/ramdisk
INITRD=$(RAMDISK)/initrd
OUT=$(CURDIR)/$(BOARD)/out
K_O_PATH=$(OUT)/$(BOARD)-linux
U_O_PATH=$(OUT)/$(BOARD)-u-boot
U_CONFIG_H=$(U_O_PATH)/include/config.h
K_BLD_CONFIG=$(BOARD)/$(KERNEL)/.config

CROSS_COMPILE=/usr/local/arm-eabi-4.6/bin/arm-eabi-
J=$(shell expr `grep ^processor /proc/cpuinfo  | wc -l` \* 2)

#all: kernel tools rootfs uboot ramdisk mkbootimg linux-pack
all: rootfs

$(BOARD)/$(KERNEL)/.git:
	mkdir -p $(BOARD)
	git clone -n $(KERNEL_REPO) $(BOARD)/$(KERNEL)
	cd $(BOARD)/$(KERNEL) && git checkout $(KERNEL_REV)

$(K_BLD_CONFIG): $(BOARD)/$(KERNEL)/.git
	mkdir -p $(K_O_PATH)
	$(MAKE) -C $(BOARD)/$(KERNEL) O=$(K_O_PATH) ARCH=arm $(KERNEL_DEFCONFIG)

kernel: $(K_BLD_CONFIG)
	$(MAKE) -C $(BOARD)/$(KERNEL) O=$(K_O_PATH) ARCH=arm oldconfig
	$(MAKE) -C $(BOARD)/$(KERNEL) O=$(K_O_PATH) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm -j$J

rootfs: tools
	scripts/$(BOARD)_mkrootfs.sh

$(BOARD)/$(UBOOT)/.git:
	git clone -n $(UBOOT_REPO) $(BOARD)/$(UBOOT)
	cd $(BOARD)/$(UBOOT) && git checkout $(UBOOT_REV)

$(U_CONFIG_H): $(BOARD)/$(UBOOT)/.git
	mkdir -p $(U_O_PATH)
	$(MAKE) -C $(BOARD)/$(UBOOT) O=$(U_O_PATH) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm $(UBOOT_DEFCONFIG)

uboot: $(U_CONFIG_H)
	$(MAKE) -C $(BOARD)/$(UBOOT) all O=$(U_O_PATH) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm -j$J

$(INITRD)/.git:
	mkdir -p $(INITRD)
	git clone $(RAMDISK_REPO) $(INITRD)
	$(MAKE) -C $(INITRD)

#initrd.img
ramdisk: $(INITRD)/.git

$(RAMDISK)/rockchip-mkbootimg/.git:
	mkdir -p $(RAMDISK)/rockchip-mkbootimg
	git clone $(MKBOOTIMG_REPO) $(RAMDISK)/rockchip-mkbootimg
	$(MAKE) -C $(RAMDISK)/rockchip-mkbootimg
	$(MAKE) -C $(RAMDISK)/rockchip-mkbootimg install

#mkbootimg
mkbootimg: $(RAMDISK)/rockchip-mkbootimg/.git

$(BOARD)/package-tools/.git:
	mkdir -p $(BOARD)/package-tools
	git clone $(TOOLS_REPO) $(BOARD)/package-tools

#tools
tools: $(BOARD)/package-tools/.git

#$(BOARD)/rkflashtool/.git:
#	mkdir -p $(BOARD)/rkflashtool
#	git clone $(FTOOLS_REPO) $(BOARD)/rkflashtool
#	$(MAKE) -C $(BOARD)/rkflashtool
#	$(MAKE) -C $(BOARD)/rkflashtool install

#flash tools
#flash-tools: $(BOARD)/rkflashtool/.git

linux-pack: tools mkbootimg ramdisk rootfs kernel uboot
	scripts/$(BOARD)_mkupdateimg.sh

help:
	@echo ""
	@echo "rockchip linux bsp"
	@echo "Usage:"
	@echo "  make          		- Default 'make' pack all"
	@echo "  make	tools		- install tools"
	@echo "  make	flash tools	- install flash tools to flash image"
	@echo "  make	uboot		- compile uboot"
	@echo "  make	kernel		- compile kernel"
	@echo "  make	ramdisk		- prepare initrd.img"
	@echo "  make	mkbootimg	- prepare linux-boot.img"
	@echo "  make	rootfs		- prepare rootfs.img"
	@echo "  make	linux-pack	- generate update.img"
	@echo "  make	clean		- delete some useless files"
	@echo "  make	update		- update the project"
	@echo ""

clean:
	rm -rf $(K_O_PATH)
	rm -rf $(U_O_PATH)
	rm $(CURDIR)/.config
