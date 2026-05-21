`timescale 1ns/1ps

import mxfp8_pkg::*;

module tb_llmt32_dot;
  logic clk;
  logic rst_n;
  logic in_valid;
  logic acc_clear;
  logic [K_BLOCK*8-1:0] a_block;
  logic [7:0] a_scale;
  logic [K_BLOCK*8-1:0] b_block;
  logic [7:0] b_scale;
  logic out_valid;
  logic [31:0] result;
  logic [31:0] expected;
  int i;

  llmt32_dot u_dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .acc_clear_i(acc_clear),
    .a_block_i(a_block),
    .a_scale_i(a_scale),
    .b_block_i(b_block),
    .b_scale_i(b_scale),
    .acc_i(32'b0),
    .out_valid(out_valid),
    .result_o(result)
  );

  always #0.5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    in_valid = 1'b0;
    acc_clear = 1'b1;
    a_block = '0;
    b_block = '0;
    a_scale = 8'h7f;
    b_scale = 8'h7f;
    expected = 32'h4200_0000;

    repeat (4) @(posedge clk);
    rst_n = 1'b1;

    for (i = 0; i < K_BLOCK; i++) begin
      a_block[i*8 +: 8] = 8'h38;
      b_block[i*8 +: 8] = 8'h38;
    end

    @(posedge clk);
    in_valid = 1'b1;
    @(posedge clk);
    in_valid = 1'b0;

    wait (out_valid);
    #0.1;
    if (result !== expected) begin
      $fatal(1, "llmt result mismatch got=%08x expected=%08x", result, expected);
    end

    $display("tb_llmt32_dot PASS result=%08x", result);
    $finish;
  end
endmodule
