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
- `tb_mx_array_dataset_5x20x96`：读取 `vectors/matmul_5x20x96_tail/` 的 `.hex` 数据，覆盖 `N=20` 尾 tile 零填充、`K=96` 与奇数行场景
- `tb_mx_array_dataset_8x32x128`：读取 `vectors/matmul_8x32x128_smoke/` 的 `.hex` 数据并覆盖双 tile、`K=128` 场景

其中 `tb_mx_array_dataset` 现已支持 `N` 不是 `16` 整数倍的情况：最后一个 tile 未使用的列 lane 会自动喂入零 block。对于有限值行，这些 padded lane 在收尾时应保持 `FP32 zero`；如果该行本身含 `NaN`，则 padded lane 也可能合法地产生 `QNaN`，testbench 会按行内容建模这个期望值。

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

尾 tile 数据集示例：
```powershell
python ./tools/mx_ref.py --emit-matmul-dataset --m 5 --n 20 --k 96 --seed 20260425 --finite-only --outdir ./vectors/matmul_5x20x96_tail
```

mixed nonfinite 数据集示例：
```powershell
python ./tools/mx_ref.py --emit-matmul-dataset --m 3 --n 18 --k 64 --seed 20260430 --outdir ./vectors/matmul_3x18x64_nonfinite
```

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

## 8. 目录说明
- `rtl/`：纯 Verilog RTL
- `tb/`：Verilog testbench
- `tools/`：Python 工具
- `sim/`：回归脚本
- `constraints/`：时序约束
- `synth/`：综合脚本模板
- `reports/`：综合/验证报告输出位
- `docs/`：技术与教学文档
