`timescale 1ns/1ps
`include "mx_defs.vh"

`ifndef TB_M
`define TB_M 4
`endif

`ifndef TB_N
`define TB_N 16
`endif

`ifndef TB_K_BLOCKS
`define TB_K_BLOCKS 2
`endif

`ifndef TB_A_BLOCKS_HEX
`define TB_A_BLOCKS_HEX "vectors/matmul_4x16x64_smoke/a_blocks.hex"
`endif

`ifndef TB_A_SCALES_HEX
`define TB_A_SCALES_HEX "vectors/matmul_4x16x64_smoke/a_scales.hex"
`endif

`ifndef TB_B_BLOCKS_HEX
`define TB_B_BLOCKS_HEX "vectors/matmul_4x16x64_smoke/b_blocks.hex"
`endif

`ifndef TB_B_SCALES_HEX
`define TB_B_SCALES_HEX "vectors/matmul_4x16x64_smoke/b_scales.hex"
`endif

`ifndef TB_EXPECTED_Y_HEX
`define TB_EXPECTED_Y_HEX "vectors/matmul_4x16x64_smoke/expected_y.hex"
`endif

module tb_mx_array_dataset;
  localparam integer BLOCK_W = `MX_BLOCK_K * `MX_ELEM_W;
  localparam integer M = `TB_M;
  localparam integer N = `TB_N;
  localparam integer K_BLOCKS = `TB_K_BLOCKS;
  localparam integer COL_TILES = N / `MX_COLS;
  localparam integer A_BLOCK_COUNT = M * K_BLOCKS;
  localparam integer B_BLOCK_COUNT = N * K_BLOCKS;
  localparam integer Y_COUNT = M * N;

  reg clk;
  reg rst_n;
  reg valid_i;
  reg [`MX_COLS-1:0] acc_clear_i;
  reg [BLOCK_W-1:0] a_elems_i;
  reg [7:0] a_scale_i;
  reg [`MX_COLS*BLOCK_W-1:0] b_elems_i;
  reg [`MX_COLS*8-1:0] b_scale_i;
  wire [`MX_COLS-1:0] valid_o;
  wire [`MX_COLS*32-1:0] acc_o;

  reg [BLOCK_W-1:0] a_blocks_mem [0:A_BLOCK_COUNT-1];
  reg [7:0] a_scales_mem [0:A_BLOCK_COUNT-1];
  reg [BLOCK_W-1:0] b_blocks_mem [0:B_BLOCK_COUNT-1];
  reg [7:0] b_scales_mem [0:B_BLOCK_COUNT-1];
  reg [31:0] y_expected_mem [0:Y_COUNT-1];

  integer row_idx;
  integer tile_idx;
  integer kb_idx;
  integer lane_idx;
  integer mismatch_count;

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

  task load_step_inputs;
    input integer row_idx_t;
    input integer tile_idx_t;
    input integer kb_idx_t;
    integer lane_idx_t;
    integer a_mem_idx;
    integer b_mem_idx;
    integer global_col_t;
    begin
      a_mem_idx = (row_idx_t * K_BLOCKS) + kb_idx_t;
      a_elems_i = a_blocks_mem[a_mem_idx];
      a_scale_i = a_scales_mem[a_mem_idx];
      acc_clear_i = (kb_idx_t == 0) ? {`MX_COLS{1'b1}} : {`MX_COLS{1'b0}};

      for (lane_idx_t = 0; lane_idx_t < `MX_COLS; lane_idx_t = lane_idx_t + 1) begin
        global_col_t = (tile_idx_t * `MX_COLS) + lane_idx_t;
        b_mem_idx = (global_col_t * K_BLOCKS) + kb_idx_t;
        b_elems_i[(lane_idx_t * BLOCK_W) +: BLOCK_W] = b_blocks_mem[b_mem_idx];
        b_scale_i[(lane_idx_t * 8) +: 8] = b_scales_mem[b_mem_idx];
      end
    end
  endtask

  task drive_block;
    input integer row_idx_t;
    input integer tile_idx_t;
    input integer kb_idx_t;
    begin
      @(negedge clk);
      load_step_inputs(row_idx_t, tile_idx_t, kb_idx_t);
      valid_i = 1'b1;

      @(negedge clk);
      valid_i = 1'b0;
      acc_clear_i = {`MX_COLS{1'b0}};
    end
  endtask

  task check_tile_results;
    input integer row_idx_t;
    input integer tile_idx_t;
    integer lane_idx_t;
    integer y_mem_idx;
    reg [31:0] expected_bits;
    reg [31:0] got_bits;
    begin
      @(posedge clk);
      #1;
      for (lane_idx_t = 0; lane_idx_t < `MX_COLS; lane_idx_t = lane_idx_t + 1) begin
        y_mem_idx = (row_idx_t * N) + (tile_idx_t * `MX_COLS) + lane_idx_t;
        expected_bits = y_expected_mem[y_mem_idx];
        got_bits = acc_o[(lane_idx_t * 32) +: 32];
        if (got_bits !== expected_bits) begin
          mismatch_count = mismatch_count + 1;
          if (mismatch_count <= 8) begin
            $display(
              "MISMATCH row=%0d col=%0d expected=%h got=%h valid=%b",
              row_idx_t,
              (tile_idx_t * `MX_COLS) + lane_idx_t,
              expected_bits,
              got_bits,
              valid_o[lane_idx_t]
            );
          end
        end
      end
    end
  endtask

  always #5 clk = ~clk;

  initial begin
    if ((N % `MX_COLS) != 0) begin
      $display("FAIL: TB_N=%0d must be a multiple of %0d", N, `MX_COLS);
      $fatal;
    end

    $readmemh(`TB_A_BLOCKS_HEX, a_blocks_mem);
    $readmemh(`TB_A_SCALES_HEX, a_scales_mem);
    $readmemh(`TB_B_BLOCKS_HEX, b_blocks_mem);
    $readmemh(`TB_B_SCALES_HEX, b_scales_mem);
    $readmemh(`TB_EXPECTED_Y_HEX, y_expected_mem);

    clk = 1'b0;
    rst_n = 1'b0;
    valid_i = 1'b0;
    acc_clear_i = {`MX_COLS{1'b0}};
    a_elems_i = {BLOCK_W{1'b0}};
    a_scale_i = 8'd0;
    b_elems_i = {(`MX_COLS*BLOCK_W){1'b0}};
    b_scale_i = {(`MX_COLS*8){1'b0}};
    mismatch_count = 0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    for (row_idx = 0; row_idx < M; row_idx = row_idx + 1) begin
      for (tile_idx = 0; tile_idx < COL_TILES; tile_idx = tile_idx + 1) begin
        for (kb_idx = 0; kb_idx < K_BLOCKS; kb_idx = kb_idx + 1) begin
          drive_block(row_idx, tile_idx, kb_idx);
        end
        check_tile_results(row_idx, tile_idx);
      end
    end

    if (mismatch_count != 0) begin
      $display("FAIL: mx_array dataset test saw %0d mismatches.", mismatch_count);
      $fatal;
    end

    $display(
      "PASS: mx_array dataset test completed. rows=%0d cols=%0d k_blocks=%0d",
      M,
      N,
      K_BLOCKS
    );
    $finish;
  end
endmodule
