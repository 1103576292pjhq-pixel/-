`timescale 1ns/1ps
`include "mx_defs.vh"

module tb_fp32_add_basic;
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
    check(32'h3f800000, 32'h3f800000, 32'h40000000);
    check(32'h42000000, 32'h42000000, 32'h42800000);
    check(32'h42000000, 32'hc2000000, 32'h00000000);
    check(32'h7f800000, 32'hff800000, `MX_FP32_QNAN);
    check(`MX_FP32_QNAN, 32'h3f800000, `MX_FP32_QNAN);

    // 1.0 + half ULP rounds to even, so it remains exactly 1.0.
    check(32'h3f800000, 32'h33800000, 32'h3f800000);

    // 1.0 + 1.5 ULP rounds to 1.0 + 2 ULP.
    check(32'h3f800000, 32'h34400000, 32'h3f800002);

    if (errors == 0) begin
      $display("PASS tb_fp32_add_basic");
    end else begin
      $display("FAIL tb_fp32_add_basic errors=%0d", errors);
      $finish(1);
    end
    $finish;
  end
endmodule
