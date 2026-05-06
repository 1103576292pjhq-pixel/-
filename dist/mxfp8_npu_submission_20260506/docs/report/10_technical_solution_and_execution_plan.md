# 10 技术方案与执行计划

## 1. 文档定位

本文是 MXFP8 NPU 比赛交付包的总入口。它不替代 `00` 到 `09` 章的详细报告，而是把赛题要求、用户要求、当前完成状态、技术架构、验证证据、后端移交边界、风险和下一步执行优先级收敛成一份可决策文件。

当前仓库定位为 RTL handoff package：交付可综合纯 Verilog RTL、仿真工程、Python 参考模型、固定向量、精度统计、综合/PPA 模板、报告正文和证据索引。当前仓库不是完整 28nm 后端/GDS/PPA 交付；除非真实工具、真实 28nm 库和真实日志到位，否则不声明面积、功耗、频率或时序实测结果。

## 2. 赛题要求复述

根据当前可见赛题要求，本项目需要面向“大语言模型块浮点计算阵列的设计与实现”提交以下内容：

| 要求 | 当前仓库落点 | 当前判断 |
| --- | --- | --- |
| 电路实现方案 | `docs/report/03_architecture_and_dataflow.md`、`04_llmt_microarchitecture.md`、`rtl/` | 已形成可提交叙事 |
| 可综合 RTL code | `rtl/*.v`、`rtl/*.vh` | 已具备纯 Verilog-2001 基线 |
| 仿真工程和验证报告 | `tb/`、`sim/`、`vectors/`、`reports/verification/`、`reports/evidence/` | 已具备日志和证据索引 |
| 精度测试结果 | `docs/report/06_precision_results.md`、`reports/precision/` | 已具备 4096 抽样和 profile sweep |
| 综合结果、面积和功耗分析 | `docs/report/07_synthesis_and_ppa.md`、`constraints/`、`synth/`、`reports/synthesis/` | 模板具备，真实结果外部阻塞 |
| 初步分析与后续优化 | `docs/report/08_optimization_and_finals_outlook.md` | 已具备优化路线 |
| 提交清单 | `docs/report/09_submission_checklist.md` | 已具备当前打包口径 |

主办方补充通知、官方模板和答辩规则当前未获得，因此正式提交格式仍需在外部资料到位后裁剪。

## 3. 用户要求复述

本轮用户要求不是继续盲目改 RTL，而是把已有工程资产整理成比赛可交付、可移交、可继续执行的技术方案：

- 单一主线：使用当前工作区本地状态文件，不混入 GitHub、PR、team、tmux 或无关 lane。
- RTL 约束：保持纯 Verilog；没有真实综合/PPA 或新增赛题约束时，不做高风险 RTL 改动。
- 交付边界：按“前端 RTL 到后端移交包”组织，不伪造真实 28nm PPA。
- 文档口径：用户可读和对外报告均用中文，清楚区分已完成、外部阻塞和未来触发条件。
- 执行目标：形成技术方案和多角色执行计划，使后续 planner、architect、RTL、DV、PPA、writer、critic 等角色知道输入、输出、依赖和验收标准。

## 4. 当前进展和已接受基线

### 4.1 RTL 基线

- 顶层：`rtl/mx_array_32x16.v`
- 列级原语：`rtl/llmt_col.v`
- 数值辅助：`rtl/e4m3_decode.v`、`rtl/e8m0_scale_decode.v`、`rtl/fixed_to_fp32.v`、`rtl/fp32_add_rne.v`
- 公共定义：`rtl/mx_defs.vh`、`rtl/mx_funcs.vh`

当前 `llmt_col` 为三级流水：S1 完成 32 lane decode/multiply 和 `4 x 8` partial-sum；S2 merge partial sums 并转换为 FP32；S3 进入 FP32 accumulator。`mx_array_32x16` 并排实例化 16 个列，A block 广播，B block 按列切片。

2026-04-28 的 RTL 收口审查结论是保持 RTL 不动，见 `reports/evidence/rtl_refinement_review_2026-04-28.md`。理由是当前接口和回归稳定，更激进的 reduction retiming、FP32 pipeline 或资源共享都应由真实综合报告或新增赛题约束驱动。

