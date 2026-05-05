# 代码讲解覆盖矩阵

本矩阵用于检查“评审或队友问到某个文件时，是否能找到对应讲解”。详细逐文件复述见 [07_major_file_defense_map.md](07_major_file_defense_map.md)。

| 文件 | 当前讲解 | 覆盖程度 | 仍需注意 |
| --- | --- | --- | --- |
| `rtl/mx_defs.vh` | `04_mx_format_helpers.md`、`07_major_file_defense_map.md`、`../line_by_line/01_rtl/00_mx_defs_vh.md` | 逐行样板已补 | 讲清宏如何影响总线宽度 |
| `rtl/mx_funcs.vh` | `04_mx_format_helpers.md`、`07_major_file_defense_map.md` | 答辩覆盖 | 后续逐行讲清 NaN 标记和 fixed zero 分离 |
| `rtl/e4m3_decode.v` | `04_mx_format_helpers.md`、`07_major_file_defense_map.md` | 答辩覆盖 | 后续逐行说明它是格式展示/复用解码，不是矩阵调度 |
| `rtl/e8m0_scale_decode.v` | `04_mx_format_helpers.md`、`07_major_file_defense_map.md` | 答辩覆盖 | 后续逐行说明 scale NaN 和 exponent 输出 |
| `rtl/fixed_to_fp32.v` | `06_fp32_helpers_and_column_tests.md`、`07_major_file_defense_map.md`、`../line_by_line/01_rtl/04_fixed_to_fp32_v.md` | 逐行样板已补 | 重点讲规格化、RNE 和 FP32 subnormal 输出 |
| `rtl/fp32_add_rne.v` | `06_fp32_helpers_and_column_tests.md`、`07_major_file_defense_map.md` | 答辩覆盖 | 后续逐行重点讲对阶、加减、规格化、nearest-even |
| `rtl/llmt_col.v` | `01_llmt_col_pipeline.md`、`07_major_file_defense_map.md` | 答辩覆盖 | 后续逐行重点讲三级流水和 `acc_clear` 延迟 |
| `rtl/mx_array_32x16.v` | `03_mx_array_top.md`、`07_major_file_defense_map.md`、`../line_by_line/01_rtl/07_mx_array_32x16_v.md` | 逐行样板已补 | 重点讲 A 广播、B 分列、输出打包 |
| `tb/tb_llmt_col_smoke.v` | `06_fp32_helpers_and_column_tests.md`、`07_major_file_defense_map.md` | 答辩覆盖 | 后续逐行说明 32 和 64 的手算来源 |
| `tb/tb_llmt_col_corner.v` | `06_fp32_helpers_and_column_tests.md` | 重点覆盖 | 已覆盖 E4M3 subnormal、FP32 subnormal、NaN 和 clear；可按需要继续补逐 case 表 |
| `tb/tb_llmt_col_back_to_back.v` | `06_fp32_helpers_and_column_tests.md`、`07_major_file_defense_map.md` | 答辩覆盖 | 后续逐行说明连续 `valid_i` 为什么重要 |
| `tb/tb_mx_array_smoke.v` | `07_major_file_defense_map.md` | 答辩覆盖 | 后续逐行补波形证据入口 |
| `tb/tb_mx_array_dataset.v` | `02_mx_array_dataset_tail_tiles.md`、`07_major_file_defense_map.md` | 答辩覆盖 | 后续逐行重点讲 manifest、tail tile、nonfinite |
| `tools/mx_ref.py` | `05_python_ref_and_scripts.md`、`07_major_file_defense_map.md` | 答辩覆盖 | 后续逐行说明它既生成向量也做统计 |
| `sim/*.ps1` | `05_python_ref_and_scripts.md`、`07_major_file_defense_map.md` | 答辩覆盖 | 后续逐行补入 `run_waveform_smoke.ps1` |

## 讲解完成口径

本目录的“覆盖”只表示答辩和复述覆盖，不等于已经完成逐行教材。一个文件算“答辩覆盖”，至少要能回答：

1. 它在系统里的目的是什么。
2. 输入、输出或命令参数是什么。
3. 关键内部信号/数据结构是什么。
4. 是否有组合逻辑、时序逻辑或脚本阶段。
5. 为什么这段逻辑存在。
6. 答辩时怎样用 2 到 3 句话复述。

## 后续可增强

- 真正逐行教材统一放在 `docs/line_by_line/`，不要把逐行解释继续塞回源码注释或本目录概览文档。
- 如果主办方给出答辩模板，把 `07_major_file_defense_map.md` 裁剪成正式讲稿。
- 如果真实后端工具返回 timing，给 `fixed_to_fp32`、`fp32_add_rne`、`llmt_col` 补“后端最差路径如何解读”小节。
- 如果新增 benchmark，补对应 dataset wrapper 和向量生成说明。
