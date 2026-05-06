# 09 提交清单

本清单用于最终打包前逐项检查。状态分为：`可提交`、`可提交，外部阻塞真实结果`、`需补齐`、`外部阻塞`。

## 1. 建议提交包结构

| 类别 | 路径 | 状态 | 检查口径 |
| --- | --- | --- | --- |
| 纯 Verilog RTL | `rtl/` | 可提交 | 不引入 SystemVerilog；顶层接口保持稳定；2026-05-06 fast/release 验收口径为 `PASS_WITH_EXTERNAL_SYNTH_BLOCKER` |
| Testbench | `tb/` | 可提交 | 覆盖列级、阵列级、tail tile、mixed nonfinite、sparse nonfinite |
| 仿真脚本 | `sim/` | 可提交 | `run_submission_regression.ps1 -Fast` 作为 2026-05-06 提交前快速验收入口；长统计证据已归档 |
| Python 参考模型 | `tools/mx_ref.py` | 可提交 | 作为 MXFP8 golden model 和统计工具；自检日志已归档 |
| 固定向量 | `vectors/` | 可提交 | manifest、输入 hex、期望输出齐全 |
| 技术报告 | `docs/report/` | 可提交 | `docs/report/submission_report.md` 是第一入口；第 11 章说明前端到后端 handoff/打包口径；第 12 章说明后端接收清单 |
| 最终提交 manifest | `docs/admin/final_submission_manifest.md` | 可提交 | 正式包唯一 admin 文档，定义 include/exclude 边界 |
| 使用文档 | `docs/usage/` | 可提交 | 已说明环境、脚本、常见失败和输出目录 |
| 教学资料 | `docs/primer/`、`docs/teaching/`、`docs/line_by_line/` | 不进入第一轮正式包 | 继续保留在仓库中，作为第二轮教学 Potter 的输入；不是当前 formal RTL handoff package 的评审/后端首包内容 |
| 综合模板 | `synth/`、`constraints/` | 可提交，外部阻塞真实结果 | `synth/rtl_filelist.f` 给出确定性 RTL 读入顺序；其余脚本只作为后端移交模板，不当作真实 28nm PPA |
| 验证证据 | `reports/verification/` | 可提交 | 已保存本轮日志和结果摘要，含默认回归和波形 smoke 日志 |
| 精度证据 | `reports/precision/` | 可提交 | 已保存 4096 抽样统计和 profile 解释 |
| 证据索引 | `reports/evidence/` | 可提交 | 已链接日志、统计、向量、波形方法和边界覆盖 |
| 综合/PPA说明 | `reports/synthesis/`、`docs/report/07_synthesis_and_ppa.md` | 外部阻塞 | 明确列出缺少真实 28nm 库和工具 |

## 2. 提交前必须通过或记录

- 快速提交验收：运行 `sim/run_submission_regression.ps1 -Fast`，得到清晰 verdict。
- Verilog 回归：由 fast 验收调用 `sim/run_iverilog.ps1`，日志归档到 `reports/verification/iverilog_default.log`。
- Python 自检：由 fast 验收调用 `sim/run_python_ref.ps1`，日志归档到 `reports/verification/python_ref_default.log`。
- 波形 smoke：由 fast 验收调用 `sim/run_waveform_smoke.ps1`，日志归档到 `reports/verification/waveform_smoke.log`，VCD 归档到 `reports/evidence/waveforms/`。
- 4096 抽样、multi-seed sweep 和 profile sweep：release 验收已归档到 `reports/precision/`；fast 模式只检查基线证据存在，不声称重跑长统计。
- 如果任何脚本因环境缺失失败，必须在日志和 `STATUS.md` 记录 exact blocker，不能只写“未完成”。

## 3. 不允许出现在提交材料中的说法

- 不允许声称已有真实 28nm 面积、功耗、频率或时序结果，除非实际使用了对应工艺库和工具。
- 不允许把 synthesis template 当作 signoff 报告。
- 不允许把前期 Potter/开发日志当作评审证据，除非报告链接到实际文件、脚本输出或统计 JSON。
- 不允许混入 `.codexpotter`、`.omx`、运行日志缓存或临时审查文件作为正式提交物。

## 4. 当前阻塞项

- 主办方补充通知、提交模板和答辩规则未获得。
- 真实 28nm 标准单元库、工艺角、线载模型和综合工具未获得。
- 小 VCD 已由 `sim/run_waveform_smoke.ps1` 生成；报告级 PNG 已由 `sim/render_waveform_screenshots.ps1` 生成并归档到 `reports/evidence/waveform_screenshots/`。
- 主办方正式模板未获得；当前 Markdown 章节需在拿到模板后裁剪成最终版式。

## 5. 最终打包建议

正式包建议只包含 reader-facing、评审和后端接收相关内容。2026-05-06 第一轮正式包入口是：

- `docs/report/submission_report.md`
- `docs/admin/final_submission_manifest.md`
- `dist/mxfp8_npu_submission_20260506/`

第一轮正式包建议包含：

- `rtl/`
- `tb/`
- `tools/`
- `sim/`
- `vectors/`
- `constraints/`
- `synth/`
- `docs/report/`
- `docs/usage/`
- `docs/admin/final_submission_manifest.md`
- `reports/verification/`
- `reports/precision/`
- `reports/evidence/`
- `reports/synthesis/`
- `README.md`
- `MAIN.md`
- `STATUS.md`

第一轮正式包不包含 `docs/primer/`、`docs/teaching/`、`docs/line_by_line/` 或历史 `docs/admin/` 规划文件。教学资料继续保留在仓库中，后续第二轮 Potter 可扩展为学习材料；它们不属于本次 formal RTL handoff package。

打包前优先确认 `docs/report/submission_report.md`、`docs/admin/final_submission_manifest.md` 与根 `STATUS.md` 的完成状态一致。

前端到后端移交的具体文件清单、顶层接口、脚本模板、禁止项和打包检查见 `docs/report/11_frontend_handoff_and_packaging.md`。
