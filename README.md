README
------

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
-------

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

LICENSE
-------

All original contributions are licensed under the GPL2 or any later version.
See LICENSE.GPL2.md for full details.

All files in the attic directory are property of Sipeed and Allwinner.
They are released publicly or under the GPL2.
