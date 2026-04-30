# 07 如何阅读这个仓库

## 第一遍只看地图

先不要立刻钻进每一行 RTL。第一遍只建立目录地图：

| 目录 | 作用 |
| --- | --- |
| `rtl/` | 可综合 Verilog 设计本体 |
| `tb/` | Verilog testbench |
| `tools/` | Python golden model、向量生成、统计 |
| `sim/` | 一键运行脚本 |
| `vectors/` | 固定输入和 expected output |
| `docs/primer/` | 零基础背景教程 |
| `docs/teaching/` | 逐文件代码讲解 |
| `docs/report/` | 比赛报告正文 |
| `reports/` | 日志、JSON、证据、PPA 边界说明 |

## 第二遍按信号流读

推荐顺序：

1. `rtl/mx_defs.vh`：看全局宽度和规模。
2. `rtl/mx_funcs.vh`：看 E4M3/E8M0 怎么解释。
3. `rtl/llmt_col.v`：看一列如何做 dot32 和累加。
4. `rtl/mx_array_32x16.v`：看 16 列如何并排。
5. `tb/tb_llmt_col_smoke.v`：看最小输入怎么喂。
6. `tb/tb_mx_array_dataset.v`：看矩阵级向量怎么比对。

## 第三遍跑命令

在仓库根目录运行：

```powershell
.\sim\run_iverilog.ps1
.\sim\run_waveform_smoke.ps1
.\sim\run_python_ref.ps1
```

默认回归日志在 `reports/verification/`。波形 VCD 在 `reports/evidence/waveforms/`。

## 答辩复述模板

可以按 6 句话讲：

1. 本项目实现 `Y=A*B` 的 MXFP8 `32x16` 前端 RTL 计算阵列。
2. 每个 MXFP8 block 有 32 个 E4M3 元素和 1 个 E8M0 scale。
3. `llmt_col` 完成 dot32、fixed-to-FP32 和 FP32 accumulator。
4. `mx_array_32x16` 把 A block 广播给 16 个列单元，每列接收不同 B block。
5. 验证覆盖 smoke、corner、back-to-back、矩阵 dataset、tail tile、nonfinite、4096 抽样和波形展示。
6. 当前是前端 handoff 包，真实 28nm PPA 等后端库和工具。

## 常见错误

- 第一遍就逐行读 `fp32_add_rne.v`，容易丢失系统视角。
- 跑脚本后只看最后 PASS，不看日志归档路径。
- 把开发过程文件当作正式提交材料。

## 自测题

1. 如果要解释顶层接口，应该先读哪个 RTL？
2. 如果要解释 tail tile，应该先读哪个 testbench？
3. 如果要解释后端边界，应该引用哪个 primer 章节？

## 用自己的话复述

“我会先看目录地图，再沿着 MXFP8 解码、列单元、阵列顶层、testbench、报告证据的顺序读。读完后要能跑回归、打开 VCD，并清楚说明哪些是前端已完成，哪些是后端阻塞。”
