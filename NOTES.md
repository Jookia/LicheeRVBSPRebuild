NOTES
=====

This document is a summary of the notes I've collected during development of this project. 
Hopefully it can be of use to others.

Buyer beware
------------

A friend of mine bought me a Lichee RV 86 Panel with a 720p screen to evaluate as a 3D printer control board. Out of the box with the SD card that came with it the device had the following problems:

- The LCD display did not display correctly
- The LCD touch screen did not work

I tried every single image and every single fex update file to fix this.

I emailed Sipeed about this issue and didn't get any response at all. Sipeed don't appear active in their Telegram group. I also can't sign up to their forum without WeChat, which seems like a nightmare to install and track on my Galaxy S2 phone.

Sipeed provides source code for the Lichee RV series in the form of a docker container containing the source code based on an Allwinner BSP tree. This source code fails to build on my machine, contains scattered uncommitted changes (including some hidden by a gitignore file), and contains a ton of proprietary Allwinner packaging tools. This source code when built is interdependent and can't be easily mixed with mainline builds of U-Boot or Linux.

In order to even get a development environment to even start fixing my LCD screen I've had to spend weeks reverse engineering what this BSP does to build and generate an image that runs and reproduces my failure.

Getting the LCD in my device to work required using a different panel driver and different touch screen driver. From this I'm guessing a part has been swapped in the supply chain somewhere. This not being immediately caught in testing certainly raises a red flag for me.

I really like this board, it's extremely great value for the price! But this lack of care in development, production, testing, and customer service makes me extremely hesitant to suggest buying this board unless you're ready to deal with being sent a faulty product. I would give it a pass until something better comes along or Sipeed gets their act together.

Power
-----

The board comes with a connector that lets you power it using a barrel jack. The barrel jack voltage must be around 6V or higher in order to regulate properly.

Powering using a 5V source is done using the USB or serial ports. The UART port drops around 0.4V over a diode to avoid back powering if it's not the main power source. The board seems to hang around 0.4A of current draw, or 2W of power. Around 160mW of that is loss over the diode if you're powering by the UART USB port.

In my tests with the USB cable that came with it and my computer's front USB ports the voltage drop can be significant, leaving the 5V rail at 4.8V or 4.4V depending on which USB port you use.

For some reason the CH340 serial adapter is only powered by the UART USB port. The UART pins have no physical pull-up resistors so this leaves them relying on the CPU to pull-up the voltage.

I've seen the board hang during boot once or twice and I suspect it's from noise on the UART causing U-Boot to interrupt the boot. This shouldn't happen as the CPU does pull the voltages up but I haven't investigated this further.

Networking
----------

There's no flash memory storing the Ethernet MAC address so it's random on every boot. U-Boot is not used to store the address from what I've seen either.

The Panel Wi-Fi chip is an XR829. There are no out of tree drivers for this chip so you must use the supplied kernel. This might improve in the future, but it also might not.

The device tree lacks any indicator the XR829 driver should be probed so you must manually modprobe it yourself at boot. You can do this by dumping a file containing just ```xr829``` in ```/etc/modules-load.d/xr829.conf``` on systemd-enabled systems. You will need firmware which is available in the Allwinner or sunxi BSP. This repository fetches it automatically.

I have had loading the module sometimes fail with an error about the module being unable to probe correctly. Lowering the kernel loglevel seems to have fixed this.

There are variant of the plain dock that use the XR829 but newer models apparently use the Realtek RTL8723DS Wi-Fi chip. This chip has an out of tree driver, but firmware must be extracted from Sipeed's images.

If you want to run mainline the best choice here is to add a USB Wi-Fi adapter.

LCD
---

The LCD I have requires the following to work properly in Linux and U-Boot:

- Pin setup from the 480p device tree
- Timings from the 720p device tree
- The default_lcd driver for the LCD configuration
- A muxsel value to be added to the backlight PWM in the kernel's tree that U-Boot loads
- The reset pin to be inverted in U-Boot's device tree but not the kernel's

The touch screen needs the following modifications to work in Linux:

- The edt-ft5x06 driver needs to be used for the touch screen as the default driver misses button release events
- Modifications to the device tree to use the edt-ft5x06 driver
- The reset pin to be inverted for the new driver
- Extra X configuration manually specifying the touch screen

As a side note I found during development that the adhesive gluing the display to the palstic case failed and the LCD was no longer secured properly.

Disk layout
-----------

For my BSP rebuild I went with the following disk format. You can go with something different but the SPL and TOC locations must stay.

The format of this list is offset, size, description.

- 0K, 1K: MBR and GPT header
- 8K, 64K: SPL (copy 1)
- 72K, 16K: GPT partition table
- 128K, 64K: SPL (copy 2)
- 192K, 8M: "boot-resource" partition, FAT32 filesystem
- 8384K, 1M: "dsp0" partition, unused
- 9408K, 1M: "env" partition, U-Boot environment
- 10432K, 1M: "env-redund" partition, U-Boot environment
- 12288K, 4112K: TOC (copy 1)
- 16400K, 4080K: TOC (copy 2)
- 20480K, 100M: "boot" partition, U-Boot kernel image
- 245760K, 8M: "recovery" partition, unused
- 131072K, 100%: "rootfs" partition, btrfs filesystem

The "boot-resource" partition contains ```bootlogo.bmp``` which is displayed on boot. Sipeed images include a ```magic.bin``` file with no explanation or use in the source code.

The "dsp0" partition contains proprietary firmware from Allwinner's SDK on Sipeed's image but is never loaded by Sipeed's U-Boot environment.

