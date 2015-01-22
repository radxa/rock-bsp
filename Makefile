.PHONY: all clean help

include $(CURDIR)/.config
OUT=$(CURDIR)/${BOARD}/out
K_O_PATH=${OUT}/$(KERNEL_DEFCONFIG)-linux

CROSS_COMPILE=/usr/local/arm-eabi-4.7/bin/arm-eabi-
J=$(shell expr `grep ^processor /proc/cpuinfo  | wc -l` \* 2)
all: kernel

kernel: ${BOARD}/kernel/.git
	mkdir -p ${K_O_PATH}
	$(MAKE) -C ${BOARD}/kernel O=$(K_O_PATH) CROSS_COMPILE=${CROSS_COMPILE} ARCH=arm ${KERNEL_DEFCONFIG} 
	$(MAKE) -C ${BOARD}/kernel O=$(K_O_PATH) CROSS_COMPILE=${CROSS_COMPILE} ARCH=arm -j$J 

${BOARD}/kernel/.git:
	mkdir -p ${BOARD}
	git clone -n ${KERNEL_REPO} ${BOARD}/kernel
	cd ${BOARD}/kernel && git checkout ${KERNEL_REV}
help:
	@echo "rockchip linux bsp"
clean:
	rm -rf ${OUT}
	rm $(CURDIR)/.config
