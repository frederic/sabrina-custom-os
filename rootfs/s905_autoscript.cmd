echo "Starting S905D3G autoscript...";

setenv kernel_loadaddr "0x11000000"
setenv dtb_loadaddr "0x1000000"
setenv initrd_loadaddr "0x13000000"
setenv env_loadaddr "0x20000000"
setenv hwver "VIM3.V12"
setenv uboottype "vendor";
setenv khadas_board "VIM3L";

setenv fb_addr "0x3d800000";
setenv outputmode "1080p60hz";
setenv hdmimode "";
setenv display_layer "osd0";
setenv wol_enable "0";
setenv loglevel "7";

echo "uboot type: $uboottype";

if test "X${uboottype}" = "Xmainline"; then
	setenv hdmiargs "";
	setenv ddr "";
	setenv wol "";
	setenv rebootmode "";
else
	setenv hdmiargs "logo=${display_layer},loaded,${fb_addr} vout=${outputmode},enable"
	setenv ddr "ddr_size=${ddr_size}";
	setenv wol "wol_enable=${wol_enable}";
	setenv rebootmode "reboot_mode=${reboot_mode}"
fi;

if test "X${autoscript_source}" = "Xmmc"; then
	echo "autoscript loaded from: mmc";
	setenv devs "mmc";
else if test "X${autoscript_source}" = "Xusb"; then
	echo "autoscript loaded from: usb";
	setenv devs "usb";
else
	setenv devs "mmc usb";
fi;fi;
setenv mmc_devplist "1 5"
setenv mmc_devnums "0 1 2"
setenv usb_devplist "1"
setenv usb_devnums "0 1 2 3"

setenv boot_start booti ${kernel_loadaddr} ${initrd_loadaddr} ${dtb_loadaddr}

## First, boot from mmc
## Second, boot from USB storage
echo "devs: $devs";
setenv dev "usb";
echo "dev: $dev";
if test "X${dev}" = "Xmmc"; then
	setenv devplist ${mmc_devplist};
	setenv devnums ${mmc_devnums};
else if test "X${dev}" = "Xusb"; then
	setenv devplist ${usb_devplist};
	setenv devnums ${usb_devnums};
