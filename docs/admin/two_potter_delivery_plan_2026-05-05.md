# 两次 Potter 交付计划：比赛/后端 handoff 与教学导学分离（2026-05-05）

## 1. 需求确认

你的核心需求按优先级分成两次 Potter：

1. 第一次 Potter：直接面向比赛提交和后端接收，交付“可比赛、可移交后端”的前端 RTL handoff 包。
2. 第二次 Potter：在第一次交付稳定后，生成高质量代码讲解、导学和逐行教材。

这两次不能混在一起。第一次的目标是“评审能看、后端能接、证据能验”；第二次的目标是“零基础能学、队友能复述、代码能逐行读”。

## 2. 关于“交给后端的东西”和 netlist

你说的 `network` 更准确可能是 `netlist`。这里必须区分三种交付层级：

| 层级 | 名称 | 当前是否必须交付 | 说明 |
| --- | --- | --- | --- |
| L1 | RTL handoff package | 必须 | 纯 Verilog RTL、顶层接口、SDC、综合脚本模板、验证日志、向量、Python golden、报告和后端说明。这是前端交给后端的标准中间产物。 |
| L2 | generic netlist | 条件交付 | 如果本机能接入 Yosys，可生成 generic netlist/JSON/stat，只能作为结构 sanity check，不能当 28nm PPA。 |
| L3 | 28nm mapped gate-level netlist | 条件交付 | 只有真实 DC/Genus + 真实 28nm `.db/.lib` + 真实约束可用时才能生成，并同时给 timing/area/power 原始报告。没有这些条件时不能承诺。 |

因此第一次 Potter 的硬目标是 L1。L2/L3 按环境检查结果决定：能跑就归档，不能跑就明确 blocker，不允许编造。

## 3. 第一次 Potter：比赛提交 + 后端 handoff

### 3.1 目标

把当前仓库收束成一个可以提交比赛初赛、也可以交给后端继续综合/PPA 的前端包。

### 3.2 严格范围

必须做：

- 提交包卫生收口。
- 验证签核增强。
- 综合环境检查。
- 后端 handoff 说明增强。
- 单一提交版技术报告。
- 正式包 manifest 和 evidence index。
- 一键验收脚本。
- 正式 `dist/` 打包草案。

禁止做：

- 不做大规模教学扩写。
- 不补完整逐行教材。
- 不改 RTL 微架构，除非发现会导致回归失败的真实 bug。
- 不声明真实 28nm PPA。
- 不把 `.omx/`、`.codexpotter/`、`work/`、`.vvp` 放入正式包。
- 不启动 GitHub、PR、team、tmux lane。

### 3.3 必须新增或更新的文件

| 文件 | 作用 |
| --- | --- |
| `sim/run_submission_regression.ps1` | 一键跑提交前验收，生成 PASS/FAIL 摘要。 |
| `reports/evidence/final_evidence_index_2026-05-05.md` | 汇总日志、JSON、VCD、PNG、向量、边界 case。 |
| `reports/evidence/boundary_case_matrix.md` | 把 zero、subnormal、NaN、scale-NaN、tail tile、back-to-back、sparse nonfinite 等映射到证据。 |
| `reports/synthesis/environment_check_2026-05-05.md` | 记录本机综合/后端工具、库文件、约束和 blocker。 |
| `docs/usage/02_synthesis_environment_check.md` | 告诉后端和队友怎么检查综合环境。 |
| `docs/admin/final_submission_manifest.md` | 明确正式提交包包含和排除内容。 |
| `docs/report/submission_report.md` | 面向评审的单一提交版报告。 |
| `docs/report/12_backend_handoff_checklist.md` | 后端接收检查清单，包含顶层、约束、脚本、证据和待补项。 |
| `tools/package_submission.py` 或 `sim/package_submission.ps1` | 生成 `dist/` 正式包。 |

### 3.4 一键验收脚本机制

`sim/run_submission_regression.ps1` 至少分 5 段：

1. `Preflight`：检查 `iverilog/vvp/python/gtkwave/yosys/openroad/dc_shell/genus/innovus`，检查目录和关键文件。
2. `Functional`：运行 `sim/run_iverilog.ps1`、`sim/run_python_ref.ps1`。
3. `Evidence`：运行 `sim/run_waveform_smoke.ps1`、`sim/render_waveform_screenshots.ps1`。
4. `Precision`：运行或校验 `sim/run_matmul_stats*.ps1` 结果。长统计可用 `-SkipLongStats` 参数，但正式 release 不能跳过。
5. `Index`：校验 evidence index 引用的文件都存在，校验日志时间、PNG/VCD/JSON 数量和状态一致。

输出状态只允许：

- `PASS`
- `PASS_WITH_EXTERNAL_SYNTH_BLOCKER`
- `FAIL_FUNCTIONAL`
- `FAIL_EVIDENCE_INCOMPLETE`
- `FAIL_SYNTH_ENV`

### 3.5 搜索门禁机制

不能只依赖 `rg`。本机或沙箱中可能出现 `rg.exe Access is denied`。

