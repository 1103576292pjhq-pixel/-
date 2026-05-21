`timescale 1ns/1ps

import mxfp8_pkg::*;

module fp8_e4m3_decode (
  input  logic [7:0] fp8_i,
  output logic       sign_o,
  output logic       is_zero_o,
  output logic       is_subnormal_o,
  output logic       is_normal_o,
  output logic       is_nan_o,
  output logic [3:0] exponent_o,
  output logic [3:0] significand_o,
  output logic signed [7:0] pow2_o
);
  always_comb begin
    sign_o         = fp8_i[7];
    exponent_o     = fp8_i[6:3];
    significand_o  = (fp8_i[6:3] == 4'd0) ? {1'b0, fp8_i[2:0]} : {1'b1, fp8_i[2:0]};
    is_zero_o      = (fp8_i[6:0] == 7'd0);
    is_subnormal_o = (fp8_i[6:3] == 4'd0) && (fp8_i[2:0] != 3'd0);
    is_nan_o       = (fp8_i[6:0] == 7'h7f);
    is_normal_o    = (fp8_i[6:3] != 4'd0) && !is_nan_o;
    pow2_o         = (fp8_i[6:3] == 4'd0) ? -8'sd9 : ($signed({4'b0, fp8_i[6:3]}) - 8'sd10);
  end
endmodule
