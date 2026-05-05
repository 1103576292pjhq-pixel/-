# MXFP8 NPU Contest Project

这个仓库用于完成“**大语言模型块浮点计算阵列的设计与实现**”赛题，目标是交付一套可综合的纯 Verilog RTL、完整验证链路、综合/PPA脚本骨架，以及中文技术/教学文档。

当前主线：

- 设计一个 `32x16` 的 `MXFP8` 计算阵列
- 输入 `A/B` 为 `MXFP8`，输出累加为 `FP32`
- 代码语言保持纯 Verilog，当前 `llmt_col` 为三级流水，且 Stage-1 只寄存 `4x8` partial sums
- 默认 Verilog 回归已覆盖 `4x16x64`、`5x20x96` 尾 tile、`8x32x128`、`9x65x192` 四组有限值矩阵数据集，以及 `3x18x64`、`6x33x160`、`7x49x224` 三组 mixed finite / `inf` / `NaN` 矩阵数据集；其中 `7x49x224` 采用 sparse mixed-nonfinite 注入，覆盖四列 tile、单 lane 尾 tile、`K=224` 与 scale-NaN
- `4096x4096x4096` 抽样统计已支持 baseline `[-8,8]`、`finite_exp32` `[-32,32]`、`finite_exp64` `[-64,64]` 和 `sparse_nonfinite` 四档 profile；当前 `reports/precision/matmul_stats_4096x4096x4096_sparse_nonfinite_sweep.json` 记录三 seed 合计 `6037` 个 finite、`107` 个 matched `NaN`、`0` 个 nonfinite mismatch
- 文档同时覆盖：
  - 面向比赛提交的正式技术报告
  - 面向 0 基础读者的 NPU 背景教程和代码讲解

快速入口：

- 工程总览：[MAIN.md](/D:/github/-/MAIN.md)
- 当前状态：[STATUS.md](/D:/github/-/STATUS.md)
- 一键提交验收脚本：[sim/run_submission_regression.ps1](/D:/github/-/sim/run_submission_regression.ps1)
- 官方打包脚本：[tools/package_submission.py](/D:/github/-/tools/package_submission.py)
- 最终提交报告：[docs/report/submission_report.md](/D:/github/-/docs/report/submission_report.md)
- 后端接收清单：[docs/report/12_backend_handoff_checklist.md](/D:/github/-/docs/report/12_backend_handoff_checklist.md)
- 最终证据索引：[reports/evidence/final_evidence_index_2026-05-06.md](/D:/github/-/reports/evidence/final_evidence_index_2026-05-06.md)
- 总技术方案与执行计划：[docs/report/10_technical_solution_and_execution_plan.md](/D:/github/-/docs/report/10_technical_solution_and_execution_plan.md)
- 前端到后端移交与打包：[docs/report/11_frontend_handoff_and_packaging.md](docs/report/11_frontend_handoff_and_packaging.md)
- 综合环境检查：[docs/usage/02_synthesis_environment_check.md](/D:/github/-/docs/usage/02_synthesis_environment_check.md)
- 波形证据状态：[reports/evidence/waveform_capture_status.md](reports/evidence/waveform_capture_status.md)
- 综合环境结果：[reports/synthesis/environment_check_2026-05-06.md](/D:/github/-/reports/synthesis/environment_check_2026-05-06.md)
- 零基础 Primer V2：[docs/primer/README.md](docs/primer/README.md)
- 教学覆盖矩阵：[docs/teaching/coverage_plan.md](docs/teaching/coverage_plan.md)
- 逐行代码讲解：[docs/line_by_line/README.md](docs/line_by_line/README.md)
- 参赛提交与教学升级计划：[docs/admin/competition_submission_and_teaching_upgrade_plan_2026-05-04.md](docs/admin/competition_submission_and_teaching_upgrade_plan_2026-05-04.md)
- 两次 Potter 交付计划：[docs/admin/two_potter_delivery_plan_2026-05-05.md](docs/admin/two_potter_delivery_plan_2026-05-05.md)
- 多角色执行计划：[docs/admin/multi_agent_execution_plan_2026-04-29.md](/D:/github/-/docs/admin/multi_agent_execution_plan_2026-04-29.md)
- 提交就绪复核：[docs/admin/submission_readiness_review_2026-04-29.md](/D:/github/-/docs/admin/submission_readiness_review_2026-04-29.md)
- 比赛要求映射：[docs/report/00_requirements_traceability.md](/D:/github/-/docs/report/00_requirements_traceability.md)
- 提交版报告目录：[docs/report/README.md](/D:/github/-/docs/report/README.md)
- Verilog 回归脚本：[sim/run_iverilog.ps1](/D:/github/-/sim/run_iverilog.ps1)
- Python 参考模型脚本：[sim/run_python_ref.ps1](/D:/github/-/sim/run_python_ref.ps1)
- 波形烟雾脚本：[sim/run_waveform_smoke.ps1](/D:/github/-/sim/run_waveform_smoke.ps1)
- 波形截图脚本：[sim/render_waveform_screenshots.ps1](/D:/github/-/sim/render_waveform_screenshots.ps1)
- `4096x4096` 抽样统计脚本：[sim/run_matmul_stats.ps1](/D:/github/-/sim/run_matmul_stats.ps1)
- `4096x4096` 多 seed sweep 脚本：[sim/run_matmul_stats_sweep.ps1](/D:/github/-/sim/run_matmul_stats_sweep.ps1)
- `4096x4096` profile sweep 脚本：[sim/run_matmul_stats_profiles.ps1](/D:/github/-/sim/run_matmul_stats_profiles.ps1)
- 报告与证据目录：[reports/README.md](/D:/github/-/reports/README.md)
- 使用说明：[docs/usage/README.md](/D:/github/-/docs/usage/README.md)
