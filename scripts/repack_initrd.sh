#!/bin/sh
# mkimage tool from khadas/u-boot/build/tools/mkimage
# initrd.img : original file from Ubuntu pre-installed media

DIR=$(dirname $(realpath $0))
$DIR/../bin/mkimage -n uInitrd -A arm -O linux -T ramdisk -C gzip -d $DIR/../rootfs/initrd.img $DIR/../rootfs/uInitrd