### 4.2 验证和证据基线

2026-04-28 已归档的验证日志：

| 命令 | 日志 | 结果 |
| --- | --- | --- |
| `sim/run_iverilog.ps1` | `reports/verification/iverilog_default.log` | PASS |
| `sim/run_python_ref.ps1` | `reports/verification/python_ref_default.log` | PASS |
| `sim/run_matmul_stats.ps1` | `reports/verification/matmul_stats_default.log` | PASS |
| `sim/run_matmul_stats_sweep.ps1` | `reports/verification/matmul_stats_sweep.log` | PASS |
| `sim/run_matmul_stats_profiles.ps1` | `reports/verification/matmul_stats_profiles.log` | PASS |

证据包入口在 `reports/evidence/README.md`，覆盖回归日志索引、关键 case、4096 抽样方法、finite/nonfinite/boundary 覆盖、波形捕获状态和 RTL 收口审查。

当前提交就绪复核入口收敛到 `docs/report/submission_report.md`、`docs/admin/final_submission_manifest.md` 和 `reports/evidence/final_evidence_index_2026-05-06.md`，用于逐项回答当前代码、验证、精度、报告和后端 handoff 分别达到什么程度。

### 4.3 报告和教学基线

- 比赛报告：`docs/report/00_requirements_traceability.md` 到 `docs/report/09_submission_checklist.md`
- 使用说明：`docs/usage/README.md`
- 零基础 primer 与代码讲解：继续保留在仓库源树中，作为第二轮教学 Potter 输入，不进入第一轮正式 handoff 包。

当前缺口不是“没有报告”，而是必须把报告、证据、后端移交和正式包边界保持一致。本文与 `docs/report/submission_report.md`、`docs/report/11_frontend_handoff_and_packaging.md`、`docs/report/12_backend_handoff_checklist.md`、`docs/admin/final_submission_manifest.md` 共同构成第一轮正式包入口。

## 5. 具体架构方案

### 5.1 MXFP8 block 路径

基本计算粒度是 `K = 32` 的 MX block。每个 block 包含 32 个 E4M3 元素和一个 E8M0 scale。A 输入每拍提供一个 block；B 输入每拍提供 16 个列 lane 的 block。每个列 lane 独立完成：

1. E4M3 元素解码。
2. E8M0 scale 解码。
3. 32 lane 元素乘法。
4. dot32 固定点归约。
5. 归约结果转换为 FP32。
6. 与列内 FP32 accumulator 累加。

Python 参考模型 `tools/mx_ref.py` 是 RTL 比对和统计的 golden source。非有限值输出统一 canonical QNaN，避免 NaN payload 差异影响比对。

### 5.2 32 x 16 阵列

`mx_array_32x16` 是当前顶层。它包含 16 个 `llmt_col`：

- A block 广播到所有列。
- B block 以列为单位切片输入。
- `acc_clear_i[15:0]` 允许逐列清 accumulator。
- `valid_o[15:0]` 返回每列输出有效。
- `acc_o` 返回 16 个 FP32 accumulator 输出。

这个结构直接服务于 `M x N x K` 矩阵乘的列 tile 调度：每次处理 16 个输出列，K 维按 32 元素 block 流过，输出停留在列内 accumulator。

### 5.3 LLMT 列

`llmt_col` 是当前可交接的列级计算单元。它的关键特征：

- 外部接口简单稳定，便于后端综合和 testbench 驱动。
- S1 只寄存 4 个 8-lane partial sums，降低完整 32 lane 归约直接压入单阶段的风险。
- S2 做 final merge 和 fixed-to-FP32。
- S3 做 FP32 add 和 accumulator 写回。
- back-to-back test 已验证连续 `valid_i` 输入。

当前不暴露 IEEE exception flags；比赛报告应说明项目对 NaN/Inf 的数值输出语义，而不是声称完整 IEEE 异常状态支持。

### 5.4 Output-stationary 数据流

本设计采用 output-stationary 数据流：

1. 新输出 tile 开始时通过 `acc_clear_i` 清 accumulator。
2. 每个 K block 周期输入 A block 和 16 个 B block。
3. 列级 accumulator 持续保留部分和。
4. K blocks 处理完成后，`acc_o` 保存当前输出 tile 的 FP32 结果。

