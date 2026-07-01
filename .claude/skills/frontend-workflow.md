---
name: frontend-workflow
description: 当需要开发或修改前端 UI 组件、页面、样式、状态管理、前端性能优化时使用
context: fork
---

# 前端开发流程编排器

你处于前端开发模式。本技能是完整的前端开发流程编排器，每个步骤关联 Superpowers Skill，根据项目配置决定是否启用。

## 配置读取（流程开始前执行）

读取 `.claude/memory/superpowers-config.md` 中的配置，确定每个 Skill 的启用状态：
- **enabled** → 对应步骤始终执行
- **disabled** → 对应步骤始终跳过
- **conditional** → 根据复杂度判断

复杂度：简单（单文件 < 30 分钟）/ 中等（新组件 30 分钟 - 2 小时）/ 复杂（新模块 > 2 小时）

---

## 流程步骤

### 步骤 0：需求入口 [必选]

- 接收用户需求描述
- 判断复杂度等级
- **简单任务**（改样式/改文案）→ 跳到步骤 3 直接实现
- **中等/复杂任务** → 进入步骤 1

> 关联 Superpowers: using-superpowers

### 步骤 1：需求澄清 + Spec 产出 [中等+复杂]

- 确认涉及的文件、组件、页面
- 检查 `.claude/memory/frontend-standards.md` 了解项目规范
- 搜索项目中是否已有可复用的组件
- 确认组件 props、events、slots 设计
- 确认需要调用的 API 接口及数据格式
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

### 步骤 3：实现 [必选]

- 读取 `specs/active/` 中对应的 spec 文件作为约束
- 按规范编写代码
- API 调用通过 `api/` 目录模块，不直接写 fetch/axios
- 处理 loading / error / empty 三种状态
- 组件保持单一职责

### 步骤 4：验证 [必选]

- 运行 `npm run lint`（或项目对应的 lint 命令）
- 运行 `npm run test:unit`（如存在）
- 贴出运行结果作为完成证据
- **将 spec 从 `active/` 移入 `archived/`**

> 关联 Superpowers: verification-before-completion

## 参考规范

阅读 `.claude/memory/frontend-standards.md` 了解完整前端规范。
