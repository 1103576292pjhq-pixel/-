`include "mx_defs.vh"

module fixed_to_fp32 #(
  parameter IN_W = `MX_DOT_W,
  parameter EXP_W = `MX_DOT_EXP_W
) (
  value_i,
  exp_shift_i,
  nan_i,
  fp32_o
);
  input signed [IN_W-1:0] value_i;
  input signed [EXP_W-1:0] exp_shift_i;
  input nan_i;
  output [31:0] fp32_o;

  reg [31:0] fp32_o;
  integer i;
  integer msb_idx;
  integer shift_amt;
  integer exp_unbiased;
  reg sign_bit;
  reg [IN_W-1:0] abs_value;
  reg [24:0] sig_rounded;
  reg [24:0] sig_work;
  reg guard_bit;
  reg sticky_bit;
  reg round_up;
  reg [7:0] exp_field_out;

  always @* begin
    fp32_o = `MX_FP32_ZERO;
    sign_bit = value_i[IN_W-1];
    if (sign_bit) begin
      abs_value = -value_i;
    end else begin
      abs_value = value_i;
    end
    msb_idx = -1;
    sig_rounded = 25'd0;
    sig_work = 25'd0;
    guard_bit = 1'b0;
    sticky_bit = 1'b0;
    round_up = 1'b0;
    exp_field_out = 8'd0;

    if (nan_i) begin
      fp32_o = `MX_FP32_QNAN;
    end else if (value_i == {IN_W{1'b0}}) begin
      fp32_o = `MX_FP32_ZERO;
    end else begin
      for (i = IN_W - 1; i >= 0; i = i - 1) begin
        if ((msb_idx == -1) && abs_value[i]) begin
          msb_idx = i;
        end
      end

      exp_unbiased = exp_shift_i + msb_idx;

      if (exp_unbiased > 127) begin
        fp32_o = {sign_bit, 8'hff, 23'd0};
      end else if (exp_unbiased < -126) begin
        fp32_o = `MX_FP32_ZERO;
      end else begin
        if (msb_idx > 23) begin
          shift_amt = msb_idx - 23;
          sig_work = abs_value >> shift_amt;
          guard_bit = abs_value[shift_amt - 1];
          sticky_bit = 1'b0;
          for (i = 0; i < shift_amt - 1; i = i + 1) begin
            sticky_bit = sticky_bit | abs_value[i];
          end
          round_up = guard_bit & (sticky_bit | sig_work[0]);
          sig_rounded = sig_work + round_up;
        end else begin
          shift_amt = 23 - msb_idx;
          sig_rounded = abs_value << shift_amt;
        end

        if (sig_rounded[24]) begin
          sig_rounded = sig_rounded >> 1;
          exp_unbiased = exp_unbiased + 1;
        end

        if (exp_unbiased > 127) begin
          fp32_o = {sign_bit, 8'hff, 23'd0};
        end else begin
          exp_field_out = exp_unbiased + 127;
          fp32_o = {sign_bit, exp_field_out, sig_rounded[22:0]};
        end
      end
    end
  end
endmodule
