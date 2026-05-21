`timescale 1ns/1ps

import mxfp8_pkg::*;

module tb_llmt_array16;
  logic clk;
  logic rst_n;
  logic in_valid;
  logic acc_clear;
  logic [K_BLOCK*8-1:0] a_block;
  logic [7:0] a_scale;
  logic [NUM_LLMT*K_BLOCK*8-1:0] b_blocks;
  logic [NUM_LLMT*8-1:0] b_scales;
  logic [NUM_LLMT*32-1:0] acc;
  logic out_valid;
  logic [NUM_LLMT*32-1:0] results;
  int i;
  int lane;

  mxfp8_array_top u_dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .acc_clear_i(acc_clear),
    .a_block_i(a_block),
    .a_scale_i(a_scale),
    .b_blocks_i(b_blocks),
    .b_scales_i(b_scales),
    .acc_i(acc),
    .out_valid(out_valid),
    .results_o(results)
  );

  always #0.5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    in_valid = 1'b0;
    acc_clear = 1'b1;
    a_block = '0;
    b_blocks = '0;
    b_scales = '0;
    acc = '0;
    a_scale = 8'h7f;

    repeat (4) @(posedge clk);
    rst_n = 1'b1;

    for (i = 0; i < K_BLOCK; i++) begin
      a_block[i*8 +: 8] = 8'h38;
    end
    for (lane = 0; lane < NUM_LLMT; lane++) begin
      b_scales[lane*8 +: 8] = 8'h7f;
      for (i = 0; i < K_BLOCK; i++) begin
        b_blocks[(lane*K_BLOCK+i)*8 +: 8] = (lane == 0) ? 8'h38 : 8'h40;
      end
    end

    @(posedge clk);
    in_valid = 1'b1;
    @(posedge clk);
    in_valid = 1'b0;

    wait (out_valid);
    #0.1;
    if (results[0 +: 32] !== 32'h4200_0000) begin
      $fatal(1, "lane0 mismatch got=%08x", results[0 +: 32]);
    end
    if (results[32 +: 32] !== 32'h4280_0000) begin
      $fatal(1, "lane1 mismatch got=%08x", results[32 +: 32]);
    end

    $display("tb_llmt_array16 PASS lane0=%08x lane1=%08x", results[0 +: 32], results[32 +: 32]);
    $finish;
  end
endmodule
