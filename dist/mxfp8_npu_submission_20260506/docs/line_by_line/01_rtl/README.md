# 01 RTL 逐行讲解

本目录讲 `rtl/` 下的可综合 Verilog。这里不会改源码文件，也不会要求把注释写进 `.v` 里。

## 阅读顺序

| 顺序 | 源文件 | 逐行讲解文件 | 状态 |
| --- | --- | --- | --- |
| 1 | `rtl/mx_defs.vh` | `00_mx_defs_vh.md` | 已完成 |
| 2 | `rtl/mx_funcs.vh` | `01_mx_funcs_vh.md` | 待续写 |
| 3 | `rtl/e4m3_decode.v` | `02_e4m3_decode_v.md` | 待续写 |
| 4 | `rtl/e8m0_scale_decode.v` | `03_e8m0_scale_decode_v.md` | 待续写 |
| 5 | `rtl/fixed_to_fp32.v` | `04_fixed_to_fp32_v.md` | 已完成 |
| 6 | `rtl/fp32_add_rne.v` | `05_fp32_add_rne_v.md` | 待续写 |
| 7 | `rtl/llmt_col.v` | `06_llmt_col_v.md` | 待续写 |
| 8 | `rtl/mx_array_32x16.v` | `07_mx_array_32x16_v.md` | 已完成 |

## RTL 阅读主线

先把全局尺寸读懂，再读格式函数，然后读单列，最后读顶层阵列。不要从 `fp32_add_rne.v` 开始，因为它是最细的数值模块，零基础读者容易陷在对阶、规格化和舍入细节里。

最短复述：

```text
rtl/mx_defs.vh 定义尺寸。
rtl/mx_funcs.vh 解释 MXFP8 编码。
fixed_to_fp32 和 fp32_add_rne 处理 FP32 数值路径。
llmt_col 做一列 dot32 和 accumulator。
mx_array_32x16 把 16 个 llmt_col 并排，形成阵列。
```
