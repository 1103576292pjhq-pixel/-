# STATUS

- 当前阶段：2026-04-28 GPT5.5 重启主线，正在把仓库从“验证原型”整理成“比赛 RTL handoff 交付包”。
- 本批已完成：已确认现有 RTL/仿真/统计/报告目录结构；正在补齐重启审计、需求映射、证据包和技术报告主线。
- 下一步：完成 `docs/admin/restart_audit_2026-04-28.md`，随后重跑可行回归并刷新 `reports/verification` 与 `reports/precision`。
- 阻塞项：缺少主办方补充通知、提交模板、答辩规则、真实 28nm 标准单元库和综合工具；因此不声明真实 28nm 面积、功耗、频率或时序结果。

## 当前交付判断

- RTL 基线：存在纯 Verilog RTL，顶层接口暂保持稳定。
- 验证基线：已有 Icarus Verilog 和 Python 参考模型脚本；需要在本重启批次重新执行并保存日志。
- 精度基线：已有 4096x4096x4096 抽样统计文件迁移到 `reports/precision`；需要核对脚本默认输出路径和统计索引。
- PPA 基线：只具备 `constraints/`、`synth/` 模板和方法说明；真实 PPA 等待后端工具链与库文件。
- 文档基线：`docs/report`、`docs/primer`、`docs/teaching` 已有内容，需要继续按比赛提交口径收口。
