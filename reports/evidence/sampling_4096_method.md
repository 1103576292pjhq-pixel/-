# 4096 抽样统计方法

## 目的

完整 `4096 x 4096 x 4096` 矩阵乘输出包含 16,777,216 个输出点。逐点全量 RTL 仿真成本过高，因此本仓库使用 Python projected path 对输出点抽样，评估有限值误差、非有限值传播和动态范围边界。

## 脚本入口

| 脚本 | 输出 |
| --- | --- |
| `sim/run_matmul_stats.ps1` | 单 seed baseline JSON |
| `sim/run_matmul_stats_sweep.ps1` | 多 seed sweep JSON |
| `sim/run_matmul_stats_profiles.ps1` | 多 profile 汇总 JSON |

默认输出目录是 `reports/precision/`。

## 默认参数

- M = 4096
- N = 4096
- K = 4096
- samples = 2048 per seed
- seeds = `20260423, 20260503, 20260504`
- baseline scale exponent range = `[-8, 8]`

## Profile

| Profile | 参数 | 目的 |
| --- | --- | --- |
| `finite_exp8` | finite-only, `[-8, 8]` | 常规范围误差基线 |
| `finite_exp32` | finite-only, `[-32, 32]` | 更大动态范围下的有限值误差 |
| `finite_exp64` | finite-only, `[-64, 64]` | 触发 projected FP32 动态范围边界 |
| `sparse_nonfinite` | finite base + sparse NaN injection | 验证稀疏异常值传播 |

## 解释规则

- finite 误差只在 project 和 ideal 都为 finite 时统计。
- Inf/NaN 使用单独计数，不并入 finite mean error。
- `finite_exp64` 的 nonfinite category differences 是动态范围现象，不等价于默认 RTL 回归失败。
- sparse nonfinite 的核心指标是 `total_mismatched_nonfinite_count`，2026-04-28 三 seed 结果为 0。
