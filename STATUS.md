# STATUS

- 当前阶段：2026-04-28 GPT5.5 重启主线，本批比赛 RTL handoff 交付包收口完成。
- 本批已完成：已确认现有 RTL/仿真/统计/报告目录结构；已补齐重启审计、比赛需求映射、提交清单；已重跑 Verilog/Python/4096 抽样统计；已收口报告第 03 到 07 章；已完成 `reports/evidence` 证据包索引；已完成 RTL 收口审查；已扩展零基础 primer 和 teaching。
- 下一步：等待主办方补充通知、提交模板、答辩规则或真实 28nm 后端环境；如继续优化，先以真实综合/PPA 或指定 benchmark 为驱动。
- 阻塞项：缺少主办方补充通知、提交模板、答辩规则、真实 28nm 标准单元库和综合工具；因此不声明真实 28nm 面积、功耗、频率或时序结果。

## 当前交付判断

- RTL 基线：存在纯 Verilog RTL，顶层接口暂保持稳定。
- 验证基线：2026-04-28 已执行 `sim/run_iverilog.ps1` 和 `sim/run_python_ref.ps1`，日志在 `reports/verification`，结果 PASS。
- 精度基线：2026-04-28 已执行 `sim/run_matmul_stats.ps1`、`sim/run_matmul_stats_sweep.ps1`、`sim/run_matmul_stats_profiles.ps1`，JSON 在 `reports/precision`。
- PPA 基线：只具备 `constraints/`、`synth/` 模板和方法说明；真实 PPA 等待后端工具链与库文件。
- 文档基线：`docs/report/03` 到 `docs/report/07` 已按比赛提交口径重写；`docs/primer` 已形成 5 篇学习路径；`docs/teaching` 已新增阵列顶层、MX helper、Python/scripts 讲解。
- 证据基线：`reports/evidence` 已包含日志索引、关键 case、4096 抽样方法、边界/非有限值覆盖和波形捕获计划。
- RTL 收口：2026-04-28 审查决定保持 RTL 不动；后续优化等待真实综合/PPA 或新增赛题约束驱动。
- 最终复查：报告 00-09、验证日志、精度 JSON、证据包和入口文档均已核对；工作树除 `.codexpotter` 进度文件外保持干净。
