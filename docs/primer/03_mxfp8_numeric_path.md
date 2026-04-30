# 03 MXFP8 数值路径：从 8 bit 到 FP32

## 先看普通小数怎么压缩

FP32 很精细，但每个数 32 bit。MXFP8 的想法是：元素用 8 bit 表示，一组 32 个元素共享一个 scale。可以粗略理解成：

```text
真实值 ≈ E4M3 元素值 * 2^(E8M0 scale)
```

这样每个元素短很多，又能靠共享 scale 表示较大的数量级。

## E4M3 是元素，E8M0 是 scale

E4M3 的 8 bit 结构：

```text
sign | exponent[3:0] | mantissa[2:0]
```

E8M0 更像一个指数 scale，没有 mantissa。一个 MXFP8 block 是：

```text
32 个 E4M3 元素 + 1 个 E8M0 scale
```

## dot32 的手算直觉

如果先忽略浮点细节，假设 32 个 A 都是 1，32 个 B 都是 1，scale 也都是 1，那么：

```text
dot32 = 1*1 + 1*1 + ... + 1*1 = 32
```

这就是 `tb_llmt_col_smoke.v` 第一段检查 `FP32_32` 的原因。第二次不清 accumulator，再加一次 32，所以输出变成 64。

## RTL 里的真实路径

本项目不是直接放 32 个 FP32 乘法器，而是走一条更适合前端 RTL 的路径：

```text
E4M3 A/B
  -> e4m3_to_fixed
  -> fixed multiply
  -> 32 lane sum
  -> fixed_to_fp32
  -> fp32_add_rne accumulator
```

对应文件：

- `rtl/mx_funcs.vh`：E4M3/E8M0 辅助函数。
- `rtl/e4m3_decode.v`、`rtl/e8m0_scale_decode.v`：格式解码。
- `rtl/fixed_to_fp32.v`：把固定点 dot 转 FP32。
- `rtl/fp32_add_rne.v`：FP32 round-to-nearest-even 加法。
- `rtl/llmt_col.v`：把这些路径串成列单元。

## finite、Inf、NaN 要分开讲

普通误差只适合 finite 输出。如果输出是 NaN 或 Inf，要先看类别是否匹配：

```text
finite: 比 absolute / relative error
NaN/Inf: 比类别是否一致
```

所以报告里会分开统计 `finite_count`、`matched_nonfinite_count` 和 `mismatched_nonfinite_count`。

## 常见错误

- 把 MXFP8 说成普通 FP8。MXFP8 的重点是 block scale。
- 把 E8M0 当成每个元素都有。它是 32 个元素共享。
- 用相对误差评价 NaN/Inf。非有限值要先看类别传播。

## 自测题

1. 如果 32 个乘积都等于 1，dot32 是多少？
2. E4M3 和 E8M0 分别负责什么？
3. 为什么 RTL 先做 fixed dot32，再转 FP32？

## 用自己的话复述

“MXFP8 用 32 个 E4M3 元素共享一个 E8M0 scale。RTL 先把元素解码成固定点，做 32 路乘加，再根据 scale 转成 FP32，最后用 FP32 accumulator 累加。finite 误差和 NaN/Inf 类别必须分开验证。”
