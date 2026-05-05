# Precision Reports

本目录存放 `4096x4096x4096` 抽样精度统计 JSON。2026-04-28 复验使用 2048 samples / seed，默认 seeds 为 `20260423, 20260503, 20260504`。

| 文件 | 含义 | 关键结论 |
| --- | --- | --- |
| `matmul_stats_4096x4096x4096.json` | 单 seed baseline，finite-only `[-8, 8]` | 2048 finite，0 nonfinite mismatch，max_rel_error `7.920360179504847e-05` |
| `matmul_stats_4096x4096x4096_sweep.json` | baseline 三 seed sweep | 6144 finite，mean_of_mean_rel_error `4.806448778641348e-07`，max_of_max_rel_error `6.593824658959058e-04` |
| `matmul_stats_4096x4096x4096_finite_exp32_sweep.json` | finite-only `[-32, 32]` | 6144 finite，0 nonfinite mismatch，max_of_max_rel_error `1.1563487692803309e-05` |
| `matmul_stats_4096x4096x4096_finite_exp64_sweep.json` | finite-only `[-64, 64]` | Projected FP32 path 出现 Inf/NaN；记录 3660 个 ideal/project nonfinite 类别差异，用于说明动态范围边界 |
| `matmul_stats_4096x4096x4096_sparse_nonfinite_sweep.json` | finite base + sparse NaN injection | 6037 finite，107 matched NaN，0 nonfinite mismatch |
| `matmul_stats_4096x4096x4096_profiles.json` | 四档 profile 总览 | 汇总 baseline、finite_exp32、finite_exp64、sparse_nonfinite |

`finite_exp64` 的 nonfinite mismatch 不是 RTL 回归失败，而是抽样统计中“projected FP32 累加路径”和 ideal double accumulator 在极端动态范围下的类别差异，应在报告中单独解释。
