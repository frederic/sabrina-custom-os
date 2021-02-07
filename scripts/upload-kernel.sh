#!/bin/sh
#Upload & boot kernel/ramdisk/dtb when U-Boot is in 'USB Burning' mode
DIR=$(dirname $(realpath $0))
UPDTOOL=$DIR/../bin/update
KERNEL=$DIR/../rootfs/zImage
KERNEL_ADDR=0x11000000
DTB=$DIR/../rootfs/dtb.img
DTB_ADDR=0x1000000
INITRD=$DIR/../rootfs/uInitrd
INITRD_ADDR=0x13000000
ENV=$DIR/../rootfs/env.txt
ENV_ADDR=0x20000000

$UPDTOOL write $KERNEL $KERNEL_ADDR
$UPDTOOL write $DTB $DTB_ADDR
$UPDTOOL write $INITRD $INITRD_ADDR
$UPDTOOL write $ENV $ENV_ADDR
$UPDTOOL bulkcmd "env import -t $ENV_ADDR 0x1000"
$UPDTOOL bulkcmd "fdt addr ${DTB_ADDR}"
$UPDTOOL bulkcmd "fdt resize 65536" # no idea what im doing here
echo 'Sleeping for 10 seconds before booting, time to insert USB disk...'
$UPDTOOL bulkcmd "sleep 10; booti $KERNEL_ADDR $INITRD_ADDR $DTB_ADDR"