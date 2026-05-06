# MXFP8 NPU 比赛主线

## 总目标

面向“MXFP8 NPU 计算阵列”比赛，整理一套可交付的 RTL 前端到后端移交包：纯 Verilog RTL、仿真与 Python 参考模型、精度统计、综合/PPA 方法模板、技术报告正文、提交清单、证据包和使用文档。

本仓库当前定位不是完整 28nm 后端实现，也不声称已经取得真实 28nm 面积、功耗或时序结果。现阶段交付边界是 RTL handoff package：提供可综合 RTL、约束与综合脚本模板、验证证据、PPA 方法说明和后端集成检查表。

## 当前主线

- 当前批次：2026-05-06 第一次比赛提交与后端 RTL handoff 包收口
- 执行模型：普通 Codex 收口，未使用 GitHub/PR/team/tmux lane
- 状态来源：根目录 `STATUS.md`、`sim/run_submission_regression.ps1`、`dist/mxfp8_npu_submission_20260506/`、`reports/verification/`、`reports/evidence/`
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
- 脚本：`sim/run_iverilog.ps1`、`sim/run_python_ref.ps1`、`sim/run_waveform_smoke.ps1`、`sim/render_waveform_screenshots.ps1`、`sim/run_submission_regression.ps1`、`sim/run_matmul_stats*.ps1`
- 报告与证据：`docs/report/submission_report.md`、`docs/report/12_backend_handoff_checklist.md`、`reports/evidence/final_evidence_index_2026-05-06.md`、`reports/evidence/boundary_case_matrix.md`、`reports/synthesis/environment_check_2026-05-06.md`
- 教学资料：继续保留在仓库源树中，第一轮正式 handoff 包不包含 `docs/primer`、`docs/teaching` 或 `docs/line_by_line`

## 2026-04-29 新增决策入口

- 总技术方案：`docs/report/10_technical_solution_and_execution_plan.md`
- 前端到后端移交与打包：`docs/report/11_frontend_handoff_and_packaging.md`
- 波形证据状态：`reports/evidence/waveform_capture_status.md`
- 波形截图：`reports/evidence/waveform_screenshots/`
- 第一次提交报告：`docs/report/submission_report.md`
- 后端接收清单：`docs/report/12_backend_handoff_checklist.md`
- 最终提交 manifest：`docs/admin/final_submission_manifest.md`
- 最终证据索引：`reports/evidence/final_evidence_index_2026-05-06.md`
- 官方提交候选包：`dist/mxfp8_npu_submission_20260506/`
- 后端 RTL filelist：`synth/rtl_filelist.f`

这些文件用于把比赛要求、用户要求、当前完成状态、后端移交边界、风险、阻塞项、后续执行优先级和提交前复核集中到可决策入口。第一轮正式包只保留 reader-facing、评审和后端接收相关入口；教学目录和历史 admin 规划文件不进入 `dist/mxfp8_npu_submission_20260506/`。这些文件不改变 RTL，也不把模板性 PPA 写成真实 28nm 结果。

## 已完成收口

