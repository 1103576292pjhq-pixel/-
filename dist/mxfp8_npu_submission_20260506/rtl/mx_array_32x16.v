`include "mx_defs.vh"

module mx_array_32x16 (
  clk,
  rst_n,
  valid_i,
  acc_clear_i,
  a_elems_i,
  a_scale_i,
  b_elems_i,
  b_scale_i,
  valid_o,
  acc_o
);
  input clk;
  input rst_n;
  input valid_i;
  input [`MX_COLS-1:0] acc_clear_i;
  input [`MX_BLOCK_K*`MX_ELEM_W-1:0] a_elems_i;
  input [7:0] a_scale_i;
  input [`MX_COLS*`MX_BLOCK_K*`MX_ELEM_W-1:0] b_elems_i;
  input [`MX_COLS*8-1:0] b_scale_i;
  output [`MX_COLS-1:0] valid_o;
  output [`MX_COLS*32-1:0] acc_o;

  wire [`MX_COLS-1:0] valid_int;
  wire [`MX_COLS*32-1:0] acc_int;

  genvar col;
  generate
    for (col = 0; col < `MX_COLS; col = col + 1) begin : gen_cols
      wire [`MX_BLOCK_K*`MX_ELEM_W-1:0] b_elems_col;
      wire [7:0] b_scale_col;

      assign b_elems_col = b_elems_i[(col*`MX_BLOCK_K*`MX_ELEM_W) +: (`MX_BLOCK_K*`MX_ELEM_W)];
      assign b_scale_col = b_scale_i[(col*8) +: 8];

      llmt_col col_u (
        .clk(clk),
        .rst_n(rst_n),
        .valid_i(valid_i),
        .acc_clear_i(acc_clear_i[col]),
        .a_elems_i(a_elems_i),
        .a_scale_i(a_scale_i),
        .b_elems_i(b_elems_col),
        .b_scale_i(b_scale_col),
        .valid_o(valid_int[col]),
        .acc_o(acc_int[(col*32) +: 32])
      );
    end
  endgenerate

  assign valid_o = valid_int;
  assign acc_o = acc_int;
endmodule
