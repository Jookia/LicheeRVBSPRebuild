README
======

The Lichee RV is an Allwinner D1 (sun20iw1p1) development board.

Sipeed provides a 10GiB Docker image as a development SDK for their board.
This contains the Allwinner SDK source code, a custom toolchain, undocumented
changes and various built binaries.

This project is an attempt to rebuild the bootloader and kernel from that
specific code dump to aid in archival, testing and development.

Instructions to get the original SDK can be found here:

- [USE BSP SDK - Basic Usage - Sipeed Wiki](https://wiki.sipeed.com/hardware/en/lichee/RV/user.html#USE-BSP-SDK)

Here are some useful projects:

- [devdotnetorg's archive of Lichee RV files](https://github.com/devdotnetorg/Lichee-RV)
- [linux-sunxi.org's Allwinner D1 SDK mirror](https://linux-sunxi.org/D1_SDK_Howto)

WARNING
=======

This project is a dead end: It is incompatible with mainline Linux or U-Boot.
There will be no upgrades, bug fixes or support from Allwinner, Sipeed or me.

There is much work happening on bringing this board to mainline Linux and
supporting its features. See these projects for inspiration:

- [sehraf's riscv-arch-image-builder](https://github.com/sehraf/riscv-arch-image-builder)
- [tmolteno's d1_build](https://github.com/tmolteno/d1_build)

As of February 2023 there are only three reasons you would want to use this code:

- You want to use the Lichee RV 86 Panel's screen
- You want to use the XR829 Wi-Fi chip
- You are a developer trying to fix the screen or Wi-Fi

HOW TO USE
==========

Install the following dependencies:

- Standard tools for compiling things on Linux
- GCC for RISC-V
- dosfstools
- btrfs-progs
- parted
- gptfdisk

Adjust the top Makefile variables to your requirements. Here's what I use:

```
CROSS_COMPILE=/usr/bin/riscv64-linux-gnu-
NPROC=$(shell nproc)
LINUXDTS=$(PWD)/extra/board_720_new.dts
UBOOTDTS=$(PWD)/extra/uboot-board-720.dts
ENV=$(PWD)/extra/u-boot.env
DEVICE=/dev/sdb
DEVICEPART=/dev/sdb
MOUNT=/mnt/lichee
```

If you want to set up a fresh SD card or image, run 'make partition'.
Skip this step if your SD card already has an image from Sipeed.

Next install your flavor of Linux to the SD card's rootfs.
How to do this depends on your distribution of choice.

For my case I downloaded an [Arch Linux RISC-V](https://archriscv.felixc.at/) rootfs,
ran 'make mount', extracted the rootfs to /mnt/lichee and ran 'make unmount'.

If you have QEMU user mode emulation installed on your system you can then chroot in
and set up the root by running something like 'systemd-nspawn -i /dev/sdb'.

After you have a rootfs ready, run 'make install' to build and install the binaries.

Now you should have a working SD card or image ready. Good luck!

NOTES
=====

If you are a developer or have more questions, see my [NOTES](NOTES.md).

LICENSE
=======

All original contributions are licensed under the GPL2 or any later version.
See LICENSE.GPL2.md for full details.

All files in the attic directory are property of Sipeed and Allwinner.
They are released publicly or under the GPL2.
