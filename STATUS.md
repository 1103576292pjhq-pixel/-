# STATUS

- 当前批次：P3 `4096x4096` profile 误差 sweep
- 本批已完成：新增 `sim/run_matmul_stats_profiles.ps1`，并把单次/多 seed 统计扩展成 baseline `[-8,8]`、`finite_exp32` `[-32,32]`、`finite_exp64` `[-64,64]` 三档 profile；baseline 仍为 `mean_of_mean_rel_error ≈ 4.81e-7`、`max_of_max_rel_error ≈ 6.59e-4`，`finite_exp32` 为 `8.88e-8 / 1.16e-5`，`finite_exp64` 则出现 `2484` 个 finite、`2928` 个 `inf`、`732` 个 `NaN` 与 `3660` 个 nonfinite mismatch；状态/报告/使用文档/本地 KB 已同步
- 下一步：继续推进 `LLMT` 的 issue / reduction 微架构，并在现有五列 tile 覆盖基础上继续扩大更大矩阵、稀疏 mixed-nonfinite 场景与硬件侧极值回归
- 阻塞项：无；当前为交互会话内推进，未启动独立长期 runner
