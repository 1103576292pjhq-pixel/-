`timescale 1ns/1ps

import mxfp8_pkg::*;

module mxfp8_array_top #(
  parameter bit ACCUMULATE = 1'b0
) (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic                       in_valid,
  input  logic                       acc_clear_i,
  input  logic [K_BLOCK*8-1:0]       a_block_i,
  input  logic [7:0]                 a_scale_i,
  input  logic [NUM_LLMT*K_BLOCK*8-1:0] b_blocks_i,
  input  logic [NUM_LLMT*8-1:0]      b_scales_i,
  input  logic [NUM_LLMT*32-1:0]     acc_i,
  output logic                       out_valid,
  output logic [NUM_LLMT*32-1:0]     results_o
);
  llmt_array16 #(.ACCUMULATE(ACCUMULATE)) u_llmt_array16 (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .acc_clear_i(acc_clear_i),
    .a_block_i(a_block_i),
    .a_scale_i(a_scale_i),
    .b_blocks_i(b_blocks_i),
    .b_scales_i(b_scales_i),
    .acc_i(acc_i),
    .out_valid(out_valid),
    .results_o(results_o)
  );
endmodule
