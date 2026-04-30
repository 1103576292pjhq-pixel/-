# 2026-04-29 提交就绪复核

## 1. 复核结论

当前仓库已经达到“初赛 RTL handoff package”的可提交基线：纯 Verilog RTL、testbench、Python golden model、固定向量、4096 抽样统计、报告正文、证据索引、综合/PPA 模板和使用/教学文档均已具备。

当前仓库尚未达到“真实 28nm 后端/PPA 交付”的标准。真实面积、功耗、频率、WNS/TNS、门级仿真和功耗活动率仍阻塞于外部 28nm 标准单元库、综合工具、corner、约束和 workload。报告中只能交付方法、模板、检查表和后续触发条件，不能写成真实实测结论。

本次复核未发现必须修改 RTL 的证据。`llmt_col` 和 `mx_array_32x16` 应保持当前稳定基线，后续 RTL 优化应由真实综合最差路径、主办方 benchmark 或新增评分约束驱动。

## 2. 初赛要求逐项状态

| 初赛要求 | 当前状态 | 仓库证据 | 缺口/触发条件 |
| --- | --- | --- | --- |
| 电路实现方案 | 可提交 | `docs/report/03_architecture_and_dataflow.md`、`docs/report/04_llmt_microarchitecture.md`、`docs/report/10_technical_solution_and_execution_plan.md` | 主办方模板到位后按版式裁剪 |
| 可综合 RTL code | 可提交 | `rtl/mx_array_32x16.v`、`rtl/llmt_col.v`、`rtl/*.v`、`rtl/*.vh` | 真实综合返回 timing/area 后再考虑 retiming 或资源调整 |
| 仿真工程 | 可提交 | `tb/`、`sim/run_iverilog.ps1`、`sim/run_python_ref.ps1`、`vectors/` | 若主办方提供 benchmark，需要补向量和 testbench |
| 仿真验证报告 | 可提交，展示材料已增强 | `docs/report/05_verification_methodology.md`、`reports/verification/README.md`、`reports/evidence/regression_log_index.md`、`reports/evidence/waveforms/` | 已有小 VCD；若最终报告需要图片，可从 VCD 截图 |
| 精度测试结果 | 可提交 | `docs/report/06_precision_results.md`、`reports/precision/matmul_stats_4096x4096x4096_profiles.json` | 若有指定 benchmark，以主办方 benchmark 补充或替换当前随机抽样 |
| 综合结果 | 部分完成，真实结果外部阻塞 | `docs/report/07_synthesis_and_ppa.md`、`constraints/mx_array_32x16.sdc`、`synth/run_dc_template.tcl`、`synth/run_yosys_generic.ys` | 需要真实 28nm `.db`、工具、corner、约束和原始综合日志 |
| 面积/功耗报告 | 外部阻塞 | `reports/synthesis/README.md`、`docs/report/07_synthesis_and_ppa.md` | 当前只能写分析口径，不能给数值 |
| 初步分析和下一阶段优化 | 可提交 | `docs/report/08_optimization_and_finals_outlook.md`、`docs/admin/multi_agent_execution_plan_2026-04-29.md` | 决赛目标或真实 PPA 返回后再细化 |

## 3. 关键证据链

