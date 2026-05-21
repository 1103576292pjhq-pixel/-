`timescale 1ns/1ps
`include "mx_defs.vh"

module tb_mx_array_dataset;
  localparam M = `DATASET_M;
  localparam N = `DATASET_N;
  localparam K_BLOCKS = `DATASET_K_BLOCKS;
  localparam A_COUNT = M * K_BLOCKS;
  localparam B_COUNT = N * K_BLOCKS;
  localparam Y_COUNT = M * N;

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

  reg [`MX_BLOCK_K*`MX_ELEM_W-1:0] a_blocks [0:A_COUNT-1];
  reg [`MX_BLOCK_K*`MX_ELEM_W-1:0] b_blocks [0:B_COUNT-1];
  reg [7:0] a_scales [0:A_COUNT-1];
  reg [7:0] b_scales [0:B_COUNT-1];
  reg [31:0] expected_y [0:Y_COUNT-1];
  integer row;
  integer tile_col;
  integer lane_col;
  integer kb;
  integer out_count;
  integer global_col;
  integer errors;
  integer active_cols;
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

  task load_vectors;
    begin
      $readmemh({`DATASET_DIR, "/a_blocks.hex"}, a_blocks);
      $readmemh({`DATASET_DIR, "/b_blocks.hex"}, b_blocks);
      $readmemh({`DATASET_DIR, "/a_scales.hex"}, a_scales);
      $readmemh({`DATASET_DIR, "/b_scales.hex"}, b_scales);
      $readmemh({`DATASET_DIR, "/expected_y.hex"}, expected_y);
    end
  endtask

  task drive_one_block;
    input integer row_i;
    input integer tile_col_i;
    input integer kb_i;
    begin
      a_elems_i = a_blocks[row_i*K_BLOCKS + kb_i];
      a_scale_i = a_scales[row_i*K_BLOCKS + kb_i];
      b_elems_i = {(`MX_COLS*`MX_BLOCK_K*`MX_ELEM_W){1'b0}};
      b_scale_i = {(`MX_COLS*8){1'b0}};

      for (lane_col = 0; lane_col < `MX_COLS; lane_col = lane_col + 1) begin
        global_col = tile_col_i + lane_col;
        if (global_col < N) begin
          b_elems_i[lane_col*`MX_BLOCK_K*`MX_ELEM_W +: `MX_BLOCK_K*`MX_ELEM_W] =
            b_blocks[global_col*K_BLOCKS + kb_i];
          b_scale_i[lane_col*8 +: 8] = b_scales[global_col*K_BLOCKS + kb_i];
        end else begin
          b_elems_i[lane_col*`MX_BLOCK_K*`MX_ELEM_W +: `MX_BLOCK_K*`MX_ELEM_W] =
            {(`MX_BLOCK_K*`MX_ELEM_W){1'b0}};
          b_scale_i[lane_col*8 +: 8] = 8'h7f;
        end
      end
    end
  endtask

  initial begin
    errors = 0;
    rst_n = 1'b0;
    valid_i = 1'b0;
    acc_clear_i = {`MX_COLS{1'b0}};
    a_elems_i = 0;
    a_scale_i = 8'h7f;
    b_elems_i = 0;
    b_scale_i = 0;
    load_vectors();

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    for (row = 0; row < M; row = row + 1) begin
      for (tile_col = 0; tile_col < N; tile_col = tile_col + `MX_COLS) begin
        active_cols = (N - tile_col) < `MX_COLS ? (N - tile_col) : `MX_COLS;
        out_count = 0;

        for (kb = 0; kb < K_BLOCKS; kb = kb + 1) begin
          @(negedge clk);
          drive_one_block(row, tile_col, kb);
          valid_i = 1'b1;
          acc_clear_i = (kb == 0) ? {`MX_COLS{1'b1}} : {`MX_COLS{1'b0}};
        end

        @(negedge clk);
        valid_i = 1'b0;
        acc_clear_i = {`MX_COLS{1'b0}};

        while (out_count < K_BLOCKS) begin
          @(posedge clk);
          if (valid_o === {`MX_COLS{1'b1}}) begin
            out_count = out_count + 1;
          end
        end
        #1;

        for (lane_col = 0; lane_col < active_cols; lane_col = lane_col + 1) begin
          expected = expected_y[row*N + tile_col + lane_col];
          if (acc_o[lane_col*32 +: 32] !== expected) begin
            $display("FAIL row=%0d col=%0d expected=%08x got=%08x",
                     row, tile_col + lane_col, expected, acc_o[lane_col*32 +: 32]);
            errors = errors + 1;
          end
        end
      end
    end

    if (errors == 0) begin
      $display("PASS tb_mx_array_dataset rows=%0d cols=%0d k_blocks=%0d", M, N, K_BLOCKS);
    end else begin
      $display("FAIL tb_mx_array_dataset errors=%0d", errors);
      $finish(1);
    end
    $finish;
  end
endmodule
