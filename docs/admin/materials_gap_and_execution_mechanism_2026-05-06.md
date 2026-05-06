# 物料审查、需求冻结与下一步执行机制（2026-05-06）

## 1. 用户需求重新冻结

当前目标分成两条线，优先级不能混乱。

第一优先级是比赛提交和后端接收。准确交付名称是 `RTL handoff package`，不是完整后端 signoff 包。它必须让评审能看懂方案、能复现实验，让后端能接收 RTL、约束、脚本模板和验证证据后继续做综合、PPA、网表和门级验证。

第二优先级是教学体系。它必须服务零基础队友，从 NPU、MXFP8、Verilog、RTL、testbench、Python golden、回归脚本和综合边界一路讲到能复述。逐行讲解应该写成 Markdown 教材，不能塞回代码注释里。

当前策略仍然是两次 Potter：

- 第一次 Potter：比赛提交 + 后端 RTL handoff 收口。
- 第二次 Potter：零基础导学 + 逐文件逐段/逐行讲解。

## 2. 当前已有物料

### 2.1 比赛与后端 handoff 物料

当前已经形成正式提交候选包：

- `dist/mxfp8_npu_submission_20260506/`
- 当前包内文件数：`161` 个
- 打包脚本：`tools/package_submission.py`
- 一键验收脚本：`sim/run_submission_regression.ps1`
- 单入口提交报告：`docs/report/submission_report.md`
- 后端接收清单：`docs/report/12_backend_handoff_checklist.md`
- 后端 RTL filelist：`synth/rtl_filelist.f`
- 最终 manifest：`docs/admin/final_submission_manifest.md`
- 最终证据索引：`reports/evidence/final_evidence_index_2026-05-06.md`
- 边界 case 矩阵：`reports/evidence/boundary_case_matrix.md`
- 综合环境检查：`reports/synthesis/environment_check_2026-05-06.md`

当前交付判定是：

```text
PASS_WITH_EXTERNAL_SYNTH_BLOCKER
```

这个结论表示 RTL、验证、证据、打包和报告链路已经形成；真实后端结果被外部环境阻塞。

### 2.2 RTL 与验证物料

当前已有：

- 纯 Verilog RTL：`rtl/*.v`、`rtl/*.vh`
- 顶层：`mx_array_32x16`
- 列级核心：`llmt_col`
- testbench：列级、阵列级、dataset wrapper
- Python golden：`tools/mx_ref.py`
- 固定向量：`vectors/`
- 回归日志：`reports/verification/`
- 精度统计：`reports/precision/`
- 波形 VCD/PNG：`reports/evidence/waveforms/`、`reports/evidence/waveform_screenshots/`

### 2.3 综合与后端物料

当前已有：

- `constraints/mx_array_32x16.sdc`
- `synth/run_dc_template.tcl`
- `synth/run_yosys_generic.ys`
- `docs/usage/02_synthesis_environment_check.md`
- `docs/report/12_backend_handoff_checklist.md`

当前缺少：

```text
BLOCKED_NO_SYNTH_TOOL
BLOCKED_NO_28NM_LIB
```

因此不能声称真实 28nm 面积、功耗、频率、WNS、TNS、mapped netlist 或 signoff 已完成。

### 2.4 教学物料

当前已有 `docs/primer/`，包含 NPU 入门、数据流、MXFP8、Verilog 生存指南、验证和后端边界等章节。

当前已有 `docs/line_by_line/`，但只完成少量样板：

- `rtl/mx_defs.vh`
- `rtl/fixed_to_fp32.v`
- `rtl/mx_array_32x16.v`

当前 `docs/teaching/coverage_plan.md` 明确说明：多数文件只是答辩覆盖，不等于逐行教材完成。

## 3. 离最终目标还差多少

### 3.1 比赛提交包成熟度

当前评分：`90% - 95%`

