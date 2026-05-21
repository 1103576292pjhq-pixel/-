`timescale 1ns/1ps

module tb_fp8_decode;
  logic [7:0] fp8;
  logic sign;
  logic is_zero;
  logic is_subnormal;
  logic is_normal;
  logic is_nan;
  logic [3:0] exponent;
  logic [3:0] significand;
  logic signed [7:0] pow2;

  logic [7:0] scale;
  logic signed [9:0] scale_exp;
  logic scale_is_nan;

  fp8_e4m3_decode u_dec (
    .fp8_i(fp8),
    .sign_o(sign),
    .is_zero_o(is_zero),
    .is_subnormal_o(is_subnormal),
    .is_normal_o(is_normal),
    .is_nan_o(is_nan),
    .exponent_o(exponent),
    .significand_o(significand),
    .pow2_o(pow2)
  );

  fp8_e8m0_decode u_scale (
    .scale_i(scale),
    .exponent_o(scale_exp),
    .is_nan_o(scale_is_nan)
  );

  initial begin
    fp8 = 8'h00; scale = 8'h7f; #1;
    if (!is_zero || sign || exponent != 0 || significand != 0 || scale_exp != 0) $fatal(1, "zero/scale decode failed");

    fp8 = 8'h01; #1;
    if (!is_subnormal || is_zero || significand != 4'h1 || pow2 != -9) $fatal(1, "subnormal decode failed");

    fp8 = 8'h38; #1;
    if (!is_normal || exponent != 4'h7 || significand != 4'h8 || pow2 != -3) $fatal(1, "normal decode failed");

    fp8 = 8'hb8; scale = 8'h80; #1;
    if (!sign || scale_exp != 1) $fatal(1, "negative/scale decode failed");

    fp8 = 8'h7e; scale = 8'hfe; #1;
    if (!is_normal || is_nan || exponent != 4'hf || significand != 4'he || scale_exp != 127 || scale_is_nan) $fatal(1, "max finite decode failed");

    fp8 = 8'h7f; scale = 8'hff; #1;
    if (!is_nan || is_normal || !scale_is_nan) $fatal(1, "nan decode failed");

    $display("tb_fp8_decode PASS");
    $finish;
  end
endmodule
