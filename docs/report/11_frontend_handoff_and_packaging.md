# 11 前端到后端移交与打包说明

## 1. 当前交付定位

本仓库当前交付的是 MXFP8 NPU 计算阵列的前端 RTL handoff package：

- 有纯 Verilog RTL。
- 有 testbench、固定向量、Python golden model 和回归日志。
- 有综合约束和脚本模板。
- 有报告、证据索引和使用说明；教学文档保留在仓库内，但不进入第一轮正式 handoff 包。

它不是完整 28nm 后端 signoff 包。真实面积、功耗、频率、WNS/TNS、门级仿真、功耗活动率和版图结果必须由后端在真实库、真实工具和真实约束下生成。

## 2. 后端应接收哪些文件

| 类别 | 路径 | 用途 |
| --- | --- | --- |
| RTL | `rtl/*.v`、`rtl/*.vh`、`synth/rtl_filelist.f` | 可综合前端设计；`rtl_filelist.f` 是后端读入顺序入口 |
| Testbench | `tb/*.v` | RTL 功能复验，不进入综合 |
| 仿真脚本 | `sim/run_iverilog.ps1`、`sim/run_waveform_smoke.ps1` | 默认回归和波形证据生成 |
| 截图脚本 | `sim/render_waveform_screenshots.ps1`、`tools/render_waveform_png.py` | 从归档 VCD 生成报告级 PNG |
| Python golden | `tools/mx_ref.py` | 向量生成、参考模型、4096 抽样统计 |
| 固定向量 | `vectors/` | dataset testbench 输入和 expected output |
| 约束模板 | `constraints/mx_array_32x16.sdc` | 后端约束起点，需按真实工艺/频率改写 |
| 综合模板 | `synth/rtl_filelist.f`、`synth/run_dc_template.tcl`、`synth/run_yosys_generic.ys` | 综合流程起点，不是 signoff 结果 |
| 报告 | `docs/report/` | 技术方案、验证、PPA 边界和提交清单 |
| 证据 | `reports/verification/`、`reports/precision/`、`reports/evidence/` | PASS 日志、统计 JSON、波形和证据索引 |

## 3. 顶层模块

顶层模块是：

```text
mx_array_32x16
```

源文件：

```text
rtl/mx_array_32x16.v
```

它实例化 16 个 `llmt_col`。A block 广播给 16 列，B block 和 accumulator 输出按列打包。

## 4. 时钟、复位和控制信号

| 信号 | 方向 | 含义 |
| --- | --- | --- |
| `clk` | input | 单时钟域时钟 |
| `rst_n` | input | 低有效异步复位 |
| `valid_i` | input | 本拍输入 A/B block 有效 |
| `acc_clear_i[15:0]` | input | 每列 accumulator 清零控制；新输出起点置 1 |
| `valid_o[15:0]` | output | 每列输出有效 |
| `acc_o[16*32-1:0]` | output | 16 个 FP32 accumulator 输出打包 |

数据端口：

- `a_elems_i[32*8-1:0]`：一个 A MXFP8 block 的 32 个 E4M3 元素。
- `a_scale_i[7:0]`：A block 的 E8M0 scale。
- `b_elems_i[16*32*8-1:0]`：16 个 B block 的 E4M3 元素，按列打包。
- `b_scale_i[16*8-1:0]`：16 个 B block 的 E8M0 scale，按列打包。

## 5. 已有脚本和模板

| 脚本/模板 | 当前作用 | 后端注意事项 |
| --- | --- | --- |
| `sim/run_iverilog.ps1` | 默认 Verilog 回归 | 功能复验入口 |
| `sim/run_waveform_smoke.ps1` | 生成小 VCD 波形 | 只用于展示，不替代回归 |
| `sim/run_python_ref.ps1` | Python 自检和基础向量 | 参考模型入口 |
| `sim/run_matmul_stats*.ps1` | 4096 抽样统计 | 数值趋势证据 |
| `constraints/mx_array_32x16.sdc` | SDC 起点 | 真实频率、IO、uncertainty 需后端确认 |
| `synth/rtl_filelist.f` | RTL 读入顺序 | 后端可据此生成 `read_verilog`/`analyze` 命令 |
| `synth/run_dc_template.tcl` | Design Compiler 模板 | 需填真实 28nm `.db`、corner 和报告路径 |
| `synth/run_yosys_generic.ys` | generic synthesis 参考 | 不可当作 28nm PPA |

## 6. 应包含的验证证据

提交或移交时建议至少包含：

- `reports/verification/iverilog_default.log`
- `reports/verification/python_ref_default.log`
- `reports/verification/waveform_smoke.log`
- `reports/evidence/waveforms/*.vcd`
- `reports/evidence/waveform_screenshots/*.png`
- `reports/evidence/regression_log_index.md`
- `reports/evidence/key_case_list.md`
- `reports/evidence/waveform_capture_status.md`
- `reports/evidence/sampling_4096_method.md`
- `reports/evidence/boundary_nonfinite_coverage.md`
- `reports/precision/matmul_stats_4096x4096x4096_profiles.json`

这些证据证明功能回归、数值统计和展示波形已具备。真实后端仍需新增综合、STA、功耗和门级仿真日志。

## 7. 后端必须补齐

- 真实 28nm 标准单元库 `.lib/.db`。
- 真实 corner、RC、wireload 或提取规则。
- 目标频率、时钟不确定度、IO delay、load、drive。
- 综合工具和版本、原始综合日志、面积报告、timing report、power report。
- power activity 来源、工作负载窗口和报告生成命令。
- 门级网表、SDF、门级仿真结果。
- 版图相关 DRC/LVS/IR/EM/signoff 结果。

## 8. 禁止在正式包中声称

在没有真实工具原始日志前，禁止写：

- 禁止声称“已完成真实 28nm PPA”。
- 禁止声称“已达到某个真实 MHz/GHz 频率”。
- 禁止声称“已得到某个真实面积或功耗数值”。
- 禁止声称“Yosys generic 结果等同于 28nm 综合结果”。
- 禁止声称“模板脚本已经代表 signoff 通过”。

允许写：

- 当前前端 RTL 回归 PASS。
- 当前提供 28nm 后端移交模板。
- 真实 PPA 阻塞于外部库、工具、corner 和约束。

## 9. 不应放入官方提交包

不要把这些开发/运行状态文件放进正式包：

- `.codexpotter/`
- `.omx/`
- `work/`
- 临时 runner 文件
- 未整理的后台运行日志
- GitHub/PR 或 agent 内部记录

`potter-run.log` 可作为本仓库内部阶段记录，但正式评审包应优先使用 `reports/`、`docs/report/`、`README.md`、`MAIN.md` 和 `STATUS.md`。

## 10. 打包前最终检查

1. 运行或确认 `sim/run_iverilog.ps1` 最新 PASS。
2. 运行或确认 `sim/run_waveform_smoke.ps1` 生成 VCD。
3. 确认 `docs/report/09_submission_checklist.md`、本文件和 `STATUS.md` 的状态一致。
4. 搜索是否误写真实 28nm 面积、功耗、频率或 signoff。
5. 确认正式包没有 `.codexpotter`、`.omx`、`work/` 或临时 runner 文件。
