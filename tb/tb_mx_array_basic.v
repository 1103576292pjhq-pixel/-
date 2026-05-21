`timescale 1ns/1ps
`include "mx_defs.vh"

module tb_mx_array_basic;
  reg clk;
  reg rst_n;
  reg valid_i;
  reg [`MX_COLS-1:0] acc_clear_i;
  reg [`MX_BLOCK_K*`MX_ELEM_W-1:0] a_elems_i;
  reg [7:0] a_scale_i;
  reg [`MX_COLS*`MX_BLOCK_K*`MX_ELEM_W-1:0] b_elems_i;
  reg [`MX_COLS*8-1:0] b_scale_i;
  wire [`MX_COLS-1:0] valid_o;
  wire [`MX_COLS*32-1:0] acc_o;
  integer col;
  integer lane;
  integer errors;
  reg [31:0] expected;

  mx_array_32x16 dut (
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
    $dumpfile("build/tb_mx_array_basic.vcd");
    $dumpvars(0, tb_mx_array_basic);
  end
`endif

  initial begin
    errors = 0;
    rst_n = 1'b0;
    valid_i = 1'b0;
    acc_clear_i = {`MX_COLS{1'b0}};
    a_elems_i = 0;
    a_scale_i = 8'h7f;
    b_elems_i = 0;
    b_scale_i = {(`MX_COLS*8){1'b0}};

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    for (lane = 0; lane < `MX_BLOCK_K; lane = lane + 1) begin
      a_elems_i[lane*`MX_ELEM_W +: `MX_ELEM_W] = 8'h38;
    end

    for (col = 0; col < `MX_COLS; col = col + 1) begin
      b_scale_i[col*8 +: 8] = 8'h7f;
      for (lane = 0; lane < `MX_BLOCK_K; lane = lane + 1) begin
        if (col[0]) begin
          b_elems_i[(col*`MX_BLOCK_K + lane)*`MX_ELEM_W +: `MX_ELEM_W] = 8'h40;
        end else begin
          b_elems_i[(col*`MX_BLOCK_K + lane)*`MX_ELEM_W +: `MX_ELEM_W] = 8'h38;
        end
      end
    end

    @(negedge clk);
    valid_i = 1'b1;
    acc_clear_i = {`MX_COLS{1'b1}};
    @(negedge clk);
    valid_i = 1'b0;
    acc_clear_i = {`MX_COLS{1'b0}};

    while (valid_o !== {`MX_COLS{1'b1}}) begin
      @(posedge clk);
    end
    #1;

    for (col = 0; col < `MX_COLS; col = col + 1) begin
      expected = col[0] ? 32'h42800000 : 32'h42000000;
      if (acc_o[col*32 +: 32] !== expected) begin
        $display("FAIL col=%0d expected=%08x got=%08x", col, expected, acc_o[col*32 +: 32]);
        errors = errors + 1;
      end
    end

    if (errors == 0) begin
      $display("PASS tb_mx_array_basic");
    end else begin
      $display("FAIL tb_mx_array_basic errors=%0d", errors);
      $finish(1);
    end
    $finish;
  end
endmodule
