# SPDX-License-Identifier: GPL-2.0-or-later
# SPDX-FileCopyrightText: Copyright 2023 Jookia <contact@jookia.org>

# Change this if you want!
CROSS_COMPILE=/usr/bin/riscv64-linux-gnu-
NPROC=$(shell nproc)
DTS=$(PWD)/attic/dts/board_waft.dts
ENV=$(PWD)/extra/u-boot.env

BLDDIR=$(PWD)/build
ATTIC=$(PWD)/attic
PATCHES=$(PWD)/patches

KERNELGIT=https://dl.linux-sunxi.org/D1/SDK/projects/lichee/linux-5.4.git
KERNELCOMMIT=035e3450a899008ef15bb387d0ed41aafd733a8a# smartx-d1-tina-v1.0.1-release
SPLGIT=https://github.com/smaeul/sun20i_d1_spl
SPLCOMMIT=882671fcf53137aaafc3a94fa32e682cb7b921f1# d1-2022-04-16
OPENSBIGIT=https://dl.linux-sunxi.org/D1/SDK/projects/lichee/brandy-2.0/opensbi.git
OPENSBICOMMIT=c50b19bc79b2cc5bf70089d61fadc7f86fcac4b1# smartx-d1-tina-v1.0.1-release
UBOOTGIT=https://dl.linux-sunxi.org/D1/SDK/projects/lichee/brandy-2.0/u-boot-2018.git
UBOOTCOMMIT=0a88ac94ab4c4c7942423d3b447e6a147fae7fbd# smartx-d1-tina-v1.0.1-release
MKIMAGEGIT=https://github.com/smaeul/u-boot
MKIMAGECOMMIT=329e94f16ff84f9cf9341f8dfdff7af1b1e6ee9a# d1-2022-10-31
FIRMWAREGIT=https://dl.linux-sunxi.org/D1/SDK/projects/package.git
FIRMWARECOMMIT=18a2da8d2e82f2f28a81d149061547c0a04d0422# smartx-d1-tina-v1.0.1-release

.ONESHELL:
SHELL=/usr/bin/bash

$(BLDDIR)/.init:
	mkdir -p $(BLDDIR)
	touch $(BLDDIR)/.init

download-linux $(BLDDIR)/.download-linux: $(BLDDIR)/.init
	@git clone "$(KERNELGIT)" $(BLDDIR)/linux
	touch $(BLDDIR)/.download-linux

download-spl $(BLDDIR)/.download-spl: $(BLDDIR)/.init
	git clone "$(SPLGIT)" $(BLDDIR)/spl
	touch $(BLDDIR)/.download-spl

download-opensbi $(BLDDIR)/.download-opensbi: $(BLDDIR)/.init
	git clone "$(OPENSBIGIT)" $(BLDDIR)/opensbi
	touch $(BLDDIR)/.download-opensbi

download-u-boot $(BLDDIR)/.download-u-boot: $(BLDDIR)/.init
	git clone "$(UBOOTGIT)" $(BLDDIR)/u-boot
	touch $(BLDDIR)/.download-u-boot

download-mkimage $(BLDDIR)/.download-mkimage: $(BLDDIR)/.init
	git clone "$(MKIMAGEGIT)" $(BLDDIR)/mkimage
	touch $(BLDDIR)/.download-mkimage

download-firmware $(BLDDIR)/.download-firmware: $(BLDDIR)/.init
	git clone "$(FIRMWAREGIT)" $(BLDDIR)/firmware
	touch $(BLDDIR)/.download-firmware

prepare-linux $(BLDDIR)/.prepare-linux: $(BLDDIR)/.download-linux
	@set -ex
	cd $(BLDDIR)/linux
	git switch --discard-changes --detach "$(KERNELCOMMIT)"
	git clean -dfx
	patch -p1 < $(ATTIC)/linux-tina-diff.patch
	patch -p1 < $(ATTIC)/linux-r8723ds.patch
	patch -p1 < $(PATCHES)/linux.patch
	cp $(ATTIC)/linux-tina.config .config
	echo 'CONFIG_FB_CONSOLE_SUNXI=y' >> .config
	echo 'CONFIG_FRAMEBUFFER_CONSOLE=y' >> .config
	echo 'CONFIG_TOUCHSCREEN_EDT_FT5X06=y' >> .config
	make ARCH=riscv olddefconfig
	touch $(BLDDIR)/.prepare-linux