The "recovery" partition is empty in Sipeed's images and preserved here to keep partition numbering compatible.

I chose partition sizes bigger than Sipeed's just to allow future expansion.


Memory layout
-------------

During boot the following memory locations are used, specified in a same format as the partition table:
 
- 0x40000000, 64K: OpenSBI
- 0x40200000, 14M: Linux kernel
- 0x41000000, 16M: TOC image
- 0x42000000, 1M: U-Boot image with device tree
- 0x42100000, 1M: Kernel device tree overlay
- 0x42200000, 1M: Kernel device tree
- 0x45000000, 100%: Kernel image loaded from disk before relocation

The kernel device tree reserves 0x42000000 with a 1M size for the DSP. I'm not sure how this is set up, given the memory layout above.

Relocating the kernel can be done using U-Boot tools, but relocating other components is a bit trickier. To do so you must:

- Set CONFIG_SYS_TEXT_BASE to the new base location
- Set CONFIG_SUNXI_BOOTPKG_BASE to the new TOC location if you modify the SPL
- Modify SUNXI_DTBO_OFFSET or SUNXI_DTB_OFFSET in ```include/spare_head.h```

There may be other places but these are the primary sources of information for these memory locations.

Boot process
------------

The Allwinner boot process seems to work like this:

1. The D1 loads the SPL
1. The SPL loads the TOC
1. The SPL relocates OpenSBI, U-Boot, and the kernel device tree
1. The SPL modifies the U-Boot header to provide early boot information
1. The SPL boots U-Boot
1. U-Boot uses its own attached device tree for initialization and hardware setup
1. U-Boot fixes up the kernel device tree
1. U-Boot uses the kernel device tree to initialize the LCD
1. U-Boot reads ```bootlogo.bmp``` from the "boot-resource" partition and displays it
1. U-Boot loads the environment from the "env-redund" or "env" partitions (in that order)
1. U-Boot loads the kernel from the "boot" partition
1. U-Boot fixes up the device tree if it hasn't already
1. U-Boot appends some arguments to the kernel command line
1. U-Boot boots Linux
1. Linux boots and relies on U-Boot's hardware setup for some device initialization, such as the SD card
1. Linux hangs if you don't specify clk_ignore_unused

Each step in the boot process requires custom Allwinner setup from the previous making running custom Allwinner code on top of a mainline setup possible impossible.

In theory you should be able to run mainline components on top of an Allwinner setup but I haven't tried it.


Makefile
--------

The Makefile I wrote is something quick I hacked up. It's nothing special but offers the following useful commands.

- download-COMPONENT: Downloads the source code for a component
- prepare-COMPONENT: Cleans, patches and configures the component
- build-COMPONENT: Builds the component
- prepare: Prepares all components
- build: Builds all components
- reprepare: Re-prepares all components
- rebuild: Re-builds all projects
- partition: Formats a device and sets up partitions
- install: Copies all built components to a device
- mount: Mounts the root partition
- unmount: Unmounts the root partition

Replace 'COMPONENT' with one of the following: linux, spl, opensbi, u-boot, mkimage, firmware, dtb, toc, uimage, uenv.

Not every target supports these commands, but most do.

An example use of this during development is to modify Linux's source code, run 'make build-linux', insert your micro SD and run 'make install', remove it then test the image.

File tour
---------

This project contains a lot of files, so here's a quick listing of what they are and what they do.

First, directories:

- attic: Unmodified files from Sipeed's SDK and related sources
- attic/dts: Unmodified device trees from Sipeed's SDK
- patches: Patches by me to build and fix Sipeed's SDK
- extra: Configuration I've made myself

The attic:

- ffmpeg_enable_mipi.patch: FFmpeg changes from Sipeed's SDK
- u-boot-tina-diff.patch: Sipeed's changes to Allwinner's U-Boot
- u-boot-tina.config: Sipeed's U-Boot config
- u-boot-tina.env: Sipeed's U-Boot environment
- bootlogo.bmp: Sipeed's boot logo
- linux-tina-diff.patch: Sipeed's changes to Linux
- linux-tina.config: Sipeed's Linux config
- linux-r8723ds.patch: Patch provided by Sipeed for RTL8723DS support
- xr829_sha256sums: Hashes for XR829 firmware
- rtl8723d_sha256sums: Hashes for RTL8723DS firmware

Device trees listing with filename and device:

- uboot-board.dts - U-Boot from build directory
- board_dock.dts - Dock
- board_dock_800480.dts - Dock with 800x480 screen
- board_480.dts - Panel with 480p screen
- board_waft.dts - Panel with 480p screen but red and blue swapped
- board_480272.dts - Panel with 480x272 screen
- board_720.dts - Panel with 720p screen
- board_hdmi.dts - Panel with HDMI output (unused)
- board_mipi.dts - Panel with MIPI output (unused)
- board_1.14.dts_ - For an unknown board (broken)
- uboot-board.dts_ - U-Boot from BSP configuration directory with framebuffer format set to XRGB instead of ARGB, probably a typo (probably unused)

My patches:

- spl.patch: Adds back SPL header modification for Allwinner U-Boot
- opensbi.patch: Builds OpenSBI on upstream binutils
- u-boot.patch: Builds U-Boot out of Allwinner's tree and on upstream binutils
- linux.patch: Builds Linux on upstream binutils, removes DSP memory reservation

My configuration:

- 99-touch.conf: Xorg configuration for my display's touch screen
- board_720_new.dts: Linux device tree for my display
- uboot-board-720.dts: U-Boot device tree for my display
- u-boot.env: A simpler U-Boot environment for booting Linux