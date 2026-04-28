# 2026-04-28 重启审计

## 审计目的

本文件记录 MXFP8 NPU 比赛项目在 2026-04-28 的干净重启入口。重启目标是把仓库从前期 RTL/验证原型整理成比赛可读的 RTL handoff 交付包，并明确哪些内容已经有证据、哪些内容仍是模板或阻塞项。

## 新主线

- 当前工作区：`D:\github\-`
- 当前主线文件：根目录 `MAIN.md`、`STATUS.md`、`potter-run.log`
- 当前进度文件：`.codexpotter/projects/2026/04/28/2/MAIN.md`
- 执行边界：CodexPotter 长跑主线；不启用 GitHub、PR、team、tmux 或其他 lane
- 交付边界：RTL 前端到后端移交包，不是完整 28nm GDS/PPA 交付

## 可复用资产

- `rtl/llmt_col.v`：列级 LLMT 数据路径，当前以 4 个 8-lane partial sum 寄存器和后续 merge 为主线。
- `rtl/mx_array_32x16.v`：32 x 16 output-stationary 阵列顶层。
- `tb/`：列级和阵列级 testbench，覆盖 smoke、corner、back-to-back、tail tile、mixed nonfinite 和 sparse nonfinite 数据集。
- `tools/mx_ref.py`：Python MXFP8 参考模型、向量生成和统计入口。
- `sim/run_iverilog.ps1`、`sim/run_python_ref.ps1`、`sim/run_matmul_stats*.ps1`：本地回归和统计脚本。
- `vectors/`：有限值、多 tile、尾 tile、非有限值和 sparse nonfinite 回归向量。
- `reports/verification`、`reports/precision`、`reports/evidence`、`reports/synthesis`：本轮证据包目标目录。
- `docs/report`、`docs/primer`、`docs/teaching`：比赛报告和教学资料目标目录。

## 历史运行与状态

- `.codexpotter/projects/2026/04/23/1`：前期 RTL、验证和统计推进主线，产生大量可复用技术资产。
- `.codexpotter/projects/2026/04/27/1`、`2026/04/27/2`：历史尝试保留，不删除；本轮仅把有用结论迁移到当前主线。
- `.codexpotter/projects/2026/04/28/1`：较早的 2026-04-28 尝试，作为旧尝试保留。
- `.codexpotter/projects/2026/04/28/2`：当前清洁重启主线。

历史项目目录只作为审计来源，不作为当前完成状态的直接证据。当前完成状态以后续根目录状态文件、报告、日志和证据包为准。

## 已知陈旧或需修复内容

- 根目录 `MAIN.md`、`STATUS.md` 曾出现中文乱码，本轮已作为重启状态文件重写。
- 原 `reports/matmul_stats_*.json` 根级统计文件已迁移意图到 `reports/precision/`，需要确认脚本输出路径和索引一致。
- 报告章节曾是开发阶段描述，需要改成比赛提交视角。
- `docs/report/07_synthesis_and_ppa.md` 必须明确写成 PPA 方法和后端移交说明，不得伪造真实 28nm 数据。

## 外部输入缺口

- 主办方补充通知：未获得。
- 官方提交模板：未获得。
- 答辩规则：未获得。
- 真实 28nm 标准单元库、工艺角、线载、时钟约束：未获得。
- IEEE 论文全文细节：未获得；只使用可公开核查信息。

## 重启验收口径

- 根目录 `MAIN.md` 和 `STATUS.md` 指向 2026-04-28 重启主线。
- `potter-run.log` 追加本轮重启记录和脚本执行记录。
- `docs/report/00_requirements_traceability.md` 和 `docs/report/09_submission_checklist.md` 能把比赛要求映射到仓库工件、状态和阻塞项。
- `reports/verification` 和 `reports/precision` 存放本轮实际执行日志或明确阻塞记录。
- `reports/evidence` 说明日志索引、波形捕获方法、关键用例、4096 抽样方法和边界/非有限值覆盖。
