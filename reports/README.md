# Reports Directory

这个目录用于存放后续自动或手动生成的结果：

- 仿真日志
- 精度统计
- 综合报告
- 面积/功耗报告
- 图表和中间摘要

当前只是占位，后续批次会把脚本输出接到这里。

当前已落地：

- `matmul_stats_4096x4096x4096.json`：`sim/run_matmul_stats.ps1` 输出的 `4096x4096` 抽样误差摘要
- `matmul_stats_4096x4096x4096_seed20260423.json` / `seed20260503.json` / `seed20260504.json`：baseline `[-8,8]` 的逐 seed 抽样误差摘要，现已额外记录 `matched_nonfinite_count` / `mismatched_nonfinite_count`
- `matmul_stats_4096x4096x4096_sweep.json`：baseline `[-8,8]` 的 3 组 seed 聚合摘要，包含 `mean_of_mean_rel_error`、`max_of_max_rel_error` 与各类 finite / nonfinite 计数
- `matmul_stats_4096x4096x4096_finite_exp32_seed*.json` / `matmul_stats_4096x4096x4096_finite_exp32_sweep.json`：`[-32,32]` profile 的逐 seed / 聚合摘要
- `matmul_stats_4096x4096x4096_finite_exp64_seed*.json` / `matmul_stats_4096x4096x4096_finite_exp64_sweep.json`：`[-64,64]` profile 的逐 seed / 聚合摘要；当前 3-seed 聚合里出现 `2484` 个 finite、`2928` 个 `inf`、`732` 个 `NaN` 与 `3660` 个 nonfinite mismatch
- `matmul_stats_4096x4096x4096_profiles.json`：`sim/run_matmul_stats_profiles.ps1` 生成的 profile 总摘要，统一列出 baseline / `finite_exp32` / `finite_exp64` 三档结果
