`include "mx_defs.vh"

module e8m0_scale_decode (
  enc_i,
  is_nan_o,
  unbiased_exp_o
);
  input [7:0] enc_i;
  output is_nan_o;
  output signed [9:0] unbiased_exp_o;

  `include "mx_funcs.vh"

  assign is_nan_o = e8m0_is_nan(enc_i);
  assign unbiased_exp_o = e8m0_unbiased_exp(enc_i);
endmodule