这种策略减少部分和在外部存储和阵列之间来回搬移，适合当前固定 `32 x 16` 计算阵列叙事。当前仓库没有实现 SRAM、DMA、NoC 或 host 接口；这些属于后端 SoC 集成边界之外。

### 5.5 valid/reset/control 合同

当前控制合同如下：

- `rst_n` 为低有效复位。
- `valid_i` 表示本拍 A/B block 有效。
- `acc_clear_i[col]` 表示对应列开始新 accumulator。
- `acc_clear_i && !valid_i` 会清空列内 accumulator 和 valid 管线。
- `valid_o[col]` 与该列 accumulator 输出对齐。

后续若要改变 accumulator latency、FP32 add pipeline 或多周期约束，必须同步更新 testbench、报告和 evidence。

### 5.6 本地 buffer 与后端移交边界

当前交付包不包含片上本地 buffer 的完整 RTL。后端或系统集成方需要补齐：

- A/B block 的本地缓存或 SRAM wrapper。
- 输入调度、DMA、host 接口或 NoC 接口。
- 输出结果写回路径。
- 与真实后端时钟、reset、scan、power domain 相关的约束。

因此，本文把“计算阵列 RTL”和“系统集成/物理实现”分开：本仓库交付前者，并提供后者需要的约束模板和检查表。

## 6. 验证策略

### 6.1 单元和列级验证

列级验证入口包括：

- `tb/tb_llmt_col_smoke.v`
- `tb/tb_llmt_col_corner.v`
- `tb/tb_llmt_col_back_to_back.v`

覆盖基本 dot32、corner case、连续输入和 valid 对齐。后续若修改 `llmt_col` pipeline，这三类测试必须先通过。

### 6.2 阵列级验证

阵列级入口包括 `tb/tb_mx_array_smoke.v` 和 `tb/tb_mx_array_dataset*.v`。当前固定向量覆盖：

- 有限值矩阵：`4x16x64`、`5x20x96_tail`、`8x32x128`、`9x65x192_five_tiles`
- 非有限值矩阵：`3x18x64_nonfinite`、`6x33x160_nonfinite`、`7x49x224_sparse_nonfinite`
- 单列 dot32：`dot32_smoke`

这些用例覆盖 row/tile/K block 调度、tail tile、连续输入、mixed finite/Inf/NaN 和 sparse scale-NaN。

### 6.3 4096 抽样精度验证

4096x4096x4096 抽样统计由 `sim/run_matmul_stats*.ps1` 驱动，结果在 `reports/precision/`。当前已形成：

- baseline `[-8, 8]`
- `finite_exp32` `[-32, 32]`
- `finite_exp64` `[-64, 64]`
- `sparse_nonfinite`

报告必须区分有限值误差和非有限值类别。`finite_exp64` 中的类别差异是 projected FP32 path 与 ideal double accumulator 的动态范围边界证据，不应解释为 RTL directed dataset 回归失败。

### 6.4 波形证据计划

当前已具备日志证据和波形捕获方法，见 `reports/evidence/waveform_capture_status.md`。正式提交若需要截图，应优先捕获：

- `llmt_col` back-to-back valid 管线。
- `mx_array_32x16` 多列 `valid_o` 对齐。
- tail tile 中 padded lane 行为。
- sparse nonfinite case 中 NaN 传播。

波形截图只作为报告展示，不能替代可复验日志、固定向量和 JSON 统计。

## 7. 后端移交包

### 7.1 RTL 清单

后端接入至少需要：

- `synth/rtl_filelist.f` 给出的确定性读入顺序
- `rtl/mx_defs.vh`
- `rtl/mx_funcs.vh`
- `rtl/e4m3_decode.v`
- `rtl/e8m0_scale_decode.v`
- `rtl/fixed_to_fp32.v`
- `rtl/fp32_add_rne.v`
- `rtl/llmt_col.v`
- `rtl/mx_array_32x16.v`

顶层模块为 `mx_array_32x16`。

### 7.2 约束与综合模板

当前已准备：

