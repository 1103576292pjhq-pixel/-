# NPU 背景教程 05：0 基础读者如何读这个仓库

## 1. 一周学习安排

| 天数 | 目标 | 要读的文件 |
| --- | --- | --- |
| Day 1 | 明白赛题和 NPU 基础 | `docs/primer/01_npu_basics.md` |
| Day 2 | 明白 tile、数据流、阵列 | `docs/primer/02_dataflow_and_tiling.md`、`docs/report/03_architecture_and_dataflow.md` |
| Day 3 | 明白 MXFP8 数值路径 | `docs/primer/03_mxfp8_numeric_path.md`、`docs/report/02_mx_format_and_numeric_rules.md` |
| Day 4 | 读懂 `llmt_col` | `docs/teaching/01_llmt_col_pipeline.md`、`rtl/llmt_col.v` |
| Day 5 | 读懂阵列和 testbench | `docs/teaching/02_mx_array_dataset_tail_tiles.md`、`docs/teaching/03_mx_array_top.md` |
| Day 6 | 跑回归和看统计 | `docs/primer/04_verification_and_error_metrics.md`、`reports/evidence/` |
| Day 7 | 练习复述比赛报告 | `docs/report/00_requirements_traceability.md` 到 `09_submission_checklist.md` |

## 2. 目录地图

| 目录 | 作用 |
| --- | --- |
| `rtl/` | 硬件设计本体 |
| `tb/` | Verilog testbench |
| `tools/` | Python golden model 和向量/统计工具 |
| `sim/` | 一键运行脚本 |
| `vectors/` | 固定输入和 expected output |
| `docs/report/` | 比赛技术报告正文 |
| `docs/primer/` | 零基础背景课 |
| `docs/teaching/` | 逐文件代码讲解 |
| `reports/` | 日志、统计、证据、PPA 模板 |

## 3. 第一次跑命令

在仓库根目录运行：

```powershell
.\sim\run_python_ref.ps1
.\sim\run_iverilog.ps1
```

如果都 PASS，再看：

```powershell
.\sim\run_matmul_stats.ps1
```

长 profile sweep 会更慢，适合最后再跑。

## 4. 复述模板

你可以按这 5 句话复述项目：

1. 这个项目实现一个 `32 x 16` MXFP8 计算阵列。
2. 每个 block 有 32 个 E4M3 元素，并共享 E8M0 scale。
3. 顶层用 output-stationary 数据流，16 列各自维护 FP32 accumulator。
4. 验证覆盖列级、阵列级、矩阵级、tail tile、nonfinite 和 4096 抽样。
5. 当前交付是 RTL/backend handoff 包，真实 28nm PPA 还需要后端库和工具。

## 5. 常见误区

- 不要把 `32 x 16` 说成 32 行 16 列完整 systolic array；这里的 `32` 是 K block 长度。
- 不要把 Yosys generic stat 说成 28nm 面积。
- 不要只看一个 smoke test 就说“全功能正确”。
- 不要把 NaN/Inf 的类别问题混进普通相对误差。
