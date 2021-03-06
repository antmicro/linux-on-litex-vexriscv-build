BOARD ?= arty
LOCAL_IP ?= 10.0.0.2
REMOTE_IP ?= 10.0.0.1
TFTP_SERVER_DIR=/tftpboot

TOOLS_DIR=${PWD}/tools
-include Makefile.local

### HELP ###

help:
	@echo "Board set to: ${BOARD}"

.PHONY: help

### SHORTCUTS ###

init:
	make toolchain/init
	make openocd/init
	make xc3sprog/init
	make update

update:
	git submodule update --init --remote
	git submodule foreach 'git submodule update --init --recursive'

ctags:
	ctags -R linux \
          linux-on-litex-vexriscv \
          migen \
          litex \
          litex-boards \
          litedram \
          liteeth \
          litepcie \
          litesata \
          litesdcard \
          liteiclink \
          litejesd204b \
          litevideo \
          litescope

.PHONY: init update ctags

### TOOLCHAIN ###

TOOLCHAIN_DIR=${TOOLS_DIR}/toolchain
RISCV_TOOLCHAIN_DIR=${TOOLCHAIN_DIR}/riscv-gnu-toolchain
TOOLCHAIN_BUILD_DIR=${TOOLCHAIN_DIR}/build

toolchain/init:
	make toolchain/prerequisites
	make toolchain/build
	make toolchain/direnv

toolchain/prerequisites:
	sudo apt install autoconf automake autotools-dev curl libmpc-dev \
                     libmpfr-dev libgmp-dev gawk build-essential bison flex \
                     texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

toolchain/build:
	mkdir -p ${TOOLCHAIN_DIR}; mkdir -p ${TOOLCHAIN_BUILD_DIR}
	cd ${TOOLCHAIN_DIR}; git clone --recursive https://github.com/riscv/riscv-gnu-toolchain ${RISCV_TOOLCHAIN_DIR}
	cd ${RISCV_TOOLCHAIN_DIR}; ./configure --prefix=${TOOLCHAIN_BUILD_DIR}/riscv
	cd ${RISCV_TOOLCHAIN_DIR}; make -j8
	cd ${RISCV_TOOLCHAIN_DIR}; make -j8 linux

toolchain/direnv:
	echo "PATH_add ${TOOLCHAIN_BUILD_DIR}/riscv/bin" >> .envrc.local
	direnv allow .

.PHONY: toolchain/init toolchain/prerequisites toolchain/build toolchain/direnv

### OPENOCD ###

OPENOCD_DIR=${TOOLS_DIR}/openocd
OPENOCD_BUILD_DIR=${OPENOCD_DIR}/src

openocd/init:
	make openocd/build
	make openocd/direnv

openocd/build:
	mkdir -p ${OPENOCD_DIR};
	cd ${OPENOCD_DIR}; git clone https://github.com/ntfreak/openocd.git .
	cd ${OPENOCD_DIR}; ./bootstrap
	cd ${OPENOCD_DIR}; ./configure --enable-ftdi
	cd ${OPENOCD_DIR}; make -j$(nproc)

openocd/direnv:
	echo "PATH_add ${OPENOCD_BUILD_DIR}" >> .envrc.local
	direnv allow .

.PHONY: openocd/init openocd/build openocd/direnv

### XC3SPROG ###

XC3SPROG_DIR=${TOOLS_DIR}/xc3sprog
XC3SPROG_BUILD_DIR=${XC3SPROG_DIR}/build
LIBFTD2XX_DIR=${TOOLS_DIR}/libftd2xx

xc3sprog/init:
	make xc3sprog/prerequisites
	make xc3sprog/build
	make xc3sprog/direnv

xc3sprog/prerequisites:
	sudo apt install -y libusb-dev libftdi-dev cmake
	mkdir -p ${LIBFTD2XX_DIR}
	cd ${LIBFTD2XX_DIR}; wget https://www.ftdichip.com/Drivers/D2XX/Linux/libftd2xx-i386-1.4.8.gz
	cd ${LIBFTD2XX_DIR}; tar -xzf libftd2xx-i386-1.4.8.gz
	cd ${LIBFTD2XX_DIR}; cd release/build && \
        sudo cp libftd2xx.* /usr/local/lib && \
        sudo chmod 0755 /usr/local/lib/libftd2xx.so.1.4.8 && \
        sudo ln -sf /usr/local/lib/libftd2xx.so.1.4.8 /usr/local/lib/libftd2xx.so

xc3sprog/build:
	mkdir -p ${XC3SPROG_DIR}
	cd ${XC3SPROG_DIR}; git clone --recursive https://github.com/rw1nkler/xc3sprog .
	mkdir -p ${XC3SPROG_BUILD_DIR};
	cd ${XC3SPROG_BUILD_DIR}; cmake ..
	cd ${XC3SPROG_BUILD_DIR}; make

xc3sprog/direnv:
	echo "PATH_add ${XC3SPROG_BUILD_DIR}" >> .envrc.local
	direnv allow .

### BUILDROOT ###

BUILDROOT_DIR=${PWD}/buildroot

br/all:
	make br/init
	make br/linux-clean
	make br/build
	make vex/soft
	make br/tftp
	make vex/load

