# 02 数据流、tile 与 `32x16`

## `32x16` 先不要想复杂

本项目里的 `32x16` 可以先拆开理解：

```text
32: 一个 dot32 一次吃 32 个 K 方向元素
16: 同时算 16 个输出列
```

它不是“32 行 16 列的完整 systolic array”。更准确的说法是：一个 A block 广播给 16 个列单元，每个列单元使用自己的 B block，得到 16 个输出列的部分和。

## 一个具体例子

如果 K=64，那么 K 方向会拆成两个 block：

```text
第 0 个 K block: k=0..31
第 1 个 K block: k=32..63
```

每个 block 做一次 dot32。两个 dot32 的结果在 FP32 accumulator 里累加，最后才是完整输出。

## output-stationary 是什么

`stationary` 表示“尽量让某类数据停在本地”。本项目采用 output-stationary：

```text
A/B block 流进来
dot32 计算部分和
每列 accumulator 留住输出部分和
下一个 K block 来了继续加
```

这样可以减少输出反复写回外部的次数。对硬件来说，少搬数据通常比少算一次更重要。

## tile 为什么存在

阵列一次只能并行算 16 列。如果真实矩阵有 20 列：

```text
tile0: col  0..15  共 16 列
tile1: col 16..19  共  4 列 + 12 个 padding lane
```

尾 tile 的 padding lane 不是有效输出。testbench 必须确认真实列正确，也要确认无效 lane 不残留旧结果。

## valid、reset 和 acc_clear

读 RTL 时先记住三个控制信号：

- `rst_n`：低有效复位，把状态清到已知值。
- `valid_i`：本拍输入是否有效。
- `acc_clear_i`：开始一个新输出时清 accumulator，不清就表示继续累加 K block。

简化时序：

```text
reset -> acc_clear + valid -> dot32 -> FP32 add -> valid_o
```

## 常见错误

- 把 `acc_clear_i` 当成 reset。reset 是全局初始化，acc_clear 是开始新输出。
- 忘记 tail tile，导致只验证 N=16、32 这种整齐尺寸。
- 把 padding lane 当成真实列输出。

## 自测题

1. N=65 时需要几个 16 列 tile？
2. K=96 时需要几个 dot32 block？
3. 为什么 output-stationary 可以减少输出搬运？

## 用自己的话复述

“`32x16` 的 32 是 dot32 的 K block 长度，16 是并行输出列数。A block 广播给所有列，B block 每列不同，输出部分和留在列内 accumulator。矩阵列数不是 16 的倍数时，要用 tail tile 和 padding lane 处理。”
