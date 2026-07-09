# 流程定义指南

本文件定义了各工作流的标准阶段、角色分工、输入输出和流转规则。

---

## 后端标准流程

| 阶段 | 触发 Skill | 输入 | 输出 | 前进条件 | 可回退到 |
|------|-----------|------|------|---------|---------|
| 需求入口 | using-superpowers | 用户描述 | 复杂度判断 | 自动判定 | - |
| 需求澄清 | brainstorming | 复杂度 ≥ 中等 | `specs/active/*.md` | 用户确认 spec | 需求入口 |
| 方案设计 | writing-plans | 复杂度 = 复杂 | 任务拆解计划 | 用户确认计划 | 需求澄清 |
| 工作空间隔离 | using-git-worktrees | 复杂度 = 复杂 | worktree 分支 | 创建成功 | - |
| 实现 | executing-plans | spec + 计划 | DAO → Service → Controller | 构建+测试通过 | 方案设计 |
| 代码评审 | code-review | 复杂度 ≥ 中等 | 评审报告（MD/Excel） | 无高危问题 | 实现 |
| 收尾 | finishing-a-development-branch | 验证通过 | spec 归档 + 分支合并 | - | - |

## 前端标准流程

| 阶段 | 触发 Skill | 输入 | 输出 | 前进条件 | 可回退到 |
|------|-----------|------|------|---------|---------|
| 需求入口 | using-superpowers | 用户描述 | 复杂度判断 | 自动判定 | - |
| 需求澄清 | brainstorming | 复杂度 ≥ 中等 | `specs/active/*.md` | 用户确认 spec | 需求入口 |
| 方案设计 | writing-plans | 复杂度 = 复杂 | 组件设计 + API 定义 | 用户确认 | 需求澄清 |
| 实现 | executing-plans | spec + 计划 | 组件 → API 模块 → 页面 | lint+构建通过 | 方案设计 |
| 代码评审 | code-review | 复杂度 ≥ 中等 | 评审报告 | 无高危问题 | 实现 |
| 收尾 | finishing-a-development-branch | 验证通过 | spec 归档 | - | - |

## 全栈标准流程

| 阶段 | 触发 Skill | 输入 | 输出 | 前进条件 | 可回退到 |
|------|-----------|------|------|---------|---------|
| 需求入口 | using-superpowers | 用户描述 | 复杂度判断 | 自动判定 | - |
| 需求澄清 | brainstorming | 复杂度 ≥ 中等 | `specs/active/*.md` | 用户确认 spec | 需求入口 |
| 方案设计 | writing-plans | 复杂度 = 复杂 | 完整任务计划（含前后端） | 用户确认 | 需求澄清 |
| 工作空间隔离 | using-git-worktrees | 复杂度 = 复杂 | worktree 分支 | 创建成功 | - |
| 后端实现 | executing-plans | spec | DB → DAO → Service → Controller | 构建+测试通过 | 方案设计 |
| 前端实现 | executing-plans | spec + 后端 API | API 模块 → 组件 → 页面 | lint+构建通过 | 后端实现 |
| 联调验证 | verification-before-completion | 前后端代码 | 联调结果 | 接口调通 | 前端实现 |
| 代码评审 | code-review | 复杂度 ≥ 中等 | 评审报告 | 无高危问题 | 联调验证 |
| 收尾 | finishing-a-development-branch | 验证通过 | spec 归档 + 分支合并 | - | - |

---

## 简单任务流程

简单任务（单文件修改，< 30 分钟）跳过所有中间阶段，直接实现 → 验证 → 完成。

## 通用规则

1. **下游不能修改上游产出** — 实现阶段不能修改 spec，只能通过 PM（即用户）打回到需求阶段
2. **每个阶段必须有明确的"完成"定义** — 不能口头说"做完了"，必须通过验证
3. **连续 3 次回退到同一阶段** — 暂停流程，由人做最终决策
4. **验证是硬门禁** — 构建失败、测试失败、评审有高危问题，流程必须回退
5. **spec 是唯一的真相来源** — AI 从文件读约束，不靠聊天记录

## 阶段产物规范

| 产物 | 文件位置 | 谁产出 | 谁消费 | 状态流转 |
|------|---------|--------|--------|---------|
| Spec | `specs/active/` → `specs/archived/` | brainstorming | 所有下游阶段 | Proposed → Applied → Completed |
| 任务计划 | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md` | writing-plans | executing-plans | - |
| 代码 | 项目源码目录 | executing-plans | code-review | - |
| 评审报告 | `.claude/reports/` | code-review | 用户 + finishing | - |
| **当前交接** | `.claude/CURRENT.md` | 每阶段结束 `/handoff` | 新会话（SessionStart 注入）| 模板 → 进行中 → 已完成 |

## 会话交接协议（切会话连续性）

> 复杂项目不在一个会话干完。状态落盘，靠 CURRENT.md 接力，保证切会话后连续。

**为什么**：主会话编排多阶段 + 多 subagent，编排 context 必然撑爆（L-004）；subagent 隔离了执行 context，没隔离编排 context。解法是把「当前快照」落盘，新会话从文件重建，而非靠聊天记录。

**三件套**：

| 环节 | 机制 |
|------|------|
| 写 | 每阶段结束 `/handoff` → 更新 CURRENT.md（状态置「进行中」）|
| 读 | 新会话 SessionStart hook 自动注入 CURRENT.md（确定性，不靠提醒）|
| 清 | 任务完成 → 状态改「已完成」+ 归档 |

**切会话 SOP**：阶段X 做完 → `/handoff`（写快照）→ `/clear` → 新会话 hook 注入 → 读 `@spec` `@plan` → 从「下一步」接着做阶段X+1。

**四文件重建**：`spec`（WHAT 真相）+ `plan`（HOW 拆解）+ `CURRENT`（停在哪快照）+ `memory`（WHY 沉淀）——任一会话都能完整接上。

## 与 Superpowers 配置的关系

各阶段的 Skill 触发条件由 `memory/superpowers-config.md` 控制：

| Skill | 触发条件 | 对应阶段 |
|-------|---------|---------|
| brainstorming | complexity ≥ medium | 需求澄清 |
| writing-plans | complexity ≥ complex | 方案设计 |
| using-git-worktrees | complexity ≥ complex | 工作空间隔离 |
| test-driven-development | complexity ≥ medium | 实现阶段内 |
| code-review | complexity ≥ complex | 代码评审 |
| finishing-a-development-branch | complexity ≥ medium | 收尾 |
