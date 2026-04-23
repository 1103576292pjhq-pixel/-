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
- `matmul_stats_4096x4096x4096_seed20260423.json` / `seed20260503.json` / `seed20260504.json`：`sim/run_matmul_stats_sweep.ps1` 逐 seed 输出的抽样误差摘要
- `matmul_stats_4096x4096x4096_sweep.json`：3 组 seed 的聚合摘要，包含 `mean_of_mean_rel_error`、`max_of_max_rel_error` 与每个 seed 的关键统计
