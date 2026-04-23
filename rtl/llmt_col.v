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
  reg [31:0] acc_reg;
  wire [31:0] dot_fp32;
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
    .value_i(dot_sum_int),
    .exp_shift_i(dot_exp_shift),
    .nan_i(any_nan),
    .fp32_o(dot_fp32)
  );

  fp32_add_rne acc_add_u (
    .a_i(acc_reg),
    .b_i(dot_fp32),
    .sum_o(acc_next)
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      acc_reg <= `MX_FP32_ZERO;
      valid_o <= 1'b0;
    end else begin
      valid_o <= valid_i;
      if (acc_clear_i && !valid_i) begin
        acc_reg <= `MX_FP32_ZERO;
      end else if (valid_i) begin
        if (acc_clear_i) begin
          acc_reg <= dot_fp32;
        end else begin
          acc_reg <= acc_next;
        end
      end
    end
  end

  assign acc_o = acc_reg;
endmodule