fi;fi;
echo "devplist: $devplist";
echo "devnums: $devnums";
#for dev_num in ${devnums}; do
setenv dev_num "0";
setenv distro_bootpart ${usb_devplist};
echo "Scanning ${dev} ${dev_num}:${distro_bootpart}...";
setenv load_method "fatload";
setenv mark_prefix "";
setenv imagetype "SD-USB";
if ${load_method} ${dev} ${dev_num}:${distro_bootpart} ${initrd_loadaddr} uInitrd; then
	if ${load_method} ${dev} ${dev_num}:${distro_bootpart} ${kernel_loadaddr} zImage; then
		if ${load_method} ${dev} ${dev_num}:${distro_bootpart} ${dtb_loadaddr} dtb.img; then
			if ${load_method} ${dev} ${dev_num}:${distro_bootpart} ${env_loadaddr} /boot/env.txt || ${load_method} ${dev} ${dev_num}:${distro_bootpart} ${env_loadaddr} env.txt; then
				echo "Import env.txt"; env import -t ${env_loadaddr} ${filesize};
			fi;
			if test "X${rootdev}" = "X"; then
				echo "rootdev is missing! use default: root=LABEL=ROOTFS!";
				setenv rootdev "LABEL=ROOTFS";
			fi;
			if test "X${dev}" = "Xmmc"; then
				part uuid mmc ${dev_num}:${distro_bootpart} ubootpartuuid;
				if test "X${ubootpartuuid}" = "X"; then
					echo "Can not get u-boot part UUID, set to NULL";
					setenv ubootpartuuid "NULL";
				fi;
			else
				setenv ubootpartuuid "NULL";
			fi;
			if test "X${custom_ethmac}" != "X"; then
				echo "Found custom ethmac: ${custom_ethmac}, overwrite eth_mac!";
				setenv eth_mac ${custom_ethmac};
			fi;
			if test "X${eth_mac}" = "X" || test "X${eth_mac}" = "X00:00:00:00:00:00"; then
				echo "Set default mac address to ethaddr: ${ethaddr}!";
				setenv eth_mac ${ethaddr};
				setenv saveethmac "save_ethmac=yes";
			fi;
			if test "X${loglevel}" != "X"; then
				setenv log "loglevel=${loglevel}"
			fi
			if test -e ${dev} ${dev_num}:${distro_bootpart} ${mark_prefix}.next; then
				echo "Booting mainline kernel...";

				# Setup dtb for different HW version
				fdt addr ${dtb_loadaddr};
				fdt resize 65536;

				if test "X${hwver}" = "XVIM1.V14"; then
					fdt set /soc/bus@c1100000/i2c@87c0/khadas-mcu@18 hwver "VIM1.V14";
				else if test "X${hwver}" = "XVIM2.V14"; then
					fdt set /soc/bus@c1100000/i2c@87c0/khadas-mcu@18 hwver "VIM2.V14";
					fdt set /gpio-fan status "disabled";
					fdt set /fan status "disabled";
				else if test "X${hwver}" = "XVIM3.V11" || test "X${hwver}" = "XVIM3.V12"; then
					fdt set /soc/bus@ff800000/i2c@5000/khadas-mcu@18 hwver ${hwver};
					kbi init;
					kbi portmode r;

					fdt get value usb2_phy0 /soc/bus@ff600000/phy@36000 phandle;
					fdt get value usb2_phy1 /soc/bus@ff600000/phy@3a000 phandle;
					fdt get value usb3_pcie_phy /soc/bus@ff600000/phy@46000 phandle;

					if test ${port_mode} = 0; then
						fdt set /soc/usb@ffe09000 phys <${usb2_phy0} ${usb2_phy1} ${usb3_pcie_phy} 0x00000004>;
						fdt set /soc/usb@ffe09000 phy-names "usb2-phy0" "usb2-phy1" "usb3-phy0";
						fdt set /soc/pcie@fc000000 status disabled;
					else
						fdt set /soc/usb@ffe09000 phys <${usb2_phy0} ${usb2_phy1}>;
						fdt set /soc/usb@ffe09000 phy-names "usb2-phy0" "usb2-phy1";
						fdt set /soc/pcie@fc000000 status okay;
					fi;
				fi;fi;fi;
			else
				echo "Booting legacy kernel...";

				# Setup dtb for different HW version
				echo "loading fdt...";
				fdt addr ${dtb_loadaddr};
				echo "resizing fdt...";
				fdt resize 65536;
				if test "X${hwver}" = "XVIM1.V14"; then
					fdt set /soc/cbus@c1100000/i2c@87c0/khadas-mcu hwver "VIM1.V14";
				else if test "X${hwver}" = "XVIM2.V14"; then
					fdt set /fan status "disabled";
					fdt set /i2c@c11087c0/khadas-mcu hwver "VIM2.V14";
					fdt set /soc/cbus@c1100000/i2c@87c0/khadas-mcu hwver "VIM2.V14";
				else if test "X${hwver}" = "XVIM3.V11" || test "X${hwver}" = "XVIM3.V12"; then
					echo "fdt setting /soc/aobus@ff800000/i2c@5000/khadas-mcu...";
					fdt set /soc/aobus@ff800000/i2c@5000/khadas-mcu hwver ${hwver};
					echo "fdt setting /usb3phy@ffe09080...";
					fdt set /usb3phy@ffe09080 portnum <1>;
					echo "fdt setting /pcieA@fc000000...";
					fdt set /pcieA@fc000000 status disabled;
					fi;
				fi;fi;fi;
			fi;

			if test "X${uboottype}" != "Xmainline"; then
				if test "X${hdmi_autodetect}" != "Xyes"; then
					if test "X${hdmi}" = "X"; then
						echo "HDMI: 'hdmi' value is missing, set to default value 720p60hz!";
						setenv hdmi 720p60hz;
					fi;
					echo "HDMI: Custom mode: ${hdmi}";
					setenv hdmiargs "${hdmiargs} hdmimode=${hdmi}";
				else
					echo "HDMI: Autodetect: ${hdmimode}";
					setenv hdmiargs "${hdmiargs} hdmimode=${hdmimode}";
				fi;
			fi;
			echo "running preboot_cmd...";
			run preboot_cmd;
			echo "running boot_start...";
			run boot_start;
		fi;
	fi;
fi;

echo "EOF!!!";
# Rebuilt
# mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "S905 autoscript" -d /boot/s905_autoscript.cmd /boot/s905_autoscript
# mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "S905 autoscript" -d /boot/s905_autoscript.cmd /boot/boot.scr
