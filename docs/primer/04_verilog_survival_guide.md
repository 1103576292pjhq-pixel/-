# 04 Verilog 生存指南：读本仓库够用的语法

## module：硬件模块的边界

Verilog 的 `module` 像一个硬件盒子，端口是盒子的引脚：

```verilog
module llmt_col (
  input clk,
  input rst_n,
  input valid_i,
  output valid_o
);
```

读模块时先问三件事：输入是什么、输出是什么、内部保存什么状态。

## input/output、wire/reg

- `input`、`output`：模块边界信号。
- `wire`：组合连线，通常由连续赋值或子模块输出驱动。
- `reg`：在 `always` 块里赋值的变量，不一定都是触发器，要看 always 类型。

常见误区：看到 `reg` 就以为一定是寄存器。`always @*` 里的 `reg` 多数只是组合逻辑变量。

## packed bus 和位切片

本项目大量使用打包总线。例如 32 个 8 bit 元素：

```verilog
reg [`MX_BLOCK_K*`MX_ELEM_W-1:0] a_elems_i;
```

取第 `idx` 个元素：

```verilog
a_elems_i[idx*8 +: 8]
```

`+:` 表示从起点向高位取固定宽度。`idx*8 +: 8` 就是取 `[idx*8+7 : idx*8]`。

## always @*：组合逻辑

`always @*` 表示输入变了就重新计算，适合写组合逻辑：

```verilog
always @* begin
  sum = a + b;
end
```

读组合块时重点看：默认值、条件分支、是否每条路径都赋值。

## always @(posedge clk or negedge rst_n)：时序逻辑

这类块通常表示触发器：

```verilog
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    valid_o <= 1'b0;
  end else begin
    valid_o <= valid_i;
  end
end
```

读时序块时重点看：reset 后是什么、每个时钟沿更新什么、valid 怎样延迟。

## testbench 是什么

testbench 不是要综合到芯片里的硬件，它负责给 DUT 输入、等待输出、检查结果：

```verilog
initial begin
  valid_i = 1'b1;
  ...
  if (acc_o !== expected) $fatal;
end
```

本仓库的 testbench 会用 hex 向量、manifest 和 expected output 做可复验检查。

## hex 向量怎么读

`8'h38` 表示 8 bit 十六进制数 `0x38`。`32'h42000000` 是一个 FP32 bit pattern，不是十进制 42000000。

在本项目中：

- `8'h38` 常用于 E4M3 的 1.0。
- `8'h7f` 常用于 E8M0 scale 的 1.0。
- `32'h42000000` 是 FP32 的 32.0。

## 常见错误

- 把 `+:` 看成加法。它是位切片语法。
- 把 testbench 当成可综合 RTL。
- 分不清 `valid_i` 输入有效和 `valid_o` 输出有效。
- 忘记低有效复位 `rst_n` 中的 `n` 表示 negative/active-low。

## 自测题

1. `x[16 +: 8]` 等价于哪一段位？
2. `always @*` 和 `always @(posedge clk)` 最大区别是什么？
3. 为什么 `32'h42000000` 不能按十进制整数理解？

## 用自己的话复述

“读这个仓库的 Verilog，先看 module 端口，再看 packed bus 怎么切片，然后分清组合 always 和时序 always。testbench 只负责喂输入和检查输出，不是提交给后端综合的电路。”
