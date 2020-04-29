# Getting Started

## Clone repository
```
git clone --recursive https://github.com/antmicro/linux-on-litex-vexriscv-build
```

## Install Prerequisites

This repository requires `direnv` program. It is used to manage the environment
variables and the python virtual environment within this repository.
You can install direnv using instructions available in the project
[website](https://direnv.net/)

If you want to see the virtual environment in your prompt,
which is *highly recommended*, read the
[Python chapter](https://github.com/direnv/direnv/wiki/Python) in `direnv` Wiki.
This will allow you to see that the `direnv` sets the proper virtual environment
for this directory.

You also need to have TFTP server available at `/tftpboot` directory.

## Basic Usage

This repository ensures that you are using only local litex and migen repositories.
It also creates a python virtual environment with all the required packages.
This virtual environment resides in the `.direnv/` directory in this repository
and is automatically set when you enter this directory.

### Preparing tools

To prepare the needed tools, use:
```
make init
```

The command will install the following tools to the `tools/` directory:
- riscv toolchain
- xc3sprog
- openocd

For selective installation, see the `Makefile`.

### Compiling LiteX+Linux (for Arty Board)

```
make vex/build
make br/all
```

### To load the bitstream into the FPGA chip:

```
make vex/load
```
