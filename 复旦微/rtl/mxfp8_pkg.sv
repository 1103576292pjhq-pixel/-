package mxfp8_pkg;
  parameter int K_BLOCK  = 32;
  parameter int NUM_LLMT = 16;
  parameter int FP8_W    = 8;
  parameter int SCALE_W  = 8;
  parameter int FP32_W   = 32;

  function automatic [55:0] shr_sticky56(input [55:0] value, input int unsigned shamt);
    logic sticky;
    begin
      if (shamt == 0) begin
        shr_sticky56 = value;
      end else if (shamt >= 56) begin
        shr_sticky56 = {55'b0, |value};
      end else begin
        sticky = |(value & ((56'h1 << shamt) - 56'h1));
        shr_sticky56 = value >> shamt;
        shr_sticky56[0] = shr_sticky56[0] | sticky;
      end
    end
  endfunction

  function automatic [31:0] fp32_pack_pow2_int(input bit sign, input int unsigned mag, input int signed pow2);
    int msb;
    int signed unbiased;
    int signed exp_field;
    logic [63:0] mant_ext;
    logic [24:0] rounded;
    int shift;
    begin
      if (mag == 0) begin
        fp32_pack_pow2_int = 32'h0000_0000;
      end else begin
        msb = 31;
        while ((msb > 0) && (((mag >> msb) & 1) == 0)) begin
          msb = msb - 1;
        end

        unbiased = pow2 + msb;
        exp_field = unbiased + 127;

        if (exp_field >= 255) begin
          fp32_pack_pow2_int = {sign, 8'hfe, 23'h7f_ffff};
        end else if (exp_field <= 0) begin
          shift = 1 - exp_field;
          if (msb + 23 >= 0) begin
            mant_ext = {32'b0, mag} << (23 - msb);
          end else begin
            mant_ext = {32'b0, mag} >> (msb - 23);
          end
          if (shift >= 64) begin
            mant_ext = 64'b0;
          end else begin
            mant_ext = mant_ext >> shift;
          end
          fp32_pack_pow2_int = {sign, 8'h00, mant_ext[22:0]};
        end else begin
          if (msb <= 23) begin
            mant_ext = {32'b0, mag} << (23 - msb);
          end else begin
            shift = msb - 23;
            mant_ext = {32'b0, mag} >> shift;
            if (shift > 0 && shift < 32) begin
              rounded = {1'b0, mant_ext[23:0]};
              if ((((mag >> (shift - 1)) & 1) != 0) && (((mag & ((32'h1 << (shift - 1)) - 1)) != 0) || mant_ext[0])) begin
                rounded = rounded + 1'b1;
              end
              if (rounded[24]) begin
                exp_field = exp_field + 1;
                mant_ext[23:0] = rounded[24:1];
              end else begin
                mant_ext[23:0] = rounded[23:0];
              end
            end
          end
          if (exp_field >= 255) begin
            fp32_pack_pow2_int = {sign, 8'hfe, 23'h7f_ffff};
          end else begin
            fp32_pack_pow2_int = {sign, exp_field[7:0], mant_ext[22:0]};
          end
        end
      end
    end
  endfunction

  function automatic [31:0] mxfp8_mul_fp32(input logic [7:0] a, input logic [7:0] b,
                                           input logic [7:0] scale_a, input logic [7:0] scale_b);
    logic sign;
    int unsigned exp_a;
    int unsigned exp_b;
    int unsigned frac_a;
    int unsigned frac_b;
    int unsigned mant_a;
    int unsigned mant_b;
    int signed pow_a;
    int signed pow_b;
    int signed pow_prod;
    int unsigned mag;
    begin
      if ((scale_a == 8'hff) || (scale_b == 8'hff) || (a[6:0] == 7'h7f) || (b[6:0] == 7'h7f)) begin
        mxfp8_mul_fp32 = 32'h7fc0_0000;
      end else begin
        sign = a[7] ^ b[7];
        exp_a = a[6:3];
        exp_b = b[6:3];
        frac_a = a[2:0];
        frac_b = b[2:0];

        if (exp_a == 0) begin
          mant_a = frac_a;
          pow_a = -9;
        end else begin
          mant_a = 8 + frac_a;
          pow_a = int'(exp_a) - 10;
        end

        if (exp_b == 0) begin
          mant_b = frac_b;
          pow_b = -9;
        end else begin
          mant_b = 8 + frac_b;
          pow_b = int'(exp_b) - 10;
        end

        mag = mant_a * mant_b;
        pow_prod = pow_a + pow_b + int'(scale_a) + int'(scale_b) - 254;
        mxfp8_mul_fp32 = fp32_pack_pow2_int(sign, mag, pow_prod);
      end
    end
  endfunction

  function automatic [31:0] fp32_add_rne_func(input logic [31:0] a, input logic [31:0] b);
    logic sign_a;
    logic sign_b;
    logic sign_r;
    int unsigned exp_a;
    int unsigned exp_b;
    int signed exp_eff_a;
    int signed exp_eff_b;
    int signed exp_big;
    int signed exp_r;
    logic [55:0] mant_a;
    logic [55:0] mant_b;
    logic [55:0] mant_big;
    logic [55:0] mant_small;
    logic [56:0] mant_sum;
    logic [55:0] mant_norm;
    int unsigned diff;
    int lead;
    logic guard;
    logic round_bit;
    logic sticky;
    logic [24:0] mant_round;
    int signed exp_field;
    begin
      sign_a = a[31];
      sign_b = b[31];
      exp_a = a[30:23];
      exp_b = b[30:23];

      if (a[30:0] == 0) begin
        fp32_add_rne_func = b;
      end else if (b[30:0] == 0) begin
        fp32_add_rne_func = a;
      end else if (exp_a == 8'hff || exp_b == 8'hff) begin
        fp32_add_rne_func = 32'h7fc0_0000;
      end else begin
        exp_eff_a = (exp_a == 0) ? -126 : int'(exp_a) - 127;
        exp_eff_b = (exp_b == 0) ? -126 : int'(exp_b) - 127;
        mant_a = {((exp_a == 0) ? 1'b0 : 1'b1), a[22:0], 32'b0};
        mant_b = {((exp_b == 0) ? 1'b0 : 1'b1), b[22:0], 32'b0};

        if ((exp_eff_a > exp_eff_b) || ((exp_eff_a == exp_eff_b) && (mant_a >= mant_b))) begin
          exp_big = exp_eff_a;
          diff = exp_eff_a - exp_eff_b;
          mant_big = mant_a;
          mant_small = shr_sticky56(mant_b, diff);
          sign_r = sign_a;
        end else begin
          exp_big = exp_eff_b;
          diff = exp_eff_b - exp_eff_a;
          mant_big = mant_b;
          mant_small = shr_sticky56(mant_a, diff);
          sign_r = sign_b;
        end

        if (sign_a == sign_b) begin
          mant_sum = {1'b0, mant_big} + {1'b0, mant_small};
          sign_r = sign_a;
        end else begin
          mant_sum = {1'b0, mant_big} - {1'b0, mant_small};
        end

        if (mant_sum == 0) begin
          fp32_add_rne_func = 32'h0000_0000;
        end else begin
          exp_r = exp_big;
          if (mant_sum[56]) begin
            mant_norm = mant_sum[56:1];
            exp_r = exp_r + 1;
          end else begin
            mant_norm = mant_sum[55:0];
            lead = 55;
            while ((lead > 0) && (mant_norm[lead] == 1'b0)) begin
              lead = lead - 1;
            end
            if (lead < 55) begin
              if ((55 - lead) > exp_r + 126) begin
                mant_norm = mant_norm << (exp_r + 126);
                exp_r = -126;
              end else begin
                mant_norm = mant_norm << (55 - lead);
                exp_r = exp_r - (55 - lead);
              end
            end
          end

          guard = mant_norm[31];
          round_bit = mant_norm[30];
          sticky = |mant_norm[29:0];
          mant_round = {1'b0, mant_norm[54:32]};
          if (guard && (round_bit || sticky || mant_round[0])) begin
            mant_round = mant_round + 1'b1;
          end
          if (mant_round[24]) begin
            mant_round = mant_round >> 1;
            exp_r = exp_r + 1;
          end

          exp_field = exp_r + 127;
          if (exp_field >= 255) begin
            fp32_add_rne_func = {sign_r, 8'hfe, 23'h7f_ffff};
          end else if (exp_field <= 0) begin
            if (exp_field < -23) begin
              fp32_add_rne_func = {sign_r, 31'b0};
            end else begin
              fp32_add_rne_func = {sign_r, 8'h00, (mant_round[22:0] >> (1 - exp_field))};
            end
          end else begin
            fp32_add_rne_func = {sign_r, exp_field[7:0], mant_round[22:0]};
          end
        end
      end
    end
  endfunction
endpackage