prepare-spl $(BLDDIR)/.prepare-spl: $(BLDDIR)/.download-spl
	@set -ex
	cd $(BLDDIR)/spl
	git switch --discard-changes --detach "$(SPLCOMMIT)"
	git clean -dfx
	patch -p1 < $(PATCHES)/spl.patch
	touch $(BLDDIR)/.prepare-spl

prepare-opensbi $(BLDDIR)/.prepare-opensbi: $(BLDDIR)/.download-opensbi
	@set -ex
	cd $(BLDDIR)/opensbi
	git clean -dfx
	git switch --discard-changes --detach "$(OPENSBICOMMIT)"
	patch -p1 < $(PATCHES)/opensbi.patch
	touch $(BLDDIR)/.prepare-opensbi

prepare-u-boot $(BLDDIR)/.prepare-u-boot: $(BLDDIR)/.download-u-boot
	@set -ex
	cd $(BLDDIR)/u-boot
	git clean -dfx
	git switch --discard-changes --detach "$(UBOOTCOMMIT)"
	patch -p1 < $(ATTIC)/u-boot-tina-diff.patch
	patch -p1 < $(PATCHES)/u-boot.patch
	cp $(ATTIC)/dts/uboot-board.dts arch/riscv/dts/.board-uboot.dts
	cp $(ATTIC)/u-boot-tina.config .config
	echo 'CONFIG_DISP2_SUNXI=y' >> .config
	echo 'CONFIG_SUNXI_SPINOR_BMP=y' >> .config
	echo 'CONFIG_LCD_SUPPORT_ST7701S_RGB=y' >> .config
	make ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) olddefconfig
	touch $(BLDDIR)/.prepare-u-boot

prepare-mkimage $(BLDDIR)/.prepare-mkimage: $(BLDDIR)/.download-mkimage
	@set -ex
	cd $(BLDDIR)/mkimage
	git switch --discard-changes --detach "$(MKIMAGECOMMIT)"
	git clean -dfx
	touch $(BLDDIR)/.prepare-mkimage

prepare-firmware $(BLDDIR)/.prepare-firmware: $(BLDDIR)/.download-firmware
	@set -ex
	cd $(BLDDIR)/firmware
	git switch --discard-changes --detach "$(FIRMWARECOMMIT)"
	git clean -dfx
	touch $(BLDDIR)/.prepare-firmware

build-linux $(BLDDIR)/.build-linux: $(BLDDIR)/.prepare-linux
	@set -ex
	cd $(BLDDIR)/linux
	export ARCH=riscv
	export CROSS_COMPILE=$(CROSS_COMPILE)
	make -j$(NPROC)
	make -j$(NPROC) modules
	rm -rf $(BLDDIR)/lib/modules
	make -j$(NPROC) modules_install INSTALL_MOD_PATH=$(BLDDIR)
	touch $(BLDDIR)/.build-linux

build-spl $(BLDDIR)/.build-spl: $(BLDDIR)/.prepare-spl
	@set -ex
	cd $(BLDDIR)/spl
	export CROSS_COMPILE=$(CROSS_COMPILE)
	make p=sun20iw1p1 mmc nand spinor fes
	touch $(BLDDIR)/.build-spl

build-opensbi $(BLDDIR)/.build-opensbi: $(BLDDIR)/.prepare-opensbi
	@set -ex
	cd $(BLDDIR)/opensbi
	export CROSS_COMPILE=$(CROSS_COMPILE)
	make PLATFORM=thead/c910 SUNXI_CHIP=sun20iw1p1 PLATFORM_RISCV_ISA=rv64gc
	touch $(BLDDIR)/.build-opensbi

build-u-boot $(BLDDIR)/.build-u-boot: $(BLDDIR)/.prepare-u-boot
	@set -ex
	cd $(BLDDIR)/u-boot
	make ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) -j$(NPROC)
	touch $(BLDDIR)/.build-u-boot

build-mkimage $(BLDDIR)/.build-mkimage: $(BLDDIR)/.prepare-mkimage
	@set -ex
	cd $(BLDDIR)/mkimage
	make sandbox_config
	make tools
	touch $(BLDDIR)/.build-mkimage

