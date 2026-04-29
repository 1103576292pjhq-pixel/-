# MXFP8 NPU 比赛主线

## 总目标

面向“MXFP8 NPU 计算阵列”比赛，整理一套可交付的 RTL 前端到后端移交包：纯 Verilog RTL、仿真与 Python 参考模型、精度统计、综合/PPA 方法模板、技术报告正文、提交清单、证据包、使用文档，以及面向零基础队友的学习资料。

本仓库当前定位不是完整 28nm 后端实现，也不声称已经取得真实 28nm 面积、功耗或时序结果。现阶段交付边界是 RTL handoff package：提供可综合 RTL、约束与综合脚本模板、验证证据、PPA 方法说明和后端集成检查表。

## 当前主线

- 当前批次：2026-04-29 提交就绪复核与证据链收口
- 执行模型：GPT5.5 / CodexPotter 长跑主线
- 状态来源：根目录 `STATUS.md`、`potter-run.log`、当前 `.codexpotter/projects/2026/04/29/2/MAIN.md`
- 禁止项：不删除历史 `.codexpotter` 项目；不使用 GitHub/PR/team/tmux lane；不把模板或方法描述写成真实 28nm PPA 实测结论

## 技术基线

- 数据流：output-stationary
- 块粒度：K = 32
- 阵列规模：32 x 16
- 数值路径：MXFP8 E4M3 元素、E8M0 scale、dot32 固定点归约、FP32 累加
- RTL 语言：纯 Verilog-2001
- 参考模型：`tools/mx_ref.py`
- 主要 RTL：`rtl/llmt_col.v`、`rtl/mx_array_32x16.v`

## 已有资产

- RTL：`llmt_col` 三段流水、`mx_array_32x16` 阵列顶层、MX decode 和 FP32 辅助模块
- Testbench：列级 smoke/corner/back-to-back，阵列级多尺寸 dataset 回归
- 向量：finite-only、tail tile、mixed nonfinite、sparse nonfinite、最多 5 个列 tile 的矩阵数据集
- 脚本：`sim/run_iverilog.ps1`、`sim/run_python_ref.ps1`、`sim/run_matmul_stats*.ps1`
- 报告骨架：`docs/report`、`reports/verification`、`reports/precision`、`reports/evidence`、`reports/synthesis`
- 教学骨架：`docs/primer`、`docs/teaching`

## 2026-04-29 新增决策入口

- 总技术方案：`docs/report/10_technical_solution_and_execution_plan.md`
- 多角色执行计划：`docs/admin/multi_agent_execution_plan_2026-04-29.md`
- 提交就绪复核：`docs/admin/submission_readiness_review_2026-04-29.md`

这些文件用于把比赛要求、用户要求、当前完成状态、后端移交边界、风险、阻塞项、后续执行优先级和提交前复核集中到可决策入口。它们不改变 RTL，也不把模板性 PPA 写成真实 28nm 结果。

## 已完成收口

- 历史审计：`docs/admin/restart_audit_2026-04-28.md` 已记录可复用资产、过期状态、失败/中断记录、外部缺口和本轮干净主线。
- 需求映射：`docs/report/00_requirements_traceability.md` 与 `docs/report/09_submission_checklist.md` 已把比赛要求映射到仓库工件、完成状态和阻塞项。
- 验证基线：2026-04-28 已重跑 `sim/run_iverilog.ps1`、`sim/run_python_ref.ps1` 和 `sim/run_matmul_stats*.ps1`；日志归档在 `reports/verification`，统计归档在 `reports/precision`。
- 报告正文：`docs/report/03_architecture_and_dataflow.md` 到 `docs/report/07_synthesis_and_ppa.md` 已按 RTL handoff 交付边界重写。
- 证据包：`reports/evidence` 已包含回归日志索引、关键 case、4096 抽样方法、边界/非有限值覆盖和波形捕获说明。
- RTL 收口：已审查 `llmt_col` 与 `mx_array_32x16`，本批保持 RTL 不动，等待真实综合/PPA 或新增赛题约束驱动。
- 教学资料：`docs/primer` 与 `docs/teaching` 已扩展为零基础队友一周内可跟读的学习路径。
- 方案深化：`docs/report/10_technical_solution_and_execution_plan.md` 已补齐决策级总方案；`docs/admin/multi_agent_execution_plan_2026-04-29.md` 已补齐角色化执行计划。
- 提交复核：`docs/admin/submission_readiness_review_2026-04-29.md` 已逐项收口初赛要求、证据链、后端 handoff 边界、禁止写法和打包建议。

## 仍然缺失的外部输入

- 主办方补充通知、提交模板、答辩规则和真实 28nm 库约束仍缺失。
- IEEE 全文细节不可用，只能记录公开可核查信息和不确定项。
- 本机未确认可用商用综合工具与 28nm 标准单元库，PPA 只能给方法、模板和待后端补齐项。

## 后续触发条件

1. 如果拿到主办方模板或答辩规则，先更新 `docs/report/09_submission_checklist.md`，再按模板裁剪报告正文。
2. 如果拿到真实 28nm 库、SDC 要求和综合工具，先跑综合脚本并归档真实日志，再更新 PPA 章节；不要从模板推断面积、功耗或时序数字。
3. 如果新增 benchmark 或评分样例，先扩展 `vectors/` 与 `sim/` 回归，再同步 `reports/evidence` 和精度统计章节。
