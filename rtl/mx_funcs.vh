function e4m3_is_nan;
  input [7:0] x;
  begin
    e4m3_is_nan = (x[6:3] == 4'hf) && (x[2:0] == 3'h7);
  end
endfunction

function signed [`MX_ELEM_Q_W-1:0] e4m3_to_q9;
  input [7:0] x;
  reg sign;
  reg [3:0] exp;
  reg [2:0] mant;
  reg [`MX_ELEM_Q_W-1:0] mag;
  integer sh;
  begin
    sign = x[7];
    exp = x[6:3];
    mant = x[2:0];
    mag = {`MX_ELEM_Q_W{1'b0}};

    if (exp == 4'h0) begin
      mag = {{(`MX_ELEM_Q_W-3){1'b0}}, mant};
    end else if ((exp == 4'hf) && (mant == 3'h7)) begin
      mag = {`MX_ELEM_Q_W{1'b0}};
    end else begin
      sh = exp - 1;
      mag = {{(`MX_ELEM_Q_W-4){1'b0}}, (4'h8 + mant)} << sh;
    end

    if (sign) begin
      e4m3_to_q9 = -$signed(mag);
    end else begin
      e4m3_to_q9 = $signed(mag);
    end
  end
endfunction

function e8m0_is_nan;
  input [7:0] x;
  begin
    e8m0_is_nan = (x == 8'hff);
  end
endfunction

function signed [9:0] e8m0_unbiased_exp;
  input [7:0] x;
  begin
    if (e8m0_is_nan(x)) begin
      e8m0_unbiased_exp = 10'sd0;
    end else begin
      e8m0_unbiased_exp = $signed({2'b00, x}) - 10'sd127;
    end
  end
endfunction
