# Synthesis Notes

这个目录存放综合相关脚本模板。

当前策略：
- 先提供通用模板，确保工程接口、目录和约束位完整
- 真正使用 28nm 库时，只需要替换库路径和 top 名称即可

建议流程：
1. 用通用脚本检查 RTL 结构和顶层连线
2. 用真实 28nm 标准单元库跑 Design Compiler / Genus
3. 把结果输出到 `reports/`
