# 参赛提交包与教学体系升级计划（2026-05-04）

> 2026-05-05 更新：后续执行改为两次 Potter。第一次只做比赛提交和后端 RTL handoff 包收口；第二次只做高质量代码讲解和导学。严格边界见 `docs/admin/two_potter_delivery_plan_2026-05-05.md`。

## 1. 当前判断

本仓库已经从早期原型进入“可验证 RTL handoff 包”状态，但还不应直接当作最终高质量参赛包原封不动提交。

| 维度 | 当前评分 | 判断 |
| --- | --- | --- |
| RTL 功能与基础验证 | 80/100 | 纯 Verilog RTL、列级/阵列级/dataset 回归、Python golden 和波形证据已经具备；仍缺 lint、综合读入、门级验证和更系统的边界覆盖矩阵 |
| 比赛提交材料 | 70/100 | 报告章节、需求映射、证据包、使用说明已经有；仍需统一最终版目录、消除旧日期、生成提交包 manifest，并把报告整理成评审可直接阅读的单一入口 |
| 综合/PPA 移交 | 45/100 | SDC 和 DC/Yosys 模板具备；当前 shell 只发现 `iverilog/vvp/python/gtkwave`，未发现 `yosys/openroad/verilator/dc_shell/genus/innovus`，因此还没有真实综合或 28nm PPA |
| 零基础教学资料 | 60/100 | `docs/primer` 已有一周学习路径，`docs/teaching` 有答辩复述地图；但 `docs/line_by_line` 目前只完成 3 个样板，离“从 RTL 到综合一步步教会”还有明显距离 |
| 可读文件结构 | 70/100 | 顶层入口和主目录已清楚；仍需把正式提交包、教学书、后端移交包、内部运行文件彻底分层，避免评审和初学者被 `.omx`、`work`、旧日志干扰 |

结论：

- 如果按“前端 RTL handoff 包”口径，可作为初赛材料继续打包。
- 如果按“高分参赛作品”口径，不建议直接提交；必须补齐提交包收口、综合环境接入说明/实跑结果、教学逐行覆盖和最终打包清单。
- 如果按“零基础教学资料”口径，当前只是骨架加样板，不够达到完整视频课程级讲解标准。

## 2. 明确用户需求

本轮后续工作必须同时满足两条主线：

1. 参赛主线：形成能提交的 MXFP8 NPU 前端 RTL 作品包，重点是 RTL、验证、证据、报告、综合/PPA 接入口和后端 handoff，不伪造真实 28nm 结果。
2. 教学主线：形成从零基础到能复述代码的学习体系，先讲 NPU/MXFP8/Verilog/验证/综合边界，再逐文件逐行讲 RTL、testbench、Python 和脚本。
3. 文件结构主线：正式提交包、教学资料、后端移交资料、内部运行记录分开；正式包不能混入 `.codexpotter`、`.omx`、`work/` 或未整理日志。
4. 质量主线：每个结论必须能指向文件、日志、JSON、波形或测试命令；所有“可提交”状态必须和当前证据一致。

## 3. 教学质量标准

这里把“video/MB-study 级别”落实成可检查规则：

| 标准 | 具体要求 |
| --- | --- |
| 先建立直觉 | 每章先用小例子解释为什么需要这个模块，再进入代码 |
| 再给正式定义 | 术语不能只用比喻，必须有硬件/数值/接口定义 |
| 保留手算 | MAC、dot32、scale、RNE、valid 延迟至少要有可手算例子 |
| 对照源码 | 逐行讲解 Markdown 必须保留行号、源码片段和“硬件含义” |
| 能复述 | 每个文件最后给 3 到 5 句答辩复述卡 |
| 能动手 | 每个阶段给运行命令、成功输出、失败信号和排查路径 |
| 讲到综合 | 必须解释 RTL、综合、SDC、库、面积、功耗、时序、PPA 为什么不是一回事 |

## 4. 严格修改计划

### S0 提交包卫生收口

目标：先让仓库状态和提交叙事一致。

必须完成：

- 更新所有旧日期和旧状态，尤其是 `docs/report/09_submission_checklist.md`、`docs/report/05_verification_methodology.md`、`reports/verification/README.md`。
- 生成 `reports/evidence/final_evidence_index_2026-05-04.md`，把日志、PNG、VCD、4096 JSON、关键 testbench 一次性索引。
- 生成 `docs/admin/final_submission_manifest.md`，列出正式提交包包含/排除文件。
- 明确 `work/` 是内部任务单，不进入正式提交包。

验收：

- `rg "2026-04-28|2026-04-30|待截图|截图待" docs reports README.md STATUS.md MAIN.md` 只剩历史审计类文件。
- `docs/report/00_requirements_traceability.md`、`09_submission_checklist.md`、`STATUS.md` 三处状态一致。

### S1 RTL 和验证签核增强

目标：让“功能正确”从 smoke 级提升到提交签核级。

必须完成：

- 保持 `sim/run_iverilog.ps1`、`sim/run_python_ref.ps1`、`sim/run_waveform_smoke.ps1` 全部 PASS 并归档日志。
- 增加一键汇总脚本，例如 `sim/run_submission_regression.ps1`，顺序跑 Verilog、Python、waveform，并输出最终 PASS/FAIL 摘要。
- 补 `reports/evidence/boundary_case_matrix.md`，逐项列出 zero、subnormal、max、NaN、scale-NaN、tail tile、back-to-back、sparse nonfinite 对应 testbench 或 JSON。
- 搜索纯 Verilog 约束：`rg "\b(package|import mx_pkg|logic|always_ff|task automatic)\b" rtl tb` 必须无命中。

