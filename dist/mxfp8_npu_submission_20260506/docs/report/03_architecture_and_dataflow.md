# 03 总体架构与数据流

## 1. 设计定位

本项目实现一个面向 MXFP8 矩阵乘的 `32 x 16` 计算阵列。阵列以 `K = 32` 为基本块粒度，每拍向一行计算输入一个 A block，并向 16 个列 lane 输入对应的 B block。每个列 lane 计算一次 `dot32`，再把结果累加到该列的 FP32 accumulator 中。

当前版本定位为 RTL/backend handoff 基线：接口、功能、验证和约束模板已经具备，后端可以在此基础上继续综合、时序收敛和 PPA 评估。

## 2. 顶层组织

顶层模块是 `rtl/mx_array_32x16.v`：

| 接口 | 含义 |
| --- | --- |
| `clk`、`rst_n` | 同步时钟和低有效复位 |
| `valid_i` | 本拍输入 A/B block 有效 |
| `acc_clear_i[15:0]` | 每列独立清 accumulator，用于新输出 tile 开始 |
| `a_elems_i`、`a_scale_i` | 一个 A block：32 个 MXFP8 元素和共享 scale |
| `b_elems_i`、`b_scale_i` | 16 个 B block：每列 32 个 MXFP8 元素和共享 scale |
| `valid_o[15:0]` | 16 列输出有效 |
| `acc_o` | 16 个 FP32 accumulator 输出 |

阵列内部并排实例化 16 个 `llmt_col`。A block 广播给所有列；B block 按列切片输入；每列维护独立 accumulator。这个组织直接匹配 output-stationary 数据流：输出元素停留在列内 accumulator 中，K 维 block 连续流过。

## 3. 数据流

一次输出 tile 的计算过程如下：

1. 对目标输出 tile，先对对应列执行 `acc_clear_i`。
2. 每个 K block 周期输入同一行的 `a_elems_i/a_scale_i`。
3. 同拍输入 16 列的 `b_elems_i/b_scale_i`。
4. 每个 `llmt_col` 执行 32 元素乘加归约。
5. 归约值转换为 FP32 后累加到列内 accumulator。
6. `valid_o` 拉高时，`acc_o` 给出当前列 tile 的 FP32 输出。

文件驱动 testbench `tb/tb_mx_array_dataset.v` 按 row、column tile、K block 三层循环驱动阵列，并检查 `valid_o` 在 16 列之间保持一致。tail tile 中超出真实 N 的列 lane 使用零填充，并检查 padded 输出语义。

## 4. 已验证调度场景

2026-04-28 默认 Verilog 回归日志见 `reports/verification/iverilog_default.log`。当前覆盖：

| 数据集 | 覆盖点 |
| --- | --- |
| `4x16x64` | 单列 tile、有限值基本矩阵 |
| `5x20x96` | 尾 tile、K_BLOCKS=3 |
| `8x32x128` | 双列 tile、有限值回归 |
| `9x65x192` | 5 个列 tile、单 lane 尾 tile、K_BLOCKS=6 |
| `3x18x64_nonfinite` | mixed finite/Inf/NaN，尾 tile |
| `6x33x160_nonfinite` | 三列 tile、K_BLOCKS=5、mixed nonfinite |
| `7x49x224_sparse_nonfinite` | 四列 tile、K_BLOCKS=7、sparse scale/element NaN |

这些用例证明当前调度不只覆盖单次 dot32，而覆盖了矩阵级 tiling、连续输入、尾列和非有限值传播。

## 5. 当前边界

- 阵列规模固定为 `MX_COLS = 16`、`MX_BLOCK_K = 32`，尚未参数化成任意阵列生成器。
- 目前没有真实后端时钟收敛结果，架构频率判断只能基于流水拆分和综合模板。
- SRAM/片上缓存、DMA、NoC、host 接口不在当前仓库范围；本项目交付的是计算阵列 RTL 和验证包。
