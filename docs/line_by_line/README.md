# 逐行代码讲解总入口

这套目录专门放“逐行读代码”的 Markdown 教材。它和 `docs/teaching/` 的区别是：

| 目录 | 用途 | 读者 |
| --- | --- | --- |
| `docs/primer/` | 先补 NPU、MXFP8、Verilog、验证背景 | 几乎没有 NPU 基础的人 |
| `docs/teaching/` | 逐文件复述地图和答辩说明 | 要快速讲清设计的人 |
| `docs/line_by_line/` | 按源码行号解释每一段代码 | 要真正读懂代码的人 |

原则：

1. 不在 `rtl/`、`tb/`、`tools/`、`sim/` 源文件里新增逐行注释。
2. 所有逐行解释写成独立 Markdown。
3. 每篇 Markdown 都保留源码行号，方便读者对照原文件。
4. 对零基础读者，先解释“这行在硬件里意味着什么”，再解释语法。
5. 对比赛答辩，最后给出“这段怎么复述”的短句。

## 文件夹拆分

| 文件夹 | 内容 |
| --- | --- |
| `00_reading_method/` | 如何读逐行讲解，先看什么、后看什么 |
| `01_rtl/` | `rtl/*.v` 和 `rtl/*.vh` 的逐行讲解 |
| `02_testbench/` | `tb/*.v` 的逐行讲解 |
| `03_tools_and_scripts/` | `tools/*.py`、`sim/*.ps1` 的逐行讲解 |
| `04_retell/` | 一周复述卡片、答辩口径、常见问答 |

## 推荐阅读顺序

1. 先读 `00_reading_method/README.md`，知道怎么对照行号。
2. 再读 `01_rtl/00_mx_defs_vh.md`，理解全局尺寸和常量。
3. 接着读 `01_rtl/01_mx_funcs_vh.md` 到 `01_rtl/07_mx_array_32x16_v.md`。
4. RTL 读完后再读 testbench，不要一开始被仿真语法带偏。
5. 最后读 Python 和 PowerShell 脚本，理解向量、回归和报告怎么生成。

## 当前状态

当前已建立目录规范，并补了三个完整样板：

- `01_rtl/00_mx_defs_vh.md`
- `01_rtl/04_fixed_to_fp32_v.md`
- `01_rtl/07_mx_array_32x16_v.md`

后续续写时，按这三个文件的格式扩展全部 RTL、testbench、Python 和脚本。
