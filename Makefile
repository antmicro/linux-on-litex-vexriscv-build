BOARD ?= arty

### HELP ###

help:
	@echo "Board set to: ${BOARD}"

### SHORTCUTS ###

init:
	make toolchain-prerequisites
	make toolchain
	make toolchain-direnv
	make update

update:
	git submodule update --remote
	git submodule foreach 'git submodule update --init --recursive'

### TOOLCHAIN ###

TOOLCHAIN_DIR=${PWD}/toolchain
RISCV_TOOLCHAIN_DIR=${TOOLCHAIN_DIR}/riscv-gnu-toolchain
TOOLCHAIN_BUILD_DIR=${TOOLCHAIN_DIR}/build

toolchain/prerequisites:
	sudo apt install autoconf automake autotools-dev curl libmpc-dev \
                     libmpfr-dev libgmp-dev gawk build-essential bison flex \
                     texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

toolchain:
	mkdir -p toolchain; mkdir -p ${TOOLCHAIN_BUILD_DIR}
	cd ${TOOLCHAIN_DIR}; git clone --recursive https://github.com/riscv/riscv-gnu-toolchain ${RISCV_TOOLCHAIN_DIR}
	cd ${RISCV_TOOLCHAIN_DIR}; ./configure --prefix=${TOOLCHAIN_BUILD_DIR}/riscv
	cd ${RISCV_TOOLCHAIN_DIR}; make -j8
	cd ${RISCV_TOOLCHAIN_DIR}; make -j8 linux

toolchain/direnv:
	echo "PATH_add ${TOOLCHAIN_BUILD_DIR}/riscv/bin" > .envrc.local
	direnv allow .

.PHONY: toolchain

### BUILDROOT ###

BUILDROOT_DIR=${PWD}/buildroot

br/init:
	cd ${BUILDROOT_DIR}; make BR2_EXTERNAL=../linux-on-litex-vexriscv/buildroot/ litex_vexriscv_defconfig

br/menuconfig:
	cd ${BUILDROOT_DIR}; make menuconfig

br/clean:
	cd ${BUILDROOT_DIR}; make clean

br/all:
	make br-init
	cd ${BUILDROOT_DIR}; make

br/linux-menuconfig:
	cd ${BUILDROOT_DIR}; make linux-menuconfig

br/linux-clean:
	cd ${BUILDROOT_DIR}; make linux-dirclean

### LINUX ON VEXRISCV ###

LINUX_ON_LITEX_VEXRISCV_DIR=${PWD}/linux-on-litex-vexriscv

vex/all:
	make vex-build
	make vex-load

vex/build:
	cd ${LINUX_ON_LITEX_VEXRISCV_DIR}; ./make.py --board=${BOARD} --build

vex/load:
	cd ${LINUX_ON_LITEX_VEXRISCV_DIR}; ./make.py --board=${BOARD} --load

vex/flash:
	cd ${LINUX_ON_LITEX_VEXRISCV_DIR}; ./make.py --board=${BOARD} --flash

vex/clean:
	cd ${LINUX_ON_LITEX_VEXRISCV_DIR}; cd build; rm -rfi *

### LINUX ###

LINUX_KERNEL_DIR=${PWD}/linux

linux/menuconfig:
	cd ${LINUX_KERNEL_DIR}; make menuconfig

linux/build:
	cd ${LINUX_KERNEL_DIR}; make -j8

linux/clean:
	cd ${LINUX_KERNEL_DIR}; make clean
