# 02 MXFP8 格式与数值规则

## 1. 数据组织

本项目按 block 处理 MXFP8 数据：

- 一个 block 含 `32` 个 E4M3 元素。
- 一个 block 共享一个 E8M0 scale。
- A 和 B 都以 block 为单位输入 `llmt_col`。
- 一个 dot32 输出再进入 FP32 accumulator。

简化表示：

```text
A_block = {a_scale, a_elem[0..31]}
B_block = {b_scale, b_elem[0..31]}
dot32   = sum(a_elem[k] * b_elem[k]) with scale adjustment
acc     = fp32_add(acc, dot32_as_fp32)
```

## 2. E4M3 元素约定

当前工程约定：

| 字段 | 说明 |
| --- | --- |
| bit[7] | sign |
| bit[6:3] | exponent |
| bit[2:0] | mantissa |
| zero | 低 7 位全 0 |
| NaN | `exp=0xf` 且 `mant=0x7` |
| subnormal | `exp=0` 且 `mant!=0` |

RTL helper 在 `rtl/mx_funcs.vh` 中实现。`e4m3_to_fixed` 会把 E4M3 转为内部 fixed 表示，供 lane product 和 dot32 归约使用。

## 3. E8M0 scale 约定

当前工程约定：

- `0xff` 视为 scale NaN。
- 其他编码按 `enc - 127` 转成无偏指数。

dot32 的指数偏移由 A scale、B scale 和 fixed 小数位共同决定：

```text
dot_exp_shift = a_scale_exp + b_scale_exp - MX_PROD_FIXED_FRAC
```

## 4. NaN 和 Inf 处理

RTL 中 NaN 传播采用 canonical QNaN 策略：

- E4M3 element NaN 会置位 `any_nan`。
- E8M0 scale NaN 会置位 `any_nan`。
- fixed 乘加路径继续以数值形式运行，但最终 `fixed_to_fp32` 通过 `nan_i` 输出 canonical QNaN。
- Python golden model 导出的 NaN 统一为 `0x7fc00000`。

这样做的目的是把“NaN 语义”与“NaN payload 差异”分开，避免不同平台的 NaN payload 造成误判。

## 5. Projected FP32 与 ideal 参考

本项目统计中区分两条路径：

- projected path：模拟当前 RTL 的 dot32 转 FP32 后再累加。
- ideal path：使用更高精度参考计算，作为误差分析基准。

在常规指数范围下，两者应主要体现有限值舍入误差。在 `finite_exp64` 这类极端动态范围下，projected FP32 可能更早溢出或进入 NaN，因此统计会出现 nonfinite category differences。报告中必须把这种现象解释为动态范围边界，而不是默认 RTL dataset 回归失败。

当前 RTL 的 projected FP32 路径支持 FP32 subnormal 输出。`fixed_to_fp32` 在 dot32 结果低于 normal FP32 下界时，会按 round-to-nearest-even 生成 subnormal mantissa；`fp32_add_rne` 在 accumulator 累加结果进入 subnormal 区间时，也会输出 subnormal 或按舍入进入最小 normal。`tb/tb_llmt_col_corner.v` 已加入最小 FP32 subnormal dot 和 subnormal accumulator directed case。

## 6. 与公开资料的关系

本项目参考 OCP MX v1.0、DeepSeek-V3 Technical Report v2 和公开 Adelia 信息来确定背景叙事，但当前 RTL 以仓库内工程约定为准。若主办方后续给出更严格的格式边界、舍入或异常处理规则，应在本章显式列出差异并更新 RTL/Python golden model。

## 7. 当前验证证据

- Verilog 回归：`reports/verification/iverilog_default.log`
- Python self-test：`reports/verification/python_ref_default.log`
- 精度统计：`reports/precision/matmul_stats_4096x4096x4096_profiles.json`
- Sparse nonfinite：`reports/precision/matmul_stats_4096x4096x4096_sparse_nonfinite_sweep.json`
