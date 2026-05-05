# 05 验证方法学

## 1. 验证目标

验证目标分成三层：

1. 功能正确：RTL 输出与 Python golden model 生成的期望值一致。
2. 调度正确：矩阵级 tiling、tail tile、连续输入和 valid 时序不出错。
3. 数值可解释：4096 规模抽样统计能说明有限值误差、动态范围边界和非有限值传播。

## 2. 验证分层

| 层级 | 文件或脚本 | 覆盖内容 |
| --- | --- | --- |
| 列级 | `tb/tb_llmt_col_smoke.v`、`tb/tb_llmt_col_corner.v`、`tb/tb_llmt_col_back_to_back.v` | 基本 dot32、corner、连续 valid 输入 |
| 阵列 smoke | `tb/tb_mx_array_smoke.v` | 32x16 顶层连线和列输出 |
| 矩阵 dataset | `tb/tb_mx_array_dataset*.v`、`vectors/` | row/tile/K block 调度、tail tile、mixed nonfinite |
| Python golden | `tools/mx_ref.py`、`sim/run_python_ref.ps1` | 自检、dot32 向量生成、矩阵统计 |
| 大矩阵统计 | `sim/run_matmul_stats*.ps1` | 4096x4096x4096 抽样误差和 profile sweep |
| 波形 smoke | `sim/run_waveform_smoke.ps1`、`reports/evidence/waveforms/*.vcd`、`reports/evidence/waveform_screenshots/*.png` | 单列、连续输入和阵列 smoke 的 valid/accumulator 时序展示 |
| 数值边界说明 | `docs/report/02_mx_format_and_numeric_rules.md`、`tb/tb_llmt_col_corner.v` | E4M3 subnormal、FP32 subnormal、NaN、scale NaN、FP32 projected path 边界 |

## 3. 回归结果

| 命令 | 日志 | 结果 |
| --- | --- | --- |
| `sim/run_iverilog.ps1` | `reports/verification/iverilog_default.log` | PASS，2026-05-04 刷新 |
| `sim/run_waveform_smoke.ps1` | `reports/verification/waveform_smoke.log` | PASS，2026-05-04 刷新 |
| `sim/run_python_ref.ps1` | `reports/verification/python_ref_default.log` | PASS，2026-05-04 刷新 |
| `sim/run_matmul_stats.ps1` | `reports/verification/matmul_stats_default.log` | PASS |
| `sim/run_matmul_stats_sweep.ps1` | `reports/verification/matmul_stats_sweep.log` | PASS |
| `sim/run_matmul_stats_profiles.ps1` | `reports/verification/matmul_stats_profiles.log` | PASS |

默认 Verilog 回归覆盖 11 个 testbench 入口，包括 7 组矩阵 dataset。所有日志已归档在 `reports/verification/`。

## 4. 固定向量策略

固定向量目录 `vectors/` 保存输入 block、scale、期望输出和 manifest。这样做有三个好处：

- RTL testbench 不依赖运行时随机数，评审可复验。
- Python golden model 的输出被固定成文件，便于定位差异。
- tail tile 和 sparse nonfinite 用例可以稳定重放。

关键数据集包括：

- 有限值：`matmul_4x16x64_smoke`、`matmul_5x20x96_tail`、`matmul_8x32x128_smoke`、`matmul_9x65x192_five_tiles`
- 非有限值：`matmul_3x18x64_nonfinite`、`matmul_6x33x160_nonfinite`、`matmul_7x49x224_sparse_nonfinite`
- 单列：`dot32_smoke`

## 5. 波形与证据包

当前日志已经能证明 PASS/FAIL；仓库已补入可复验的 VCD 生成路径，用于答辩展示和时序解释。本仓库把这部分归档在 `reports/evidence/`：

- 回归日志索引
- 关键 case 清单
- 波形捕获方法和 VCD 文件
- 4096 抽样方法
- finite/nonfinite/boundary 覆盖说明

已生成的小 VCD 位于 `reports/evidence/waveforms/`，覆盖 `tb_llmt_col_smoke`、`tb_llmt_col_back_to_back` 和 `tb_mx_array_smoke`。2026-05-04 已用 `sim/render_waveform_screenshots.ps1` 从这些 VCD 刷新报告级 PNG，位于 `reports/evidence/waveform_screenshots/`。VCD/截图只作为证据补充，不替代可复验日志和固定向量。

## 6. 当前限制

- 当前 testbench 是 directed regression，不是完整 constrained random verification。
- 未接入 UVM、形式验证或覆盖率工具。
- 当前 projected FP32 路径已补 FP32 subnormal directed regression；更完整的随机化 FP32 边界覆盖仍可继续扩展。
- 真实后端门级仿真、SDF 回标和功耗波形不在当前环境内完成。

这些限制不会影响 RTL 功能基线判断，但必须在提交材料中如实说明。