已经具备参赛前端正式提交候选包主体。它可以作为“初赛技术材料 + RTL handoff 包”的当前交付版本；后续若要再推进，主要取决于主办方模板、答辩规则或真实后端环境。

主要差距：

- `docs/report/09_submission_checklist.md` 已按最新正式包范围更新，教学目录不进入第一轮正式 handoff 包。
- 非历史 handoff 入口已统一到 2026-05-06 验收口径；历史记录仍保留其原始日期。
- 当前是 Markdown 提交包，还没有按主办方最终模板导出 PDF/Word/PPT。
- 真实 28nm PPA 是外部阻塞项，不能靠前端继续补齐。

### 3.2 后端接收成熟度

当前评分：`85% - 90%`

L1 `RTL handoff package` 已经基本成型。后端能接 RTL、SDC、脚本模板、验证证据和接收清单。

主要差距：

- 缺真实后端工具和 28nm 库，所以没有 mapped netlist。
- 缺后端工具版本、工艺角、库版本、负载/驱动口径、功耗 activity 口径。
- 已补 `synth/rtl_filelist.f`，后端无需从报告里手工拼 RTL 读入顺序；真实综合仍需外部工具、库、corner、load/drive、activity、raw logs 和 reports。

### 3.3 教学资料成熟度

当前评分：`35% - 45%`

现在有入门教程框架和答辩复述材料，但还没有达到“零基础一周内能复述代码”的标准。

主要差距：

- 缺 `docs/study_book/` 课程化总书。
- `docs/line_by_line/` 只完成 3 个 RTL 样板，远未覆盖全部 RTL/TB/tools/scripts。
- 需要把每个文件讲成：为什么需要、输入输出、逐段逻辑、硬件含义、运行证据、常见误区、复述卡。
- 教学质量应该按类似视频课程笔记的标准写，而不是只做 API 摘要。

## 4. 下一步规划

## A. 比赛提交包终审收口

目标：当前 `dist/mxfp8_npu_submission_20260506/` 已从“草案包”推进到“正式提交候选包”。

动作：

- 已修正 `docs/report/09_submission_checklist.md` 的旧口径，删除把教学资料放入正式包的建议。
- 已扫描并修正 handoff 入口文档中的旧阻塞表述和过度完成表述。
- 已重新运行 `sim/run_submission_regression.ps1 -Fast`。
- 已重新生成 `dist/mxfp8_npu_submission_20260506/`。
- 已检查正式包不含 `.omx/`、`.codexpotter/`、`work/`、`.vvp`、`docs/primer/`、`docs/teaching/`、`docs/line_by_line/`。

完成标准：

```text
PASS_WITH_EXTERNAL_SYNTH_BLOCKER
```

并且所有文档口径一致：第一轮提交包只交比赛与后端 handoff 物料。

## B. 后端接收包增强

目标：让后端工程师拿到包后能按清单继续综合，不需要猜文件顺序。

动作：

- 已增加 `synth/rtl_filelist.f`。
- 在 `docs/report/12_backend_handoff_checklist.md` 中补“后端第一小时操作步骤”。
- 明确 DC/Yosys 输入文件顺序、顶层、约束、预期输出目录。
- 把真实 28nm PPA 的前置条件写成 checklist：工具、库、工艺角、约束、activity、日志、报告。

完成标准：

- 后端能直接按文件清单读入 RTL。
- 后端能明确知道当前包缺什么外部材料。
- 报告中没有任何虚假 PPA 数字。

## C. 比赛报告版式与答辩材料准备

目标：把 Markdown 技术报告变成真正便于提交和答辩的材料。

动作：

- 以 `docs/report/submission_report.md` 作为单入口摘要。
- 以 `docs/report/00` 到 `12` 作为完整报告正文。
- 若主办方给模板，再裁剪成 PDF/Word/PPT。
- 准备 6-8 页答辩讲稿：赛题理解、格式、架构、验证、精度、PPA 边界、后端计划、创新点。

完成标准：

