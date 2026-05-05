# 代码讲解 04：MX 格式 helper 怎么读

## 1. 相关文件

- `rtl/mx_defs.vh`
- `rtl/mx_funcs.vh`
- `rtl/e4m3_decode.v`
- `rtl/e8m0_scale_decode.v`

这些文件决定“8 bit 输入到底代表什么数”。

## 2. `mx_defs.vh`

这个文件定义全局宽度：

| 宏 | 含义 |
| --- | --- |
| `MX_BLOCK_K` | 一个 block 的元素数，当前 32 |
| `MX_COLS` | 阵列并行列数，当前 16 |
| `MX_ELEM_W` | 元素宽度，8 bit |
| `MX_ELEM_FIXED_W` | 元素转 fixed 后的内部宽度 |
| `MX_DOT_W` | dot32 归约宽度 |
| `MX_FP32_QNAN` | canonical QNaN |

读 RTL 时，先看这些宏，否则总线宽度会很难跟。

## 3. `mx_funcs.vh`

这个文件提供 Verilog function：

- 判断 E4M3 是否 zero/subnormal/NaN。
- 把 E4M3 转成 fixed。
- 判断 E8M0 scale 是否 NaN。
- 把 E8M0 转成 unbiased exponent。

`llmt_col` 通过 include 这些 function，避免把格式解析逻辑散落在主 always 块里。

## 4. 为什么 NaN 直接转 fixed zero

在 `e4m3_to_fixed` 中，NaN 的 fixed magnitude 走 zero；但同时 `llmt_col` 会用 `any_nan` 单独记录 NaN 是否出现。

这样做的原因是：

- 数值归约路径不用承载 NaN payload。
- 最终 `fixed_to_fp32` 可以通过 `nan_i` 直接输出 canonical QNaN。
- testbench 和 Python golden model 更容易一致。

## 5. 自测题

1. `MX_BLOCK_K = 32` 会影响哪些输入总线宽度？
2. 为什么 scale NaN 和 element NaN 都要进入 `any_nan`？
3. canonical QNaN 的十六进制值是多少？
