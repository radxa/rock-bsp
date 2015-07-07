#!/bin/sh -e
#
# (C) Copyright 2015, Radxa Limited
# support@radxa.com
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.


if [ ! -d configs/ ];then
	echo "config does not exist"
fi

list_boards() {
	ls -1 configs/*_config |
	sed -n -e 's|.*/\([^/]\+\)\_config$|\1|p' | sort -V |
	sed -e 's|.*|\t* \0|'
}

usage() {
	cat <<-EOT >&2
	Usage: $0 <board>

	supported boards images:
	EOT
	list_boards
}

if [ $# -eq 0 ];then
	usage
elif [ -e "configs/$1_config" ];then
	cat configs/$1_config > .config
	cat configs/defconfig >> .config

	echo "$1 configured. Now run \`make\`"
else
	echo "$1: invalid board name" >&2
	usage
	exit 1
fi

