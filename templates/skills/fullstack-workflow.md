---
name: fullstack-workflow
description: 当需要开发完整功能模块（从数据库到前端页面）或进行前后端联调时使用
context: fork
---

# 全栈开发流程编排器

你处于全栈协调模式。本技能是完整的开发流程编排器，每个步骤关联 Superpowers Skill，根据项目配置决定是否启用。

## 配置读取（流程开始前执行）

读取 `.claude/memory/superpowers-config.md` 中的配置，确定每个 Skill 的启用状态：
- **enabled** 中的 Skill → 对应步骤始终执行
- **disabled** 中的 Skill → 对应步骤始终跳过
- **conditional** 中的 Skill → 根据当前任务复杂度判断

复杂度判断标准：
- **简单**：单文件修改、字段调整、bug 修复（< 30 分钟）
- **中等**：新组件 + 新接口、多文件变更（30 分钟 - 2 小时）
- **复杂**：新功能模块、跨前后端、多表多接口（> 2 小时）

---

## 流程步骤

### 步骤 0：需求入口 [必选]

- 接收用户需求描述
- 判断复杂度等级（简单 / 中等 / 复杂）
- **简单任务** → 跳到步骤 4 直接实现
- **中等任务** → 进入步骤 1
- **复杂任务** → 进入步骤 1

> 关联 Superpowers: using-superpowers（入口判断）

### 步骤 1：需求澄清 + Spec 产出 [中等+复杂]

- 确认功能边界：涉及哪些数据表、接口数量、页面数量
- 向用户确认不明确的细节（鉴权方式、数据量级、异常策略等）
- 提出方案选项，让用户选择
- **产出：在 `specs/active/` 下创建 spec 文件**（状态 Proposed）
- 让用户确认 spec 后，状态改为 Applied

> Spec 格式参见 `.claude/specs/SPEC-GUIDE.md`
> 关联 Superpowers: brainstorming
> 配置项: 如 brainstorming 已禁用，直接用用户描述创建 spec

### 步骤 2：任务拆解与计划 [复杂]

- 将需求拆解为 2-5 分钟可完成的小任务
- 每个任务标注：涉及文件路径、变更范围、依赖关系
- 计划写给"一个技术很强但对项目一无所知的陌生人"看，必须精确到文件和行号
- 输出计划让用户确认

> 关联 Superpowers: writing-plans
> 配置项: 如 writing-plans 已禁用，跳过此步骤

### 步骤 3：工作空间隔离 [复杂]

- 创建 git worktree 隔离开发环境
- 在隔离环境中安装依赖、运行基线测试

> 关联 Superpowers: using-git-worktrees
> 配置项: 如 using-git-worktrees 已禁用，在当前分支直接开发

### 步骤 4：实现 [必选]

- 读取 `specs/active/` 中对应的 spec 文件作为约束

#### 4a. 接口契约设计

- 定义 API 路径、请求参数 JSON、响应 JSON 格式
- 定义错误码和错误响应
- 确保前后端字段名/类型一致

#### 4b. 自底向上实现

1. **数据库层** → 2. **DAO/Mapper 层** → 3. **Service 层** → 4. **Controller 层** → 5. **前端 API 模块** → 6. **前端页面**

### 步骤 5：联调验证 [必选]

- 运行后端构建和测试，贴出结果
- 运行前端 lint 和测试，贴出结果
- 验证前后端字段名/类型完全一致
- **将 spec 从 `active/` 移入 `archived/`**

> 关联 Superpowers: verification-before-completion

### 步骤 6：代码审查 [中等+复杂，可选]

- 对变更代码进行系统审查
- 按严重度分级：Critical（必须修）、Important（应该修）、Minor（记录）
- 逐条验证审查意见：合理的修复，不合理的说明原因（技术正确性 > 社交舒适度）

> 关联 Superpowers: requesting-code-review + receiving-code-review
> 配置项: 如 code-review 已禁用，跳过此步骤

### 步骤 7：收尾 [必选]

- 更新知识库（如有架构变更更新 architecture.md，有新规范更新 *-standards.md）
- 决定分支合并策略（创建 PR / 直接合并）
- 如使用了 worktree，清理工作空间

> 关联 Superpowers: finishing-a-development-branch
> 配置项: 如 finishing-a-development-branch 已禁用，只执行知识库更新

---

## 完成标准

- 后端编译通过 + 测试通过
- 前端 lint 无错误 + 测试通过
- 端到端数据流通畅
- 前后端字段名/类型完全一致
- 错误链路完整
- 验证结果已贴出

## 参考规范

阅读 `.claude/memory/` 目录下所有规范文档了解完整项目规范。
