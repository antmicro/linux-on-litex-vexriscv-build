# Compiling linux-on-litex-vexriscv for arty + HDMI expansion

0. Prerequisites

- TFTP server directory available at `/tftpboot`
- IP of computer set to `10.0.0.1`

1. Apply patches:
```
cd <linux-on-vex-build>/litex-boards/
git apply ../patches/arty_hdmi_expansion_board/litex-boards.patch

cd <linux-on-vex-build>/litex/
git apply ../patches/arty_hdmi_expansion_board/litex.patch


cd <linux-on-vex-build>/linux-on-litex-vexriscv/
git apply ../patches/arty_hdmi_expansion_board/linux-on-litex-vexriscv.patch
```

2. Prepare repository:

```
cd <linux-on-vex-build>
make init
```

3. Generate bitstream

```
cd <linux-on-vex-build>
make vex/build
```

4. Generate linux binaries

```
cd <linux-on-vex-build>
make br/all
```

5. Load the bitstream

```
cd <linux-on-vex-build>
make vex/load
```

