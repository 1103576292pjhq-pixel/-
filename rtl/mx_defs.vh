`ifndef MX_DEFS_VH
`define MX_DEFS_VH

`define MX_BLOCK_K 32
`define MX_COLS 16
`define MX_ELEM_W 8

`define MX_ELEM_Q_FRAC 9
`define MX_ELEM_Q_W 20
`define MX_PROD_Q_FRAC (`MX_ELEM_Q_FRAC * 2)
`define MX_PROD_W (`MX_ELEM_Q_W * 2)
`define MX_DOT_W 48
`define MX_DOT_EXP_W 12

`define MX_FP32_ZERO 32'h00000000
`define MX_FP32_QNAN 32'h7fc00000
`define MX_FP32_PINF 32'h7f800000
`define MX_FP32_NINF 32'hff800000

`endif
