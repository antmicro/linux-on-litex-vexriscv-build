LITEX_DIR=../../litex/
LITEX_BOARDS_DIR=../../litex-boards/
LINUX_ON_LITEX_VEXRISCV_DIR=../../linux-on-litex-vexriscv/
PATCH_DIR=../patches/arty_hdmi_expansion_board

apply-patches:
	cd ${LITEX_DIR}; git apply ${PATCH_DIR}/litex.patch
	cd ${LITEX_BOARDS_DIR}; git apply ${PATCH_DIR}/litex-boards.patch
	cd ${LINUX_ON_LITEX_VEXRISCV_DIR}; git apply ${PATCH_DIR}/linux-on-litex-vexriscv.patch
