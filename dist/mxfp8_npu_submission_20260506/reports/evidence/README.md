# Evidence Package

本目录把比赛报告中的关键结论链接到可复验文件。报告正文引用结论时，优先引用这里的索引，再追到原始日志、JSON 或向量目录。

## 文件索引

| 文件 | 用途 |
| --- | --- |
| `regression_log_index.md` | Verilog、Python、4096 抽样脚本日志索引 |
| `key_case_list.md` | 固定向量和 testbench 覆盖的关键 case |
| `sampling_4096_method.md` | 4096x4096x4096 抽样统计方法 |
| `boundary_nonfinite_coverage.md` | finite、tail、Inf/NaN、sparse nonfinite、dynamic range 边界覆盖说明 |
| `final_evidence_index_2026-05-06.md` | 最终提交版证据映射总索引 |
| `boundary_case_matrix.md` | 边界 case 与 RTL/testbench/vector/log/JSON/report 对照矩阵 |
| `rtl_refinement_review_2026-04-28.md` | 本轮 RTL 收口审查结论和保持 RTL 不动的依据 |
| `waveform_capture_status.md` | 波形证据现状、VCD 文件、截图脚本和 PNG 说明 |
| `waveform_screenshots/` | 从 VCD 导出的报告级 PNG 截图 |

提交就绪复核见 `final_evidence_index_2026-05-06.md`、`../../docs/report/submission_report.md` 和 `../../docs/admin/final_submission_manifest.md`。这些文件不替代原始日志和 JSON，而是把本目录证据映射到初赛要求、后端 handoff 边界、正式包边界和禁止写法。

## 当前证据状态

- 2026-05-06 Verilog 默认回归：PASS，见 `../verification/iverilog_default.log`
- 2026-05-06 波形 smoke：PASS，见 `../verification/waveform_smoke.log` 和 `waveforms/*.vcd`
- 2026-05-06 报告级波形截图：已刷新，见 `waveform_screenshots/*.png`
- 2026-05-06 Python 参考模型自检：PASS，见 `../verification/python_ref_default.log`
- 2026-05-06 4096 抽样 profile release 口径复验：PASS，见 `../precision/matmul_stats_4096x4096x4096_profiles.json` 和 `../verification/matmul_stats_profiles.log`
- 2026-05-06 最终证据索引：`final_evidence_index_2026-05-06.md`
- 2026-05-06 边界 case 矩阵：`boundary_case_matrix.md`
- 2026-04-28 RTL 收口审查：保持 `llmt_col` 与 `mx_array_32x16` 不动，见 `rtl_refinement_review_2026-04-28.md`
- 真实 28nm PPA：未完成，阻塞于标准单元库和综合工具，不在本证据包中伪造
