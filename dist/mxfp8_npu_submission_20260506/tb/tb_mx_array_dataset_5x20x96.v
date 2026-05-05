`define TB_M 5
`define TB_N 20
`define TB_K_BLOCKS 3
`define TB_A_BLOCKS_HEX "vectors/matmul_5x20x96_tail/a_blocks.hex"
`define TB_A_SCALES_HEX "vectors/matmul_5x20x96_tail/a_scales.hex"
`define TB_B_BLOCKS_HEX "vectors/matmul_5x20x96_tail/b_blocks.hex"
`define TB_B_SCALES_HEX "vectors/matmul_5x20x96_tail/b_scales.hex"
`define TB_EXPECTED_Y_HEX "vectors/matmul_5x20x96_tail/expected_y.hex"

`include "tb_mx_array_dataset.v"