- 历史审计：仓库源树已记录可复用资产、过期状态、失败/中断记录、外部缺口和本轮干净主线；历史 admin 规划文件不进入第一轮正式包。
- 需求映射：`docs/report/00_requirements_traceability.md` 与 `docs/report/09_submission_checklist.md` 已把比赛要求映射到仓库工件、完成状态和阻塞项。
- 验证基线：2026-04-28 已重跑 `sim/run_iverilog.ps1`、`sim/run_python_ref.ps1` 和 `sim/run_matmul_stats*.ps1`；日志归档在 `reports/verification`，统计归档在 `reports/precision`。
- 报告正文：`docs/report/03_architecture_and_dataflow.md` 到 `docs/report/07_synthesis_and_ppa.md` 已按 RTL handoff 交付边界重写。
- 证据包：`reports/evidence` 已包含回归日志索引、关键 case、4096 抽样方法、边界/非有限值覆盖和波形捕获说明。
- RTL 收口：已审查 `llmt_col` 与 `mx_array_32x16`，本批保持 RTL 不动，等待真实综合/PPA 或新增赛题约束驱动。
- 教学资料：仓库源树中的 `docs/primer`、`docs/teaching` 和 `docs/line_by_line` 继续作为第二轮教学 Potter 输入，不进入第一轮正式 handoff 包。
- 方案深化：`docs/report/10_technical_solution_and_execution_plan.md` 已补齐决策级总方案；历史角色化执行计划留在仓库源树，不进入第一轮正式包。
- 提交复核：当前复核入口已收敛为 `docs/report/submission_report.md`、`docs/report/09_submission_checklist.md`、`docs/admin/final_submission_manifest.md` 和最终证据索引。
- 2026-04-30 增强与验收：已加入 opt-in VCD 波形脚本与三份小 VCD；源树教学材料扩成零基础一周路径和答辩复述地图；`docs/report/11_frontend_handoff_and_packaging.md` 明确后端移交和正式包排除项；最终验收确认默认回归和波形 smoke 日志均为 PASS。
- 2026-04-30 人工审查补强：已把教学覆盖口径从“逐行完成”收紧为“答辩覆盖”，并在源树新增独立逐行 Markdown 线；已把矩阵 dataset testbench 改为 valid 窗口内锁存最后输出；已生成三张报告级波形 PNG；已重跑默认 Verilog 回归和 waveform smoke，均为 PASS。
- 2026-05-01 第二轮补强：已把 `fixed_to_fp32` 和 `fp32_add_rne` 扩展为支持 FP32 subnormal 输出，并在 `tb_llmt_col_corner` 加入 directed case；已补 `fixed_to_fp32` 逐行讲解；默认 Verilog 回归、Python golden、waveform smoke 和 PNG 截图刷新均已完成。
- 2026-05-04 复核与规划：已重跑默认 Verilog 回归、Python golden、waveform smoke 和 PNG 截图生成；源树规划把后续工作拆成提交包卫生、RTL/验证签核、综合接入、提交报告、教学总书、逐行讲解和最终打包。
- 2026-05-05 两次 Potter 边界：第一次 Potter 只做比赛提交与后端 RTL handoff 包，不做教学大扩写；第二次 Potter 在 handoff 包冻结后专门做零基础导学与逐行代码讲解。`netlist` 只在真实综合工具和库可用时生成，否则第一交付物是 RTL handoff package。
- 2026-05-06 第一次 handoff 收口：已新增 `sim/run_submission_regression.ps1`、`tools/package_submission.py`、`docs/report/submission_report.md`、`docs/report/12_backend_handoff_checklist.md`、`docs/admin/final_submission_manifest.md`、`docs/usage/02_synthesis_environment_check.md`、`reports/evidence/final_evidence_index_2026-05-06.md`、`reports/evidence/boundary_case_matrix.md`、`reports/synthesis/environment_check_2026-05-06.md`，并生成 `dist/mxfp8_npu_submission_20260506/`。release 验收与 fast 验收 verdict 均为 `PASS_WITH_EXTERNAL_SYNTH_BLOCKER`，其中 release 验收已重跑 4096 sampled stats。
- 2026-05-06 handoff 终审增强：已新增 `synth/rtl_filelist.f` 作为后端确定性 RTL 读入顺序，更新提交清单、前后端 handoff 文档、综合环境说明和最终 manifest；本轮 fast 验收再次得到 `PASS_WITH_EXTERNAL_SYNTH_BLOCKER`，重新打包后的 `dist/mxfp8_npu_submission_20260506/` 已排除 `.omx/`、`.codexpotter/`、`work/`、`.vvp`、教学目录和多余 admin 历史文件。当前第一轮包是正式提交候选包；第二轮教学 Potter 应在该包稳定后再启动。

## 仍然缺失的外部输入

- 主办方补充通知、提交模板、答辩规则和真实 28nm 库约束仍缺失。
- IEEE 全文细节不可用，只能记录公开可核查信息和不确定项。
- 本机已确认缺少 `yosys/openroad/verilator/dc_shell/genus/innovus` 和真实 28nm `.db/.lib`，PPA 只能给方法、模板和待后端补齐项。

## 后续触发条件

1. 如果拿到主办方模板或答辩规则，先更新 `docs/report/09_submission_checklist.md`，再按模板裁剪报告正文。
2. 如果拿到真实 28nm 库、SDC 要求和综合工具，先跑综合脚本并归档真实日志，再更新 PPA 章节；不要从模板推断面积、功耗或时序数字。
3. 如果新增 benchmark 或评分样例，先扩展 `vectors/` 与 `sim/` 回归，再同步 `reports/evidence` 和精度统计章节。
