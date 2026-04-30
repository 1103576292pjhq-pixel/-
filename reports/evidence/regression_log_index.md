# 回归日志索引

## 2026-04-30 增量日志

| 日志 | 生成命令 | 结论 | 可支撑报告位置 |
| --- | --- | --- | --- |
| `../verification/iverilog_default.log` | `sim/run_iverilog.ps1` | PASS | `docs/report/03`、`04`、`05` |
| `../verification/waveform_smoke.log` | `sim/run_waveform_smoke.ps1` | PASS | `docs/report/05`、`reports/evidence/waveform_capture_status.md` |

## 2026-04-28 基线日志

| 日志 | 生成命令 | 结论 | 可支撑报告位置 |
| --- | --- | --- | --- |
| `../verification/python_ref_default.log` | `sim/run_python_ref.ps1` | PASS | `docs/report/05`、`06` |
| `../verification/matmul_stats_default.log` | `sim/run_matmul_stats.ps1` | PASS | `docs/report/06` |
| `../verification/matmul_stats_sweep.log` | `sim/run_matmul_stats_sweep.ps1` | PASS | `docs/report/06` |
| `../verification/matmul_stats_profiles.log` | `sim/run_matmul_stats_profiles.ps1` | PASS | `docs/report/06` |

## Verilog 回归覆盖摘要

最新 `iverilog_default.log` 包含以下 PASS 项：

- `tb_llmt_col_smoke`
- `tb_llmt_col_back_to_back`
- `tb_llmt_col_corner`
- `tb_mx_array_smoke`
- `tb_mx_array_dataset` for `4x16x64`
- `tb_mx_array_dataset_3x18x64_nonfinite`
- `tb_mx_array_dataset_6x33x160_nonfinite`
- `tb_mx_array_dataset_7x49x224_sparse_nonfinite`
- `tb_mx_array_dataset_8x32x128`
- `tb_mx_array_dataset_9x65x192`
- `tb_mx_array_dataset_5x20x96`

## 使用规则

- 每次 RTL、testbench、Python golden model 或向量变更后，必须重跑相关日志。
- 报告中引用“已通过”时，应说明日志文件名和日期。
- 如果脚本因环境失败，应保留失败日志并在 `STATUS.md` 写明 exact blocker。
