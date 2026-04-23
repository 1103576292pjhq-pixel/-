`timescale 1ns/1ps
`include "mx_defs.vh"

module tb_llmt_col_back_to_back;
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

  localparam [7:0] E4M3_ONE = 8'h38;
  localparam [7:0] E8M0_ONE = 8'h7f;
  localparam [31:0] FP32_32 = 32'h42000000;
  localparam [31:0] FP32_64 = 32'h42800000;
  localparam [31:0] FP32_96 = 32'h42c00000;

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

  task fill_ones;
    integer idx;
    begin
      for (idx = 0; idx < `MX_BLOCK_K; idx = idx + 1) begin
        a_elems_i[idx*8 +: 8] = E4M3_ONE;
        b_elems_i[idx*8 +: 8] = E4M3_ONE;
      end
      a_scale_i = E8M0_ONE;
      b_scale_i = E8M0_ONE;
    end
  endtask

  task wait_for_valid_high;
    begin
      while (valid_o !== 1'b1) begin
        @(negedge clk);
      end
      #1;
    end
  endtask

  task check_cycle;
    input [31:0] expected;
    input [255:0] name;
    begin
      if (valid_o !== 1'b1) begin
        $display("FAIL: %0s expected valid_o=1 got %b", name, valid_o);
        $fatal;
      end
      if (acc_o !== expected) begin
        $display("FAIL: %0s expected %h got %h", name, expected, acc_o);
        $fatal;
      end
    end
  endtask

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    valid_i = 1'b0;
    acc_clear_i = 1'b0;
    a_elems_i = {(`MX_BLOCK_K*`MX_ELEM_W){1'b0}};
    a_scale_i = 8'd0;
    b_elems_i = {(`MX_BLOCK_K*`MX_ELEM_W){1'b0}};
    b_scale_i = 8'd0;

    fill_ones();

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    @(negedge clk);
    valid_i = 1'b1;
    acc_clear_i = 1'b1;

    @(negedge clk);
    valid_i = 1'b1;
    acc_clear_i = 1'b0;

    @(negedge clk);
    valid_i = 1'b1;

    @(negedge clk);
    valid_i = 1'b0;

    wait_for_valid_high();
    check_cycle(FP32_32, "first result");

    @(negedge clk);
    #1;
    check_cycle(FP32_64, "second result");

    @(negedge clk);
    #1;
    check_cycle(FP32_96, "third result");

    @(negedge clk);
    #1;
    if (valid_o !== 1'b0) begin
      $display("FAIL: expected valid_o to drop after third result, got %b", valid_o);
      $fatal;
    end

    $display("PASS: llmt_col back-to-back test completed.");
    $finish;
  end
endmodule
