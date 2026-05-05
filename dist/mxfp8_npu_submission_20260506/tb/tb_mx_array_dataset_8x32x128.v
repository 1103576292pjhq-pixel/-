`define TB_M 8
`define TB_N 32
`define TB_K_BLOCKS 4
`define TB_A_BLOCKS_HEX "vectors/matmul_8x32x128_smoke/a_blocks.hex"
`define TB_A_SCALES_HEX "vectors/matmul_8x32x128_smoke/a_scales.hex"
`define TB_B_BLOCKS_HEX "vectors/matmul_8x32x128_smoke/b_blocks.hex"
`define TB_B_SCALES_HEX "vectors/matmul_8x32x128_smoke/b_scales.hex"
`define TB_EXPECTED_Y_HEX "vectors/matmul_8x32x128_smoke/expected_y.hex"

`include "tb_mx_array_dataset.v"
