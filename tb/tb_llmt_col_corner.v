`timescale 1ns/1ps
`include "mx_defs.vh"

module tb_llmt_col_corner;
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

  localparam [7:0] E4M3_POS_ONE = 8'h38;
  localparam [7:0] E4M3_NEG_ONE = 8'hb8;
  localparam [7:0] E4M3_SUB_ONE = 8'h01;
  localparam [7:0] E4M3_NAN = 8'h7f;
  localparam [7:0] E8M0_ONE = 8'h7f;
  localparam [7:0] E8M0_NAN = 8'hff;

  localparam [31:0] FP32_ZERO = 32'h00000000;
  localparam [31:0] FP32_NEG32 = 32'hc2000000;
  localparam [31:0] FP32_SUBSUM = 32'h3d800000;  // 0.0625
  localparam [31:0] FP32_QNAN = 32'h7fc00000;

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

  task fill_block;
    input [7:0] a_elem;
    input [7:0] b_elem;
    input [7:0] a_scale;
    input [7:0] b_scale;
    integer idx;
    begin
      for (idx = 0; idx < `MX_BLOCK_K; idx = idx + 1) begin
        a_elems_i[idx*8 +: 8] = a_elem;
        b_elems_i[idx*8 +: 8] = b_elem;
      end
      a_scale_i = a_scale;
      b_scale_i = b_scale;
    end
  endtask

  task pulse_valid;
    input clear_value;
    begin
      @(negedge clk);
      valid_i = 1'b1;
      acc_clear_i = clear_value;

      @(negedge clk);
      valid_i = 1'b0;
      acc_clear_i = 1'b0;
    end
  endtask

  task wait_for_output;
    begin
      while (valid_o === 1'b1) begin
        @(negedge clk);
      end
      while (valid_o !== 1'b1) begin
        @(negedge clk);
      end
      #1;
    end
  endtask

  task check_acc;
    input [31:0] expected;
    input [255:0] name;
    begin
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

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    fill_block(8'h00, 8'h00, E8M0_ONE, E8M0_ONE);
    pulse_valid(1'b1);
    wait_for_output();
    check_acc(FP32_ZERO, "zero block");

    fill_block(E4M3_NEG_ONE, E4M3_POS_ONE, E8M0_ONE, E8M0_ONE);
    pulse_valid(1'b1);
    wait_for_output();
    check_acc(FP32_NEG32, "negative ones");

    @(negedge clk);
    valid_i = 1'b0;
    acc_clear_i = 1'b1;
    @(posedge clk);
    #1;
    check_acc(FP32_ZERO, "clear without valid");
    @(negedge clk);
    acc_clear_i = 1'b0;

    fill_block(E4M3_SUB_ONE, E4M3_POS_ONE, E8M0_ONE, E8M0_ONE);
    pulse_valid(1'b1);
    wait_for_output();
    check_acc(FP32_SUBSUM, "subnormal path");

    fill_block(E4M3_POS_ONE, E4M3_POS_ONE, E8M0_NAN, E8M0_ONE);
    pulse_valid(1'b1);
    wait_for_output();
    check_acc(FP32_QNAN, "scale nan");

    @(negedge clk);
    valid_i = 1'b0;
    acc_clear_i = 1'b1;
    @(posedge clk);
    #1;
    @(negedge clk);
    acc_clear_i = 1'b0;

    fill_block(E4M3_POS_ONE, E4M3_POS_ONE, E8M0_ONE, E8M0_ONE);
    a_elems_i[7:0] = E4M3_NAN;
    pulse_valid(1'b1);
    wait_for_output();
    check_acc(FP32_QNAN, "element nan");

    $display("PASS: llmt_col corner test completed.");
    $finish;
  end
endmodule
