# claude-apprentice

> Train Claude Code into a reliable apprentice — spec-driven, memory-backed, code-reviewed.

[![npm version](https://img.shields.io/npm/v/claude-apprentice.svg)](https://www.npmjs.com/package/claude-apprentice)
[![GitHub stars](https://img.shields.io/github/stars/shuoyue/claude-apprentice.svg)](https://github.com/shuoyue/claude-apprentice/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node](https://img.shields.io/badge/node-%3E%3D14-green)](https://nodejs.org)

AI 驱动全栈开发工程化体系 — 一条命令初始化项目。

基于"三件套"（Claude Code + Superpowers + Spec）构建的轻量级 Harness 体系，解决 LLM 不可控和无状态的缺陷，让 AI 从"聊天玩具"进化为"可靠开发员工"。

---

## 快速开始

### 推荐方式（npx）

```bash
cd your-project
npx claude-apprentice init
```

### curl 一键安装（非 Node.js 用户）

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/shuoyue/claude-apprentice/main/install.sh | bash
```

### 初始化后做什么

1. 检查 `CLAUDE.md` 中的技术栈信息
2. 补充 `.claude/memory/business-logic.md` 中的业务逻辑
3. 打开 Claude Code 直接开始工作

---

## 体系架构

### 三层架构

| 层级 | 对应 | 职责 |
|------|------|------|
| **执行底盘** | Claude Code + `scripts/` | 文件读写、沙箱隔离、工具调用 — 让 AI 能操作真实世界 |
| **行为纪律** | `rules/` + Superpowers | TDD、代码审查、系统化调试 — 让 AI 不犯野路子错误 |
| **规格对齐** | `specs/`（`SPEC-GUIDE.md`）+ `memory/` + `CLAUDE.md` | 结构化需求文档作为共享锚点 — 防止理解偏差 |

### 核心原则：原生优先

> **90% 的场景用原生 Claude Code 就够了。过度工程化是最大的浪费。**

| 复杂度 | 定义 | 策略 |
|--------|------|------|
| **简单** | 单文件修改，< 30 分钟 | 直接说需求，不走 workflow |
| **中等** | 新组件/新接口，30 分钟 - 2 小时 | brainstorming + spec + TDD |
| **复杂** | 新功能模块，> 2 小时 | 完整 workflow + spec + worktree + review |

### 开发铁律

1. **没设计不写代码** — 动手前先确认文件、范围、方案
2. **没测试不写代码** — 先写失败测试，再写实现
3. **没验证不说完成** — 必须运行验证命令并贴出结果

---

## 日常使用

### 简单任务（推荐 90% 场景）

直接说需求，不用切模式：

```
你: 修复登录接口返回 500 的问题
你: 把分页改成每页 20 条
```

### 模式切换

| 命令 | 模式 | 适用场景 |
|------|------|----------|
| `/frontend` | 前端模式 | 页面开发、组件开发、样式调整 |
| `/backend` | 后端模式 | 接口开发、数据库操作、业务逻辑 |
| `/fullstack` | 全栈模式 | 新功能从 0 到 1、前后端联调 |
| `/spec` | Spec 模式 | 只想把需求理清楚，不立刻动手编码 |

### `/spec` 命令

强制产出 spec 文件，不进入实现阶段：

```
你: /spec 创建用户积分入账接口，需要幂等和并发控制
```

| 入口 | 行为 |
|------|------|
| `/spec <需求>` | **只产出 spec，不写代码** |
| `/backend` `/frontend` `/fullstack` | 走完整 workflow（spec + 实现 + 验证 + 归档） |

### 工作流步骤

| 步骤 | 名称 | 触发条件 | 产出 |
|------|------|---------|------|
| 0 | 需求入口 | 所有任务 | 复杂度判断 |
| 1 | 需求澄清 + Spec | 中等+复杂 | `specs/active/[feature].md` |
| 2 | 任务拆解 | 复杂 | 任务计划 |
| 3 | 实现 | 所有任务 | 代码（读取 spec 作为约束） |
| 4 | 验证 + 归档 | 所有任务 | 测试结果 + spec 移入 archived |

### 代码评审

自动触发或手动触发，按 7 个维度逐项检查：

| 优先级 | 维度 | 项数 |
|--------|------|------|
| 1 | 安全性 | 18 项 |
| 2 | 正确性 | 5 项 |
| 3 | 性能 | 4 项 |
| 4 | 设计与架构 | 4 项 |
| 5 | 可维护性 | 6 项 |
| 6 | 规范与一致性 | 3 项 |
| 7 | 文件类型专属 | 按后缀激活 |

输出 MD 或 Excel 格式报告到 `.claude/reports/`。

---

## Spec 规格驱动

> 规格是唯一的真相来源。AI 每次从 spec 文件读约束，不靠聊天记录。

```
Propose（提案）→ Apply（实施）→ Archive（归档）
```

| 阶段 | 触发方式 | 做什么 |
|------|---------|--------|
| **Propose** | `/spec` 命令 或 workflow 步骤 1 | 在 `specs/active/` 创建 spec 文件 |
| **Apply** | 用户确认 spec 后 | 状态改为 Applied，后续 Session 从文件读约束 |
| **Archive** | workflow 最后一步 | 移入 `specs/archived/`，作为活文档保留 |

---

## 错题本机制

每一条 `rules/` 和 `learned-lessons.md` 中的规则都对应一个真实失败案例：

```markdown
### L-001: AI 先写实现再补测试
- 错误现象：AI 直接写完整个实现，然后说"接下来补测试"
- 根因：没有强制 TDD 流程，AI 倾向走捷径
- 规避规则：workflow 步骤 3 必须先写失败测试，看到红灯再写实现
```

**机制闭环**：AI 犯错 → 加一条规则 → 以后不再犯同类错误。

---

## CLI 命令

```bash
apprentice init                # 初始化项目（复制模板 + 运行 init.sh）
apprentice update              # 增量更新（不覆盖已有文件）
apprentice doctor              # 运行健康检查
apprentice version             # 显示版本号
apprentice help                # 显示帮助
```

---

## 项目初始化后的目录结构

```
your-project/
├── CLAUDE.md                       # [自动加载] 项目最高优先级指令
└── .claude/
    ├── settings.json               # 主配置（团队共享，提交 git）
    ├── MEMORY.md                   # 知识库索引
    ├── commands/                   # 斜杠命令
    │   ├── frontend.md             #   /frontend
    │   ├── backend.md              #   /backend
    │   ├── fullstack.md            #   /fullstack
    │   ├── spec.md                 #   /spec
    │   └── scan-todos.md           #   /scan-todos (Loop 层试点)
    ├── rules/                      # 条件规则（自动触发）
    │   ├── INDEX.md                #   规则触发索引
    │   ├── coding-standards.md     #   编码标准
    │   ├── git-safety.md           #   Git 安全
    │   └── superpowers-workflow.md #   工作流 + 调试规则
    ├── skills/                     # 工作流技能
    │   ├── frontend-workflow.md
    │   ├── backend-workflow.md
    │   ├── fullstack-workflow.md
    │   └── code-review/            #   代码评审（7 维度）
    ├── reports/                    # 评审报告输出
    ├── specs/                      # 功能规格（Propose → Apply → Archive）
    │   ├── SPEC-GUIDE.md
    │   ├── active/
    │   └── archived/
    ├── scripts/
    │   ├── init.sh                 # 初始化（自动检测项目类型）
    │   ├── health-check.sh         # 健康巡检（9 项检查）
    │   └── auto-review.sh          # PostToolUse hook 自动评审
    ├── usage-guides/               # 操作手册
    │   ├── README.md
    │   ├── usage-guide-v5.8.md
    │   └── bottleneck-navigation.md  # 瓶颈定位指南
    └── memory/                     # 项目知识库
        ├── architecture.md
        ├── frontend-standards.md
        ├── backend-standards.md
        ├── business-logic.md
        ├── superpowers-config.md
        ├── learned-lessons.md      # 错误驱动的知识积累
        └── issues.md
```

---

## 多角色协同

| 阶段 | 参与角色 | 做什么 | 产出 |
|------|---------|--------|------|
| **混沌期** (Brainstorming) | PM + Tech Lead | 苏格拉底式对话，理清业务与技术选型 | 需求共识 |
| **规划期** (`/spec`) | PM 签收标准，Tech Lead 定方案 | 固化为 `specs/active/` 文档 | spec 文件 |
| **执行期** (Workflow) | Developer | TDD 流程：先写测试再实现，自我审查 | 代码 + 测试 |
| **验证期** (QA 左移) | QA | 基础单元测试已内建，专注集成/E2E/探索性测试 | 测试报告 |

---

## 渐进式落地

| 阶段 | 时间 | 聚焦 | 做什么 |
|------|------|------|--------|
| **起步期** | 第 1-2 周 | 单兵作战 | 统一工具链，建立 `CLAUDE.md` + `rules/`，跑通小需求闭环 |
| **进阶期** | 第 3-8 周 | 团队资产积累 | 封装 Skills，完善知识库和跨会话记忆 |
| **成熟期** | 第 9 周+ | 复杂场景扩展 | 按需引入 worktree 隔离、多 Agent 协调 |

---

## 常见问题

### `/spec` 和 `/backend` 怎么选？

| 你的诉求 | 用哪个 |
|----------|--------|
| 只想把需求理清楚，不写代码 | `/spec` |
| 想直接做完一个功能 | `/backend` `/frontend` `/fullstack` |
| 多人协作，先对齐再分发 | `/spec` 写完分发 |

### 新员工怎么上手？

```bash
cd your-project
npx claude-apprentice init
claude
```

### 团队物理隔离怎么统一环境？

所有规范配置提交到 Git 仓库。新成员拉取代码后，AI 自动读取配置文件，加载出完全一致的环境。**代码即配置，Git 即分发。**

### 什么时候不用这套体系？

| 场景 | 建议 |
|------|------|
| 一次性脚本 | 直接写，跑通即可 |
| 探索性原型 | 快速验证，不走 spec |
| 紧急 Hotfix | 先修复，事后补测试和 spec |

---

## 兼容性

- ✅ **Claude Code** — 原生（slash commands + skills）
- ⚠️ **Cursor** — 手动（模板可用，无 slash commands）
- ⚠️ **GitHub Copilot Chat** — 手动（模板可用）
- ⚠️ **Windsurf** — 手动（模板可用）

---

## 版本更新

```bash
# 增量更新，已有文件不覆盖
apprentice update
```

## 详细文档

- 完整使用手册见 `templates/usage-guides/` 目录
- 版本演进史见 [CHANGELOG.md](./CHANGELOG.md)

---

## 相关

- **Blog (中文)**: 公众号「造物手记」— author's writings on AI engineering
- **Mitchell Hashimoto's [AGENTS.md](https://github.com/mitchellh/agentkit)** — inspiration for `learned-lessons.md`
- **Anthropic's [Claude Code Skills](https://docs.claude.com/en/docs/agents-and-tools/claude-code/skills)** — the underlying mechanism

---

## License

[MIT](./LICENSE) — © 2026

---

_Made with discipline. Crafted over 5 internal versions (v5.2 → v5.8), open-sourced as v1.0._
