function e4m3_is_zero;
  input [7:0] enc;
  begin
    e4m3_is_zero = (enc[6:0] == 7'd0);
  end
endfunction

function e4m3_is_nan;
  input [7:0] enc;
  begin
    e4m3_is_nan = (enc[6:3] == 4'hf) && (enc[2:0] == 3'h7);
  end
endfunction

function e4m3_is_subnormal;
  input [7:0] enc;
  begin
    e4m3_is_subnormal = (enc[6:3] == 4'd0) && (enc[2:0] != 3'd0);
  end
endfunction

function signed [5:0] e4m3_unbiased_exp;
  input [7:0] enc;
  begin
    if (enc[6:3] == 4'd0) begin
      e4m3_unbiased_exp = -6'sd6;
    end else begin
      e4m3_unbiased_exp = $signed({2'b00, enc[6:3]}) - 6'sd7;
    end
  end
endfunction

function [3:0] e4m3_significand;
  input [7:0] enc;
  begin
    if (enc[6:3] == 4'd0) begin
      e4m3_significand = {1'b0, enc[2:0]};
    end else begin
      e4m3_significand = {1'b1, enc[2:0]};
    end
  end
endfunction

function signed [`MX_ELEM_FIXED_W-1:0] e4m3_to_fixed;
  input [7:0] enc;
  reg sign_bit;
  reg [3:0] exp_field;
  reg [2:0] mant_field;
  reg signed [`MX_ELEM_FIXED_W-1:0] magnitude;
  reg signed [`MX_ELEM_FIXED_W-1:0] significand;
  integer shift_amt;
  begin
    sign_bit = enc[7];
    exp_field = enc[6:3];
    mant_field = enc[2:0];

    if (e4m3_is_zero(enc) || e4m3_is_nan(enc)) begin
      magnitude = {`MX_ELEM_FIXED_W{1'b0}};
    end else if (exp_field == 4'd0) begin
      magnitude = $signed({{(`MX_ELEM_FIXED_W-3){1'b0}}, mant_field});
    end else begin
      significand = $signed({{(`MX_ELEM_FIXED_W-4){1'b0}}, 1'b1, mant_field});
      shift_amt = exp_field - 1;
      magnitude = significand <<< shift_amt;
    end

    if (sign_bit) begin
      e4m3_to_fixed = -magnitude;
    end else begin
      e4m3_to_fixed = magnitude;
    end
  end
endfunction

function e8m0_is_nan;
  input [7:0] enc;
  begin
    e8m0_is_nan = (enc == 8'hff);
  end
endfunction

function signed [9:0] e8m0_unbiased_exp;
  input [7:0] enc;
  begin
    if (e8m0_is_nan(enc)) begin
      e8m0_unbiased_exp = 10'sd0;
    end else begin
      e8m0_unbiased_exp = $signed({2'b00, enc}) - 10'sd127;
    end
  end
endfunction
