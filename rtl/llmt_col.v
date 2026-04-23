`include "mx_defs.vh"

module llmt_col (
  clk,
  rst_n,
  valid_i,
  acc_clear_i,
  a_elems_i,
  a_scale_i,
  b_elems_i,
  b_scale_i,
  valid_o,
  acc_o
);
  input clk;
  input rst_n;
  input valid_i;
  input acc_clear_i;
  input [`MX_BLOCK_K*`MX_ELEM_W-1:0] a_elems_i;
  input [7:0] a_scale_i;
  input [`MX_BLOCK_K*`MX_ELEM_W-1:0] b_elems_i;
  input [7:0] b_scale_i;
  output valid_o;
  output [31:0] acc_o;

  reg valid_o;
  reg signed [`MX_DOT_W-1:0] dot_sum_int;
  reg any_nan;
  reg signed [`MX_ELEM_FIXED_W-1:0] a_fixed;
  reg signed [`MX_ELEM_FIXED_W-1:0] b_fixed;
  reg signed [`MX_PROD_W-1:0] lane_prod;
  reg signed [`MX_DOT_W-1:0] lane_prod_ext;
  reg signed [9:0] a_scale_exp;
  reg signed [9:0] b_scale_exp;
  reg signed [`MX_DOT_EXP_W-1:0] dot_exp_shift;
  reg valid_s1;
  reg acc_clear_s1;
  reg signed [`MX_DOT_W-1:0] dot_sum_s1;
  reg signed [`MX_DOT_EXP_W-1:0] dot_exp_shift_s1;
  reg any_nan_s1;
  reg valid_s2;
  reg acc_clear_s2;
  reg [31:0] dot_fp32_s2;
  reg [31:0] acc_reg;
  wire [31:0] dot_fp32_s1;
  wire [31:0] acc_next;
  integer idx;

  `include "mx_funcs.vh"

  always @* begin
    dot_sum_int = {`MX_DOT_W{1'b0}};
    any_nan = e8m0_is_nan(a_scale_i) || e8m0_is_nan(b_scale_i);

    for (idx = 0; idx < `MX_BLOCK_K; idx = idx + 1) begin
      if (e4m3_is_nan(a_elems_i[idx*`MX_ELEM_W +: `MX_ELEM_W]) ||
          e4m3_is_nan(b_elems_i[idx*`MX_ELEM_W +: `MX_ELEM_W])) begin
        any_nan = 1'b1;
      end

      a_fixed = e4m3_to_fixed(a_elems_i[idx*`MX_ELEM_W +: `MX_ELEM_W]);
      b_fixed = e4m3_to_fixed(b_elems_i[idx*`MX_ELEM_W +: `MX_ELEM_W]);
      lane_prod = a_fixed * b_fixed;
      lane_prod_ext = {{(`MX_DOT_W-`MX_PROD_W){lane_prod[`MX_PROD_W-1]}}, lane_prod};
      dot_sum_int = dot_sum_int + lane_prod_ext;
    end
  end

  always @* begin
    a_scale_exp = e8m0_unbiased_exp(a_scale_i);
    b_scale_exp = e8m0_unbiased_exp(b_scale_i);
    dot_exp_shift = a_scale_exp + b_scale_exp - `MX_PROD_FIXED_FRAC;
  end

  fixed_to_fp32 dot_cast_u (
    .value_i(dot_sum_s1),
    .exp_shift_i(dot_exp_shift_s1),
    .nan_i(any_nan_s1),
    .fp32_o(dot_fp32_s1)
  );

  fp32_add_rne acc_add_u (
    .a_i(acc_reg),
    .b_i(dot_fp32_s2),
    .sum_o(acc_next)
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_s1 <= 1'b0;
      acc_clear_s1 <= 1'b0;
      dot_sum_s1 <= {`MX_DOT_W{1'b0}};
      dot_exp_shift_s1 <= {`MX_DOT_EXP_W{1'b0}};
      any_nan_s1 <= 1'b0;
      valid_s2 <= 1'b0;
      acc_clear_s2 <= 1'b0;
      dot_fp32_s2 <= `MX_FP32_ZERO;
      acc_reg <= `MX_FP32_ZERO;
      valid_o <= 1'b0;
    end else if (acc_clear_i && !valid_i) begin
      valid_s1 <= 1'b0;
      acc_clear_s1 <= 1'b0;
      dot_sum_s1 <= {`MX_DOT_W{1'b0}};
      dot_exp_shift_s1 <= {`MX_DOT_EXP_W{1'b0}};
      any_nan_s1 <= 1'b0;
      valid_s2 <= 1'b0;
      acc_clear_s2 <= 1'b0;
      dot_fp32_s2 <= `MX_FP32_ZERO;
      acc_reg <= `MX_FP32_ZERO;
      valid_o <= 1'b0;
    end else begin
      valid_s1 <= valid_i;
      acc_clear_s1 <= acc_clear_i;
      dot_sum_s1 <= dot_sum_int;
      dot_exp_shift_s1 <= dot_exp_shift;
      any_nan_s1 <= any_nan;

      valid_s2 <= valid_s1;
      acc_clear_s2 <= acc_clear_s1;
      dot_fp32_s2 <= dot_fp32_s1;

      valid_o <= valid_s2;
      if (valid_s2) begin
        if (acc_clear_s2) begin
          acc_reg <= dot_fp32_s2;
        end else begin
          acc_reg <= acc_next;
        end
      end
    end
  end

  assign acc_o = acc_reg;
endmodule
