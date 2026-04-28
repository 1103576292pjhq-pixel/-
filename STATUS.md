# STATUS

- 当前阶段：2026-04-28 GPT5.5 重启主线，正在把仓库从“验证原型”整理成“比赛 RTL handoff 交付包”。
- 本批已完成：已确认现有 RTL/仿真/统计/报告目录结构；已补齐重启审计、比赛需求映射、提交清单；已重跑 Verilog/Python/4096 抽样统计；已收口报告第 03 到 07 章。
- 下一步：完成 `reports/evidence`，把日志、统计、关键用例、波形方法和边界覆盖串成证据包。
- 阻塞项：缺少主办方补充通知、提交模板、答辩规则、真实 28nm 标准单元库和综合工具；因此不声明真实 28nm 面积、功耗、频率或时序结果。

## 当前交付判断

- RTL 基线：存在纯 Verilog RTL，顶层接口暂保持稳定。
- 验证基线：2026-04-28 已执行 `sim/run_iverilog.ps1` 和 `sim/run_python_ref.ps1`，日志在 `reports/verification`，结果 PASS。
- 精度基线：2026-04-28 已执行 `sim/run_matmul_stats.ps1`、`sim/run_matmul_stats_sweep.ps1`、`sim/run_matmul_stats_profiles.ps1`，JSON 在 `reports/precision`。
- PPA 基线：只具备 `constraints/`、`synth/` 模板和方法说明；真实 PPA 等待后端工具链与库文件。
- 文档基线：`docs/report/03` 到 `docs/report/07` 已按比赛提交口径重写；`docs/primer`、`docs/teaching` 仍需继续扩展。
