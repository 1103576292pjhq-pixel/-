# Reports Directory

比赛交付物相关结果统一按下面四类组织：

- `reports/verification/`：Verilog / Python 回归日志与验证摘要
- `reports/precision/`：误差统计 JSON、抽样报告、多 seed/profile 结果
- `reports/synthesis/`：综合、面积、功耗、时序报告
- `reports/evidence/`：证据索引、波形说明、截图清单、评审辅助材料

当前状态：

- `verification/` 与 `precision/` 已在 2026-04-28 重跑并落地
- `synthesis/` 仍是模板位，因为本机暂无可用综合工具
- `evidence/` 当前以日志和波形说明为主，真实截图仍待补充

当前可引用证据：

- `reports/verification/iverilog_default.log`：默认 Verilog 回归 PASS
- `reports/verification/python_ref_default.log`：Python 参考模型 self-test PASS
- `reports/precision/matmul_stats_4096x4096x4096_profiles.json`：4096 抽样 profile 总览
- `reports/precision/matmul_stats_4096x4096x4096_sparse_nonfinite_sweep.json`：sparse nonfinite 三 seed 统计
