rock-bsp
===========
Introduction
---------------

rock-bsp is a collection of bootloader(u-boot), Linux kernel, flashing tools and toolchains for making a Linux images for radxa products as well as other rockchip based platform. Currently supported boards are:

* rock pro
* rock lite
* rock2 square 

supported Linux distributions are `Debian` and `Ubuntu`.

Getting Started
------------------
1. get the source code

    git clone https://github.com/radxa/rock-bsp.git
    cd rock-bsp

2. Choose a board doing `./config.sh board`, or `./config.sh` to see
   the list of supported boards.

    ./config.sh 
    Usage: ./config.sh < board >

    supported boards:
	* rock2_square
	* rock_lite
	* rock_pro


3. Run `make` to build and pack nand/emmc/sdcard image or `make help` to list available targets

    make
