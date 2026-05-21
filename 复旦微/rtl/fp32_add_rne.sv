`timescale 1ns/1ps

import mxfp8_pkg::*;

module fp32_add_rne (
  input  logic [31:0] a_i,
  input  logic [31:0] b_i,
  output logic [31:0] y_o
);
  always_comb begin
    y_o = mxfp8_pkg::fp32_add_rne_func(a_i, b_i);
  end
endmodule
