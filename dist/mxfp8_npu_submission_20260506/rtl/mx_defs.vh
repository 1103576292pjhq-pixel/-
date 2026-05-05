`ifndef MX_DEFS_VH
`define MX_DEFS_VH

`define MX_BLOCK_K 32
`define MX_COLS 16
`define MX_ELEM_W 8
`define MX_SCALE_W 8
`define MX_BLOCK_W ((`MX_BLOCK_K * `MX_ELEM_W) + `MX_SCALE_W)

`define MX_ELEM_FIXED_FRAC 9
`define MX_ELEM_FIXED_W 19
`define MX_PROD_FIXED_FRAC (`MX_ELEM_FIXED_FRAC * 2)
`define MX_PROD_W (`MX_ELEM_FIXED_W * 2)
`define MX_DOT_W 44
`define MX_DOT_EXP_W 12

`define MX_FP32_ZERO 32'h00000000
`define MX_FP32_QNAN 32'h7fc00000
`define MX_FP32_INF  32'h7f800000

`endif
