`timescale 1ns/1ps

import mxfp8_pkg::*;

module tb_mxfp8_array_top;
  localparam int MAX_CASES = 1024;

  logic clk;
  logic rst_n;
  logic in_valid;
  logic acc_clear;
  logic [K_BLOCK*8-1:0] a_block;
  logic [7:0] a_scale;
  logic [NUM_LLMT*K_BLOCK*8-1:0] b_blocks;
  logic [NUM_LLMT*8-1:0] b_scales;
  logic [NUM_LLMT*32-1:0] acc;
  logic out_valid;
  logic [NUM_LLMT*32-1:0] results;

  logic [K_BLOCK*8-1:0] vec_a [MAX_CASES];
  logic [7:0] vec_as [MAX_CASES];
  logic [NUM_LLMT*K_BLOCK*8-1:0] vec_b [MAX_CASES];
  logic [NUM_LLMT*8-1:0] vec_bs [MAX_CASES];
  logic [31:0] vec_exp [MAX_CASES][NUM_LLMT];

  int fd;
  int num_cases;
  int idx;
  int lane;
  int code;
  int out_idx;
  logic [31:0] tmp_exp;

  mxfp8_array_top u_dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .acc_clear_i(acc_clear),
    .a_block_i(a_block),
    .a_scale_i(a_scale),
    .b_blocks_i(b_blocks),
    .b_scales_i(b_scales),
    .acc_i(acc),
    .out_valid(out_valid),
    .results_o(results)
  );

  always #0.5 clk = ~clk;

  initial begin
    fd = $fopen("sim/array_vectors.hex", "r");
    if (fd == 0) $fatal(1, "failed to open sim/array_vectors.hex");
    code = $fscanf(fd, "%d\n", num_cases);
    if (num_cases > MAX_CASES) $fatal(1, "too many num_cases");
    for (idx = 0; idx < num_cases; idx++) begin
      code = $fscanf(fd, "%h %h %h %h", vec_a[idx], vec_as[idx], vec_b[idx], vec_bs[idx]);
      if (code != 4) $fatal(1, "failed to read case header %0d code=%0d", idx, code);
      for (lane = 0; lane < NUM_LLMT; lane++) begin
        code = $fscanf(fd, "%h", tmp_exp);
        vec_exp[idx][lane] = tmp_exp;
        if (code != 1) $fatal(1, "failed to read expected case=%0d lane=%0d", idx, lane);
      end
    end
    $fclose(fd);
  end

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    in_valid = 1'b0;
    acc_clear = 1'b1;
    a_block = '0;
    a_scale = '0;
    b_blocks = '0;
    b_scales = '0;
    acc = '0;
    out_idx = 0;

    repeat (4) @(posedge clk);
    rst_n = 1'b1;

    for (idx = 0; idx < num_cases; idx++) begin
      @(posedge clk);
      a_block <= vec_a[idx];
      a_scale <= vec_as[idx];
      b_blocks <= vec_b[idx];
      b_scales <= vec_bs[idx];
      in_valid <= 1'b1;
    end
    @(posedge clk);
    in_valid <= 1'b0;

    wait (out_idx == num_cases);
    $display("tb_mxfp8_array_top PASS num_cases=%0d", num_cases);
    $finish;
  end

  always @(posedge clk) begin
    if (rst_n && out_valid) begin
      for (lane = 0; lane < NUM_LLMT; lane++) begin
        if (results[lane*32 +: 32] !== vec_exp[out_idx][lane]) begin
          $fatal(1, "case=%0d lane=%0d got=%08x expected=%08x", out_idx, lane,
                 results[lane*32 +: 32], vec_exp[out_idx][lane]);
        end
      end
      out_idx <= out_idx + 1;
    end
  end
endmodule
