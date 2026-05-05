# 00 逐行讲解：rtl/mx_defs.vh

## 文件定位

`mx_defs.vh` 是全项目的“尺寸表”和“常量表”。它不产生独立硬件模块，但会被其他 RTL 文件 `include`，决定 block 长度、列数、元素位宽、内部 fixed 位宽和常用 FP32 常量。

## 先看结论

这个文件回答三个问题：

1. 一个 MXFP8 block 有多少个元素。
2. 一个阵列有多少列。
3. 内部乘法、dot32 和 FP32 特殊值用多少 bit 表示。

## 逐行讲解

| 行号 | 源码 | 讲解 |
| --- | --- | --- |
| 1 | <code>`ifndef MX_DEFS_VH</code> | 防止头文件被重复包含。第一次包含时继续往下读，第二次包含时会跳过。 |
| 2 | <code>`define MX_DEFS_VH</code> | 定义保护宏，表示这个头文件已经被包含过。 |
| 3 | 空行 | 只用于分隔保护宏和真正的定义。 |
| 4 | <code>`define MX_BLOCK_K 32</code> | 定义一个 block 内有 32 个 E4M3 元素。赛题要求每 32 个元素共享一个 scale，这里把这个要求固化成宏。 |
| 5 | <code>`define MX_COLS 16</code> | 定义阵列有 16 个列单元，也就是 16 个 `llmt_col` 并行工作。 |
| 6 | <code>`define MX_ELEM_W 8</code> | 定义每个 E4M3 元素宽度为 8 bit。 |
| 7 | <code>`define MX_SCALE_W 8</code> | 定义 E8M0 scale 宽度为 8 bit。 |
| 8 | <code>`define MX_BLOCK_W ((`MX_BLOCK_K * `MX_ELEM_W) + `MX_SCALE_W)</code> | 定义一个完整 block 的理论总宽度：32 个 8 bit 元素加 1 个 8 bit scale。当前顶层端口把元素和 scale 分开传，但这个宏可以描述 block 总大小。 |
| 9 | 空行 | 把外部格式尺寸和内部 fixed 尺寸隔开。 |
| 10 | <code>`define MX_ELEM_FIXED_FRAC 9</code> | 定义 E4M3 转成内部 fixed 后保留 9 位小数尺度。后面乘法后小数位会翻倍。 |
| 11 | <code>`define MX_ELEM_FIXED_W 19</code> | 定义单个元素转 fixed 后的总位宽。位宽要够放符号、整数部分和小数尺度。 |
| 12 | <code>`define MX_PROD_FIXED_FRAC (`MX_ELEM_FIXED_FRAC * 2)</code> | 两个 fixed 元素相乘，小数尺度相加，所以乘积的小数位是 9 + 9 = 18。 |
| 13 | <code>`define MX_PROD_W (`MX_ELEM_FIXED_W * 2)</code> | 两个 19 bit fixed 数相乘，乘积位宽按保守方式取 38 bit。 |
| 14 | <code>`define MX_DOT_W 44</code> | dot32 要把 32 个乘积相加，需要比单个乘积更宽，避免普通累加溢出。 |
| 15 | <code>`define MX_DOT_EXP_W 12</code> | dot32 转 FP32 时需要指数偏移，这里定义指数偏移信号的位宽。 |
| 16 | 空行 | 把内部 fixed 定义和 FP32 常量隔开。 |
| 17 | <code>`define MX_FP32_ZERO 32'h00000000</code> | 定义 FP32 正零的 bit pattern。 |
| 18 | <code>`define MX_FP32_QNAN 32'h7fc00000</code> | 定义 canonical quiet NaN。项目中遇到 NaN 时统一输出这个值，避免 payload 差异影响比对。 |
| 19 | <code>`define MX_FP32_INF  32'h7f800000</code> | 定义 FP32 正无穷的 bit pattern。负无穷可以用符号位加同样的 exponent/mantissa 形式得到。 |
| 20 | 空行 | 只用于分隔常量和文件结束保护。 |
| 21 | <code>`endif</code> | 结束第 1 行的 include guard。 |

## 关键复述

`mx_defs.vh` 不做计算，它定义全项目尺寸。最关键的两个宏是 `MX_BLOCK_K=32` 和 `MX_COLS=16`：前者来自 MXFP8 block 规则，后者来自赛题要求的 32x16 阵列。其他 fixed 位宽宏服务于元素解码、乘法和 dot32 累加。

## 自测题

1. 如果 `MX_COLS` 从 16 改成 8，顶层阵列会少什么？
2. 为什么 `MX_PROD_FIXED_FRAC` 是 `MX_ELEM_FIXED_FRAC * 2`？
3. `MX_FP32_QNAN` 为什么要统一成一个固定值？
