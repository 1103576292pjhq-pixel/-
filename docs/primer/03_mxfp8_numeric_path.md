# NPU 背景教程 03：MXFP8 数值路径怎么走

## 1. MXFP8 是什么

本项目里的 MXFP8 可以理解成：

- 元素本身用 8 bit E4M3 表示。
- 每 32 个元素共享一个 8 bit E8M0 scale。
- 计算时先解释元素，再结合 scale 得到真实数量级。

它的核心思想是“元素短，scale 共享”。这样比 FP32 省面积和带宽，又比纯整数多一些动态范围。

## 2. E4M3 元素

E4M3 的 8 bit 可以粗略拆成：

```text
sign | exponent[3:0] | mantissa[2:0]
```

本项目的 Verilog 函数在 `rtl/mx_funcs.vh`：

- `e4m3_is_zero`
- `e4m3_is_nan`
- `e4m3_to_fixed`

硬件内部不会直接用浮点乘法器做 E4M3 x E4M3，而是先转成固定点，再做整数/固定点乘加。

## 3. E8M0 scale

E8M0 没有 mantissa，主要表示 2 的指数缩放。`rtl/mx_funcs.vh` 里有：

- `e8m0_is_nan`
- `e8m0_unbiased_exp`

两个 block 相乘时，A scale 和 B scale 的指数会相加，再扣掉固定点小数位，得到 dot32 的最终指数偏移。

## 4. 本项目的数值路径

简化后可以写成：

```text
E4M3 A/B -> fixed A/B
fixed A * fixed B -> lane product
32 lane product sum -> dot32
dot32 + scale exponent -> FP32
FP32 + accumulator -> output FP32
```

对应 RTL：

- `rtl/llmt_col.v`：组织 dot32 和 accumulator。
- `rtl/fixed_to_fp32.v`：把 fixed dot 转成 FP32。
- `rtl/fp32_add_rne.v`：FP32 accumulator 加法。

## 5. 为什么 finite 和 NaN 要分开看

误差统计只对 finite 数值有意义。例如：

```text
project = 1.0001
ideal   = 1.0000
```

可以计算 absolute error 和 relative error。

但如果输出是 NaN 或 Inf，问题就不是“误差多少”，而是“类别是否匹配”。所以 `tools/mx_ref.py` 分开记录：

- `finite_count`
- `inf_count`
- `nan_count`
- `matched_nonfinite_count`
- `mismatched_nonfinite_count`

## 6. 一周复述要点

你需要能讲清楚：

1. E4M3 是元素格式，E8M0 是 block scale。
2. 32 个元素共享一个 scale。
3. RTL 先走 fixed dot32，再转 FP32 accumulator。
4. finite 误差和 nonfinite 类别匹配必须分开统计。
5. sparse nonfinite 用例是为了证明异常值传播语义。
