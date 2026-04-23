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
- `tb_llmt_col_corner`
- `tb_mx_array_smoke`

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

## 7. 目录说明
- `rtl/`：纯 Verilog RTL
- `tb/`：Verilog testbench
- `tools/`：Python 工具
- `sim/`：回归脚本
- `constraints/`：时序约束
- `synth/`：综合脚本模板
- `reports/`：综合/验证报告输出位
- `docs/`：技术与教学文档
