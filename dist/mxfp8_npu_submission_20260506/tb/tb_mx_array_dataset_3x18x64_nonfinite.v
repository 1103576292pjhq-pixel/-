`define TB_M 3
`define TB_N 18
`define TB_K_BLOCKS 2
`define TB_A_BLOCKS_HEX "vectors/matmul_3x18x64_nonfinite/a_blocks.hex"
`define TB_A_SCALES_HEX "vectors/matmul_3x18x64_nonfinite/a_scales.hex"
`define TB_B_BLOCKS_HEX "vectors/matmul_3x18x64_nonfinite/b_blocks.hex"
`define TB_B_SCALES_HEX "vectors/matmul_3x18x64_nonfinite/b_scales.hex"
`define TB_EXPECTED_Y_HEX "vectors/matmul_3x18x64_nonfinite/expected_y.hex"

`include "tb_mx_array_dataset.v"
