# 04 逐行讲解：rtl/fixed_to_fp32.v

## 文件定位

`fixed_to_fp32.v` 把 `llmt_col` 中 dot32 归约得到的有符号 fixed 数，转换成 32 bit FP32 bit pattern。它不做 32 路乘法，也不做历史 accumulator 累加；它只负责“一次 dot32 结果怎么变成 FP32”。

## 先看结论

这个文件处理五类结果：

1. `nan_i=1`：直接输出 canonical QNaN。
2. `value_i=0`：直接输出 FP32 zero。
3. 指数太大：输出 FP32 infinity。
4. 指数低于 normal 下界：输出 FP32 subnormal，必要时舍入进最小 normal。
5. 普通范围：输出 normal FP32，并用 round-to-nearest-even 舍入。

## 关键背景

`value_i` 是一个整数，但它代表的真实值不是整数本身，而是：

```text
real_value = value_i * 2^exp_shift_i
```

所以本模块要做两件事：

1. 找到 `value_i` 的最高有效 1，确定 FP32 exponent。
2. 把有效数字移到 FP32 mantissa 的位置，并用 guard/sticky 做 RNE 舍入。

## 逐行讲解

| 行号 | 源码 | 讲解 |
| --- | --- | --- |
| 1 | <code>`include "mx_defs.vh"</code> | 引入全局宏，例如 dot 宽度、指数宽度和 FP32 常量。 |
| 2 | 空行 | 分隔 include 和模块定义。 |
| 3 | <code>module fixed_to_fp32 #(</code> | 开始定义带参数的模块。`#(` 表示后面是 parameter 参数。 |
| 4 | <code>parameter IN_W = `MX_DOT_W,</code> | 输入 fixed 值默认宽度等于 dot32 归约宽度。 |
| 5 | <code>parameter EXP_W = `MX_DOT_EXP_W</code> | 指数偏移输入默认宽度等于项目定义的 dot exponent 宽度。 |
| 6 | <code>) (</code> | 参数列表结束，端口列表开始。 |
| 7 | <code>value_i,</code> | 输入 fixed 数值端口。 |
| 8 | <code>exp_shift_i,</code> | 输入指数偏移端口。 |
| 9 | <code>nan_i,</code> | 输入 NaN 标志。 |
| 10 | <code>fp32_o</code> | 输出 FP32 bit pattern。 |
| 11 | <code>);</code> | 端口列表结束。 |
| 12 | <code>input signed [IN_W-1:0] value_i;</code> | `value_i` 是有符号 fixed 数，可能为正也可能为负。 |
| 13 | <code>input signed [EXP_W-1:0] exp_shift_i;</code> | `exp_shift_i` 是有符号指数偏移，决定 fixed 小数点在哪里。 |
| 14 | <code>input nan_i;</code> | 只要上游发现 E4M3 或 E8M0 NaN，就会让这个信号为 1。 |
| 15 | <code>output [31:0] fp32_o;</code> | 输出是 32 bit FP32 编码，不是 Verilog `real`。 |
| 16 | 空行 | 分隔端口和内部变量。 |
| 17 | <code>reg [31:0] fp32_o;</code> | 因为 `fp32_o` 在 `always @*` 里赋值，所以声明为 `reg`。这里的 `reg` 不一定代表触发器。 |
| 18 | <code>integer i;</code> | 循环变量，用于扫描 bit 和计算 sticky。 |
| 19 | <code>integer msb_idx;</code> | 保存 `abs_value` 最高有效 1 的 bit 位置。 |
| 20 | <code>integer shift_amt;</code> | normal 路径中移动 significand 的位数。 |
| 21 | <code>integer sub_shift_amt;</code> | subnormal 路径中把数值对齐到 `2^-149` 单位所需的右移位数。 |
| 22 | <code>integer exp_unbiased;</code> | FP32 的无偏指数，也就是真实 exponent。 |
| 23 | <code>reg sign_bit;</code> | 保存输出符号位。 |
| 24 | <code>reg [IN_W-1:0] abs_value;</code> | 保存 `value_i` 的绝对值，后续规格化只看正数幅值。 |
| 25 | <code>reg [24:0] sig_rounded;</code> | normal 路径舍入后的 significand，多留 1 bit 检查进位。 |
| 26 | <code>reg [24:0] sig_work;</code> | normal 路径舍入前的 significand 工作变量。 |
| 27 | <code>reg [24:0] sub_sig_rounded;</code> | subnormal 路径舍入后的 mantissa 工作值。 |
| 28 | <code>reg [24:0] sub_sig_work;</code> | subnormal 路径舍入前的 mantissa 工作值。 |
| 29 | <code>reg guard_bit;</code> | normal 路径 RNE 的 guard bit。 |
| 30 | <code>reg sticky_bit;</code> | normal 路径 RNE 的 sticky bit，表示被丢弃低位里是否有 1。 |
| 31 | <code>reg round_up;</code> | normal 路径是否向上舍入。 |
| 32 | <code>reg sub_guard_bit;</code> | subnormal 路径 RNE 的 guard bit。 |
| 33 | <code>reg sub_sticky_bit;</code> | subnormal 路径 RNE 的 sticky bit。 |
| 34 | <code>reg sub_round_up;</code> | subnormal 路径是否向上舍入。 |
| 35 | <code>reg [7:0] exp_field_out;</code> | 最终写入 FP32 的 8 bit exponent 字段。 |
| 36 | 空行 | 分隔变量和组合逻辑。 |
| 37 | <code>always @* begin</code> | 开始组合逻辑。输入变化时，输出立即重新计算。 |
| 38 | <code>fp32_o = `MX_FP32_ZERO;</code> | 给默认输出，避免组合逻辑漏赋值产生 latch。 |
| 39 | <code>sign_bit = value_i[IN_W-1];</code> | 取 fixed 输入最高位作为符号。 |
| 40 | <code>if (sign_bit) begin</code> | 如果是负数，进入取绝对值路径。 |
| 41 | <code>abs_value = -value_i;</code> | 对负数取补码相反数，得到幅值。 |
| 42 | <code>end else begin</code> | 如果不是负数，进入正数路径。 |
| 43 | <code>abs_value = value_i;</code> | 正数的绝对值就是自己。 |
| 44 | <code>end</code> | 绝对值选择结束。 |
| 45 | <code>msb_idx = -1;</code> | 初始化为 -1，表示还没找到最高有效 1。 |
| 46 | <code>sig_rounded = 25'd0;</code> | 清空 normal 舍入结果。 |
| 47 | <code>sig_work = 25'd0;</code> | 清空 normal 工作值。 |
| 48 | <code>sub_sig_rounded = 25'd0;</code> | 清空 subnormal 舍入结果。 |
| 49 | <code>sub_sig_work = 25'd0;</code> | 清空 subnormal 工作值。 |
| 50 | <code>guard_bit = 1'b0;</code> | normal guard 默认 0。 |
| 51 | <code>sticky_bit = 1'b0;</code> | normal sticky 默认 0。 |
| 52 | <code>round_up = 1'b0;</code> | normal 默认不进位。 |
| 53 | <code>sub_guard_bit = 1'b0;</code> | subnormal guard 默认 0。 |
| 54 | <code>sub_sticky_bit = 1'b0;</code> | subnormal sticky 默认 0。 |
| 55 | <code>sub_round_up = 1'b0;</code> | subnormal 默认不进位。 |
| 56 | <code>exp_field_out = 8'd0;</code> | 输出 exponent 默认 0。 |
| 57 | 空行 | 分隔初始化和特殊值判断。 |
| 58 | <code>if (nan_i) begin</code> | NaN 优先级最高。 |
| 59 | <code>fp32_o = `MX_FP32_QNAN;</code> | 输出统一 canonical QNaN。 |
| 60 | <code>end else if (value_i == {IN_W{1'b0}}) begin</code> | 如果 fixed 数值为 0，进入 zero 路径。 |
| 61 | <code>fp32_o = `MX_FP32_ZERO;</code> | 输出 FP32 正零。 |
| 62 | <code>end else begin</code> | 非 NaN、非 0，进入真正转换路径。 |
| 63 | <code>for (i = IN_W - 1; i >= 0; i = i - 1) begin</code> | 从高位往低位扫描绝对值。 |
| 64 | <code>if ((msb_idx == -1) && abs_value[i]) begin</code> | 只在第一次看到 1 时记录位置。 |
| 65 | <code>msb_idx = i;</code> | 保存最高有效 1 的 bit index。 |
| 66 | <code>end</code> | 最高位判断结束。 |
| 67 | <code>end</code> | 扫描循环结束。 |
| 68 | 空行 | 分隔最高位扫描和指数计算。 |
| 69 | <code>exp_unbiased = exp_shift_i + msb_idx;</code> | 真实指数等于 fixed 小数点偏移加最高有效 1 的位置。 |
| 70 | 空行 | 分隔指数计算和范围分类。 |
| 71 | <code>if (exp_unbiased > 127) begin</code> | FP32 normal 最大无偏指数是 127，超过就 overflow。 |
| 72 | <code>fp32_o = {sign_bit, 8'hff, 23'd0};</code> | 输出带符号 infinity。 |
| 73 | <code>end else if (exp_unbiased < -126) begin</code> | 低于 normal 最小指数，进入 FP32 subnormal 路径。 |
| 74 | <code>sub_shift_amt = -149 - exp_shift_i;</code> | FP32 最小 subnormal 单位是 `2^-149`，这里计算要把 `abs_value` 右移多少位才能变成 subnormal mantissa。 |
| 75 | <code>if (sub_shift_amt <= 0) begin</code> | 如果不需要右移，说明可以左移精确对齐。 |
| 76 | <code>sub_sig_rounded = abs_value << (-sub_shift_amt);</code> | 左移得到 subnormal mantissa，没有丢弃位，所以不用舍入。 |
| 77 | <code>end else if (sub_shift_amt > IN_W) begin</code> | 如果右移超过输入宽度，结果小到主 mantissa 和 guard 都为 0。 |
| 78 | <code>sub_sig_work = 25'd0;</code> | 主结果为 0。 |
| 79 | <code>sub_guard_bit = 1'b0;</code> | guard 也为 0，因此不会向上舍入。 |
| 80 | <code>sub_sticky_bit = 1'b0;</code> | 先清 sticky。 |
| 81 | <code>for (i = 0; i < IN_W; i = i + 1) begin</code> | 扫描所有被丢弃的输入位。 |
| 82 | <code>sub_sticky_bit = sub_sticky_bit | abs_value[i];</code> | 只要有任何 1，sticky 就为 1。 |
| 83 | <code>end</code> | sticky 扫描结束。 |
| 84 | <code>sub_round_up = sub_guard_bit & (sub_sticky_bit | sub_sig_work[0]);</code> | RNE 规则：guard 为 1 且 sticky 或最低保留位为 1 才进位。这里 guard 为 0，所以不会进位。 |
| 85 | <code>sub_sig_rounded = sub_sig_work + sub_round_up;</code> | 得到最终 subnormal mantissa，通常为 0。 |
| 86 | <code>end else if (sub_shift_amt == IN_W) begin</code> | 右移位数刚好等于输入宽度，最高输入位成为 guard。 |
| 87 | <code>sub_sig_work = 25'd0;</code> | 主结果仍然为 0。 |
| 88 | <code>sub_guard_bit = abs_value[IN_W-1];</code> | 原最高位成为 guard bit。 |
| 89 | <code>sub_sticky_bit = 1'b0;</code> | 清 sticky。 |
| 90 | <code>for (i = 0; i < IN_W - 1; i = i + 1) begin</code> | 扫描 guard 以下所有低位。 |
| 91 | <code>sub_sticky_bit = sub_sticky_bit | abs_value[i];</code> | 有任何低位 1，sticky 就为 1。 |
| 92 | <code>end</code> | sticky 扫描结束。 |
| 93 | <code>sub_round_up = sub_guard_bit & (sub_sticky_bit | sub_sig_work[0]);</code> | 执行 subnormal RNE。 |
| 94 | <code>sub_sig_rounded = sub_sig_work + sub_round_up;</code> | 得到舍入后的 subnormal mantissa。 |
| 95 | <code>end else begin</code> | 常规 subnormal 右移路径。 |
| 96 | <code>sub_sig_work = abs_value >> sub_shift_amt;</code> | 先保留右移后的主 mantissa。 |
| 97 | <code>sub_guard_bit = abs_value[sub_shift_amt - 1];</code> | 被丢弃的最高位作为 guard。 |
| 98 | <code>sub_sticky_bit = 1'b0;</code> | 清 sticky。 |
| 99 | <code>for (i = 0; i < sub_shift_amt - 1; i = i + 1) begin</code> | 扫描 guard 以下的所有被丢弃位。 |
| 100 | <code>sub_sticky_bit = sub_sticky_bit | abs_value[i];</code> | 汇总 sticky。 |
| 101 | <code>end</code> | sticky 扫描结束。 |
| 102 | <code>sub_round_up = sub_guard_bit & (sub_sticky_bit | sub_sig_work[0]);</code> | subnormal 路径 RNE 判断。 |
| 103 | <code>sub_sig_rounded = sub_sig_work + sub_round_up;</code> | 得到舍入后的 mantissa。 |
| 104 | <code>end</code> | subnormal 对齐和舍入分支结束。 |
| 105 | 空行 | 分隔 subnormal 舍入和 FP32 字段打包。 |
| 106 | <code>if (sub_sig_rounded[24]) begin</code> | 舍入后如果超过 `2^-125` 边界，进入 exponent=2 的 normal。 |
| 107 | <code>fp32_o = {sign_bit, 8'd2, 23'd0};</code> | 输出 `2^-125` 对应的 normal FP32。 |
| 108 | <code>end else if (sub_sig_rounded[23]) begin</code> | 如果达到或超过 `2^-126`，进入 exponent=1 的 normal。 |
| 109 | <code>fp32_o = {sign_bit, 8'd1, sub_sig_rounded[22:0]};</code> | 输出最小 normal 区间，低 23 位作为 mantissa。 |
| 110 | <code>end else begin</code> | 仍然在 subnormal 或 zero 范围。 |
| 111 | <code>fp32_o = {sign_bit, 8'd0, sub_sig_rounded[22:0]};</code> | 输出 FP32 subnormal；如果 mantissa 为 0，就是带符号 zero。 |
| 112 | <code>end</code> | subnormal 打包结束。 |
| 113 | <code>end else begin</code> | 指数在 normal 范围，进入 normal FP32 路径。 |
| 114 | <code>if (msb_idx > 23) begin</code> | 如果 fixed 幅值太宽，需要右移到 24 位 significand 附近。 |
| 115 | <code>shift_amt = msb_idx - 23;</code> | 计算右移位数。 |
| 116 | <code>sig_work = abs_value >> shift_amt;</code> | 右移后保留 24 位左右的有效数字。 |
| 117 | <code>guard_bit = abs_value[shift_amt - 1];</code> | 被丢弃最高位作为 guard。 |
| 118 | <code>sticky_bit = 1'b0;</code> | 清 sticky。 |
| 119 | <code>for (i = 0; i < shift_amt - 1; i = i + 1) begin</code> | 扫描 guard 以下所有被丢弃位。 |
| 120 | <code>sticky_bit = sticky_bit | abs_value[i];</code> | 汇总 sticky。 |
| 121 | <code>end</code> | sticky 扫描结束。 |
| 122 | <code>round_up = guard_bit & (sticky_bit | sig_work[0]);</code> | normal 路径 RNE 判断。 |
| 123 | <code>sig_rounded = sig_work + round_up;</code> | 得到舍入后的 significand。 |
| 124 | <code>end else begin</code> | 如果 fixed 幅值不宽，不需要右移。 |
| 125 | <code>shift_amt = 23 - msb_idx;</code> | 计算左移位数，把最高有效 1 放到 hidden-bit 位置。 |
| 126 | <code>sig_rounded = abs_value << shift_amt;</code> | 左移精确对齐，没有丢弃位，所以不需要舍入。 |
| 127 | <code>end</code> | normal significand 对齐结束。 |
| 128 | 空行 | 分隔 significand 舍入和进位检查。 |
| 129 | <code>if (sig_rounded[24]) begin</code> | 如果舍入后多出一位，说明 significand 进位。 |
| 130 | <code>sig_rounded = sig_rounded >> 1;</code> | 把 significand 右移回合法范围。 |
| 131 | <code>exp_unbiased = exp_unbiased + 1;</code> | significand 右移相当于 exponent 加 1。 |
| 132 | <code>end</code> | 进位修正结束。 |
| 133 | 空行 | 分隔进位修正和 overflow 检查。 |
| 134 | <code>if (exp_unbiased > 127) begin</code> | 舍入后 exponent 可能从最大 normal 进位到 overflow。 |
| 135 | <code>fp32_o = {sign_bit, 8'hff, 23'd0};</code> | 输出带符号 infinity。 |
| 136 | <code>end else begin</code> | 没有 overflow，正常打包。 |
| 137 | <code>exp_field_out = exp_unbiased + 127;</code> | 把无偏指数加 bias=127，得到 FP32 exponent 字段。 |
| 138 | <code>fp32_o = {sign_bit, exp_field_out, sig_rounded[22:0]};</code> | 拼出 FP32：sign、exponent、mantissa。 |
| 139 | <code>end</code> | normal 打包结束。 |
| 140 | <code>end</code> | normal/subnormal/overflow 大分支结束。 |
| 141 | <code>end</code> | 非 NaN、非 zero 转换路径结束。 |
| 142 | <code>end</code> | `always @*` 结束。 |
| 143 | <code>endmodule</code> | 模块结束。 |

## 关键复述

`fixed_to_fp32` 的主线是：先把 signed fixed 变成绝对值和符号，再找最高有效 1 算 exponent。如果指数太大输出 infinity；如果低于 normal 范围，就按 `2^-149` 单位生成 FP32 subnormal；否则按 normal FP32 规格化并用 RNE 舍入。

## 自测题

1. 为什么 `exp_unbiased = exp_shift_i + msb_idx`？
2. `guard_bit` 和 `sticky_bit` 分别代表什么？
3. 为什么 subnormal 路径要用 `-149`，而 normal 路径用 `-126`？
4. `sub_sig_rounded[23]` 为 1 时为什么会打包成 exponent=1？
