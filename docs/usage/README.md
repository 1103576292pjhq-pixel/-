# 工程使用说明

## 1. 环境要求
- Windows PowerShell
- `iverilog` / `vvp`
- Python 3.12 或兼容版本

## 2. 运行 Verilog 基础回归
```powershell
./sim/run_iverilog.ps1
```

当前会运行：
- `tb_llmt_col_smoke`
- `tb_llmt_col_back_to_back`
- `tb_llmt_col_corner`
- `tb_mx_array_smoke`
- `tb_mx_array_dataset`：读取 `vectors/matmul_4x16x64_smoke/` 的 `.hex` 数据，按 burst 方式连续送入一个 tile 的全部 `K_BLOCKS`，再逐 tile 对比 `expected_y.hex`
- `tb_mx_array_dataset_3x18x64_nonfinite`：读取 `vectors/matmul_3x18x64_nonfinite/` 的 `.hex` 数据，覆盖 mixed finite / `inf` / `NaN` 输出与尾 tile 并存场景
- `tb_mx_array_dataset_6x33x160_nonfinite`：读取 `vectors/matmul_6x33x160_nonfinite/` 的 `.hex` 数据，覆盖三列 tile、最后一 tile 只剩 1 个有效 lane、`K=160` 与 mixed finite / `inf` / `NaN` 并存场景
- `tb_mx_array_dataset_7x49x224_sparse_nonfinite`：读取 `vectors/matmul_7x49x224_sparse_nonfinite/` 的 `.hex` 数据，覆盖四列 tile、最后一 tile 只剩 1 个有效 lane、`K=224`，并在有限值底座上稀疏注入 scale-NaN 与 element-NaN
- `tb_mx_array_dataset_5x20x96`：读取 `vectors/matmul_5x20x96_tail/` 的 `.hex` 数据，覆盖 `N=20` 尾 tile 零填充、`K=96` 与奇数行场景
- `tb_mx_array_dataset_8x32x128`：读取 `vectors/matmul_8x32x128_smoke/` 的 `.hex` 数据并覆盖双 tile、`K=128` 场景
- `tb_mx_array_dataset_9x65x192`：读取 `vectors/matmul_9x65x192_five_tiles/` 的 `.hex` 数据，覆盖五列 tile、最后一 tile 只剩 1 个有效 lane、`K=192` 与更大的有限值矩阵组合

其中 `tb_mx_array_dataset` 现已支持 `N` 不是 `16` 整数倍的情况：最后一个 tile 未使用的列 lane 会自动喂入零 block。对于有限值行，这些 padded lane 在收尾时应保持 `FP32 zero`；如果该行本身含 `NaN`，则 padded lane 也可能合法地产生 `QNaN`，testbench 会按行内容建模这个期望值。与此同时，testbench 会显式检查 `valid_o` 只能 16 位同时为 0 或同时为 1，因此用 `valid_o[0]` 作为等待条件不会掩盖单列失步。

## 3. 运行 Python 参考模型自检
```powershell
./sim/run_python_ref.ps1
```

## 4. 生成随机 dot32 日志
```powershell
python ./tools/mx_ref.py --random 8 --seed 1234
```

## 5. 导出 dot32 向量集
```powershell
python ./tools/mx_ref.py --emit-dot32-vectors 64 --seed 1234 --outdir ./vectors/dot32_demo
```

## 6. 导出矩阵级数据集
```powershell
python ./tools/mx_ref.py --emit-matmul-dataset --m 8 --n 8 --k 64 --seed 1234 --outdir ./vectors/matmul_demo
```

如果希望导出更稳定、便于硬件回归的有限值数据集：
```powershell
python ./tools/mx_ref.py --emit-matmul-dataset --m 4 --n 16 --k 64 --seed 20260423 --finite-only --outdir ./vectors/matmul_4x16x64_smoke
```

更长 `K` / 多 tile 数据集示例：
```powershell
python ./tools/mx_ref.py --emit-matmul-dataset --m 8 --n 32 --k 128 --seed 20260424 --finite-only --outdir ./vectors/matmul_8x32x128_smoke
```

五列 tile 数据集示例：
```powershell
python ./tools/mx_ref.py --emit-matmul-dataset --m 9 --n 65 --k 192 --seed 20260502 --finite-only --outdir ./vectors/matmul_9x65x192_five_tiles
```

尾 tile 数据集示例：
```powershell
python ./tools/mx_ref.py --emit-matmul-dataset --m 5 --n 20 --k 96 --seed 20260425 --finite-only --outdir ./vectors/matmul_5x20x96_tail
```

mixed nonfinite 数据集示例：
```powershell
python ./tools/mx_ref.py --emit-matmul-dataset --m 3 --n 18 --k 64 --seed 20260430 --outdir ./vectors/matmul_3x18x64_nonfinite
```

三列 tile mixed nonfinite 数据集示例：
```powershell
python ./tools/mx_ref.py --emit-matmul-dataset --m 6 --n 33 --k 160 --seed 20260501 --outdir ./vectors/matmul_6x33x160_nonfinite
```

