#!/bin/sh

DIR=$(dirname $(realpath $0))
$DIR/bin/amlogic-usbdl $DIR/bootloader/sabrina.bl2.noSB.noARB.img
$DIR/bin/update bl2_boot $DIR/bootloader/sabrina.bootloader.bin
echo "U-Boot waits for 10 seconds before attempting to boot from USB drive"