# SPDX-License-Identifier: GPL-2.0-or-later
# SPDX-FileCopyrightText: Copyright 2023 Jookia <contact@jookia.org>

# Change this if you want!
CROSS_COMPILE=/usr/bin/riscv64-linux-gnu-
NPROC=$(shell nproc)
DTS=$(ATTIC)/dts/board_waft.dts # Used by Sipeed

BLDDIR=$(PWD)/build
ATTIC=$(PWD)/attic
PATCHES=$(PWD)/patches

KERNELGIT=https://dl.linux-sunxi.org/D1/SDK/projects/lichee/linux-5.4.git
KERNELCOMMIT=035e3450a899008ef15bb387d0ed41aafd733a8a# smartx-d1-tina-v1.0.1-release
SPLGIT=https://github.com/smaeul/sun20i_d1_spl
SPLCOMMIT=882671fcf53137aaafc3a94fa32e682cb7b921f1# d1-2022-04-16
OPENSBIGIT=https://dl.linux-sunxi.org/D1/SDK/projects/lichee/brandy-2.0/opensbi.git
OPENSBICOMMIT=c50b19bc79b2cc5bf70089d61fadc7f86fcac4b1# product-smartx-d1-tina-v1.0-release

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

prepare-linux $(BLDDIR)/.prepare-linux: $(BLDDIR)/.download-linux
	@set -ex
	cd $(BLDDIR)/linux
	git switch --discard-changes --detach "$(KERNELCOMMIT)"
	git clean -dfx
	patch -p1 < $(ATTIC)/linux-tina-diff.patch
	patch -p1 < $(PATCHES)/linux.patch
	cp $(ATTIC)/linux-tina.config .config
	make ARCH=riscv olddefconfig
	touch $(BLDDIR)/.prepare-linux

prepare-spl $(BLDDIR)/.prepare-spl: $(BLDDIR)/.download-spl
	@set -ex
	cd $(BLDDIR)/spl
	git switch --discard-changes --detach "$(SPLCOMMIT)"
	git clean -dfx
	touch $(BLDDIR)/.prepare-spl

prepare-opensbi $(BLDDIR)/.prepare-opensbi: $(BLDDIR)/.download-opensbi
	@set -ex
	cd $(BLDDIR)/opensbi
	git clean -dfx
	git switch --discard-changes --detach "$(OPENSBICOMMIT)"
	patch -p1 < $(PATCHES)/opensbi.patch
	touch $(BLDDIR)/.prepare-opensbi

build-linux $(BLDDIR)/.build-linux: $(BLDDIR)/.prepare-linux
	@set -ex
	cd $(BLDDIR)/linux
	export ARCH=riscv
	export CROSS_COMPILE=$(CROSS_COMPILE)
	make -j$(NPROC)
	make -j$(NPROC) modules
	make -j$(NPROC) modules_install INSTALL_MOD_PATH=$(BLDDIR)
	cp arch/riscv/boot/Image $(BLDDIR)/Image
	touch $(BLDDIR)/.build-linux

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
	rm -rf $(BLDDIR)/.prepare-linux
	rm -rf $(BLDDIR)/.prepare-spl
	rm -rf $(BLDDIR)/.prepare-opensbi

clean-build:
	rm -rf $(BLDDIR)/.build-linux
	rm -rf $(BLDDIR)/.build-spl
	rm -rf $(BLDDIR)/.build-opensbi
	rm -rf $(BLDDIR)/Image
	rm -rf $(BLDDIR)/lib

prepare: $(BLDDIR)/.prepare-linux $(BLDDIR)/.prepare-spl$(BLDDIR)/.prepare-opensbi
build: $(BLDDIR)/.build-linux $(BLDDIR)/.build-spl $(BLDDIR)/.build-opensbi
rebuild: clean-build build
reprepare: clean-build clean-prepare prepare
