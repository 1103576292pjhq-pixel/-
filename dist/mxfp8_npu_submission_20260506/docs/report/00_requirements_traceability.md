# 00 赛题要求映射

本章把赛题输出要求、评分关注点和当前仓库工件逐项对应。状态只按本仓库可核查文件判断；缺少外部资料或真实工具结果的地方明确列为阻塞项。

## 1. 初赛输出要求映射

| 赛题要求 | 仓库产物 | 当前状态 | 证据或阻塞项 |
| --- | --- | --- | --- |
| 书面报告：电路实现方案、验证方案、精度测试结果、综合结果 | `docs/report/01_problem_and_goals.md` 到 `docs/report/10_technical_solution_and_execution_plan.md` | 可作为初赛报告正文 | `03` 到 `07` 已按 RTL handoff 边界重写；`10` 汇总技术方案、执行计划和后端边界；提交就绪复核见 `docs/admin/submission_readiness_review_2026-04-29.md`；`07_synthesis_and_ppa.md` 只给综合模板和 PPA 方法，真实 28nm 结果阻塞于库和工具 |
| 仿真验证报告：含仿真波形图等 | `docs/report/05_verification_methodology.md`、`reports/verification/`、`reports/evidence/` | 日志、VCD 和 PNG 截图证据具备 | 2026-05-01 默认回归、Python golden、波形 smoke 日志、VCD 和 PNG 截图已刷新；证据见 `reports/evidence/waveform_capture_status.md` |
| 可综合 RTL code | `rtl/llmt_col.v`、`rtl/mx_array_32x16.v`、`rtl/*.v`、`rtl/*.vh` | 基线具备 | RTL 保持纯 Verilog-2001；后续改动必须保持顶层接口稳定并重跑回归 |
| 仿真工程 | `tb/`、`sim/`、`tools/mx_ref.py`、`vectors/` | 基线具备 | 覆盖列级、阵列级、多尺寸矩阵、tail tile、mixed nonfinite、sparse nonfinite |
| 初步面积和功耗报告 | `constraints/mx_array_32x16.sdc`、`synth/`、`reports/synthesis/`、`docs/report/07_synthesis_and_ppa.md` | 模板具备，真实结果未具备 | 本机未确认商用综合工具和真实 28nm 标准单元库；不得写成真实 PPA 实测 |
| 初步分析报告与下一阶段优化思路 | `docs/report/08_optimization_and_finals_outlook.md` | 可提交 | 已串联 RTL 微架构、误差、后端风险和决赛优化路线；后续只需按主办方模板裁剪 |

## 2. 评分项映射

| 评分项 | 目标落点 | 当前状态 | 完成证据或待补 |
| --- | --- | --- | --- |
| 低精度块浮点格式研究 | `docs/report/02_mx_format_and_numeric_rules.md`、`tools/mx_ref.py` | 可提交 | 已说明 OCP MX v1.0 公开规则、E4M3/E8M0 解码、NaN/Inf 策略和本项目取舍 |
| 电路实现方案 | `docs/report/03_architecture_and_dataflow.md`、`docs/report/04_llmt_microarchitecture.md`、`rtl/` | 可提交 | 已按评审叙事说明阵列、tile、流水、valid 时序和归约树 |
| 测试验证报告 | `docs/report/05_verification_methodology.md`、`reports/verification/`、`reports/evidence/` | 可提交 | 2026-05-01 已刷新默认回归日志、Python golden 日志、小 VCD 与报告级 PNG；后端门级验证仍等待真实综合环境 |
| 精度测试分析 | `docs/report/06_precision_results.md`、`reports/precision/` | 可提交 | 4096 抽样统计、profile 解释和 nonfinite 单独统计已归档 |
| 物理实现报告 | `docs/report/07_synthesis_and_ppa.md`、`synth/`、`constraints/`、`reports/synthesis/` | 阻塞 | 只有 RTL handoff 方法和模板；真实 28nm 数据等待库、工艺角、综合约束和工具 |
| 面积和功耗分析 | `docs/report/07_synthesis_and_ppa.md` | 阻塞 | 可写预期分析维度，不可给虚构面积/功耗数值 |
| RTL code 功能正确 | `rtl/`、`tb/`、`sim/run_iverilog.ps1`、`sim/run_python_ref.ps1` | 已复验 | 2026-05-01 默认 Verilog 回归与 Python golden 均已刷新到 `reports/verification/*.log` |
| RTL code 实现高效性 | `rtl/llmt_col.v`、`rtl/mx_array_32x16.v`、`docs/report/04_llmt_microarchitecture.md` | 基线具备 | 当前有 32-lane dot、4x8 partial sum、三级流水；后续优化需由真实 PPA 或新增 benchmark 驱动 |
| 代码风格 | `rtl/`、`docs/usage/README.md` | 基线具备 | 维持纯 Verilog；避免 SystemVerilog 语法；关键接口说明已归入报告和 usage |
| 报告逻辑清晰 | `docs/report/README.md`、`docs/report/tech_report.md`、`docs/report/10_technical_solution_and_execution_plan.md`、`docs/admin/submission_readiness_review_2026-04-29.md` | 基线具备 | 章节顺序、术语边界、总方案入口、提交就绪复核和证据引用已统一；最终格式等待主办方模板 |
| 创新性/专项突出 | `docs/report/08_optimization_and_finals_outlook.md`、`docs/primer/` | 基线具备 | 突出 MXFP8、非有限值语义、可复验向量、零基础教学线 |

## 3. 外部输入缺口

- 主办方补充通知：未获得；可能影响最终提交格式和答辩材料。
- 官方提交模板：未获得；当前按章节化 Markdown 技术报告准备。
- 答辩规则：未获得；当前只准备可解释的报告、证据索引和教学材料。
- 真实 28nm 标准单元库与工艺角：未获得；阻塞真实面积、功耗和时序。
- IEEE 全文：未获得；仅引用公开可核查信息，不把不可访问细节写成确定结论。

## 4. 后续优先级

1. 若收到主办方提交模板或答辩规则，按模板裁剪 `docs/report/` 和 `09_submission_checklist.md`。
2. 若获得真实 28nm 库和综合工具，先生成真实综合日志，再更新 `07_synthesis_and_ppa.md` 与 `reports/synthesis/`。
3. 若新增 benchmark 或评分样例，先扩展 `vectors/` 和 `sim/`，再同步 `reports/evidence/` 与 `06_precision_results.md`。
4. 若需要演示材料，按 `reports/evidence/waveform_capture_status.md` 捕获关键波形截图。
