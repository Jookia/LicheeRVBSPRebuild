# SPDX-License-Identifier: GPL-2.0-or-later
# SPDX-FileCopyrightText: Copyright 2023 Jookia <contact@jookia.org>

# Change this if you want!
CROSS_COMPILE=/usr/bin/riscv64-linux-gnu-
NPROC=$(shell nproc)
DTS=$(ATTIC)/dts/board_waft.dts # Used by Sipeed

BLDDIR=$(PWD)/build
ATTIC=$(PWD)/attic
ROOT=$(PWD)

KERNELGIT=https://dl.linux-sunxi.org/D1/SDK/projects/lichee/linux-5.4.git
KERNELTAG=smartx-d1-tina-v1.0.1-release
SPLGIT=https://github.com/smaeul/sun20i_d1_spl
SPLTAG=d1-2022-04-16
OPENSBIGIT=https://dl.linux-sunxi.org/D1/SDK/projects/lichee/brandy-2.0/opensbi.git
OPENSBITAG=product-smartx-d1-tina-v1.0-release

.ONESHELL:
SHELL=/usr/bin/bash

$(BLDDIR)/.init:
	mkdir -p $(BLDDIR)
	touch $(BLDDIR)/.init

download-kernel $(BLDDIR)/.download-kernel: $(BLDDIR)/.init
	git clone "$(KERNELGIT)" -b "$(KERNELTAG)" $(BLDDIR)/linux
	touch $(BLDDIR)/.download-kernel

download-spl $(BLDDIR)/.download-spl: $(BLDDIR)/.init
	git clone "$(SPLGIT)" -b "$(SPLTAG)" $(BLDDIR)/spl
	touch $(BLDDIR)/.download-spl

download-opensbi $(BLDDIR)/.download-opensbi: $(BLDDIR)/.init
	git clone "$(OPENSBIGIT)" -b "$(OPENSBITAG)" $(BLDDIR)/opensbi
	touch $(BLDDIR)/.download-opensbi

prepare-kernel $(BLDDIR)/.prepare-kernel: $(BLDDIR)/.download-kernel
	@set -ex
	export ARCH=riscv
	cd $(BLDDIR)/linux
	git restore -W -S -s "$(KERNELTAG)" .
	git clean -dfx
	patch -p1 < $(ATTIC)/linux-tina-diff.patch
	patch -p1 < $(ROOT)/gcc12fix.patch
	patch -p1 < $(ROOT)/vectorfix.patch
	echo "" > arch/riscv/boot/dts/sunxi/Makefile # Disable DTB build
	cp $(ATTIC)/linux-tina.config .config
	make ARCH=riscv olddefconfig
	touch $(BLDDIR)/.prepare-kernel

prepare-spl $(BLDDIR)/.prepare-spl: $(BLDDIR)/.download-spl
	@set -ex
	cd $(BLDDIR)/spl
	git restore -W -S -s "$(SPLTAG)" .
	git clean -dfx
	touch $(BLDDIR)/.prepare-spl

prepare-opensbi $(BLDDIR)/.prepare-opensbi: $(BLDDIR)/.download-opensbi
	@set -ex
	cd $(BLDDIR)/opensbi
	git restore -W -S -s "$(OPENSBITAG)" .
	git clean -dfx
	patch -p1 < $(ROOT)/opensbifix.patch
	touch $(BLDDIR)/.prepare-opensbi

build-kernel $(BLDDIR)/.build-kernel: $(BLDDIR)/.prepare-kernel
	@set -ex
	cd $(BLDDIR)/linux
	export ARCH=riscv
	export CROSS_COMPILE=$(CROSS_COMPILE)
	make -j$(NPROC)
	make -j$(NPROC) modules
	make -j$(NPROC) modules_install INSTALL_MOD_PATH=$(BLDDIR)
	cp arch/riscv/boot/Image $(BLDDIR)/Image
	touch $(BLDDIR)/.build-kernel

build-spl $(BLDDIR)/.build-spl: $(BLDDIR)/.prepare-spl
	@set ex
	cd $(BLDDIR)/spl
	export CROSS_COMPILE=$(CROSS_COMPILE)
	make p=sun20iw1p1 mmc nand spinor fes
	touch $(BLDDIR)/.build-spl

build-opensbi $(BLDDIR)/.build-opensbi: $(BLDDIR)/.prepare-opensbi
	@set ex
	cd $(BLDDIR)/opensbi
	export CROSS_COMPILE=$(CROSS_COMPILE)
	make PLATFORM=thead/c910 SUNXI_CHIP=sun20iw1p1 PLATFORM_RISCV_ISA=rv64gc
	touch $(BLDDIR)/.build-opensbi

clean-prepare:
	rm -rf $(BLDDIR)/.prepare-kernel
	rm -rf $(BLDDIR)/.prepare-spl

clean-build:
	rm -rf $(BLDDIR)/.build-kernel
	rm -rf $(BLDDIR)/.build-spl
	rm -rf $(BLDDIR)/Image
	rm -rf $(BLDDIR)/lib

prepare: $(BLDDIR)/.prepare-kernel $(BLDDIR)/.prepare-spl$(BLDDIR)/.prepare-opensbi
build: $(BLDDIR)/.build-kernel $(BLDDIR)/.build-spl $(BLDDIR)/.build-opensbi
rebuild: clean-build build
reprepare: clean-build clean-prepare prepare
