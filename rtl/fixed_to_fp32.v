`include "mx_defs.vh"

module fixed_to_fp32 (
  value_i,
  exp_shift_i,
  nan_i,
  fp32_o
);
  parameter WIDE_W = 512;

  input signed [`MX_DOT_W-1:0] value_i;
  input signed [`MX_DOT_EXP_W-1:0] exp_shift_i;
  input nan_i;
  output [31:0] fp32_o;

  reg [31:0] fp32_o;
  reg sign;
  reg [`MX_DOT_W-1:0] abs_value;
  reg [WIDE_W-1:0] wide_abs;
  reg [WIDE_W-1:0] wide_scaled;
  reg [WIDE_W-1:0] wide_rounded;
  reg [23:0] sig24;
  reg [22:0] frac;
  integer i;
  integer wide_msb;
  integer scale_shift;
  integer shift_amt;
  integer exp_unbiased;
  integer exp_field;

  function [WIDE_W-1:0] round_shift_right_wide;
    input [WIDE_W-1:0] value;
    input integer shift;
    reg [WIDE_W-1:0] shifted;
    reg guard_bit;
    reg sticky_bit;
    reg round_inc;
    integer sticky_idx;
    begin
      if (shift <= 0) begin
        round_shift_right_wide = value << (-shift);
      end else if (shift >= WIDE_W) begin
        round_shift_right_wide = {WIDE_W{1'b0}};
      end else begin
        shifted = value >> shift;
        guard_bit = value[shift-1];
        sticky_bit = 1'b0;
        for (sticky_idx = 0; sticky_idx < shift-1; sticky_idx = sticky_idx + 1) begin
          sticky_bit = sticky_bit | value[sticky_idx];
        end
        round_inc = guard_bit & (sticky_bit | shifted[0]);
        if (round_inc) begin
          shifted = shifted + 1'b1;
        end
        round_shift_right_wide = shifted;
      end
    end
  endfunction

  always @* begin
    fp32_o = `MX_FP32_ZERO;
    sign = 1'b0;
    abs_value = {`MX_DOT_W{1'b0}};
    wide_abs = {WIDE_W{1'b0}};
    wide_scaled = {WIDE_W{1'b0}};
    wide_rounded = {WIDE_W{1'b0}};
    sig24 = 24'd0;
    frac = 23'd0;
    wide_msb = -1;
    scale_shift = 0;
    shift_amt = 0;
    exp_unbiased = 0;
    exp_field = 0;

    if (nan_i) begin
      fp32_o = `MX_FP32_QNAN;
    end else if (value_i == {`MX_DOT_W{1'b0}}) begin
      fp32_o = `MX_FP32_ZERO;
    end else begin
      sign = value_i[`MX_DOT_W-1];
      abs_value = sign ? -value_i : value_i;
      wide_abs[`MX_DOT_W-1:0] = abs_value;

      scale_shift = exp_shift_i + 149;
      if (scale_shift >= 0) begin
        wide_scaled = wide_abs << scale_shift;
      end else begin
        wide_scaled = round_shift_right_wide(wide_abs, -scale_shift);
      end

      if (wide_scaled == {WIDE_W{1'b0}}) begin
        fp32_o = {sign, 31'd0};
      end else begin
        for (i = 0; i < WIDE_W; i = i + 1) begin
          if (wide_scaled[i]) begin
            wide_msb = i;
          end
        end

        if (wide_msb > 276) begin
          fp32_o = sign ? `MX_FP32_NINF : `MX_FP32_PINF;
        end else if (wide_msb < 23) begin
          frac = wide_scaled[22:0];
          fp32_o = {sign, 8'd0, frac};
        end else begin
          exp_unbiased = wide_msb - 149;
          if (exp_unbiased > 127) begin
            fp32_o = sign ? `MX_FP32_NINF : `MX_FP32_PINF;
          end else begin
            shift_amt = wide_msb - 23;
            exp_field = exp_unbiased + 127;
            wide_rounded = round_shift_right_wide(wide_scaled, shift_amt);
            if (wide_rounded[24]) begin
              sig24 = wide_rounded[24:1];
              exp_field = exp_field + 1;
            end else begin
              sig24 = wide_rounded[23:0];
            end

            if (exp_field >= 255) begin
              fp32_o = sign ? `MX_FP32_NINF : `MX_FP32_PINF;
            end else begin
              fp32_o = {sign, exp_field[7:0], sig24[22:0]};
            end
          end
        end
      end
    end
  end
endmodule