br/init:
	cd ${BUILDROOT_DIR}; make BR2_EXTERNAL=../linux-on-litex-vexriscv/buildroot/ litex_vexriscv_defconfig

br/menuconfig:
	cd ${BUILDROOT_DIR}; make menuconfig

br/clean:
	cd ${BUILDROOT_DIR}; make clean

br/build:
	make br/init
	cd ${BUILDROOT_DIR}; make

br/linux-menuconfig:
	cd ${BUILDROOT_DIR}; make linux-menuconfig

br/linux-clean:
	cd ${BUILDROOT_DIR}; make linux-dirclean

br/tftp:
	make tftp/clean
	cp -f ${BUILDROOT_DIR}/output/images/Image ${TFTP_SERVER_DIR}/Image
	cp -f ${BUILDROOT_DIR}/output/images/rootfs.cpio ${TFTP_SERVER_DIR}/rootfs.cpio
	cp -f ${LINUX_ON_LITEX_VEXRISCV_DIR}/buildroot/rv32.dtb ${TFTP_SERVER_DIR}/rv32.dtb
	cp -f ${LINUX_ON_LITEX_VEXRISCV_DIR}/emulator/emulator.bin ${TFTP_SERVER_DIR}/emulator.bin

.PHONY: br/all br/init br/menuconfig br/clean br/build br/linux-menuconfig br/linux-clean br/tftp

### LINUX ON VEXRISCV ###

LINUX_ON_LITEX_VEXRISCV_DIR=${PWD}/linux-on-litex-vexriscv
LINUX_ON_LITEX_VEXRISCV_PATCH_DIR=${LINUX_ON_LITEX_VEXRISCV_DIR}/buildroot/board/litex_vexriscv/patches/linux

vex/all:
	make vex/build
	make vex/soft
	make vex/tftp
	make vex/load

vex/build:
	cd ${LINUX_ON_LITEX_VEXRISCV_DIR}; ./make.py --board=${BOARD} --local-ip ${LOCAL_IP} --remote-ip ${REMOTE_IP} --build

vex/load:
	cd ${LINUX_ON_LITEX_VEXRISCV_DIR}; ./make.py --board=${BOARD} --local-ip ${LOCAL_IP} --remote-ip ${REMOTE_IP} --load

vex/flash:
	cd ${LINUX_ON_LITEX_VEXRISCV_DIR}; ./make.py --board=${BOARD} --local-ip ${LOCAL_IP} --remote-ip ${REMOTE_IP} --flash

vex/soft:
	cd ${LINUX_ON_LITEX_VEXRISCV_DIR}; ./make.py --board=${BOARD} --local-ip ${LOCAL_IP} --remote-ip ${REMOTE_IP}

vex/clean:
	cd ${LINUX_ON_LITEX_VEXRISCV_DIR}/build; rm -rf *
	cd ${LINUX_ON_LITEX_VEXRISCV_DIR}/emulator; rm *.d *.o *.elf *.bin

vex/tftp:
	make tftp/vex-clean
	cp -f ${LINUX_ON_LITEX_VEXRISCV_DIR}/buildroot/rv32.dtb ${TFTP_SERVER_DIR}/rv32.dtb
	cp -f ${LINUX_ON_LITEX_VEXRISCV_DIR}/emulator/emulator.bin ${TFTP_SERVER_DIR}/emulator.bin

.PHONY: vex/all vex/build vex/load vex/flash vex/soft vex/clean vex/tftp

### LINUX ###

LINUX_KERNEL_DIR=${PWD}/linux

linux/init:
	cp ${LINUX_ON_LITEX_VEXRISCV_DIR}/buildroot/board/litex_vexriscv/linux.config ${LINUX_KERNEL_DIR}/.config
	cd ${LINUX_KERNEL_DIR}; make olddefconfig

linux/apply-patches:
	apply_patches.sh

linux/all:
	make linux/build
	make vex/soft
	make linux/tftp
	make vex/load

linux/menuconfig:
	cd ${LINUX_KERNEL_DIR}; make menuconfig

linux/build:
	cd ${LINUX_KERNEL_DIR}; make -j$(nproc)

linux/clean:
	cd ${LINUX_KERNEL_DIR}; make clean

linux/tftp:
	make tftp/clean
	cp ${LINUX_KERNEL_DIR}/arch/riscv/boot/Image ${TFTP_SERVER_DIR}/Image
	cp ${LINUX_ON_LITEX_VEXRISCV_DIR}/buildroot/rv32.dtb ${TFTP_SERVER_DIR}/rv32.dtb
	cp ${LINUX_ON_LITEX_VEXRISCV_DIR}/emulator/emulator.bin ${TFTP_SERVER_DIR}/emulator.bin
	cp ${BUILDROOT_DIR}/output/images/rootfs.cpio ${TFTP_SERVER_DIR}/rootfs.cpio

.PHONY: linux/init linux/all linux/menuconfig linux/build linux/clean linux/tftp

### TFTP SERVER ###

tftp/clean:
	cd ${TFTP_SERVER_DIR}; rm -f Image rv32.dtb emulator.bin rootfs.cpio

tftp/vex-clean:
	cd ${TFTP_SERVER_DIR}; rm -f rv32.dtb emulator.bin

.PHONY: tftp/clean tftp/vex-clean
