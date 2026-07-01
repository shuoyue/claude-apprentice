切换到全栈协调模式。从现在起，你需要同时关注前后端一致性和完整数据流。

## 约束

- 后端遵循 `.claude/memory/backend-standards.md`，前端遵循 `.claude/memory/frontend-standards.md`
- 前后端数据格式必须统一，接口契约必须一致
- 开发顺序：数据库 → 后端 API → 前端页面，自底向上
- 前端 API 调用必须与后端接口定义匹配（字段名、类型、路径）
- 错误处理链路完整：数据库异常 → 后端异常处理 → 前端错误展示

## 下一步

- **简单任务**（改字段/修 bug）：直接描述需求即可
- **中等任务**（新页面+新接口）：说"帮我设计一下"，会触发 brainstorming
- **复杂任务**（新功能模块）：说"帮我规划"，会走 brainstorming → planning → TDD 完整流程
- **完整流程**：调用 `/fullstack-workflow` 走结构化全栈开发流水线

$ARGUMENTS
