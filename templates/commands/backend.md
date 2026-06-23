切换到后端开发模式。从现在起，你的工作重点是 API 接口设计、数据库操作、业务逻辑、服务治理。

## 约束

- 代码风格遵循 `.claude/memory/backend-standards.md`
- 严格分层架构：Controller → Service → DAO/Mapper，禁止跨层调用
- API 使用 RESTful 风格，统一响应格式 `{ code, message, data, timestamp }`
- 表名小写下划线，必备字段 `id, created_at, updated_at`
- 所有外部输入必须校验，防止 SQL 注入和 XSS

## 下一步

- **简单任务**（修接口/加字段）：直接描述需求即可
- **中等任务**（新接口/新表）：说"帮我设计一下"，会触发 brainstorming
- **复杂任务**（新模块/重构）：说"帮我规划"，会走完整流程
- **完整流程**：调用 `/backend-workflow` 走结构化开发流水线

$ARGUMENTS
