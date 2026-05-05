# 多角色执行计划（2026-04-29）

## 1. 计划定位

本文把 MXFP8 NPU 比赛项目后续工作拆成多个角色化 planning lane。这里的“角色”只表示职责分工和检查视角，不表示已经启动 team、tmux 或并行执行工具。

当前项目边界是 RTL handoff package。后续所有角色都必须遵守：

- 保持 RTL 纯 Verilog。
- 不伪造真实 28nm PPA。
- 不把 `.codexpotter`、`.omx` 或临时日志混入正式提交包。
- 修改 RTL 后必须重跑 Verilog 回归并更新证据。
- 外部模板、真实 28nm 库、真实 benchmark 到位前，只能写清楚方法和阻塞项。

## 2. 总体依赖顺序

推荐顺序：

1. Planner lane 关闭需求和提交范围。
2. Architect lane 固化架构边界和后端移交边界。
3. DV lane 确认现有回归、证据、波形计划和 benchmark 缺口。
4. PPA lane 准备真实后端接入检查表和模板校准项。
5. RTL lane 只处理由 Architect/DV/PPA 明确触发的低风险 RTL 事项。
6. Writer/teacher lane 统一报告、使用说明和教学材料。
7. Critic/reviewer lane 做最终一致性和 unsupported claim 审查。

没有真实 PPA 或新增赛题约束时，RTL lane 不应抢先改计算路径。

## 3. Planner lane：需求和提交闭环

| 项目 | 内容 |
| --- | --- |
| 目标 | 把赛题要求、用户要求、当前仓库产物、外部阻塞和提交动作闭环 |
| 输入 | `docs/report/00_requirements_traceability.md`、`09_submission_checklist.md`、`MAIN.md`、`STATUS.md`、主办方新通知 |
| 输出 | 更新后的需求追踪表、提交清单、最终打包范围和下一步触发条件 |
| 验收标准 | 每个赛题要求都有仓库路径、状态和证据；外部阻塞写清楚；没有把模板写成实测结果 |
| 阻塞项 | 官方模板、答辩规则、补充通知未获得 |
| 依赖 | 先于 Writer/teacher lane；收到外部规则后要重新触发 |

Planner lane 当前结论：现有 `00`、`09` 已可用；本轮新增 `10_technical_solution_and_execution_plan.md` 后，需要把索引和状态指向新总入口。

## 4. Architect lane：微架构和 handoff 边界

| 项目 | 内容 |
| --- | --- |
| 目标 | 固化 `32 x 16` output-stationary 阵列、LLMT 列、MXFP8 数值路径和系统边界 |
| 输入 | `rtl/llmt_col.v`、`rtl/mx_array_32x16.v`、`docs/report/03_architecture_and_dataflow.md`、`04_llmt_microarchitecture.md` |
| 输出 | 架构说明、接口合同、后端移交边界、不可在当前阶段误称的系统能力 |
| 验收标准 | 能解释 A/B block、scale、dot32、FP32 accumulation、valid/reset/clear；清楚说明本仓库没有 SRAM/DMA/NoC/host 接口 |
| 阻塞项 | 真实系统集成要求和后端接口约束未获得 |
| 依赖 | 先于 RTL lane 和 PPA lane |

Architect lane 当前结论：现有架构稳定；除非真实综合或 benchmark 指出瓶颈，不建议改阵列规模、pipeline latency 或接口。

## 5. RTL lane：Verilog 质量和低风险精修

| 项目 | 内容 |
| --- | --- |
| 目标 | 保持纯 Verilog RTL 可综合、接口稳定、回归可通过 |
| 输入 | `rtl/`、`tb/`、`sim/run_iverilog.ps1`、`reports/evidence/rtl_refinement_review_2026-04-28.md` |
| 输出 | 必要时的小范围 RTL 修复、变更说明、刷新后的 Verilog 回归日志 |
| 验收标准 | 不引入 SystemVerilog；不破坏顶层接口；`sim/run_iverilog.ps1` PASS；相关报告和 evidence 同步更新 |
| 阻塞项 | 当前无必须改 RTL 的证据；真实 timing/PPA 未返回 |
| 依赖 | 只能在 Architect/DV/PPA 给出明确触发后执行 |

当前建议：保持 RTL 不动。候选触发包括 S1 reduction 为最差路径、FP32 add 为最差路径、面积成为主要评分瓶颈、主办方要求 exception flag。

## 6. DV lane：回归、向量、波形和精度证据

| 项目 | 内容 |
| --- | --- |
| 目标 | 维护可复验验证链路，保证 RTL、Python 参考模型和报告证据一致 |
| 输入 | `tb/`、`sim/`、`vectors/`、`tools/mx_ref.py`、`reports/verification/`、`reports/precision/`、`reports/evidence/` |
| 输出 | 回归日志、固定向量、4096 抽样统计、波形捕获记录、coverage gap 清单 |
| 验收标准 | Verilog/Python/统计日志归档；dataset manifest 齐全；finite/nonfinite/boundary 覆盖说明可追溯 |
| 阻塞项 | 没有主办方 benchmark；没有门级网表和 SDF；若最终报告需要图片，还需从现有 VCD 截取标注截图 |
| 依赖 | 支撑 Writer/teacher lane 和 Critic/reviewer lane；RTL 改动后必须立即执行 |

