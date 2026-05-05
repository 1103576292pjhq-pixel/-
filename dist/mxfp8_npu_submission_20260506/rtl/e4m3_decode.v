`include "mx_defs.vh"

module e4m3_decode (
  enc_i,
  sign_o,
  is_zero_o,
  is_subnormal_o,
  is_nan_o,
  unbiased_exp_o,
  significand_o,
  fixed_o
);
  input [7:0] enc_i;
  output sign_o;
  output is_zero_o;
  output is_subnormal_o;
  output is_nan_o;
  output signed [5:0] unbiased_exp_o;
  output [3:0] significand_o;
  output signed [`MX_ELEM_FIXED_W-1:0] fixed_o;

  `include "mx_funcs.vh"

  assign sign_o = enc_i[7];
  assign is_zero_o = e4m3_is_zero(enc_i);
  assign is_subnormal_o = e4m3_is_subnormal(enc_i);
  assign is_nan_o = e4m3_is_nan(enc_i);
  assign unbiased_exp_o = e4m3_unbiased_exp(enc_i);
  assign significand_o = e4m3_significand(enc_i);
  assign fixed_o = e4m3_to_fixed(enc_i);
endmodule
