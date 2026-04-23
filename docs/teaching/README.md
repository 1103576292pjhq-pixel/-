# 代码讲解总入口

这部分文档用于给 0 基础读者讲解代码，不和正式报告混写。

## 建议阅读顺序
1. 先看 [NPU 背景教程](/D:/github/-/docs/primer/01_npu_basics.md)
2. 再看 [技术报告初稿](/D:/github/-/docs/report/tech_report.md)
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

## 讲解目标
- 知道每个文件是干什么的
- 知道输入输出是什么意思
- 能解释关键 always 块为什么这样写
- 能用自己的话复述“输入 block 怎么一步步变成输出 FP32”

## 当前状态
当前已经补出 `llmt_col` 三级流水文档（已同步到 `4x8` 分组归约树版本），以及 `tb_mx_array_dataset` 的矩阵级 burst / tail tile 驱动讲解。  
后续 `P7` 会继续把其他文件拆成独立讲解文档，做到“逐文件逐段解释”。
