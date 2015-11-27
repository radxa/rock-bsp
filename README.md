rock-bsp
===========
Introduction
---------------

rock-bsp is a collection of bootloader(u-boot), Linux kernel, flashing tools and toolchains for making a Linux images for radxa products as well as other rockchip based platform. Currently supported boards are:

* rock full(2013)
* rock pro
* rock lite
* rock2 square 
* q7 rk3188

supported Linux distributions are `Debian` and `Ubuntu`.

Getting Started
------------------
0. install required packages


    sudo apt-get install build-essential lzop libncurses5-dev libssl-dev libusb-1.0-0-dev

you also need to install the following if you run it on 64bit system:

    sudo apt-get install libc6-i386

1. get the source code


    git clone https://github.com/radxa/rock-bsp.git
    cd rock-bsp

2. Choose a board doing `./config.sh board`, or `./config.sh` to see
   the list of supported boards.


    ./config.sh 
    Usage: ./config.sh < board >
    supported boards:
	* q7_rk3188
	* q7_rk3188_sdcard
	* rock
	* rock2_square
	* rock2_square_sdcard
	* rock_lite
	* rock_lite_lvds
	* rock_pro
	* rock_pro_lvds
	* rock_pro_lvds_sdcard
	* rock_pro_sdcard
	* rock_sdcard


3. Run `make` to build and pack nand/emmc/sdcard image or `make help` to list available targets


    make

Configuration
-------------
The directory structure of rock-bsp is as below:

    .
    ├── configs
    │   ├── defconfig
    │   ├── *board*_config
    ├── package-file
    │   ├── *board*-package-file
    ├── parameter
    │   ├── *board*-parameter
    ├── rootfs
    │   └── rootfs_null.ext4
    └── tools
        └── scripts

* configs: define board kernel/u-boot repository, revision, defconfigs and rootfs name/url.
* package-file: define what can be packed into the image
* parameter: define kernel command line, emmc/nand partitions
* rootfs: put your rootfs image here and add the image name in board_config
* tools: tools developed by linux-rockchip community and arm toolchains
    
