# 07 综合与 PPA

## 1. 当前结论先行

本仓库当前没有真实 28nm 标准单元库、工艺角、线载模型或商用综合工具运行结果。因此本章不提供真实面积、功耗、频率或时序数值。

当前可交付内容是 RTL/backend handoff package：

- 可综合纯 Verilog RTL
- 顶层约束模板
- Design Compiler 脚本模板
- Yosys 通用结构检查脚本
- 后端接入检查表
- PPA 评估方法说明

## 2. 已准备文件

| 文件 | 用途 | 当前状态 |
| --- | --- | --- |
| `constraints/mx_array_32x16.sdc` | 时钟、输入输出 delay、clock uncertainty 模板 | 可作为起点，需按真实后端环境调整 |
| `synth/run_dc_template.tcl` | Design Compiler 综合流程模板 | 需替换真实 28nm `.db` 库路径 |
| `synth/run_yosys_generic.ys` | Yosys 通用读入、层次检查和 generic stat | 可用于结构 sanity check，不代表 28nm PPA |
| `reports/synthesis/README.md` | 综合/PPA 报告落点说明 | 待后端补真实结果 |

## 3. 后端接入步骤

真实 PPA 应按以下步骤补齐：

1. 获取主办方或后端团队指定的 28nm standard-cell library。
2. 明确工艺角、温度、电压、wire-load 或 RC corner。
3. 替换 `synth/run_dc_template.tcl` 中的 `TARGET_LIBRARY` 和 `LINK_LIBRARY`。
4. 校准 `constraints/mx_array_32x16.sdc` 的目标周期、I/O delay、clock uncertainty、reset/valid 约束。
5. 运行综合，生成 timing、area、power、netlist。
6. 若使用 switching activity 做功耗估计，先从 RTL 仿真导出 VCD/SAIF，并说明 workload 窗口。
7. 将报告归档到 `reports/synthesis/`，并在本章填入真实数值、工具版本、库版本和 corner。

## 4. 当前模板约束

当前 SDC 模板使用：

- `create_clock -period 1.000`
- 输入 delay：`0.10`
- 输出 delay：`0.10`
- clock uncertainty：`0.05`

这些数值只用于占位和流程接入。没有真实库和后端约束前，不能解释为目标频率已经达成。

## 5. 面积和功耗分析口径

后续真实 PPA 报告至少应包含：

| 类别 | 必须记录 |
| --- | --- |
| 面积 | 总 cell area、组合/时序面积、各模块面积占比 |
| 时序 | 目标周期、WNS/TNS、最差路径、路径经过的归约树或 FP32 add 逻辑 |
| 功耗 | internal/switching/leakage、活动率来源、仿真窗口 |
| 环境 | 工具版本、库版本、corner、约束版本、RTL commit |
| 可解释性 | 与 `llmt_col` partial-sum 归约、16 列阵列复制、FP32 accumulator 的关联 |

## 6. 预计风险

- `llmt_col` 内的 dot32 reduction 和 FP32 add 可能成为关键路径。
- 16 列并行复制会放大面积和切换功耗。
- 若真实目标频率较高，可能需要继续拆分 partial sum 或 FP32 add pipeline。
- 若后端要求门级仿真和 SDF 回标，当前仓库还需要补门级验证流程。

## 7. 当前可写入提交材料的说法

可以写：

- “本项目已准备 RTL handoff 所需的约束和综合脚本模板。”
- “当前 PPA 章节提供后端接入方法和待补报告项。”
- “真实 28nm 面积、功耗和时序需要在获得标准单元库与综合环境后补齐。”

不可以写：

- “本设计已在 28nm 达到某频率。”
- “面积/功耗为某具体数值。”
- “Yosys generic stat 等价于 28nm PPA。”