DV lane 下一步：

1. 若只改文档，做轻量 grep/索引检查即可。
2. 若改 RTL 或 `tools/mx_ref.py`，重跑 `sim/run_iverilog.ps1` 和 `sim/run_python_ref.ps1`。
3. 若新增 benchmark，新增 `vectors/`、testbench wrapper、verification log、precision JSON 和 evidence 索引。
4. 若需要答辩截图，按 `reports/evidence/waveform_capture_status.md` 捕获关键波形。

## 7. PPA lane：约束、综合模板和后端检查表

| 项目 | 内容 |
| --- | --- |
| 目标 | 准备真实 28nm 后端接入路径，同时防止虚假 PPA 声明 |
| 输入 | `constraints/mx_array_32x16.sdc`、`synth/run_dc_template.tcl`、`synth/run_yosys_generic.ys`、`docs/report/07_synthesis_and_ppa.md` |
| 输出 | 校准后的约束、真实综合日志、timing/area/power 报告、后端 checklist |
| 验收标准 | 所有 PPA 数字都有工具、库、corner、约束、commit 和原始日志支撑 |
| 阻塞项 | 真实 28nm 库、综合工具、corner、目标频率和功耗 workload 未获得 |
| 依赖 | Architect lane 给出接口和 top；RTL lane 保持代码稳定 |

PPA lane 当前只能维护方法和模板。Yosys generic stat 可以做结构 sanity check，但不能写成 28nm PPA。

## 8. Writer/teacher lane：报告、使用和教学材料

| 项目 | 内容 |
| --- | --- |
| 目标 | 让评审、后端工程师和零基础队友都能读懂当前交付 |
| 输入 | `docs/report/`、`docs/usage/`、`docs/primer/`、`docs/teaching/`、`reports/evidence/` |
| 输出 | 技术报告正文、索引、使用说明、教学材料、答辩叙事 |
| 验收标准 | 中文清晰；术语一致；证据链接可达；明确区分已完成、阻塞和未来工作 |
| 阻塞项 | 官方模板和答辩规则未获得 |
| 依赖 | Planner/Architect/DV/PPA lane 的事实输入 |

Writer/teacher lane 本轮重点：

- 把 `10_technical_solution_and_execution_plan.md` 加入报告索引。
- 保持 `tech_report.md` 与 `README.md` 的章节列表同步。
- 不把教学材料写成评审证据，证据仍以 `reports/` 为准。

## 9. Critic/reviewer lane：一致性和风险审查

| 项目 | 内容 |
| --- | --- |
| 目标 | 找出 unsupported claim、陈旧状态、断链、缺失证据和风险掩盖 |
| 输入 | 全部文档入口、`reports/`、`rtl/`、`sim/`、`potter-run.log` |
| 输出 | 审查清单、必须修复项、可接受残余风险 |
| 验收标准 | 无真实 28nm PPA 虚假声明；状态文件指向当前批次；报告和证据一致；阻塞项没有被写成完成项 |
| 阻塞项 | 外部资料未获得时无法审查最终格式 |
| 依赖 | 所有 lane 输出后执行；也可在关键文档修改后轻量执行 |

本轮必须检查：

- 新文档是否出现在报告索引。
- `STATUS.md` 是否从 2026-04-28 收口状态更新到 2026-04-29 规划深化状态。
- `potter-run.log` 是否记录本批。
- 是否误写“真实 28nm PPA 已完成”。

## 10. 触发条件矩阵

| 触发条件 | 第一响应 lane | 后续 lane |
| --- | --- | --- |
| 收到官方模板/答辩规则 | Planner | Writer/teacher、Critic/reviewer |
| 收到真实 28nm 库和综合工具 | PPA | Architect、RTL、DV、Writer/teacher |
| 收到指定 benchmark | DV | Planner、Writer/teacher、Critic/reviewer |
| 综合报告显示 timing fail | PPA | Architect、RTL、DV |
| 用户要求进一步优化 RTL | Architect | RTL、DV、Critic/reviewer |
| 用户要求最终打包 | Planner | Writer/teacher、Critic/reviewer |

## 11. 当前推荐执行批次

本批只做文档和状态深化：

1. 新增 `docs/report/10_technical_solution_and_execution_plan.md`。
2. 新增本文。
3. 刷新 `docs/report/README.md` 和 `docs/report/tech_report.md` 索引。
4. 刷新根 `MAIN.md`、`STATUS.md`、`potter-run.log`。
5. 做轻量一致性检查，不改 RTL，不重跑长统计。

验收标准：后续任一角色打开仓库时，可以从根状态进入总方案，再从总方案进入报告、证据和执行计划；同时不会误以为当前已经完成真实 28nm PPA。