build-dtb $(BLDDIR)/.build-dtb: $(BLDDIR)/.build-linux
	@set -ex
	cd $(BLDDIR)/linux
	DTSDIR=arch/riscv/boot/dts/sunxi
	rm -rf $$DTSDIR/mydts.dts $$DTSDIR/mydts.dtb
	echo 'dtb-y += mydts.dtb' > $$DTSDIR/Makefile
	cp $(DTS) $$DTSDIR/mydts.dts
	make ARCH=riscv dtbs
	touch $(BLDDIR)/.build-dtb

build-toc $(BLDDIR)/.build-toc: $(BLDDIR)/.build-mkimage $(BLDDIR)/.build-opensbi $(BLDDIR)/.build-dtb $(BLDDIR)/.build-u-boot
	@set -ex
	cd $(BLDDIR)
	rm -rf toc toc.fg
	cat <<-EOF >toc.cfg
	[opensbi]
	file = opensbi/build/platform/thead/c910/firmware/fw_dynamic.bin
	addr = 0x40000000
	[u-boot]
	file = u-boot/u-boot.bin
	addr = 0x42000000
	[dtb]
	file = linux/arch/riscv/boot/dts/sunxi/mydts.dtb
	addr = 0x42200000
	EOF
	mkimage/tools/mkimage -T sunxi_toc1 -d toc.cfg toc
	rm toc.cfg
	touch $(BLDDIR)/.build-toc

build-firmware $(BLDDIR)/.build-firmware: $(BLDDIR)/.prepare-firmware
	@set -ex
	cd $(BLDDIR)
	rm -rf lib/firmware
	mkdir -p lib/firmware
	cp -r firmware/firmware/linux-firmware/xr829/*.bin lib/firmware
	touch $(BLDDIR)/.build-firmware

build-uimage $(BLDDIR)/.build-uimage: $(BLDDIR)/.build-linux $(BLDDIR)/.build-u-boot
	@set -ex
	cd $(BLDDIR)
	u-boot/tools/mkimage -A riscv -O linux -T kernel -C none -a 0x40200000 \
		-d linux/arch/riscv/boot/Image uImage
	touch $(BLDDIR)/.build-uimage

build-uenv $(BLDDIR)/.build-uenv: $(BLDDIR)/.build-u-boot
	@set -ex
	cd $(BLDDIR)
	u-boot/tools/mkenvimage -r -s 0x20000 -o uEnv $(ENV)
	touch $(BLDDIR)/.build-uenv

clean-prepare:
	rm -rf $(BLDDIR)/.prepare-linux
	rm -rf $(BLDDIR)/.prepare-spl
	rm -rf $(BLDDIR)/.prepare-opensbi
	rm -rf $(BLDDIR)/.prepare-u-boot
	rm -rf $(BLDDIR)/.prepare-mkimage
	rm -rf $(BLDDIR)/.prepare-firmware

clean-build:
	rm -rf $(BLDDIR)/uImage
	rm -rf $(BLDDIR)/uEnv
	rm -rf $(BLDDIR)/.build-linux
	rm -rf $(BLDDIR)/.build-spl
	rm -rf $(BLDDIR)/.build-opensbi
	rm -rf $(BLDDIR)/.build-u-boot
	rm -rf $(BLDDIR)/.build-mkimage
	rm -rf $(BLDDIR)/.build-dtb
	rm -rf $(BLDDIR)/.build-toc
	rm -rf $(BLDDIR)/.build-firmware
	rm -rf $(BLDDIR)/.build-uimage
	rm -rf $(BLDDIR)/.build-uenv
	rm -rf $(BLDDIR)/lib

prepare: $(BLDDIR)/.prepare-linux $(BLDDIR)/.prepare-spl $(BLDDIR)/.prepare-opensbi $(BLDDIR)/.prepare-u-boot $(BLDDIR)/.prepare-mkimage $(BLDDIR)/.prepare-firmware
build: $(BLDDIR)/.build-linux $(BLDDIR)/.build-spl $(BLDDIR)/.build-toc $(BLDDIR)/.build-firmware $(BLDDIR)/.build-uimage $(BLDDIR)/.build-uenv
rebuild: clean-build build
reprepare: clean-build clean-prepare prepare
