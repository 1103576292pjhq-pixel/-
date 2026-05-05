`define TB_M 9
`define TB_N 65
`define TB_K_BLOCKS 6
`define TB_A_BLOCKS_HEX "vectors/matmul_9x65x192_five_tiles/a_blocks.hex"
`define TB_A_SCALES_HEX "vectors/matmul_9x65x192_five_tiles/a_scales.hex"
`define TB_B_BLOCKS_HEX "vectors/matmul_9x65x192_five_tiles/b_blocks.hex"
`define TB_B_SCALES_HEX "vectors/matmul_9x65x192_five_tiles/b_scales.hex"
`define TB_EXPECTED_Y_HEX "vectors/matmul_9x65x192_five_tiles/expected_y.hex"

`include "tb_mx_array_dataset.v"
