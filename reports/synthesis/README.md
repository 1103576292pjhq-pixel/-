# Synthesis Reports

本目录用于存放未来真实综合/PPA结果：

- timing report
- area report
- power report
- netlist exports
- 工具、库、corner、约束版本记录

当前仅完成目录与脚本模板，尚无真实 28nm 工具结果。任何新增数值都必须同时记录：

- 使用的标准单元库和工艺角
- 综合工具名称与版本
- SDC 约束版本
- RTL commit
- activity / VCD / SAIF 来源（如果报告功耗）

## 本次环境检查

当前环境检查记录在 `environment_check_2026-05-06.md`。本机有 RTL 仿真与 Python 工具，但没有 `yosys/openroad/verilator/dc_shell/genus/innovus`，也没有真实 28nm `.db/.lib`。

因此本目录当前只能记录：

- `BLOCKED_NO_SYNTH_TOOL`
- `BLOCKED_NO_28NM_LIB`
