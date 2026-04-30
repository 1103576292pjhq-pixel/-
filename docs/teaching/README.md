# 代码讲解总入口

这部分文档用于给 0 基础读者讲解代码，不和正式报告混写。

## 建议阅读顺序
1. 先看 [NPU 背景教程](../primer/README.md)
2. 再看 [提交版技术报告目录](../report/README.md)
3. 最后按下面顺序读代码：
   - `rtl/mx_defs.vh`
   - `rtl/mx_funcs.vh`
   - `rtl/e4m3_decode.v`
   - `rtl/e8m0_scale_decode.v`
   - `rtl/fixed_to_fp32.v`
   - `rtl/fp32_add_rne.v`
   - `rtl/llmt_col.v`
   - `rtl/mx_array_32x16.v`
   - `tb/*.v`
   - `tools/mx_ref.py`

首篇讲解文档：
- [llmt_col 三级流水讲解](/D:/github/-/docs/teaching/01_llmt_col_pipeline.md)
- [矩阵级数据集回归与尾 tile 讲解](/D:/github/-/docs/teaching/02_mx_array_dataset_tail_tiles.md)
- [mx_array_32x16 顶层讲解](/D:/github/-/docs/teaching/03_mx_array_top.md)
- [MX 格式 helper 讲解](/D:/github/-/docs/teaching/04_mx_format_helpers.md)
- [Python 参考模型和脚本讲解](/D:/github/-/docs/teaching/05_python_ref_and_scripts.md)
- [FP32 辅助模块和列级 testbench 讲解](/D:/github/-/docs/teaching/06_fp32_helpers_and_column_tests.md)
- [主要文件答辩复述地图](07_major_file_defense_map.md)
- [代码讲解覆盖矩阵](coverage_plan.md)

## 讲解目标
- 知道每个文件是干什么的
- 知道输入输出是什么意思
- 能解释关键 always 块为什么这样写
- 能用自己的话复述“输入 block 怎么一步步变成输出 FP32”

## 当前状态
当前已经覆盖 `llmt_col`、矩阵级 dataset testbench、阵列顶层、MX 格式 helper、FP32 辅助模块、列级 testbench、阵列 smoke、Python 参考模型和脚本。后续如果继续扩展，按 [coverage_plan.md](coverage_plan.md) 做更细的逐行注释或答辩问答。
