`timescale 1ns/1ps
`include "mx_defs.vh"

module tb_llmt_col_basic;
  reg clk;
  reg rst_n;
  reg valid_i;
  reg acc_clear_i;
  reg [`MX_BLOCK_K*`MX_ELEM_W-1:0] a_elems_i;
  reg [7:0] a_scale_i;
  reg [`MX_BLOCK_K*`MX_ELEM_W-1:0] b_elems_i;
  reg [7:0] b_scale_i;
  wire valid_o;
  wire [31:0] acc_o;
  integer errors;

  llmt_col dut (
    .clk(clk),
    .rst_n(rst_n),
    .valid_i(valid_i),
    .acc_clear_i(acc_clear_i),
    .a_elems_i(a_elems_i),
    .a_scale_i(a_scale_i),
    .b_elems_i(b_elems_i),
    .b_scale_i(b_scale_i),
    .valid_o(valid_o),
    .acc_o(acc_o)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

`ifdef DUMP_VCD
  initial begin
    $dumpfile("build/tb_llmt_col_basic.vcd");
    $dumpvars(0, tb_llmt_col_basic);
  end
`endif

  task fill_block;
    output [`MX_BLOCK_K*`MX_ELEM_W-1:0] block;
    input [7:0] elem;
    integer i;
    begin
      block = {(`MX_BLOCK_K*`MX_ELEM_W){1'b0}};
      for (i = 0; i < `MX_BLOCK_K; i = i + 1) begin
        block[i*`MX_ELEM_W +: `MX_ELEM_W] = elem;
      end
    end
  endtask

  task send_dot;
    input [7:0] a_elem;
    input [7:0] b_elem;
    input clear;
    begin
      @(negedge clk);
      fill_block(a_elems_i, a_elem);
      fill_block(b_elems_i, b_elem);
      a_scale_i = 8'h7f;
      b_scale_i = 8'h7f;
      acc_clear_i = clear;
      valid_i = 1'b1;
      @(negedge clk);
      valid_i = 1'b0;
      acc_clear_i = 1'b0;
    end
  endtask

  task expect_next;
    input [31:0] expected;
    begin
      while (!valid_o) begin
        @(posedge clk);
      end
      #1;
      if (acc_o !== expected) begin
        $display("FAIL expected=%08x got=%08x", expected, acc_o);
        errors = errors + 1;
      end
      @(posedge clk);
    end
  endtask

  initial begin
    errors = 0;
    rst_n = 1'b0;
    valid_i = 1'b0;
    acc_clear_i = 1'b0;
    a_elems_i = 0;
    b_elems_i = 0;
    a_scale_i = 8'h7f;
    b_scale_i = 8'h7f;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    send_dot(8'h38, 8'h38, 1'b1);
    expect_next(32'h42000000);

    send_dot(8'h38, 8'h38, 1'b0);
    expect_next(32'h42800000);

    send_dot(8'h01, 8'h38, 1'b1);
    expect_next(32'h3d800000);

    send_dot(8'h7f, 8'h38, 1'b1);
    expect_next(`MX_FP32_QNAN);

    if (errors == 0) begin
      $display("PASS tb_llmt_col_basic");
    end else begin
      $display("FAIL tb_llmt_col_basic errors=%0d", errors);
      $finish(1);
    end
    $finish;
  end
endmodule
