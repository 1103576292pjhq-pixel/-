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
  integer i;
  integer exp_a;
  integer exp_b;
  integer exp_big;
  integer exp_small;
  integer exp_res;
  integer diff_exp;
  integer lead_idx;
  reg sign_a;
  reg sign_b;
  reg sign_big;
  reg sign_small;
  reg [7:0] exp_field_a;
  reg [7:0] exp_field_b;
  reg [23:0] mant_a;
  reg [23:0] mant_b;
  reg [23:0] mant_big_raw;
  reg [23:0] mant_small_raw;
  reg [26:0] mant_big_ext;
  reg [26:0] mant_small_ext;
  reg [26:0] mant_small_aligned;
  reg [27:0] mant_sum;
  reg [27:0] mant_norm;
  reg [23:0] mant_main;
  reg guard_bit;
  reg round_bit;
  reg sticky_bit;
  reg round_up;
  reg [24:0] mant_rounded;
  reg [7:0] exp_field_out;
  reg a_is_zero;
  reg b_is_zero;
  reg a_is_nan;
  reg b_is_nan;
  reg a_is_inf;
  reg b_is_inf;

  function [26:0] shr_sticky_27;
    input [26:0] value;
    input integer shift_amt;
    reg [26:0] shifted;
    reg sticky;
    integer j;
    begin
      if (shift_amt <= 0) begin
        shifted = value;
      end else if (shift_amt >= 27) begin
        shifted = 27'd0;
        shifted[0] = |value;
      end else begin
        shifted = value >> shift_amt;
        sticky = 1'b0;
        for (j = 0; j < shift_amt; j = j + 1) begin
          sticky = sticky | value[j];
        end
        shifted[0] = shifted[0] | sticky;
      end
      shr_sticky_27 = shifted;
    end
  endfunction

  always @* begin
    sign_a = a_i[31];
    sign_b = b_i[31];
    exp_field_a = a_i[30:23];
    exp_field_b = b_i[30:23];
    if (exp_field_a == 8'd0) begin
      mant_a = {1'b0, a_i[22:0]};
    end else begin
      mant_a = {1'b1, a_i[22:0]};
    end
    if (exp_field_b == 8'd0) begin
      mant_b = {1'b0, b_i[22:0]};
    end else begin
      mant_b = {1'b1, b_i[22:0]};
    end
    if (exp_field_a == 8'd0) begin
      exp_a = -126;
    end else begin
      exp_a = exp_field_a - 127;
    end
    if (exp_field_b == 8'd0) begin
      exp_b = -126;
    end else begin
      exp_b = exp_field_b - 127;
    end

    a_is_zero = (a_i[30:0] == 31'd0);
    b_is_zero = (b_i[30:0] == 31'd0);
    a_is_nan = (exp_field_a == 8'hff) && (a_i[22:0] != 23'd0);
    b_is_nan = (exp_field_b == 8'hff) && (b_i[22:0] != 23'd0);
    a_is_inf = (exp_field_a == 8'hff) && (a_i[22:0] == 23'd0);
    b_is_inf = (exp_field_b == 8'hff) && (b_i[22:0] == 23'd0);

    sum_o = `MX_FP32_ZERO;
    mant_big_ext = 27'd0;
    mant_small_ext = 27'd0;
    mant_small_aligned = 27'd0;
    mant_sum = 28'd0;
    mant_norm = 28'd0;
    mant_main = 24'd0;
    guard_bit = 1'b0;
    round_bit = 1'b0;
    sticky_bit = 1'b0;
    round_up = 1'b0;
    mant_rounded = 25'd0;
    exp_field_out = 8'd0;
    lead_idx = -1;

    if (a_is_nan || b_is_nan) begin
      sum_o = `MX_FP32_QNAN;
    end else if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
      sum_o = `MX_FP32_QNAN;
    end else if (a_is_inf) begin
      sum_o = a_i;
    end else if (b_is_inf) begin
      sum_o = b_i;
    end else if (a_is_zero) begin
      sum_o = b_i;
    end else if (b_is_zero) begin
      sum_o = a_i;
    end else begin
      if ((exp_a > exp_b) || ((exp_a == exp_b) && (mant_a >= mant_b))) begin
        sign_big = sign_a;
        sign_small = sign_b;
        exp_big = exp_a;
        exp_small = exp_b;
        mant_big_raw = mant_a;
        mant_small_raw = mant_b;
      end else begin
        sign_big = sign_b;
        sign_small = sign_a;
        exp_big = exp_b;
        exp_small = exp_a;
        mant_big_raw = mant_b;
        mant_small_raw = mant_a;
      end

      diff_exp = exp_big - exp_small;
      mant_big_ext = {mant_big_raw, 3'b000};
      mant_small_ext = {mant_small_raw, 3'b000};
      mant_small_aligned = shr_sticky_27(mant_small_ext, diff_exp);
      exp_res = exp_big;

      if (sign_big == sign_small) begin
        mant_sum = {1'b0, mant_big_ext} + {1'b0, mant_small_aligned};
        if (mant_sum[27]) begin
          mant_norm = mant_sum >> 1;
          mant_norm[0] = mant_norm[0] | mant_sum[0];
          exp_res = exp_res + 1;
        end else begin
          mant_norm = mant_sum;
        end
      end else begin
        mant_sum = {1'b0, mant_big_ext} - {1'b0, mant_small_aligned};
        if (mant_sum == 28'd0) begin
          sum_o = `MX_FP32_ZERO;
        end else begin
          for (i = 27; i >= 0; i = i - 1) begin
            if ((lead_idx == -1) && mant_sum[i]) begin
              lead_idx = i;
            end
          end
          if (lead_idx > 26) begin
            mant_norm = mant_sum >> (lead_idx - 26);
            exp_res = exp_res + (lead_idx - 26);
          end else begin
            mant_norm = mant_sum << (26 - lead_idx);
            exp_res = exp_res - (26 - lead_idx);
          end
        end
      end

      if ((mant_sum != 28'd0) || (sign_big == sign_small)) begin
        if (exp_res > 127) begin
          sum_o = {sign_big, 8'hff, 23'd0};
        end else if (exp_res < -126) begin
          sum_o = `MX_FP32_ZERO;
        end else begin
          mant_main = mant_norm[26:3];
          guard_bit = mant_norm[2];
          round_bit = mant_norm[1];
          sticky_bit = mant_norm[0];
          round_up = guard_bit & (round_bit | sticky_bit | mant_main[0]);
          mant_rounded = {1'b0, mant_main} + round_up;

          if (mant_rounded[24]) begin
            mant_rounded = mant_rounded >> 1;
            exp_res = exp_res + 1;
          end

          if (exp_res > 127) begin
            sum_o = {sign_big, 8'hff, 23'd0};
          end else begin
            exp_field_out = exp_res + 127;
            sum_o = {sign_big, exp_field_out, mant_rounded[22:0]};
          end
        end
      end
    end
  end
endmodule
