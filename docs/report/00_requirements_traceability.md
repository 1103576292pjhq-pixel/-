# 00 赛题要求映射

本章把赛题输出要求、评分关注点和当前仓库工件逐项对应。状态只按本仓库可核查文件判断；缺少外部资料或真实工具结果的地方明确列为阻塞项。

## 1. 初赛输出要求映射

| 赛题要求 | 仓库产物 | 当前状态 | 证据或阻塞项 |
| --- | --- | --- | --- |
| 书面报告：电路实现方案、验证方案、精度测试结果、综合结果 | `docs/report/01_problem_and_goals.md` 到 `docs/report/09_submission_checklist.md` | 进行中 | 报告章节已拆分；`07_synthesis_and_ppa.md` 只能给综合模板和 PPA 方法，真实 28nm 结果阻塞于库和工具 |
| 仿真验证报告：含仿真波形图等 | `docs/report/05_verification_methodology.md`、`reports/verification/`、`reports/evidence/` | 进行中 | 已有脚本和日志目录；波形截图/生成命令需要在本轮证据包中补齐 |
| 可综合 RTL code | `rtl/llmt_col.v`、`rtl/mx_array_32x16.v`、`rtl/*.v`、`rtl/*.vh` | 基线具备 | RTL 保持纯 Verilog-2001；后续改动必须保持顶层接口稳定并重跑回归 |
| 仿真工程 | `tb/`、`sim/`、`tools/mx_ref.py`、`vectors/` | 基线具备 | 覆盖列级、阵列级、多尺寸矩阵、tail tile、mixed nonfinite、sparse nonfinite |
| 初步面积和功耗报告 | `constraints/mx_array_32x16.sdc`、`synth/`、`reports/synthesis/`、`docs/report/07_synthesis_and_ppa.md` | 模板具备，真实结果未具备 | 本机未确认商用综合工具和真实 28nm 标准单元库；不得写成真实 PPA 实测 |
| 初步分析报告与下一阶段优化思路 | `docs/report/08_optimization_and_finals_outlook.md` | 进行中 | 需要把 RTL 微架构、误差、后端风险和决赛优化路线串成评审可读叙事 |

## 2. 评分项映射

| 评分项 | 目标落点 | 当前状态 | 完成证据或待补 |
| --- | --- | --- | --- |
| 低精度块浮点格式研究 | `docs/report/02_mx_format_and_numeric_rules.md`、`tools/mx_ref.py` | 进行中 | 需明确 OCP MX v1.0 公开规则、E4M3/E8M0 解码、NaN/Inf 策略和本项目取舍 |
| 电路实现方案 | `docs/report/03_architecture_and_dataflow.md`、`docs/report/04_llmt_microarchitecture.md`、`rtl/` | 进行中 | 需从开发描述改成评审叙事：阵列、tile、流水、valid 时序、归约树 |
| 测试验证报告 | `docs/report/05_verification_methodology.md`、`reports/verification/`、`reports/evidence/` | 进行中 | 本轮需重跑脚本并保存日志；若环境缺工具，记录确切 blocker |
| 精度测试分析 | `docs/report/06_precision_results.md`、`reports/precision/` | 进行中 | 已有 4096 抽样统计文件；需核对脚本输出路径、profile 解释和 nonfinite 单独统计 |
| 物理实现报告 | `docs/report/07_synthesis_and_ppa.md`、`synth/`、`constraints/`、`reports/synthesis/` | 阻塞 | 只有 RTL handoff 方法和模板；真实 28nm 数据等待库、工艺角、综合约束和工具 |
| 面积和功耗分析 | `docs/report/07_synthesis_and_ppa.md` | 阻塞 | 可写预期分析维度，不可给虚构面积/功耗数值 |
| RTL code 功能正确 | `rtl/`、`tb/`、`sim/run_iverilog.ps1`、`sim/run_python_ref.ps1` | 待本轮复验 | 前期记录为通过；本轮必须生成新的 `reports/verification/*.log` |
| RTL code 实现高效性 | `rtl/llmt_col.v`、`rtl/mx_array_32x16.v`、`docs/report/04_llmt_microarchitecture.md` | 部分具备 | 当前有 32-lane dot、4x8 partial sum、三级流水；是否继续优化需以回归不退化为前提 |
| 代码风格 | `rtl/`、`docs/usage/README.md` | 部分具备 | 维持纯 Verilog；避免 SystemVerilog 语法；补齐关键接口说明 |
| 报告逻辑清晰 | `docs/report/README.md`、`docs/report/tech_report.md` | 进行中 | 需要章节之间统一术语和证据引用 |
| 创新性/专项突出 | `docs/report/08_optimization_and_finals_outlook.md`、`docs/primer/` | 进行中 | 突出 MXFP8、非有限值语义、可复验向量、零基础教学线 |

## 3. 外部输入缺口

- 主办方补充通知：未获得；可能影响最终提交格式和答辩材料。
- 官方提交模板：未获得；当前按章节化 Markdown 技术报告准备。
- 答辩规则：未获得；当前只准备可解释的报告、证据索引和教学材料。
- 真实 28nm 标准单元库与工艺角：未获得；阻塞真实面积、功耗和时序。
- IEEE 全文：未获得；仅引用公开可核查信息，不把不可访问细节写成确定结论。

## 4. 当前优先级

1. 重跑 Verilog/Python/统计脚本，生成本轮可追踪日志。
2. 用 `reports/evidence` 把每个报告结论链接到日志、向量、统计文件或波形方法。
3. 收口报告第 03 到 07 章，尤其是 PPA 章节的边界说明。
4. 补齐提交清单中的阻塞项和最终打包规则。