稀疏 mixed nonfinite 数据集示例：
```powershell
python ./tools/mx_ref.py --emit-matmul-dataset --m 7 --n 49 --k 224 --seed 20260509 --elem-nan-stride 1009 --scale-nan-stride 149 --outdir ./vectors/matmul_7x49x224_sparse_nonfinite
```

`tools/mx_ref.py` 在导出 `.hex` 时会把所有 `NaN` 统一规范化为 canonical `0x7fc00000`，避免宿主平台保留 NaN 符号位时把硬件/黄金模型的语义对齐误判成失败。

## 7. 生成 `4096x4096` 抽样统计
```powershell
./sim/run_matmul_stats.ps1
```

默认行为：
- 规模：`4096 x 4096 x 4096`
- 采样：`2048` 个输出点
- 输入：有限值 `MXFP8` 随机块，`E8M0` 指数范围 `[-8, 8]`
- 输出：`reports/matmul_stats_4096x4096x4096.json`

如需自定义：
```powershell
./sim/run_matmul_stats.ps1 -M 1024 -N 1024 -K 2048 -Samples 512 -Seed 7
```

如需跑更宽的有限值指数范围，建议补一个 tag，避免覆盖默认报告：
```powershell
./sim/run_matmul_stats.ps1 -ScaleExpMin -32 -ScaleExpMax 32 -Tag finite_exp32
```

如果确实要观测非有限值输入，可显式关闭 `finite-only`：
```powershell
./sim/run_matmul_stats.ps1 -AllowNonFinite -Tag mixed_nonfinite
```

如果想保留大多数 finite 样本、只稀疏注入少量 `NaN`，可以直接传 stride：
```powershell
./sim/run_matmul_stats.ps1 -ElemNanStride 524288 -ScaleNanStride 262144 -Tag sparse_nonfinite
```

此时 JSON 会额外给出 `matched_nonfinite_count` / `mismatched_nonfinite_count`，而 `mean_*` / `max_*` 只对 finite samples 统计，不会被 `inf` / `NaN` 直接污染成 `nan`。

## 8. 生成 `4096x4096` 多 seed sweep
```powershell
./sim/run_matmul_stats_sweep.ps1
```

默认行为：
- seeds：`20260423`、`20260503`、`20260504`
- 规模：`4096 x 4096 x 4096`
- 采样：每个 seed `2048` 个输出点
- 输出：
  - `reports/matmul_stats_4096x4096x4096_seed*.json`
  - `reports/matmul_stats_4096x4096x4096_sweep.json`

该脚本现支持 `-Tag`、`-ScaleExpMin` / `-ScaleExpMax`、`-AllowNonFinite` 与 `-ElemNanStride` / `-ScaleNanStride`。如果 sweep 中出现 `inf` / `NaN`，摘要会把 finite / nonfinite 计数分别列出，并把 `matched_nonfinite_count` / `mismatched_nonfinite_count` 单独统计；`-Seeds 1,2,3` 这类逗号分隔写法也已做兼容处理。

如需自定义：
```powershell
./sim/run_matmul_stats_sweep.ps1 -Samples 1024 -Seeds 1,2,3 -ScaleExpMin -32 -ScaleExpMax 32 -Tag finite_exp32 -OutFile ./reports/custom_sweep.json
```

## 9. 生成 `4096x4096` profile sweep
```powershell
./sim/run_matmul_stats_profiles.ps1
```

默认会跑四档 profile：
- baseline `[-8, 8]`
- `finite_exp32` `[-32, 32]`
- `finite_exp64` `[-64, 64]`
- `sparse_nonfinite`：有限值底座 `[-8,8]` + 稀疏 `NaN` 注入

输出包括：
- `reports/matmul_stats_4096x4096x4096_finite_exp32_seed*.json`
- `reports/matmul_stats_4096x4096x4096_finite_exp32_sweep.json`
- `reports/matmul_stats_4096x4096x4096_finite_exp64_seed*.json`
- `reports/matmul_stats_4096x4096x4096_finite_exp64_sweep.json`
- `reports/matmul_stats_4096x4096x4096_sparse_nonfinite_seed*.json`
- `reports/matmul_stats_4096x4096x4096_sparse_nonfinite_sweep.json`
- `reports/matmul_stats_4096x4096x4096_profiles.json`

其中 `finite_exp64` 会显式暴露 `inf_count` / `nan_count` / `mismatched_nonfinite_count`，用于定位“逐 block 转 `FP32` 再累加”在极宽指数范围下何时开始早于理想双精度累加发生溢出或无效化；`sparse_nonfinite` 则用于验证少量 `NaN` 注入时，finite 子集误差统计和 nonfinite 传播能否被稳定分开观察。

## 10. 目录说明
- `rtl/`：纯 Verilog RTL
- `tb/`：Verilog testbench
- `tools/`：Python 工具
- `sim/`：回归脚本
- `constraints/`：时序约束
- `synth/`：综合脚本模板
- `reports/`：综合/验证报告输出位
- `docs/`：技术与教学文档
