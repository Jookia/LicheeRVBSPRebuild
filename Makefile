# SPDX-License-Identifier: GPL-2.0-or-later
# SPDX-FileCopyrightText: Copyright 2023 Jookia <contact@jookia.org>

# Change this if you want!
CROSS_COMPILE=riscv64-linux-gnu-
NPROC=$(shell nproc)
DTS=$(ATTIC)/dts/board_waft.dts # Used by Sipeed

BLDDIR=$(PWD)/build
ATTIC=$(PWD)/attic
ROOT=$(PWD)

KERNELGIT=https://dl.linux-sunxi.org/D1/SDK/projects/lichee/linux-5.4.git
KERNELTAG=smartx-d1-tina-v1.0.1-release

.ONESHELL:
SHELL=/usr/bin/bash

$(BLDDIR)/.init:
	mkdir -p $(BLDDIR)
	touch $(BLDDIR)/.init

download-kernel $(BLDDIR)/.download-kernel: $(BLDDIR)/.init
	@set -ex
	cd $(BLDDIR)
	git clone "$(KERNELGIT)" linux
	git -C linux checkout $(KERNELTAG)
	touch $(BLDDIR)/.download-kernel

prepare-kernel $(BLDDIR)/.prepare-kernel: $(BLDDIR)/.download-kernel
	@set -ex
	export ARCH=riscv
	cd $(BLDDIR)/linux
	git restore -W -S -s $(KERNELTAG) .
	git clean -dfx
	patch -p1 < $(ATTIC)/linux-tina-diff.patch
	patch -p1 < $(ROOT)/gcc12fix.patch
	echo "" > arch/riscv/boot/dts/sunxi/Makefile # Disable DTB build
	cp $(ATTIC)/linux-tina.config .config
	sed -i '/^CONFIG_VECTOR=y/d' .config # Vector requires custom toolchain
	make ARCH=riscv olddefconfig
	touch $(BLDDIR)/.prepare-kernel

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

clean-prepare:
	rm -rf $(BLDDIR)/.prepare-kernel

clean-build:
	rm -rf $(BLDDIR)/.build-kernel
	rm -rf $(BLDDIR)/Image
	rm -rf $(BLDDIR)/lib

prepare: $(BLDDIR)/.prepare-kernel
build: $(BLDDIR)/.build-kernel
rebuild: clean-build build
reprepare: clean-build clean-prepare prepare
