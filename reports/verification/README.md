# Verification Reports

本目录存放本轮实际运行日志。2026-05-06 release 口径复验结果如下：

| 日志 | 命令 | 结果 |
| --- | --- | --- |
| `iverilog_default.log` | `sim/run_iverilog.ps1` | PASS：列级 smoke/back-to-back/corner、阵列 smoke、7 组矩阵 dataset 全部通过 |
| `python_ref_default.log` | `sim/run_python_ref.ps1` | PASS：Python MX 参考模型 self-test 通过，并刷新 `vectors/dot32_smoke` |
| `matmul_stats_default.log` | `sim/run_matmul_stats.ps1` | PASS：4096x4096x4096，2048 sample，finite-only `[-8, 8]` |
| `matmul_stats_sweep.log` | `sim/run_matmul_stats_sweep.ps1` | PASS：3 seeds，6144 finite samples，0 nonfinite mismatch |
| `matmul_stats_profiles.log` | `sim/run_matmul_stats_profiles.ps1` | PASS：finite_exp8、finite_exp32、finite_exp64、sparse_nonfinite 四档 profile |

若后续修改 RTL 或参考模型，必须重新生成这些日志并同步 `reports/precision`。

## 提交验收

`sim/run_submission_regression.ps1` 会继续校验并写入这些日志：

- `iverilog_default.log`
- `python_ref_default.log`
- `waveform_smoke.log`
- `matmul_stats_default.log`
- `matmul_stats_sweep.log`
- `matmul_stats_profiles.log`
- `waveform_screenshots.log`

它的最终 verdict 应为 `PASS` 或 `PASS_WITH_EXTERNAL_SYNTH_BLOCKER`。若出现功能、证据或纯 Verilog 门禁失败，则必须先修复再提交。
