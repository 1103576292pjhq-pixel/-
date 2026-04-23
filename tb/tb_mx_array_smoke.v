`timescale 1ns/1ps
`include "mx_defs.vh"

module tb_mx_array_smoke;
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
  wire ref_valid_o;
  wire [31:0] ref_acc_o;

  localparam [7:0] E4M3_ONE = 8'h38;
  localparam [7:0] E8M0_ONE = 8'h7f;
  localparam [31:0] FP32_32 = 32'h42000000;
  localparam [31:0] FP32_64 = 32'h42800000;

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

  llmt_col ref_col (
    .clk(clk),
    .rst_n(rst_n),
    .valid_i(valid_i),
    .acc_clear_i(acc_clear_i[0]),
    .a_elems_i(a_elems_i),
    .a_scale_i(a_scale_i),
    .b_elems_i(b_elems_i[0 +: (`MX_BLOCK_K*`MX_ELEM_W)]),
    .b_scale_i(b_scale_i[7:0]),
    .valid_o(ref_valid_o),
    .acc_o(ref_acc_o)
  );

  task fill_all_ones;
    integer row_idx;
    integer col_idx;
    begin
      for (row_idx = 0; row_idx < `MX_BLOCK_K; row_idx = row_idx + 1) begin
        a_elems_i[row_idx*8 +: 8] = E4M3_ONE;
      end
      a_scale_i = E8M0_ONE;

      for (col_idx = 0; col_idx < `MX_COLS; col_idx = col_idx + 1) begin
        b_scale_i[col_idx*8 +: 8] = E8M0_ONE;
        for (row_idx = 0; row_idx < `MX_BLOCK_K; row_idx = row_idx + 1) begin
          b_elems_i[(col_idx*`MX_BLOCK_K*8) + (row_idx*8) +: 8] = E4M3_ONE;
        end
      end
    end
  endtask

  task check_all_cols;
    input [31:0] expected;
    integer col_idx;
    begin
      for (col_idx = 0; col_idx < `MX_COLS; col_idx = col_idx + 1) begin
        if (acc_o[col_idx*32 +: 32] !== expected) begin
          $display(
            "FAIL: col %0d expected %h got %h ref_col=%h",
            col_idx,
            expected,
            acc_o[col_idx*32 +: 32],
            ref_acc_o
          );
          $fatal;
        end
      end
    end
  endtask

  task wait_for_output;
    begin
      while (valid_o[0] === 1'b1) begin
        @(negedge clk);
      end
      while (valid_o[0] !== 1'b1) begin
        @(negedge clk);
      end
      #1;
    end
  endtask

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    valid_i = 1'b0;
    acc_clear_i = {`MX_COLS{1'b0}};
    a_elems_i = {(`MX_BLOCK_K*`MX_ELEM_W){1'b0}};
    a_scale_i = 8'd0;
    b_elems_i = {(`MX_COLS*`MX_BLOCK_K*`MX_ELEM_W){1'b0}};
    b_scale_i = {(`MX_COLS*8){1'b0}};

    fill_all_ones();

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    @(negedge clk);
    valid_i = 1'b1;
    acc_clear_i = {`MX_COLS{1'b1}};

    @(negedge clk);
    valid_i = 1'b0;
    acc_clear_i = {`MX_COLS{1'b0}};

    wait_for_output();
    check_all_cols(FP32_32);

    @(negedge clk);
    valid_i = 1'b1;
    acc_clear_i = {`MX_COLS{1'b0}};

    @(negedge clk);
    valid_i = 1'b0;

    wait_for_output();
    check_all_cols(FP32_64);

    $display("PASS: mx_array_32x16 smoke test completed.");
    $finish;
  end
endmodule
