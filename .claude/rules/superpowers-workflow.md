<important if="executing any workflow skill">
Workflow 执行规则：

1. 没设计不写代码 — 先确认文件、范围、方案
2. 没测试不写代码 — 先写失败测试，再写实现
3. 没验证不说完成 — 运行验证命令并贴结果
</important>

<important if="encountering a bug or test failure">
调试规则：

- 先找根因再修，不靠猜
- 读堆栈 → 复现 → 追踪数据流 → 假设 → 最小改动验证
- 连续 3 次失败，停下来审视架构
</important>
