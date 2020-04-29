# Compiling linux-on-litex-vexriscv for arty + HDMI expansion

0. Prerequisites

- TFTP server directory available at `/tftpboot`
- IP of computer set to `10.0.0.1`

1. Apply patches:
```
make apply-patches
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

