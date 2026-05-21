`timescale 1ns/1ps

import mxfp8_pkg::*;

module llmt_array16 #(
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
  logic [NUM_LLMT-1:0] lane_valid;

  genvar lane;
  generate
    for (lane = 0; lane < NUM_LLMT; lane++) begin : gen_lane
      llmt32_dot #(.ACCUMULATE(ACCUMULATE)) u_llmt32_dot (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .acc_clear_i(acc_clear_i),
        .a_block_i(a_block_i),
        .a_scale_i(a_scale_i),
        .b_block_i(b_blocks_i[lane*K_BLOCK*8 +: K_BLOCK*8]),
        .b_scale_i(b_scales_i[lane*8 +: 8]),
        .acc_i(acc_i[lane*32 +: 32]),
        .out_valid(lane_valid[lane]),
        .result_o(results_o[lane*32 +: 32])
      );
    end
  endgenerate

  assign out_valid = lane_valid[0];
endmodule