- `synth/rtl_filelist.f`
- `constraints/mx_array_32x16.sdc`
- `synth/run_dc_template.tcl`
- `synth/run_yosys_generic.ys`
- `reports/synthesis/README.md`

这些文件是接入起点，不是 signoff 结果。`create_clock -period 1.000`、I/O delay 和 uncertainty 都是模板值，必须按真实后端环境校准。

### 7.3 后端需要补齐的输入

真实 PPA 必须等待：

- 28nm standard-cell library `.db`。
- 工艺角、温度、电压、RC corner 或 wire-load 模型。
- 真实目标频率、I/O delay、uncertainty 和时钟定义。
- 综合工具版本和 license。
- 功耗分析所需 VCD/SAIF workload 窗口。

没有这些输入时，任何面积、功耗、频率和 WNS/TNS 数字都不应进入报告。

### 7.4 PPA 方法

后端 PPA 流程建议：

1. 用真实库替换 `synth/run_dc_template.tcl` 中的 target/link library。
2. 校准 `constraints/mx_array_32x16.sdc`。
3. 运行综合，生成 timing、area、power、mapped netlist。
4. 若需要功耗，先由代表性 RTL 仿真生成 VCD/SAIF。
5. 把原始报告归档到 `reports/synthesis/`。
6. 更新 `docs/report/07_synthesis_and_ppa.md`，注明工具、库、corner、commit 和约束版本。

## 8. 风险与缓解

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| OCP MX 语义仍有公开资料边界 | 可能影响 NaN/Inf 或 scale 细节解释 | 报告只引用当前公开可核查规则和项目定义，不把未知细节写死 |
| Adelia/IEEE 全文不可用 | 可能影响背景论述完整性 | 把论文细节列为不确定项，技术实现以本仓库可复验模型和 RTL 为准 |
| 主办方模板缺失 | 最终报告格式可能返工 | 当前用章节化 Markdown，拿到模板后先改 `09_submission_checklist.md` |
| 真实 28nm 库和工具缺失 | PPA 数字无法给出 | 只交付方法、模板和后端检查表，不伪造结果 |
| timing/area 未知 | 可能需要 RTL retiming | 等真实综合最差路径后再改 `llmt_col`，每次改动重跑回归 |
| 文档漂移 | 报告、状态和证据可能不一致 | 以 `reports/verification`、`reports/precision`、`reports/evidence` 为证据源；修改后同步入口文件 |
| 波形截图未实采 | 评审材料展示性不足 | 按 `waveform_capture_status.md` 捕获关键 case，保留 VCD/截图路径 |

## 9. 下一步执行优先级

当前优先级：

1. 以 `docs/report/submission_report.md` 作为第一轮评审入口。
2. 以后端接收清单 `docs/report/12_backend_handoff_checklist.md` 和 `synth/rtl_filelist.f` 作为后端 intake 起点。
3. 以 `docs/admin/final_submission_manifest.md` 和 `dist/mxfp8_npu_submission_20260506/PACKAGE_CONTENTS.txt` 作为正式包边界依据。
4. 继续保持 `PASS_WITH_EXTERNAL_SYNTH_BLOCKER` 口径；缺少真实综合工具和 28nm `.db/.lib` 时，不生成 mapped netlist 或 PPA 数字。
5. 第二轮教学 Potter 只在当前正式提交候选包稳定后启动。

未来触发条件：

- 收到主办方模板或答辩规则：先更新提交清单，再裁剪报告。
- 收到真实 28nm 库和工具：先跑综合并归档原始报告，再更新 PPA 章节。
- 收到 benchmark：先扩展 `vectors/` 和 `sim/`，再更新精度与 evidence。
- 决定改 RTL：先写变更意图，改完必须跑 `sim/run_iverilog.ps1`，必要时跑 Python/统计脚本。

## 10. 当前结论

当前仓库已经具备初赛 RTL handoff 交付基础，第一轮正式包是 `dist/mxfp8_npu_submission_20260506/`。本文补齐的是“决策完整性”：评审、后端工程师或后续执行者可以明确知道比赛要求如何映射到仓库，哪些内容已经有证据，哪些内容被外部输入阻塞，哪些 RTL 改动现在不应做，以及下一步应该按什么触发条件推进。
