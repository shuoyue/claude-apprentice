<important if="editing any source code file">
编码标准：

- 不引入安全漏洞（SQL 注入、XSS、命令注入等 OWASP Top 10）
- 不添加超出任务需求的抽象或功能
- 不写多余注释，只在 WHY 不明显时注释
- 命名清晰即可，不写解释 WHAT 的注释
</important>

<important if="creating or modifying backend code">
后端分层：

- Controller 层：只接收请求、参数校验，不写业务逻辑
- Service 层：业务逻辑，可调用 DAO 或其他 Service
- DAO/Repository 层：数据访问，不含业务逻辑
- 禁止跨层调用，统一响应格式，异常统一处理
</important>

<important if="creating or modifying frontend code">
前端规范：

- 组件文件名 PascalCase，新增前先搜索已有组件
- API 调用统一通过 `api/` 目录模块，不直接写 fetch/axios
- 处理 loading / error / empty 三种状态
</important>