| 结论 | 证据 | 复核判断 |
| --- | --- | --- |
| RTL 回归通过 | `reports/verification/iverilog_default.log` | 日志含列级 smoke/back-to-back/corner、阵列 smoke、7 组矩阵 dataset PASS |
| Python golden model 可用 | `reports/verification/python_ref_default.log` | self-test PASS，并可生成 `vectors/dot32_smoke` |
| 4096 抽样统计可复验 | `reports/verification/matmul_stats_default.log`、`reports/verification/matmul_stats_sweep.log`、`reports/verification/matmul_stats_profiles.log` | 三类统计日志均为 PASS，JSON 已归档到 `reports/precision/` |
| 常规 profile 数值稳定 | `reports/precision/matmul_stats_4096x4096x4096_sweep.json` | baseline 三 seed 共 6144 finite sample，0 nonfinite mismatch |
| sparse nonfinite 语义可解释 | `reports/precision/matmul_stats_4096x4096x4096_sparse_nonfinite_sweep.json` | 6037 finite、107 matched NaN、0 mismatched nonfinite |
| 极端动态范围边界已说明 | `reports/precision/matmul_stats_4096x4096x4096_profiles.json`、`docs/report/06_precision_results.md` | `finite_exp64` 的类别差异被解释为 projected FP32 path 与 ideal double accumulator 的动态范围边界，不是 directed RTL 回归失败 |
| PPA 没有伪造 | `docs/report/07_synthesis_and_ppa.md`、`docs/report/09_submission_checklist.md` | 文档明确没有真实 28nm 面积、功耗、频率或时序结果 |
| 波形证据已补齐 | `sim/run_waveform_smoke.ps1`、`reports/verification/waveform_smoke.log`、`reports/evidence/waveforms/*.vcd` | VCD 覆盖单列 smoke、连续输入和阵列 smoke；默认回归不受影响 |

## 4. 后端 handoff 边界

当前可交给后端的内容：

- 顶层计算阵列 RTL：`rtl/mx_array_32x16.v`
- 列级计算单元：`rtl/llmt_col.v`
- MX/FP32 辅助模块与 include：`rtl/e4m3_decode.v`、`rtl/e8m0_scale_decode.v`、`rtl/fixed_to_fp32.v`、`rtl/fp32_add_rne.v`、`rtl/mx_defs.vh`、`rtl/mx_funcs.vh`
- 约束与综合模板：`constraints/mx_array_32x16.sdc`、`synth/run_dc_template.tcl`、`synth/run_yosys_generic.ys`
- 验证与证据：`tb/`、`sim/`、`vectors/`、`reports/verification/`、`reports/precision/`、`reports/evidence/`

后端或系统集成仍需补齐：

- A/B block 本地 buffer、SRAM wrapper、DMA/host/NoC 接口和输出写回路径。
- 真实 28nm standard-cell library、corner、RC/wire-load、I/O delay、clock uncertainty 和 scan/power 约束。
- mapped netlist、timing/area/power 原始报告、门级仿真和功耗 VCD/SAIF。

因此当前材料应称为 RTL/backend handoff package，而不是完整芯片后端实现。

## 5. 不应写入提交材料的内容

- 不应声称已经达到 1GHz 或 1TFOPS 的真实 28nm 后端结果。
- 不应给出面积、功耗、WNS/TNS 或 signoff 数值。
- 不应把 `synth/` 模板、Yosys generic stat 或占位 SDC 写成真实 28nm PPA。
- 不应把 `.codexpotter`、`.omx`、Potter runner 文件或临时任务单列入正式提交包。
- 不应把不可访问的 IEEE/Adelia 全文细节写成已确认事实。

## 6. 当前可提交包建议

建议正式包只包含 reader-facing 和评审相关内容：

- `README.md`
- `MAIN.md`
- `STATUS.md`
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

不建议打包：

- `.git/`
- `.codexpotter/`
- `.omx/`
- `work/`
- 本地 runner、临时日志缓存或未引用草稿

## 7. 结论分级

| 领域 | 结论 |
| --- | --- |
| 代码 | 可提交 RTL handoff 基线；当前不建议改 RTL |
| 验证 | 可提交；日志和固定向量证据完整，波形截图是展示增强项 |
| 精度 | 可提交；4096 抽样和 profile 解释完整 |
| 报告 | 可提交为 Markdown 技术报告；官方模板到位后需裁剪 |
| 教学 | 可提交为辅助材料；不影响初赛核心判断 |
| 后端/PPA | 只能提交模板和方法；真实结果外部阻塞 |

最终判断：当前项目可以作为初赛 RTL handoff 提交包继续整理和打包；不能作为真实 28nm PPA 完成包宣传。
