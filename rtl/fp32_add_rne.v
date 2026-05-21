`include "mx_defs.vh"

module fp32_add_rne (
  a_i,
  b_i,
  sum_o
);
  input [31:0] a_i;
  input [31:0] b_i;
  output [31:0] sum_o;

  reg [31:0] sum_o;
  reg [31:0] sum_pre_o;
  reg sign_a;
  reg sign_b;
  reg [7:0] exp_a_f;
  reg [7:0] exp_b_f;
  reg [22:0] frac_a;
  reg [22:0] frac_b;
  reg [27:0] sig_a;
  reg [27:0] sig_b;
  reg signed [30:0] signed_a;
  reg signed [30:0] signed_b;
  reg signed [31:0] signed_sum;
  reg signed [`MX_DOT_W-1:0] sum_value;
  reg signed [`MX_DOT_EXP_W-1:0] sum_exp_shift;
  reg [7:0] exp_field_s;
  integer exp_a;
  integer exp_b;
  integer exp_s;
  integer shift_a;
  integer shift_b;
  reg use_cast;
  wire [31:0] sum_cast_o;

  function fp32_is_nan;
    input [31:0] x;
    begin
      fp32_is_nan = (x[30:23] == 8'hff) && (x[22:0] != 23'd0);
    end
  endfunction

  function fp32_is_inf;
    input [31:0] x;
    begin
      fp32_is_inf = (x[30:23] == 8'hff) && (x[22:0] == 23'd0);
    end
  endfunction

  function fp32_is_zero;
    input [31:0] x;
    begin
      fp32_is_zero = (x[30:0] == 31'd0);
    end
  endfunction

  function [27:0] shr_sticky;
    input [27:0] value;
    input integer shift;
    integer j;
    reg sticky;
    begin
      if (shift <= 0) begin
        shr_sticky = value;
      end else if (shift >= 28) begin
        shr_sticky = {27'd0, |value};
      end else begin
        sticky = 1'b0;
        for (j = 0; j < shift; j = j + 1) begin
          sticky = sticky | value[j];
        end
        shr_sticky = (value >> shift);
        shr_sticky[0] = shr_sticky[0] | sticky;
      end
    end
  endfunction

  fixed_to_fp32 sum_cast_u (
    .value_i(sum_value),
    .exp_shift_i(sum_exp_shift),
    .nan_i(1'b0),
    .fp32_o(sum_cast_o)
  );

  always @* begin
    sum_pre_o = `MX_FP32_ZERO;
    sign_a = a_i[31];
    sign_b = b_i[31];
    exp_a_f = a_i[30:23];
    exp_b_f = b_i[30:23];
    frac_a = a_i[22:0];
    frac_b = b_i[22:0];
    sig_a = 28'd0;
    sig_b = 28'd0;
    signed_a = 31'sd0;
    signed_b = 31'sd0;
    signed_sum = 32'sd0;
    sum_value = {`MX_DOT_W{1'b0}};
    sum_exp_shift = {`MX_DOT_EXP_W{1'b0}};
    exp_field_s = 8'd0;
    exp_a = 0;
    exp_b = 0;
    exp_s = 0;
    shift_a = 0;
    shift_b = 0;
    use_cast = 1'b0;

    if (fp32_is_nan(a_i) || fp32_is_nan(b_i)) begin
      sum_pre_o = `MX_FP32_QNAN;
    end else if (fp32_is_inf(a_i) && fp32_is_inf(b_i) && (sign_a != sign_b)) begin
      sum_pre_o = `MX_FP32_QNAN;
    end else if (fp32_is_inf(a_i)) begin
      sum_pre_o = a_i;
    end else if (fp32_is_inf(b_i)) begin
      sum_pre_o = b_i;
    end else if (fp32_is_zero(a_i) && fp32_is_zero(b_i)) begin
      sum_pre_o = (sign_a && sign_b) ? 32'h80000000 : `MX_FP32_ZERO;
    end else if (fp32_is_zero(a_i)) begin
      sum_pre_o = b_i;
    end else if (fp32_is_zero(b_i)) begin
      sum_pre_o = a_i;
    end else begin
      exp_a = (exp_a_f == 8'd0) ? -126 : (exp_a_f - 127);
      exp_b = (exp_b_f == 8'd0) ? -126 : (exp_b_f - 127);
      sig_a = {((exp_a_f == 8'd0) ? 1'b0 : 1'b1), frac_a, 4'b0000};
      sig_b = {((exp_b_f == 8'd0) ? 1'b0 : 1'b1), frac_b, 4'b0000};

      if (exp_a >= exp_b) begin
        exp_s = exp_a;
        shift_b = exp_a - exp_b;
        sig_b = shr_sticky(sig_b, shift_b);
      end else begin
        exp_s = exp_b;
        shift_a = exp_b - exp_a;
        sig_a = shr_sticky(sig_a, shift_a);
      end

      signed_a = sign_a ? -$signed({3'b000, sig_a}) : $signed({3'b000, sig_a});
      signed_b = sign_b ? -$signed({3'b000, sig_b}) : $signed({3'b000, sig_b});
      signed_sum = signed_a + signed_b;

      if (signed_sum == 32'sd0) begin
        sum_pre_o = `MX_FP32_ZERO;
      end else begin
        sum_value = {{(`MX_DOT_W-32){signed_sum[31]}}, signed_sum};
        sum_exp_shift = exp_s - 27;
        use_cast = 1'b1;
      end
    end
  end

  always @* begin
    sum_o = use_cast ? sum_cast_o : sum_pre_o;
  end
endmodule
