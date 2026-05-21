`timescale 1ns/1ps

module fp8_e8m0_decode (
  input  logic [7:0] scale_i,
  output logic signed [9:0] exponent_o,
  output logic              is_nan_o
);
  always_comb begin
    is_nan_o   = (scale_i == 8'hff);
    exponent_o = $signed({2'b00, scale_i}) - 10'sd127;
  end
endmodule