所有搜索门禁必须双实现：

```text
优先：rg
兜底：Get-ChildItem -Recurse -File | Select-String
```

必须检查：

- SystemVerilog 残留：`package`、`import mx_pkg`、`logic`、`always_ff`、`task automatic`。
- 过度 PPA 声明：`已完成真实 28nm`、真实面积、真实功耗、真实频率、`signoff 通过`。
- 旧状态混乱：非历史审计文件中的过期完成日期和旧阻塞表述。
- 正式包污染：`.omx`、`.codexpotter`、`work`、`.vvp` 是否进入 manifest。

### 3.6 后端 handoff 验收

第一次 Potter 完成后，后端至少能拿到：

- `rtl/*.v`、`rtl/*.vh`
- `constraints/mx_array_32x16.sdc`
- `synth/run_dc_template.tcl`
- `synth/run_yosys_generic.ys`
- `docs/report/12_backend_handoff_checklist.md`
- `docs/report/11_frontend_handoff_and_packaging.md`
- `reports/verification/*.log`
- `reports/precision/*.json`
- `reports/evidence/*.md`
- `reports/evidence/waveforms/*.vcd`
- `reports/evidence/waveform_screenshots/*.png`

如果生成了 generic netlist 或 mapped netlist，必须附上工具、版本、库、约束、命令和原始日志；否则不放 netlist 数值结论。

### 3.7 第一次 Potter 完成判定

必须同时满足：

- `sim/run_submission_regression.ps1` 结论为 `PASS` 或 `PASS_WITH_EXTERNAL_SYNTH_BLOCKER`。
- `docs/report/submission_report.md` 可单独阅读。
- `docs/admin/final_submission_manifest.md` 明确正式包内容。
- `reports/evidence/final_evidence_index_2026-05-05.md` 每个结论都有证据路径。
- `reports/synthesis/environment_check_2026-05-05.md` 明确工具和库状态。
- `dist/` 下存在正式提交包草案。
- `STATUS.md` 和 `MAIN.md` 指向第一次 Potter 完成状态。

## 4. 第二次 Potter：高质量代码讲解和导学

### 4.1 启动前置

第二次 Potter 只能在第一次 Potter 通过后启动。原因是教学材料必须解释冻结后的接口、验证和交付边界，否则会边写边改，质量不稳。

### 4.2 目标

做一套高质量中文教材，使零基础队友能从背景、RTL、验证、脚本、综合边界一路读懂并复述项目。

### 4.3 必须新增或补齐的内容

| 目录 | 内容 |
| --- | --- |
| `docs/study_book/` | 课程化导学总书，从数字电路、Verilog、NPU、MXFP8 到 RTL、验证和后端 handoff。 |
| `docs/line_by_line/01_rtl/` | 补齐全部 RTL 和 `.vh` 的逐行讲解。 |
| `docs/line_by_line/02_testbench/` | 补齐主 testbench 和 dataset wrapper 讲解。 |
| `docs/line_by_line/03_tools_and_scripts/` | 补齐 Python golden、PowerShell 回归、波形、综合脚本讲解。 |
| `docs/line_by_line/04_retell/` | 复述卡、答辩问答、常见错误。 |

### 4.4 教学质量门禁

每篇教学文档必须包含：

- 本文件/本章解决什么问题。
- 最小直觉例子。
- 正式定义。
- 输入输出。
- 关键代码段或行号表。
- 硬件含义。
- 常见误解。
- 成功运行结果或失败信号。
- 3 到 5 句复述卡。

### 4.5 第二次 Potter 完成判定

必须同时满足：

- `docs/study_book/README.md` 给出完整学习路线。
- `docs/line_by_line/**/README.md` 中主文件不再是 `待续写`。
- 教学文档不把答辩覆盖冒充逐行覆盖。
- 教学材料引用第一次 Potter 冻结后的正式接口、报告和证据。
- `STATUS.md` 和 `MAIN.md` 指向第二次 Potter 完成状态。

## 5. 两次 Potter 的启动任务边界

第一次任务标题建议：

```text
MXFP8 NPU 第一次 Potter：比赛提交与后端 RTL handoff 包收口
```

第一次任务只做 S0、S1、S2、S3、S6 中与比赛/后端移交相关的内容。

第二次任务标题建议：

```text
MXFP8 NPU 第二次 Potter：零基础导学与逐行代码讲解
```

第二次任务只做 S4、S5 和教学复述材料。

## 6. 当前下一步

下一步不是马上扩写教学，而是准备第一次 Potter 任务单：

```text
work/potter_task_competition_handoff_2026-05-05.md
```

任务单必须写清：

- 工作区：`D:\github\-`
- 模型：`gpt-5.5`
- 目标：比赛提交 + 后端 RTL handoff 包
- 禁止项：不做教学大扩写、不改 RTL 算法、不声明真实 PPA、不混入内部目录
- 输出文件：第一次 Potter 的所有新增文件
- 验收：`run_submission_regression.ps1` 状态和 `dist/` 包

