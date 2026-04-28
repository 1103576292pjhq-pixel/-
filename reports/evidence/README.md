# Evidence Package

本目录把比赛报告中的关键结论链接到可复验文件。报告正文引用结论时，优先引用这里的索引，再追到原始日志、JSON 或向量目录。

## 文件索引

| 文件 | 用途 |
| --- | --- |
| `regression_log_index.md` | Verilog、Python、4096 抽样脚本日志索引 |
| `key_case_list.md` | 固定向量和 testbench 覆盖的关键 case |
| `sampling_4096_method.md` | 4096x4096x4096 抽样统计方法 |
| `boundary_nonfinite_coverage.md` | finite、tail、Inf/NaN、sparse nonfinite、dynamic range 边界覆盖说明 |
| `waveform_capture_status.md` | 波形证据现状和后续捕获方法 |

## 当前证据状态

- 2026-04-28 Verilog 默认回归：PASS，见 `../verification/iverilog_default.log`
- 2026-04-28 Python 参考模型自检：PASS，见 `../verification/python_ref_default.log`
- 2026-04-28 4096 抽样 profile：PASS，见 `../precision/matmul_stats_4096x4096x4096_profiles.json`
- 真实 28nm PPA：未完成，阻塞于标准单元库和综合工具，不在本证据包中伪造