验收：

- 默认回归 11 个入口 PASS。
- Python self-test PASS。
- 三张波形 PNG 可重新生成。
- 边界 case 矩阵每行都有文件证据。

### S2 综合环境接入与前端移交增强

目标：把“电脑环境应该齐全”变成可验证环境清单。

必须完成：

- 新增 `docs/usage/02_synthesis_environment_check.md`，列出 `iverilog/vvp/python/gtkwave/yosys/openroad/verilator/dc_shell/genus/innovus` 的检测命令和当前检测结果。
- 若 `yosys` 可接入，跑 `synth/run_yosys_generic.ys` 并生成 `reports/synthesis/yosys_generic_*.log/json`；若不可接入，明确写“当前 PATH 未发现”。
- 若有 DC/Genus，补真实工具启动说明和库路径占位；没有 28nm `.db/.lib` 时不写 PPA 数值。
- 更新 `docs/report/07_synthesis_and_ppa.md`，把“模板”与“已实跑 generic check/真实 PPA”分开。

验收：

- 有 `reports/synthesis/environment_check_2026-05-04.md`。
- 若工具存在，有对应原始 log；若不存在，有明确 blocker，不含虚假 PPA。

### S3 提交版技术报告重排

目标：评审打开一个入口就能读完整作品。

必须完成：

- 新增 `docs/report/submission_report.md`，按比赛评分项重排正文，而不是让评审自己拼 00-11。
- 把架构图、数据流、验证表、误差表、波形 PNG、PPA 阻塞说明放入同一提交叙事。
- 把“前端交后端”定位写在摘要和 PPA 章节，避免被误判为后端 signoff 缺失。
- 把 DeepSeek/OCP/Adelia 参考点统一写成“参考动机和对比”，不把不可访问细节写成已实现事实。

验收：

- `submission_report.md` 能单独阅读。
- 每个评分项都能在报告中找到对应章节。
- 没有“真实 28nm 已达成”的未证实表述。

### S4 教学总书结构重建

目标：从“若干文档”升级为“课程化教材”。

建议目录：

```text
docs/study_book/
  README.md
  00_学习方法和总路线.md
  01_数字电路和Verilog最小基础.md
  02_NPU和矩阵乘硬件直觉.md
  03_MXFP8和块浮点数值路径.md
  04_从接口看懂mx_array_32x16.md
  05_从一列LLMT看懂dot32和累加.md
  06_从testbench看懂验证.md
  07_从Python golden看懂向量和误差.md
  08_从RTL到综合和后端handoff.md
  09_一周复述卡和答辩问答.md
```

验收：

- 每章有“本章目标、最小例子、正式定义、代码入口、自测题、复述卡”。
- 初学者不需要先打开 RTL，也能知道为什么要读这些文件。

### S5 逐行讲解补完

目标：满足“逐行讲解，不写进源码注释”的要求。

优先级：

1. RTL：`mx_funcs.vh`、`e4m3_decode.v`、`e8m0_scale_decode.v`、`fp32_add_rne.v`、`llmt_col.v`。
2. Testbench：smoke、corner、back-to-back、array smoke、dataset。
3. 工具脚本：`mx_ref.py`、`run_iverilog.ps1`、`run_matmul_stats*.ps1`、waveform 脚本。
4. 综合脚本：`constraints/mx_array_32x16.sdc`、`synth/run_dc_template.tcl`、`synth/run_yosys_generic.ys`。

验收：

- `docs/line_by_line/**/README.md` 中不再有主文件“待续写”。
- 每个逐行文件有行号表、硬件含义、语法解释和复述卡。

### S6 打包与最终验收

目标：生成正式提交包和内部保留包。

必须完成：

- 新增 `scripts/package_submission.ps1` 或 `tools/package_submission.py`。
- 输出 `dist/mxfp8_npu_submission_YYYYMMDD/`。
- 正式包包含 `rtl/tb/tools/sim/vectors/constraints/synth/docs/report/docs/usage/reports`。
- 正式包排除 `.git/.codexpotter/.omx/work/sim/*.vvp`。

验收：

- 从 `dist/` 解压后能运行基本回归。
- `README.md` 第一屏能说明如何运行、如何读报告、如何交后端。

## 5. Potter 执行建议

这项工作适合继续用 GPT5.5 CodexPotter 长跑，但必须按批次收窄，不能一次性让它“全部写完”。

建议启动顺序：

1. 第一轮：只做 S0 + S1，目标是提交包卫生和验证签核。
2. 第二轮：只做 S2 + S3，目标是综合接入和提交报告。
3. 第三轮：只做 S4，目标是教学总书结构。
4. 第四轮：只做 S5 的 RTL 逐行讲解。
5. 第五轮：只做 S5 的 testbench/tools/synth 逐行讲解。
6. 第六轮：只做 S6，目标是打包和最终验收。

每轮 Potter 必须更新：

- `STATUS.md`
- `MAIN.md`
- 本计划中的完成状态
- 对应日志或新增文档

## 6. 下一步建议

立即执行 S0。理由：

- S0 改动最小，但直接影响“能否提交”的可信度。
- 当前仓库还有旧日期、内部运行目录和提交叙事混杂的问题。
- S0 完成后，再启动 Potter 跑 S1/S2，风险更低。
