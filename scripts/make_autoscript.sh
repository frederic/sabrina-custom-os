#!/bin/sh

DIR=$(dirname $(realpath $0))
$DIR/../bin/mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "S905 autoscript" -d $DIR/../rootfs/s905_autoscript.cmd $DIR/../rootfs/s905_autoscript