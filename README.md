# sabrina-custom-os : Ubuntu for Chromecast with Google TV

Resources to run a custom OS like Ubuntu on Chromecast with Google TV (CCwGTV) using [a bootROM bug in the SoC](https://fredericb.info/2021/02/amlogic-usbdl-unsigned-code-loader-for-amlogic-bootrom.html).

Demo video : [Ubuntu 20.10 on Chromecast with Google TV](https://youtu.be/pBg6oJn8aZM)
[![Demo video : Ubuntu 20.10 on Chromecast with Google TV](https://img.youtube.com/vi/pBg6oJn8aZM/maxresdefault.jpg)](https://youtu.be/pBg6oJn8aZM)

# Disclaimer
You are solely responsible for any damage caused to your hardware/software/keys/DRM licences/warranty/data/cat/etc...

# Requirements

- USB flash drive
- USB-C adapter : to keep the device powered while switching cables. Must support OTG (USB-C hubs likely not compatible). Tested models : ZasLuke USB-C adapter, [INTPW USB-C adapter](https://intpw.com/collections/hub/products/intpw-usb-c-to-hdmi-adapter-for-nintendo-switch)
- USB hub : if you need additional USB devices like keyboard, mouse, etc...
- Chromecast With Google TV (sabrina) without USB password mitigation

The USB password mitigation has been enabled on units manufactured in December 2020 and after. For units manufactured before, the mitigation was enabled by software update in February 2021.
It's not possible to disable/change the password since it's burnt into the chip (efuses).

# Content
- /bin/ : prebuilt set of required tools
  - [amlogic-usbdl](https://github.com/frederic/amlogic-usbdl) : to exploit bootROM bug to gain arbitrary code execution
  - [aml_encrypt_g12a](https://github.com/khadas/u-boot/blob/khadas-vims-pie/fip/g12a/aml_encrypt_g12a) : to repack U-Boot image into bootloader
  - [mkimage](https://github.com/khadas/u-boot/blob/khadas-vims-pie/tools/mkimage.c) : to make images with U-Boot file format
  - [update](https://github.com/khadas/utils/blob/master/aml-flash-tool/tools/linux-x86/update) : client for the USB Burning protocol implemented in Amlogic bootloaders
- /bootloader/ : prebuilt bootloader image to upload via USB
  - sabrina.bl2.noSB.noARB.img : BL2 customized to remove Secure Boot check on BL33 and anti-rollback check
  - sabrina.bootloader.bin : bootloaders (BL3x, DDR, etc...) repacked with [custom U-Boot image](https://github.com/frederic/sabrina-uboot)
- /rootfs/ : prebuilt files to add in Ubuntu boot partition
  - dtb.img : Device Tree Blob from project [sabrina-linux](https://github.com/frederic/sabrina-linux)
  - env.txt : environment variables imported by boot script
  - s905_autoscript : boot script run by U-Boot
  - uInitrd : original ramdisk repacked for U-Boot
  - zImage : [custom Linux kernel](https://github.com/frederic/sabrina-linux) image
- /scripts/ : few scripts used to create the images in this repo
- /boot.sh : exploit bootROM to load unsigned bootloaders over USB

# Guide
This guide describes steps to boot Ubuntu from an USB flash drive. Internal flash memory is not modified.

The two first steps are a one-time installation process to prepare the USB flash drive. The third step is required each time you boot from the USB flash drive.

## 1. Write Ubuntu image to USB drive
Recommended Ubuntu image : [Ubuntu 20.10 Preinstalled desktop image for Raspberry Pi Generic (64-bit ARM) computers (preinstalled SD Card image)](https://cdimage.ubuntu.com/releases/20.10/release/ubuntu-20.10-preinstalled-desktop-arm64+raspi.img.xz)

```shell
$ dd if=ubuntu-20.10-preinstalled-desktop-arm64+raspi.img of=/dev/<device> bs=1M
```
Alternative working Ubuntu image : [Ubuntu for Khadas VIM3L](https://dl.khadas.com/Firmware/VIM3L/Ubuntu/SD_USB/VIM3L_Ubuntu-gnome-focal_Linux-4.9_arm64_SD-USB_V0.9-20200530.7z)

## 2. Copy files from rootfs/ to system-boot partition
Since the pre-installed Ubuntu image is designed for a different board, we have to update few files in *system-boot* partition to support our target.

Copy all the files from rootfs/ directory to the *system-boot* partition of USB flash drive.

## 3. Booting from USB flash drive
- Prepare USB hub by connecting USB flash drive and other devices needed (i.e. keyboard, mouse).
```
Legend: [Device] (male plug)

    _[USB flash drive]
   /  _[USB keyboard]
  |  /  _[USB mouse] 
  | |  / 
  | | |
[USB hub]
    |
 (USB-A)
```
- Connect both power supply (USB type-C) and host computer (USB type-A) to the USB-C adapter.
- Connect device's HDMI cable to screen.
- Press and hold physical button on the back of the CCwGTV device while connecting USB-C adapter to it.
```
      
        [Host computer]
[Power] (USB-C)
    |      |
(USB-PD)(USB-A)
[USB-C adapter]
       |
    (USB-C)
    [CCwGTV]
       |
     (HDMI)
    [Screen]
```
The host should see a new USB device :
```text
[10504.840173] usb 1-4.3.1: new high-speed USB device number 16 using xhci_hcd
[10504.979469] usb 1-4.3.1: New USB device found, idVendor=1b8e, idProduct=c003, bcdDevice= 0.20
[10504.979495] usb 1-4.3.1: New USB device strings: Mfr=1, Product=2, SerialNumber=0
[10504.979514] usb 1-4.3.1: Product: GX-CHIP
[10504.979525] usb 1-4.3.1: Manufacturer: Amlogic
```
- Release the button once this device has been detected by host computer.
- Execute script **boot&#46;sh** to load & run the custom bootloader.

U-Boot starts once script execution is over. It waits 10 seconds before attempting to boot from USB flash drive.
- Disconnect host computer cable from USB-C adapter and connect USB hub instead.
```
            _[USB flash drive]
           /  _[USB keyboard]
          |  /  _[USB mouse] 
          | |  / 
          | | |
[Power] [USB hub]
    |      |
(USB-PD)(USB-A)
[USB-C adapter]
       |
    (USB-C)
    [CCwGTV]
       |
     (HDMI)
    [Screen]
```

### Alternative : load kernel via USB
It's also possible to load kernel/ramdisk/dtb images directly via USB. The rest of OS is still loaded from USB flash drive.
This is mostly useful for rapid testing during kernel development.

Once bootloaders are loaded using **boot&#46;sh** script, instead of releasing the physical button, hodl until U-Boot starts in *USB Burning* mode : a new USB device will appear on your host. Then, the **update** tool allows operations like executing U-Boot commands, reading/writing memory, etc...

Use script **upload-kernel&#46;sh** to upload and run Linux kernel via USB.

# Current progress
- [x] Boot
- [x] USB Host
- [x] HDMI video
- [x] eMMC support
- [ ] Wifi
- [ ] Audio
- [ ] Bluetooth

# Contribute
- U-Boot : [sabrina-uboot](https://github.com/frederic/sabrina-uboot)
- Linux : [sabrina-linux](https://github.com/frederic/sabrina-linux)