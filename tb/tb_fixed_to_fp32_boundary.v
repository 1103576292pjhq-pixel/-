`timescale 1ns/1ps
`include "mx_defs.vh"

module tb_fixed_to_fp32_boundary;
  reg signed [`MX_DOT_W-1:0] value_i;
  reg signed [`MX_DOT_EXP_W-1:0] exp_shift_i;
  reg nan_i;
  wire [31:0] fp32_o;
  integer errors;

  fixed_to_fp32 dut (
    .value_i(value_i),
    .exp_shift_i(exp_shift_i),
    .nan_i(nan_i),
    .fp32_o(fp32_o)
  );

  task check;
    input signed [`MX_DOT_W-1:0] value;
    input signed [`MX_DOT_EXP_W-1:0] shift;
    input [31:0] expected;
    begin
      value_i = value;
      exp_shift_i = shift;
      nan_i = 1'b0;
      #1;
      if (fp32_o !== expected) begin
        $display("FAIL value=%0d shift=%0d expected=%08x got=%08x", value, shift, expected, fp32_o);
        errors = errors + 1;
      end
    end
  endtask

  task check_nan;
    input signed [`MX_DOT_W-1:0] value;
    input signed [`MX_DOT_EXP_W-1:0] shift;
    input [31:0] expected;
    begin
      value_i = value;
      exp_shift_i = shift;
      nan_i = 1'b1;
      #1;
      if (fp32_o !== expected) begin
        $display("FAIL nan value=%0d shift=%0d expected=%08x got=%08x", value, shift, expected, fp32_o);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    errors = 0;
    check(48'sd1, -149, 32'h00000001);
    check(-48'sd1, -149, 32'h80000001);
    check(48'sd1, -150, 32'h00000000);
    check(48'sd8388607, -149, 32'h007fffff);
    check(48'sd16777215, -150, 32'h00800000);
    check(48'sd1, 128, `MX_FP32_PINF);
    check(-48'sd1, 128, `MX_FP32_NINF);
    check_nan(48'sd123, -17, `MX_FP32_QNAN);

    // 1.0 + half ULP ties to even and stays at exactly 1.0.
    check(48'sd16777217, -24, 32'h3f800000);

    // 1.0 + 1.5 ULP rounds up to the next even mantissa.
    check(48'sd16777219, -24, 32'h3f800002);

    if (errors == 0) begin
      $display("PASS tb_fixed_to_fp32_boundary");
    end else begin
      $display("FAIL tb_fixed_to_fp32_boundary errors=%0d", errors);
      $finish(1);
    end
    $finish;
  end
endmodule
