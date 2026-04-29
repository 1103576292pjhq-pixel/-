# 09 提交清单

本清单用于最终打包前逐项检查。状态分为：`可提交`、`可提交，外部阻塞真实结果`、`需补齐`、`外部阻塞`。

## 1. 建议提交包结构

| 类别 | 路径 | 状态 | 检查口径 |
| --- | --- | --- | --- |
| 纯 Verilog RTL | `rtl/` | 可提交 | 不引入 SystemVerilog；顶层接口保持稳定；2026-04-28 回归已通过 |
| Testbench | `tb/` | 可提交 | 覆盖列级、阵列级、tail tile、mixed nonfinite、sparse nonfinite |
| 仿真脚本 | `sim/` | 可提交 | `run_iverilog.ps1`、`run_python_ref.ps1`、`run_matmul_stats*.ps1` 已在 2026-04-28 执行并归档日志 |
| Python 参考模型 | `tools/mx_ref.py` | 可提交 | 作为 MXFP8 golden model 和统计工具；自检日志已归档 |
| 固定向量 | `vectors/` | 可提交 | manifest、输入 hex、期望输出齐全 |
| 技术报告 | `docs/report/` | 可提交 | 第 03 到 07 章已和本轮证据同步；第 10 章提供总技术方案和执行计划入口；最终版等待主办方模板裁剪 |
| 提交就绪复核 | `docs/admin/submission_readiness_review_2026-04-29.md` | 可提交 | 逐项列出初赛要求、当前证据、缺口、后端 handoff 边界和禁止写法 |
| 使用文档 | `docs/usage/` | 可提交 | 已说明环境、脚本、常见失败和输出目录 |
| 教学资料 | `docs/primer/`、`docs/teaching/` | 可提交 | 已覆盖零基础路径和核心代码；完整逐文件扩展可作为后续教学增强 |
| 综合模板 | `synth/`、`constraints/` | 可提交，外部阻塞真实结果 | 只作为后端移交模板，不当作真实 28nm PPA |
| 验证证据 | `reports/verification/` | 可提交 | 已保存本轮日志和结果摘要 |
| 精度证据 | `reports/precision/` | 可提交 | 已保存 4096 抽样统计和 profile 解释 |
| 证据索引 | `reports/evidence/` | 可提交 | 已链接日志、统计、向量、波形方法和边界覆盖 |
| 综合/PPA说明 | `reports/synthesis/`、`docs/report/07_synthesis_and_ppa.md` | 外部阻塞 | 明确列出缺少真实 28nm 库和工具 |

## 2. 提交前必须通过或记录

- Verilog 回归：运行 `sim/run_iverilog.ps1`，日志归档到 `reports/verification/iverilog_default.log`。
- Python 自检：运行 `sim/run_python_ref.ps1`，日志归档到 `reports/verification/python_ref_default.log`。
- 单次 4096 抽样：运行 `sim/run_matmul_stats.ps1`，结果归档到 `reports/precision/`。
- 多 seed sweep：运行 `sim/run_matmul_stats_sweep.ps1`，结果归档到 `reports/precision/`。
- Profile sweep：运行 `sim/run_matmul_stats_profiles.ps1`，结果归档到 `reports/precision/`。
- 如果任何脚本因环境缺失失败，必须在日志和 `STATUS.md` 记录 exact blocker，不能只写“未完成”。

## 3. 不允许出现在提交材料中的说法

- 不允许声称已有真实 28nm 面积、功耗、频率或时序结果，除非实际使用了对应工艺库和工具。
- 不允许把 synthesis template 当作 signoff 报告。
- 不允许把前期 Potter/开发日志当作评审证据，除非报告链接到实际文件、脚本输出或统计 JSON。
- 不允许混入 `.codexpotter`、`.omx`、运行日志缓存或临时审查文件作为正式提交物。

## 4. 当前阻塞项

- 主办方补充通知、提交模板和答辩规则未获得。
- 真实 28nm 标准单元库、工艺角、线载模型和综合工具未获得。
- 波形截图尚未实采；VCD/截图生成方法已记录在 `reports/evidence/waveform_capture_status.md`。
- 主办方正式模板未获得；当前 Markdown 章节需在拿到模板后裁剪成最终版式。

## 5. 最终打包建议

正式包建议只包含 reader-facing 和评审相关内容：

- `rtl/`
- `tb/`
- `tools/`
- `sim/`
- `vectors/`
- `constraints/`
- `synth/`
- `docs/report/`
- `docs/usage/`
- `docs/primer/`
- `docs/teaching/`
- `reports/verification/`
- `reports/precision/`
- `reports/evidence/`
- `reports/synthesis/`
- `README.md`
- `MAIN.md`
- `STATUS.md`

打包前优先确认 `docs/report/10_technical_solution_and_execution_plan.md`、`docs/admin/submission_readiness_review_2026-04-29.md` 与根 `STATUS.md` 的完成状态一致。
