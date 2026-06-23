---
name: backend-workflow
description: 当需要开发或修改后端 API 接口、数据库操作、业务逻辑、服务配置时使用
context: fork
---

# 后端开发流程编排器

你处于后端开发模式。本技能是完整的后端开发流程编排器，每个步骤关联 Superpowers Skill，根据项目配置决定是否启用。

## 配置读取（流程开始前执行）

读取 `.claude/memory/superpowers-config.md` 中的配置，确定每个 Skill 的启用状态：
- **enabled** → 对应步骤始终执行
- **disabled** → 对应步骤始终跳过
- **conditional** → 根据复杂度判断

复杂度：简单（单接口/加字段 < 30 分钟）/ 中等（新表+新接口 30 分钟 - 2 小时）/ 复杂（新模块 > 2 小时）

---

## 流程步骤

### 步骤 0：需求入口 [必选]

- 接收用户需求描述
- 判断复杂度等级
- **简单任务**（修接口/加字段）→ 跳到步骤 3 直接实现
- **中等/复杂任务** → 进入步骤 1

> 关联 Superpowers: using-superpowers

### 步骤 1：需求澄清 + Spec 产出 [中等+复杂]

- 确认涉及的业务模块、数据表、接口
- 检查 `.claude/memory/backend-standards.md` 了解项目规范
- 确认现有数据库表结构和 DAO/Mapper
- 设计 API 路径、请求参数、响应格式、错误码
- 设计数据库变更（如需建表/改表，先输出 DDL）
- **产出：在 `specs/active/` 下创建 spec 文件**（状态 Proposed）
- 让用户确认 spec 后，状态改为 Applied

> Spec 格式参见 `.claude/specs/SPEC-GUIDE.md`
> 关联 Superpowers: brainstorming
> 配置项: 如 brainstorming 已禁用，直接用用户描述创建 spec

### 步骤 2：任务拆解与计划 [复杂]

- 拆解为 2-5 分钟可完成的小任务
- 每个任务标注文件路径和变更范围
- 输出计划让用户确认

> 关联 Superpowers: writing-plans
> 配置项: 如 writing-plans 已禁用，跳过此步骤

### 步骤 3：自底向上实现 [必选]

- 读取 `specs/active/` 中对应的 spec 文件作为约束
- 按顺序逐层实现：

1. **DAO/Mapper 层** — 数据访问方法、SQL 映射
2. **Service 层** — 业务逻辑、事务管理
3. **Controller 层** — 接口定义、参数校验、响应封装

### 步骤 4：验证 [必选]

- 运行构建命令（如 `mvn compile` / `go build` / `python -m py_compile`）
- 运行测试命令（如 `mvn test` / `go test` / `pytest`）
- 贴出运行结果作为完成证据
- **将 spec 从 `active/` 移入 `archived/`**

> 关联 Superpowers: verification-before-completion

---

## 完成标准

- 编译通过
- 测试通过（如有测试）
- 分层正确，无跨层调用
- 接口格式符合统一响应规范
- 输入校验到位，无安全隐患
- 验证结果已贴出

## 参考规范

阅读 `.claude/memory/backend-standards.md` 了解完整后端规范。
