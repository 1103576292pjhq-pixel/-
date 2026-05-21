`timescale 1ns/1ps
`include "mx_defs.vh"

module tb_fp32_add_subnormal;
  reg [31:0] a_i;
  reg [31:0] b_i;
  wire [31:0] sum_o;
  integer errors;

  fp32_add_rne dut (
    .a_i(a_i),
    .b_i(b_i),
    .sum_o(sum_o)
  );

  task check;
    input [31:0] a;
    input [31:0] b;
    input [31:0] expected;
    begin
      a_i = a;
      b_i = b;
      #1;
      if (sum_o !== expected) begin
        $display("FAIL a=%08x b=%08x expected=%08x got=%08x", a, b, expected, sum_o);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    errors = 0;
    check(32'h00800000, 32'h807fffff, 32'h00000001);
    check(32'h00000001, 32'h00000001, 32'h00000002);
    check(32'h00400000, 32'h00400000, 32'h00800000);
    check(32'h00000001, 32'h80000001, 32'h00000000);
    check(32'h00000000, 32'h80000000, 32'h00000000);
    check(32'h80000000, 32'h00000000, 32'h00000000);
    check(32'h80000000, 32'h80000000, 32'h80000000);
    check(32'h007fffff, 32'h00000001, 32'h00800000);
    check(32'h007fffff, 32'h00000002, 32'h00800001);
    check(`MX_FP32_PINF, 32'h3f800000, `MX_FP32_PINF);
    check(32'h3f800000, `MX_FP32_NINF, `MX_FP32_NINF);

    if (errors == 0) begin
      $display("PASS tb_fp32_add_subnormal");
    end else begin
      $display("FAIL tb_fp32_add_subnormal errors=%0d", errors);
      $finish(1);
    end
    $finish;
  end
endmodule
