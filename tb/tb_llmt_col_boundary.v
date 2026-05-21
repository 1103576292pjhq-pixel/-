`timescale 1ns/1ps
`include "mx_defs.vh"

module tb_llmt_col_boundary;
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

  localparam [7:0] E4M3_POS_ONE = 8'h38;
  localparam [7:0] E4M3_NEG_ONE = 8'hb8;
  localparam [7:0] E4M3_POS_MIN_SUB = 8'h01;
  localparam [7:0] E4M3_NAN = 8'h7f;
  localparam [7:0] E8M0_ONE = 8'h7f;
  localparam [7:0] E8M0_EXP_NEG77 = 8'h32;
  localparam [7:0] E8M0_EXP_NEG66 = 8'h3d;
  localparam [7:0] E8M0_EXP_NEG65 = 8'h3e;
  localparam [7:0] E8M0_NAN = 8'hff;

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
    $dumpfile("build/tb_llmt_col_boundary.vcd");
    $dumpvars(0, tb_llmt_col_boundary);
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

  task load_uniform;
    input [7:0] a_elem;
    input [7:0] b_elem;
    input [7:0] a_scale;
    input [7:0] b_scale;
    begin
      fill_block(a_elems_i, a_elem);
      fill_block(b_elems_i, b_elem);
      a_scale_i = a_scale;
      b_scale_i = b_scale;
    end
  endtask

  task pulse_once;
    input clear;
    begin
      @(negedge clk);
      valid_i = 1'b1;
      acc_clear_i = clear;
      @(negedge clk);
      valid_i = 1'b0;
      acc_clear_i = 1'b0;
    end
  endtask

  task clear_idle_and_check_zero;
    begin
      @(negedge clk);
      valid_i = 1'b0;
      acc_clear_i = 1'b1;
      @(posedge clk);
      #1;
      if (acc_o !== `MX_FP32_ZERO) begin
        $display("FAIL idle_clear expected=%08x got=%08x", `MX_FP32_ZERO, acc_o);
        errors = errors + 1;
      end
      @(negedge clk);
      acc_clear_i = 1'b0;
    end
  endtask

  task expect_next;
    input [31:0] expected;
    input [255:0] name;
    begin
      while (!valid_o) begin
        @(posedge clk);
      end
      #1;
      if (acc_o !== expected) begin
        $display("FAIL %0s expected=%08x got=%08x", name, expected, acc_o);
        errors = errors + 1;
      end
      @(posedge clk);
    end
  endtask

  task send_and_expect;
    input [7:0] a_elem;
    input [7:0] b_elem;
    input [7:0] a_scale;
    input [7:0] b_scale;
    input clear;
    input [31:0] expected;
    input [255:0] name;
    begin
      load_uniform(a_elem, b_elem, a_scale, b_scale);
      pulse_once(clear);
      expect_next(expected, name);
    end
  endtask

  initial begin
    errors = 0;
    rst_n = 1'b0;
    valid_i = 1'b0;
    acc_clear_i = 1'b0;
    a_elems_i = {(`MX_BLOCK_K*`MX_ELEM_W){1'b0}};
    b_elems_i = {(`MX_BLOCK_K*`MX_ELEM_W){1'b0}};
    a_scale_i = E8M0_ONE;
    b_scale_i = E8M0_ONE;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    clear_idle_and_check_zero();

    send_and_expect(E4M3_POS_ONE, E4M3_POS_ONE, E8M0_EXP_NEG77, E8M0_EXP_NEG77, 1'b1, 32'h00000001, "min_subnormal");
    send_and_expect(E4M3_NEG_ONE, E4M3_POS_ONE, E8M0_EXP_NEG77, E8M0_EXP_NEG77, 1'b1, 32'h80000001, "negative_min_subnormal");
    send_and_expect(E4M3_POS_ONE, E4M3_POS_ONE, E8M0_EXP_NEG66, E8M0_EXP_NEG65, 1'b1, 32'h00800000, "min_normal");
    send_and_expect(E4M3_POS_ONE, E4M3_POS_ONE, E8M0_NAN, E8M0_ONE, 1'b1, `MX_FP32_QNAN, "scale_nan_propagation");

    load_uniform(E4M3_POS_ONE, E4M3_POS_ONE, E8M0_ONE, E8M0_ONE);
    a_elems_i[7:0] = E4M3_NAN;
    pulse_once(1'b1);
    expect_next(`MX_FP32_QNAN, "elem_nan_propagation");

    clear_idle_and_check_zero();

    load_uniform(E4M3_POS_ONE, E4M3_POS_ONE, E8M0_ONE, E8M0_ONE);
    @(negedge clk);
    valid_i = 1'b1;
    acc_clear_i = 1'b1;
    @(negedge clk);
    valid_i = 1'b1;
    acc_clear_i = 1'b0;
    @(negedge clk);
    valid_i = 1'b1;
    acc_clear_i = 1'b0;
    @(negedge clk);
    valid_i = 1'b0;

    expect_next(32'h42000000, "accumulate_after_clear_1");
    expect_next(32'h42800000, "accumulate_after_clear_2");
    expect_next(32'h42c00000, "accumulate_after_clear_3");

    if (errors == 0) begin
      $display("PASS tb_llmt_col_boundary");
    end else begin
      $display("FAIL tb_llmt_col_boundary errors=%0d", errors);
      $finish(1);
    end
    $finish;
  end
endmodule
