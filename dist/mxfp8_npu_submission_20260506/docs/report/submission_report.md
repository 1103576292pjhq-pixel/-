# MXFP8 NPU 参赛提交报告

## 1. 项目目标与交付边界

本项目面向“AI 赛道命题七：大语言模型块浮点计算阵列的设计与实现”，完成了一套可综合的纯 Verilog MXFP8 计算阵列前端实现，并整理为可直接交给评审和后端团队继续处理的 `RTL handoff package`。

本次交付边界是前端 RTL 包，而不是真实 28nm 后端结果。仓库当前提供：

- 纯 Verilog RTL 与 testbench
- Python 黄金模型与固定向量
- 功能回归日志
- 精度统计结果
- 波形 VCD 与 PNG 截图
- 约束模板与综合脚本模板
- 后端接收清单与提交包说明

当前环境没有真实 28nm 标准单元库，也没有可用的真实综合/后端工具链，因此本报告不声称已经完成真实 28nm 面积、功耗、频率、WNS、TNS、mapped netlist 或 signoff。

## 2. 数值格式与计算语义

本设计采用 MXFP8 风格块浮点表示：

- 每个 block 含 32 个 `E4M3` 元素
- 每个 block 共享 1 个 `E8M0` scale
- 输入矩阵 `A`、`B` 为 MXFP8
- 输出矩阵 `Y` 为 FP32

RTL 与参考模型共同遵循“块共享 scale + 块内低精度元素”的计算思路。实现中，先完成 block 内 32 路元素乘法与归约，再把结果投影到 FP32 累加器路径。相关实现入口包括：

- `rtl/e4m3_decode.v`
- `rtl/e8m0_scale_decode.v`
- `rtl/fixed_to_fp32.v`
- `rtl/fp32_add_rne.v`
- `tools/mx_ref.py`

定向测试和矩阵级数据集已经覆盖 `NaN`、`scale-NaN`、subnormal、最大值、tail tile 和 sparse nonfinite 等关键边界。

## 3. 阵列架构与模块组织

顶层模块为 [mx_array_32x16.v](/D:/github/-/rtl/mx_array_32x16.v)，阵列规模为 `32x16`。

架构要点如下：

- 数据流采用 output-stationary
- 每个时钟周期广播一个 32 元素的 `A block`
- 16 列同时接收不同的 `B block`
- 每列由一个 [llmt_col.v](/D:/github/-/rtl/llmt_col.v) 完成 block dot32 与 FP32 累加
- 输出打包为 `acc_o[16*32-1:0]`

本次交付保持顶层接口稳定，不在第一轮提交中做激进重构，避免在没有真实 PPA 反馈前过早改动微架构边界。

## 4. LLMT 列级微架构

`llmt_col` 是列级计算核心，主要完成四件事：

1. 对 32 路 `E4M3` 元素和 `E8M0` scale 进行解码
2. 完成 32 路乘法与分级归约
3. 将 dot32 结果投影到 FP32 并更新累加器
4. 输出 `valid_o`，使列级和阵列级时序可验证

当前实现是可验证、可综合的前端基线版本。后续若要冲击更高频率或更低面积/功耗，应以真实综合结果为依据，围绕 dot32 归约树、FP32 累加路径和控制路径做定量优化。

## 5. 验证方法与结果

验证分三层进行：

- 列级定向测试：smoke、corner、back-to-back valid
- 阵列/矩阵级数据集测试：finite、tail tile、mixed nonfinite、sparse nonfinite
- Python 黄金模型与 `4096x4096x4096` 抽样精度统计

主要脚本如下：

```powershell
.\sim\run_iverilog.ps1
.\sim\run_python_ref.ps1
.\sim\run_waveform_smoke.ps1
.\sim\render_waveform_screenshots.ps1
.\sim\run_submission_regression.ps1
```

当前可核查日志包括：

- `reports/verification/iverilog_default.log`
- `reports/verification/python_ref_default.log`
- `reports/verification/waveform_smoke.log`
- `reports/verification/matmul_stats_profiles.log`

一键验收脚本 `sim/run_submission_regression.ps1` 已经把纯 Verilog 门禁、功能回归、波形证据、精度统计、提交包洁净度和综合环境检查串成单入口流程。

## 6. 精度与波形证据

`4096x4096x4096` 抽样统计结果存放在 `reports/precision/`。其中 `matmul_stats_4096x4096x4096_profiles.json` 覆盖：

- `finite_exp8`
- `finite_exp32`
- `finite_exp64`
- `sparse_nonfinite`

当前稀疏非有限值 profile 记录为：

- `6037` 个 finite 样本
- `107` 个 matched `NaN`
- `0` 个 nonfinite mismatch

波形证据为可重现实验结果，而不是人工绘图：

- VCD：`reports/evidence/waveforms/`
- PNG：`reports/evidence/waveform_screenshots/`

三张报告级截图分别覆盖：

- `tb_llmt_col_smoke`
- `tb_llmt_col_back_to_back`
- `tb_mx_array_smoke`

最终证据索引见 [final_evidence_index_2026-05-06.md](/D:/github/-/reports/evidence/final_evidence_index_2026-05-06.md)，边界条件矩阵见 [boundary_case_matrix.md](/D:/github/-/reports/evidence/boundary_case_matrix.md)。

## 7. 综合与 PPA 边界

本仓库已经准备了后端接入所需的最小前置材料：

- `constraints/mx_array_32x16.sdc`
- `synth/run_dc_template.tcl`
- `synth/run_yosys_generic.ys`
- `docs/usage/02_synthesis_environment_check.md`
- `docs/report/12_backend_handoff_checklist.md`

但当前环境的真实状态是：

```text
BLOCKED_NO_SYNTH_TOOL
BLOCKED_NO_28NM_LIB
```

因此本次提交的正确结论是：

```text
PASS_WITH_EXTERNAL_SYNTH_BLOCKER
```

也就是说，前端 RTL handoff 已完成；真实 28nm 映射网表和 PPA 结果仍需后端环境补齐。

## 8. 后端接收与后续工作

后端团队收到本包后，应优先阅读 [12_backend_handoff_checklist.md](/D:/github/-/docs/report/12_backend_handoff_checklist.md)。

本次交付的后端输入包括：

- `rtl/` 下的纯 Verilog RTL
- `tb/` 下的 testbench
- `constraints/` 下的 SDC 模板
- `synth/rtl_filelist.f` 给出的确定性 RTL 读入顺序
- `synth/` 下的综合模板
- `reports/verification/`、`reports/precision/`、`reports/evidence/` 下的验证证据

后端后续应补齐：

- mapped netlist
- timing report
- area report
- power report
- gate-level simulation evidence
- 竞赛若要求的物理实现或 signoff 材料

## 9. 结论

截至 2026-05-06，本项目已经形成可提交、可移交后端继续处理的第一轮 `RTL handoff package`。它满足“前端 RTL + 完整验证 + 证据链 + 后端接收说明”的交付目标。

当前唯一明确未完成项不是 RTL 功能或文档缺失，而是外部环境缺口：缺少真实综合工具与真实 28nm 标准单元库。因此，本项目当前最准确的提交状态不是“真实后端完成”，而是“前端交付完成，后端环境待接入”。
