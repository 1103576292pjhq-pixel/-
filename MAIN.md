# MXFP8 NPU 比赛重启主线

## 总目标

面向“MXFP8 NPU 计算阵列”比赛，整理一套可交付的 RTL 前端到后端移交包：纯 Verilog RTL、仿真与 Python 参考模型、精度统计、综合/PPA 方法模板、技术报告正文、提交清单、证据包、使用文档，以及面向零基础队友的学习资料。

本仓库当前定位不是完整 28nm 后端实现，也不声称已经取得真实 28nm 面积、功耗或时序结果。现阶段交付边界是 RTL handoff package：提供可综合 RTL、约束与综合脚本模板、验证证据、PPA 方法说明和后端集成检查表。

## 当前主线

- 重启日期：2026-04-28
- 执行模型：GPT5.5 / CodexPotter 长跑主线
- 状态来源：根目录 `STATUS.md`、`potter-run.log`、当前 `.codexpotter/projects/2026/04/28/2/MAIN.md`
- 当前批次：比赛交付重启、需求映射、证据包和报告收口
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

## 缺口

- 主办方补充通知、提交模板、答辩规则和真实 28nm 库约束仍缺失
- IEEE 全文细节不可用，只能记录公开可核查信息和不确定项
- 本机未确认可用商用综合工具与 28nm 标准单元库，PPA 只能给方法、模板和待后端补齐项
- 报告、证据包和零基础教学资料仍需按比赛提交口径收口

## 下一步

1. 完成历史审计和干净重启入口。
2. 将比赛要求映射到仓库工件、完成状态和阻塞项。
3. 重跑可行的 Verilog/Python/统计脚本，并把日志和统计归档。
4. 收口 `docs/report` 技术报告正文。
5. 完成 `reports/evidence` 证据索引。
6. 在不破坏稳定接口的前提下审视 RTL 竞赛化改进点。
7. 扩展零基础 primer 和逐文件教学文档。