- 评审能从单入口报告快速理解项目。
- 完整报告每个结论都能指到证据文件。
- 答辩时能解释为什么没有真实 28nm PPA。

## D. 第二次 Potter 教学长跑

目标：生成零基础导学和逐文件逐段讲解。

动作：

- 新建 `docs/study_book/`。
- 补齐 `docs/line_by_line/01_rtl/` 全部 RTL 和 `.vh`。
- 补齐 `docs/line_by_line/02_testbench/` 主 testbench 和 dataset wrapper。
- 补齐 `docs/line_by_line/03_tools_and_scripts/` Python、PowerShell、综合脚本。
- 补齐 `docs/line_by_line/04_retell/` 复述卡、答辩问答、易错点。

完成标准：

- 每个主文件都有 Markdown 讲解。
- 每篇讲解包含最小例子、输入输出、关键代码段、硬件含义、失败信号和复述卡。
- 零基础读者按目录学习一周后能讲清“MXFP8 block 如何进入阵列并变成 FP32 输出”。

## 5. 具体执行机制

### 5.1 状态机制

继续使用三个可见状态源：

- `STATUS.md`
- `MAIN.md`
- `.omx/potter-run.json`

每次长跑只允许一个主线。第一轮是比赛/handoff，第二轮是教学，不混写。

### 5.2 验收机制

比赛包验收命令：

```powershell
.\sim\run_submission_regression.ps1
```

快速复查命令：

```powershell
.\sim\run_submission_regression.ps1 -Fast
```

打包命令：

```powershell
python tools/package_submission.py --date 20260506
```

包污染检查：

```powershell
Get-ChildItem -Recurse -File dist/mxfp8_npu_submission_20260506 |
  Select-String -Pattern '.omx|.codexpotter|work|.vvp|docs/primer|docs/teaching|docs/line_by_line'
```

### 5.3 文档机制

文档分三层：

- `docs/report/`：比赛正式报告。
- `docs/usage/`：队友和后端使用说明。
- `docs/study_book/` 与 `docs/line_by_line/`：第二轮教学资料。

第一轮正式包只收 `docs/report/`、`docs/usage/` 和必要 `docs/admin/final_submission_manifest.md`。教学目录不进入第一轮正式包。

### 5.4 Potter 机制

第一次 Potter 已完成，下一步不应直接开第二次。应先做 A/B/C 的终审补丁，把第一轮包彻底稳定。

第二次 Potter 启动前必须准备新任务单：

```text
work/potter_task_teaching_line_by_line_2026-05-06.md
```

任务单必须明确：

- 只做教学资料。
- 不改 RTL 行为。
- 不改正式提交包口径。
- 逐文件讲解必须落在 Markdown。
- 每批自审至少 2 轮。

### 5.5 阻塞机制

真实 PPA 和 mapped netlist 只在满足以下条件后推进：

- 有真实综合工具，如 DC、Genus、Yosys 或其他指定工具。
- 有真实 28nm `.db/.lib`。
- 有明确 clock、I/O delay、load/drive、corner、activity 口径。
- 有原始 logs/reports。

缺任一项时，只能记录 blocker，不能补虚构结果。

## 6. 推荐立即执行顺序

1. 修正 `docs/report/09_submission_checklist.md` 的旧包范围和旧日期。
2. 增加 `synth/rtl_filelist.f` 或确认现有综合脚本已内置完整读入顺序。
3. 运行 `sim/run_submission_regression.ps1 -Fast`。
4. 重新生成 `dist/mxfp8_npu_submission_20260506/`。
5. 做包污染检查。
6. 若全部通过，再启动第二次 Potter 做教学资料。

## 7. 当前结论

当前项目第一目标已经收口到正式提交候选包：比赛和后端 handoff 主体完成，终审、文档一致性、后端接收便利性和打包污染检查均已通过。

当前项目离第二目标还比较远：教学框架已经有，但完整逐文件逐段讲解尚未完成，需要单独一次 Potter 长跑。
