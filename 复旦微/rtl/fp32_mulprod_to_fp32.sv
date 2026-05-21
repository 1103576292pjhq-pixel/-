`timescale 1ns/1ps

import mxfp8_pkg::*;

module fp32_mulprod_to_fp32 (
  input  logic [7:0] a_i,
  input  logic [7:0] b_i,
  input  logic [7:0] scale_a_i,
  input  logic [7:0] scale_b_i,
  output logic [31:0] fp32_o
);
  always_comb begin
    fp32_o = mxfp8_pkg::mxfp8_mul_fp32(a_i, b_i, scale_a_i, scale_b_i);
  end
endmodule
