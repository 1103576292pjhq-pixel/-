`timescale 1ns/1ps

import mxfp8_pkg::*;

module mxfp8_mul (
  input  logic [7:0] a_i,
  input  logic [7:0] b_i,
  input  logic [7:0] scale_a_i,
  input  logic [7:0] scale_b_i,
  output logic [31:0] product_o
);
  always_comb begin
    product_o = mxfp8_pkg::mxfp8_mul_fp32(a_i, b_i, scale_a_i, scale_b_i);
  end
endmodule
