# 06 精度结果

## 1. 统计口径

精度统计由 `tools/mx_ref.py` 生成，脚本入口在 `sim/run_matmul_stats*.ps1`。当前统一使用：

- 矩阵规模：`4096 x 4096 x 4096`
- 默认抽样：每个 seed 2048 个输出点
- 默认 seeds：`20260423`、`20260503`、`20260504`
- 输出目录：`reports/precision/`

统计同时区分 finite 误差和 nonfinite 类别匹配，避免把 Inf/NaN 传播问题混入有限值误差均值。

## 2. Baseline 有限值结果

`reports/precision/matmul_stats_4096x4096x4096_sweep.json` 汇总了 baseline `[-8, 8]` 三 seed sweep：

| 指标 | 数值 |
| --- | --- |
| finite samples | 6144 |
| inf samples | 0 |
| NaN samples | 0 |
| nonfinite mismatch | 0 |
| mean_of_mean_abs_error | `341.72226118170852` |
| mean_of_mean_rel_error | `4.806448778641348e-07` |
| max_of_max_abs_error | `6442.180576324463` |
| max_of_max_rel_error | `6.593824658959058e-04` |

结论：常规 scale 指数范围下，projected FP32 路径的有限值相对误差保持在可解释范围内，三 seed 结果没有非有限值类别差异。

## 3. Profile sweep

`reports/precision/matmul_stats_4096x4096x4096_profiles.json` 汇总四档 profile：

| Profile | 重点 | 关键结果 |
| --- | --- | --- |
| `finite_exp8` | baseline `[-8, 8]` | 6144 finite，0 nonfinite mismatch |
| `finite_exp32` | 扩大 scale 指数到 `[-32, 32]` | 6144 finite，0 nonfinite mismatch，max_of_max_rel_error `1.1563487692803309e-05` |
| `finite_exp64` | 极端动态范围 `[-64, 64]` | 2484 finite、2928 Inf、732 NaN、3660 nonfinite category differences |
| `sparse_nonfinite` | 有限值底座 + sparse NaN 注入 | 6037 finite、107 matched NaN、0 nonfinite mismatch |

`finite_exp64` 中的 nonfinite category differences 不应解释为 RTL dataset 回归失败。它反映的是 projected FP32 accumulation 与 ideal double accumulator 在极端动态范围下的类别差异：FP32 路径可能先溢出或进入 NaN，而 double accumulator 仍能表示中间值。报告中应把它作为动态范围边界证据。

## 4. Sparse nonfinite 结果

`reports/precision/matmul_stats_4096x4096x4096_sparse_nonfinite_sweep.json` 结果：

| 指标 | 数值 |
| --- | --- |
| finite samples | 6037 |
| matched NaN | 107 |
| mismatched nonfinite | 0 |
| mean_of_mean_rel_error | `4.779095730775324e-07` |
| max_of_max_rel_error | `6.593824658959058e-04` |

该结果说明：在有限值底座上稀疏注入 element-NaN 和 scale-NaN 时，当前 Python 语义和 projected path 的非有限值传播可以对齐。

## 5. 报告结论

- 常规 `[-8, 8]` 范围：有限值误差稳定，三 seed 没有非有限值类别差异。
- 扩展到 `[-32, 32]`：仍保持有限值类别一致，但绝对误差随数值尺度增大。
- 扩展到 `[-64, 64]`：动态范围已触发 projected FP32 路径边界，必须单独说明。
- sparse nonfinite：NaN 传播匹配，适合作为比赛证据中的异常值覆盖点。

## 6. 后续可补

- 把 JSON 统计导出成报告图表。
- 增加 worst-case case study，说明最大相对误差来自低幅值输出。
- 若获得比赛指定 benchmark，应替换或补充当前随机抽样 profile。
