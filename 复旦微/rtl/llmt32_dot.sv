`timescale 1ns/1ps

import mxfp8_pkg::*;

module llmt32_dot #(
  parameter bit ACCUMULATE = 1'b0
) (
  input  logic                 clk,
  input  logic                 rst_n,
  input  logic                 in_valid,
  input  logic                 acc_clear_i,
  input  logic [K_BLOCK*8-1:0] a_block_i,
  input  logic [7:0]           a_scale_i,
  input  logic [K_BLOCK*8-1:0] b_block_i,
  input  logic [7:0]           b_scale_i,
  input  logic [31:0]          acc_i,
  output logic                 out_valid,
  output logic [31:0]          result_o
);
  logic [31:0] prod_s1 [K_BLOCK];
  logic        valid_s1;

  logic [31:0] sum16_s2 [16];
  logic        valid_s2;

  logic [31:0] sum8_s3 [8];
  logic        valid_s3;

  logic [31:0] sum4_s4 [4];
  logic        valid_s4;

  logic [31:0] sum2_s5 [2];
  logic        valid_s5;

  logic [31:0] sum1_s6;
  logic        valid_s6;

  logic [31:0] final_s7;
  logic        valid_s7;

  genvar gi;
  generate
    for (gi = 0; gi < K_BLOCK; gi++) begin : gen_prod
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          prod_s1[gi] <= 32'b0;
        end else if (in_valid) begin
          prod_s1[gi] <= mxfp8_pkg::mxfp8_mul_fp32(a_block_i[gi*8 +: 8], b_block_i[gi*8 +: 8], a_scale_i, b_scale_i);
        end
      end
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_s1 <= 1'b0;
    end else begin
      valid_s1 <= in_valid;
    end
  end

  generate
    for (gi = 0; gi < 16; gi++) begin : gen_sum16
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          sum16_s2[gi] <= 32'b0;
        end else if (valid_s1) begin
          sum16_s2[gi] <= mxfp8_pkg::fp32_add_rne_func(prod_s1[2*gi], prod_s1[2*gi+1]);
        end
      end
    end

    for (gi = 0; gi < 8; gi++) begin : gen_sum8
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          sum8_s3[gi] <= 32'b0;
        end else if (valid_s2) begin
          sum8_s3[gi] <= mxfp8_pkg::fp32_add_rne_func(sum16_s2[2*gi], sum16_s2[2*gi+1]);
        end
      end
    end

    for (gi = 0; gi < 4; gi++) begin : gen_sum4
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          sum4_s4[gi] <= 32'b0;
        end else if (valid_s3) begin
          sum4_s4[gi] <= mxfp8_pkg::fp32_add_rne_func(sum8_s3[2*gi], sum8_s3[2*gi+1]);
        end
      end
    end

    for (gi = 0; gi < 2; gi++) begin : gen_sum2
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          sum2_s5[gi] <= 32'b0;
        end else if (valid_s4) begin
          sum2_s5[gi] <= mxfp8_pkg::fp32_add_rne_func(sum4_s4[2*gi], sum4_s4[2*gi+1]);
        end
      end
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_s2 <= 1'b0;
      valid_s3 <= 1'b0;
      valid_s4 <= 1'b0;
      valid_s5 <= 1'b0;
      valid_s6 <= 1'b0;
      valid_s7 <= 1'b0;
      sum1_s6  <= 32'b0;
      final_s7 <= 32'b0;
    end else begin
      valid_s2 <= valid_s1;
      valid_s3 <= valid_s2;
      valid_s4 <= valid_s3;
      valid_s5 <= valid_s4;
      valid_s6 <= valid_s5;
      valid_s7 <= valid_s6;

      if (valid_s5) begin
        sum1_s6 <= mxfp8_pkg::fp32_add_rne_func(sum2_s5[0], sum2_s5[1]);
      end

      if (valid_s6) begin
        if (ACCUMULATE && !acc_clear_i) begin
          final_s7 <= mxfp8_pkg::fp32_add_rne_func(acc_i, sum1_s6);
        end else begin
          final_s7 <= sum1_s6;
        end
      end
    end
  end

  assign out_valid = valid_s7;
  assign result_o  = final_s7;
endmodule
