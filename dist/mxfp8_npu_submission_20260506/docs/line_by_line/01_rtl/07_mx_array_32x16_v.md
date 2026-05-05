# 07 逐行讲解：rtl/mx_array_32x16.v

## 文件定位

`mx_array_32x16.v` 是当前 RTL 的顶层阵列模块。它不重新实现乘法和累加，而是复制 16 个 `llmt_col`，让同一个 A block 广播到所有列，每一列使用自己的 B block 和 accumulator。

## 先看结论

这个文件做四件事：

1. 定义顶层端口。
2. 建立 16 列内部连线。
3. 用 `generate for` 实例化 16 个 `llmt_col`。
4. 把 16 列的 `valid_o` 和 `acc_o` 打包成顶层输出。

## 逐行讲解

| 行号 | 源码 | 讲解 |
| --- | --- | --- |
| 1 | <code>`include "mx_defs.vh"</code> | 引入全局宏，例如 `MX_COLS`、`MX_BLOCK_K`、`MX_ELEM_W`。没有这一行，后面的位宽表达式无法展开。 |
| 2 | 空行 | 分隔 include 和模块定义。 |
| 3 | <code>module mx_array_32x16 (</code> | 开始定义顶层模块，模块名必须和赛题/脚本中使用的顶层名一致。 |
| 4 | <code>  clk,</code> | 端口列表中的时钟信号。 |
| 5 | <code>  rst_n,</code> | 端口列表中的低有效复位信号。 |
| 6 | <code>  valid_i,</code> | 输入有效信号，表示本拍 A/B block 有效。 |
| 7 | <code>  acc_clear_i,</code> | 16 列 accumulator 的清零控制。 |
| 8 | <code>  a_elems_i,</code> | A block 的 32 个 E4M3 元素。 |
| 9 | <code>  a_scale_i,</code> | A block 共享的 E8M0 scale。 |
| 10 | <code>  b_elems_i,</code> | 16 个 B block 的元素打包总线。 |
| 11 | <code>  b_scale_i,</code> | 16 个 B block 的 scale 打包总线。 |
| 12 | <code>  valid_o,</code> | 16 列输出有效信号。 |
| 13 | <code>  acc_o</code> | 16 列 FP32 accumulator 输出打包总线。 |
| 14 | <code>);</code> | 端口列表结束。 |
| 15 | <code>  input clk;</code> | 声明 `clk` 是输入时钟。所有列单元共用同一个时钟。 |
| 16 | <code>  input rst_n;</code> | 声明 `rst_n` 是输入复位，低电平有效。 |
| 17 | <code>  input valid_i;</code> | 声明输入 valid。这个信号会同时送到 16 个列单元。 |
| 18 | <code>  input [`MX_COLS-1:0] acc_clear_i;</code> | 每列一个清零位。`MX_COLS=16` 时，这是一条 16 bit 总线。 |
| 19 | <code>  input [`MX_BLOCK_K*`MX_ELEM_W-1:0] a_elems_i;</code> | A block 元素总线宽度是 32 x 8 = 256 bit。 |
| 20 | <code>  input [7:0] a_scale_i;</code> | A block 的 scale 是 8 bit。 |
| 21 | <code>  input [`MX_COLS*`MX_BLOCK_K*`MX_ELEM_W-1:0] b_elems_i;</code> | B 元素总线宽度是 16 x 32 x 8 = 4096 bit，每列 256 bit。 |
| 22 | <code>  input [`MX_COLS*8-1:0] b_scale_i;</code> | B scale 总线宽度是 16 x 8 = 128 bit。 |
| 23 | <code>  output [`MX_COLS-1:0] valid_o;</code> | 输出 16 bit valid，每一位对应一列。 |
| 24 | <code>  output [`MX_COLS*32-1:0] acc_o;</code> | 输出 16 个 FP32 结果，总宽度是 16 x 32 = 512 bit。 |
| 25 | 空行 | 分隔端口声明和内部连线。 |
| 26 | <code>  wire [`MX_COLS-1:0] valid_int;</code> | 内部 valid 连线，收集 16 个 `llmt_col` 的 valid 输出。 |
| 27 | <code>  wire [`MX_COLS*32-1:0] acc_int;</code> | 内部 accumulator 输出打包线，收集 16 个列结果。 |
| 28 | 空行 | 分隔内部连线和 generate 变量。 |
| 29 | <code>  genvar col;</code> | 声明 generate 循环变量。它不是运行时变量，而是综合展开时用来复制硬件实例。 |
| 30 | <code>  generate</code> | 开始 generate 结构。综合器会根据循环展开多个硬件块。 |
| 31 | <code>    for (col = 0; col < `MX_COLS; col = col + 1) begin : gen_cols</code> | 复制 `MX_COLS` 次列单元。当前是 16 次，命名块叫 `gen_cols`。 |
| 32 | <code>      wire [`MX_BLOCK_K*`MX_ELEM_W-1:0] b_elems_col;</code> | 为当前列取出一条 256 bit B 元素局部线。 |
| 33 | <code>      wire [7:0] b_scale_col;</code> | 为当前列取出一个 8 bit B scale 局部线。 |
| 34 | 空行 | 分隔局部线声明和切片连接。 |
| 35 | <code>      assign b_elems_col = b_elems_i[(col*`MX_BLOCK_K*`MX_ELEM_W) +: (`MX_BLOCK_K*`MX_ELEM_W)];</code> | 从大 B 总线中切出第 `col` 列的 256 bit 元素。`+:` 表示从起点开始向高位取固定宽度。 |
| 36 | <code>      assign b_scale_col = b_scale_i[(col*8) +: 8];</code> | 从 B scale 总线中切出第 `col` 列的 8 bit scale。 |
| 37 | 空行 | 分隔切片和实例化。 |
| 38 | <code>      llmt_col col_u (</code> | 实例化一个列单元。generate 循环展开后会得到 16 个这样的实例。 |
| 39 | <code>        .clk(clk),</code> | 把顶层时钟接给这一列。 |
| 40 | <code>        .rst_n(rst_n),</code> | 把顶层复位接给这一列。 |
| 41 | <code>        .valid_i(valid_i),</code> | 16 列共享同一个输入有效信号。 |
| 42 | <code>        .acc_clear_i(acc_clear_i[col]),</code> | 当前列只接收自己的清零控制位。 |
| 43 | <code>        .a_elems_i(a_elems_i),</code> | A block 广播给所有列，这是阵列数据流的核心。 |
| 44 | <code>        .a_scale_i(a_scale_i),</code> | A scale 同样广播给所有列。 |
| 45 | <code>        .b_elems_i(b_elems_col),</code> | 当前列接收自己切出来的 B block 元素。 |
| 46 | <code>        .b_scale_i(b_scale_col),</code> | 当前列接收自己切出来的 B scale。 |
| 47 | <code>        .valid_o(valid_int[col]),</code> | 当前列的输出 valid 写入 `valid_int` 的对应 bit。 |
| 48 | <code>        .acc_o(acc_int[(col*32) +: 32])</code> | 当前列的 FP32 输出写入 `acc_int` 中对应的 32 bit 槽位。 |
| 49 | <code>      );</code> | 当前列实例化结束。 |
| 50 | <code>    end</code> | 当前 generate 循环体结束。 |
| 51 | <code>  endgenerate</code> | generate 结构结束。到这里，16 个列单元已经被展开。 |
| 52 | 空行 | 分隔实例化和顶层输出连接。 |
| 53 | <code>  assign valid_o = valid_int;</code> | 把内部 valid 总线直接接到顶层输出。 |
| 54 | <code>  assign acc_o = acc_int;</code> | 把内部 accumulator 打包总线直接接到顶层输出。 |
| 55 | <code>endmodule</code> | 顶层模块结束。 |

## 关键复述

`mx_array_32x16` 本身不做乘法。它的工作是把 16 个 `llmt_col` 并排实例化：A block 和 A scale 广播到所有列，B block 和 B scale 按列切片，每列输出一个 FP32 accumulator，最后打包成 16 路输出。

## 自测题

1. 为什么 `a_elems_i` 不需要按列切片？
2. `b_elems_i[(col*`MX_BLOCK_K*`MX_ELEM_W) +: (`MX_BLOCK_K*`MX_ELEM_W)]` 这行在取哪一列的数据？
3. 如果 `MX_COLS=16`，`acc_o` 总线宽度是多少？
4. 这个文件有没有新增寄存器状态？为什么？
