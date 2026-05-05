# 03 工具和脚本逐行讲解

本目录用于讲 `tools/` 和 `sim/`。这些文件不进入硬件综合，但它们负责生成向量、运行回归和产出报告证据。

## 阅读顺序

| 顺序 | 源文件 | 逐行讲解文件 | 状态 |
| --- | --- | --- | --- |
| 1 | `sim/run_iverilog.ps1` | `00_run_iverilog_ps1.md` | 待续写 |
| 2 | `sim/run_waveform_smoke.ps1` | `01_run_waveform_smoke_ps1.md` | 待续写 |
| 3 | `sim/run_python_ref.ps1` | `02_run_python_ref_ps1.md` | 待续写 |
| 4 | `sim/run_matmul_stats*.ps1` | `03_run_matmul_stats_scripts.md` | 待续写 |
| 5 | `tools/mx_ref.py` | `04_mx_ref_py.md` | 待续写 |

## 为什么脚本也要逐行讲

比赛提交不是只交 RTL。评审或后端同学还会问：

1. 回归怎么跑。
2. 向量怎么生成。
3. 4096 统计怎么复现。
4. VCD 波形怎么导出。
5. 哪些文件是证据，哪些只是中间产物。

这些问题主要靠 `sim/` 和 `tools/` 回答。
