# AI 驱动全栈开发 — 使用手册

**版本:** v5.9
**更新日期:** 2026-07-09

---

## 零、5 分钟上手

### 第一步：初始化项目

```bash
# 把 .claude/ 模板复制到你的项目根目录，然后执行初始化
cp -r /path/to/harness/.claude/  your-project/
cd your-project
.claude/scripts/init.sh
```

init.sh 会自动检测项目类型（Java/Python/Go/Vue/React）、深度扫描依赖、生成全套配置。

> 详见 **一、初始化新项目**

### 然后直接用

```bash
# 打开 Claude Code
claude

# 90% 场景直接说需求就够了
你: 修复登录接口返回 500 的问题
你: 把分页改成每页 20 条
```

### 需要走完整流程？

```
你: /backend 创建积分入账接口，需要幂等和并发控制
你: /fullstack 开发用户积分系统
```

**记住一条原则：简单的事情简单做。不确定该走流程就直接说需求，不够再上 workflow。**

---

## 一、初始化新项目

### 12.1 运行模式

```bash
# 自动检测模式（推荐）
cd <目录>
init.sh                          # 自动判断单项目 or 多项目工作区

# 显式指定模式
init.sh --workspace               # 强制工作区模式（扫描子目录）
init.sh --project <目录>          # 只初始化指定子项目
init.sh --scan                    # 只扫描报告，不创建文件
```

### 12.2 自动检测逻辑

init.sh 扫描目标目录（根目录 + 一级子目录）的项目标记文件：

| 标记文件 | 识别为 |
|---------|--------|
| `pom.xml` / `build.gradle` | Java + Spring Boot |
| `go.mod` | Go + Gin |
| `requirements.txt` / `pyproject.toml` | Python + FastAPI/Django |
| `package.json`（含 vue） | Vue 前端 |
| `package.json`（含 react） | React 前端 |

判定规则：

| 情况 | 模式 |
|------|------|
| 根目录本身是单一项目 | 单项目模式（原有行为） |
| 根目录无项目标记，子目录有多个项目 | 工作区模式 |
| 根目录也是项目，子目录也有项目 | 工作区模式 |

### 12.3 单项目初始化

```bash
cd <新项目根目录>
/path/to/.claude/scripts/init.sh
```

脚本自动完成：检测项目类型 → 深度扫描依赖和工具链 → 创建 CLAUDE.md → 生成命令/规则/技能/知识库。

#### 深度检测

init.sh 不仅检测语言和框架，还会深度扫描项目依赖，自动填充到 memory/ 文件中：

| 检测项 | 数据来源 | 涵盖内容 |
|--------|---------|----------|
| 语言/框架版本 | pom.xml / go.mod / package.json | Java 版本、Spring Boot 版本、Go 版本等 |
| ORM | pom.xml / requirements.txt / go.mod | MyBatis-Plus / JPA / SQLAlchemy / GORM |
| 测试框架 | pom.xml / package.json | JUnit / Mockito / pytest / Vitest / Jest / Cypress |
| API 文档 | pom.xml / go.mod | SpringDoc / Swagger / Knife4j / Swag |
| UI 组件库 | package.json | Element Plus / Ant Design / Material UI |
| 状态管理 | package.json | Pinia / Vuex / Redux / Zustand |
| CSS 框架 | package.json | Tailwind / SCSS / Less |
| 缓存 / MQ | pom.xml / requirements.txt | Redis / RabbitMQ / Kafka / Celery |

#### 输出示例

```
==> 单项目模式初始化
[INFO] 检测项目类型...
  名称: my-project
  类型: java-maven
  语言: Java
  后端: Spring Boot
  数据库: MySQL
  ORM: MyBatis-Plus
  测试: JUnit 5 + Mockito
  缓存: Redis
```

生成的 `architecture.md` 和 `backend-standards.md` 会自动填充检测到的信息，不再显示"待填写"。

### 12.4 多项目工作区初始化

```
workspace/
├── java-api/        # pom.xml → Java/Spring Boot
├── vue-web/         # package.json → Vue
├── python-ml/       # requirements.txt → Python/FastAPI
└── go-gateway/      # go.mod → Go/Gin
```

运行 `init.sh` 后：

```
> 扫描检测到 4 个子项目
> 创建工作区全局 .claude/（共享 rules/commands/skills/memory）
> 为每个子项目创建专属 .claude/（技术栈 rules + 项目 memory）
```

#### 扫描报告示例

```
========================================
  项目扫描结果
========================================

  项目               类型       技术栈            框架
  go-gateway         backend    Go                Gin
  java-api           backend    Java              Spring Boot
  python-ml          backend    Python            FastAPI
  vue-web            frontend   JavaScript/TS     Vue

后端项目: 3 个
前端项目: 1 个
总计: 4 个项目
```

### 12.5 子项目单独初始化

已有工作区但某个子项目没有 `.claude/` 时：

```bash
init.sh --project ./java-api       # 初始化指定子项目
init.sh --project .                # 在子项目目录内初始化当前项目
```

### 12.6 初始化后必做

1. 检查 `CLAUDE.md` 和 `memory/architecture.md` 中的自动检测信息是否准确（大部分已自动填充）
2. 补充 `memory/business-logic.md` 中的业务逻辑说明
3. 创建 `settings.local.json` 填入 API 密钥（不提交到 git）
4. 运行 `.claude/scripts/verify.sh` 验证

### 12.7 settings 配置说明

| 文件 | 用途 | 是否提交 |
|------|------|---------|
| `settings.json` | 团队共享：模型、语言、权限白名单、插件 | 提交 |
| `settings.local.json` | 个人本地：API 密钥、个人偏好 | 不提交 |

```json
// settings.json 示例
{
  "language": "chinese",
  "permissions": {
    "allow": [
      "Bash(npm *)",
      "Bash(mvn *)",
      "Bash(git show *)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git diff-tree *)",
      "Read(*)",
      "Edit(*)"
    ],
    "deny": ["Bash(git push --force)", "Bash(rm -rf *)"]
  }
}
```

```json
// settings.local.json 示例（不提交）
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "你的API密钥",
    "ANTHROPIC_BASE_URL": "API地址"
  }
}
```

### 12.8 增量更新

重复运行 `init.sh` 是安全的，不会覆盖已有内容：

```bash
# 随时可以重新运行，只补全缺失项
init.sh
```

**行为：**
- 已有 `.claude/` 目录时自动进入增量模式，无需交互确认
- 所有文件都有 `if [ ! -f ]` 保护，已有文件（包括用户手动修改的内容）不会被覆盖
- 只补全缺失的文件（如新增了子项目、rules 目录缺文件等）

**典型场景：**
- 项目新增了依赖（如加了 Redis），重新运行 init.sh 会检测到并补全
- 工作区新增了子项目，重新运行会为新子项目生成专属配置
- 模板升级后，重新运行只会生成新文件，不影响已有配置

---

## 二、设计哲学

### 1.1 四条演进线

这套体系不是凭空设计的，它来自业界验证的四条认知。每当模型变强，系统瓶颈就往外移一层：

| 阶段 | 核心问题 | 答案 | 来源 |
|------|---------|------|------|
| Prompt Engineering（2023） | 怎么把指令说清楚 | 系统提示词 + Few-shot | 通用实践 |
| Context Engineering（2024） | 该给 AI 看什么 | 按需加载，渐进披露 | Anthropic / OpenAI |
| Harness Engineering（2026） | AI 跑起来怎么不翻车 | 约束 + 验证 + 反馈回路 | Claude Code / Stripe |
| Loop Engineering（2026） | 谁来持续驱动 AI | 自动循环、定时任务、hook 触发 | Peter Steinberger / Boris Cherny |

四层**层层包含**，不是替代：Prompt ⊂ Context ⊂ Harness ⊂ Loop。公式 `Agent = 模型 + Harness` — 模型决定上限，harness 决定落地。

我们的体系对应关系：

```
Prompt  → CLAUDE.md + rules/（说什么）
Context → memory/ + specs/（看什么）
Harness → workflow skills + Superpowers + scripts/（怎么跑）
Loop    → /loop skill + scan-todos + auto-review.sh + hooks（谁来跑）
```

> 效果不好时，按 [瓶颈定位指南](bottleneck-navigation.md) 排查瓶颈在哪一层，不要一上来就加 rule。

### 1.2 三层架构模型

体系由三个互补层级构成，覆盖从"AI 能动手"到"AI 干得对"的完整链路：

| 层级 | 定位 | 对应目录 | 解决什么问题 |
|------|------|---------|------------|
| **执行底盘** | AI 的"操作系统" | Claude Code 本身 + `scripts/` | 文件读写、沙箱隔离、工具调用 — 让 AI 能操作真实世界 |
| **行为纪律** | AI 的"肌肉记忆与 SOP" | `rules/` + Superpowers skills | TDD、代码审查、系统化调试 — 让 AI 不犯野路子错误 |
| **规格对齐** | 项目的"唯一真相来源" | `specs/`（`SPEC-GUIDE.md`）+ `memory/` + `CLAUDE.md` | 结构化需求文档作为共享锚点 — 防止理解偏差和上下文丢失 |

**核心逻辑：** 三层缺一不可。没有底盘，AI 无法行动；没有纪律，AI 质量失控；没有规格，AI 自由发挥。

### 1.3 多角色协同流水线

当团队从个人开发扩展到多人协作时，传统线性接力模式被打破，取而代之的是以 **Spec 为核心枢纽** 的协同网络：

| 阶段 | 参与角色 | 做什么 | 产出 |
|------|---------|--------|------|
| **混沌期** (Brainstorming) | PM + Tech Lead | 苏格拉底式对话，理清业务逻辑、技术选型与潜在风险 | 需求共识 |
| **规划期** (`/spec`) | PM 签收验收标准，Tech Lead 定技术方案 | 将共识固化为 `specs/active/` 下的结构化文档 | spec 文件（Proposed → Applied） |
| **执行期** (Superpowers Workflow) | Developer | 领取任务，走 TDD 流程先写测试再实现，自我代码审查 | 代码 + 单元测试 |
| **验证期** (QA 左移) | QA | 基础单元测试已由 AI 内建，QA 重心放在集成测试、E2E 测试、探索性测试 | 测试报告 + spec 归档 |

**关键变化：**

- **不再依赖口头传递**：Spec 是所有角色共享的唯一真相来源
- **QA 重心左移**：AI 已内建单元测试，QA 专注于更高价值的验证
- **职责清晰不重叠**：PM 定"做什么"，Tech Lead 定"怎么做"，Dev 做，QA 验

### 1.4 渐进式落地路线

不要一次性引入所有机制，按阶段稳步推进：

| 阶段 | 时间 | 聚焦 | 做什么 |
|------|------|------|--------|
| **起步期** | 第 1-2 周 | 单兵作战 | 统一安装工具链，建立 `CLAUDE.md` 和基础 `rules/`，跑通小需求闭环 |
| **进阶期** | 第 3-8 周 | 团队资产积累 | 将反复出现的痛点封装为 Skills，完善 `memory/` 知识库和跨会话记忆 |
| **成熟期** | 第 9 周+ | 复杂场景扩展 | 面向大规模重构或多模块并行时，按需引入 worktree 隔离、多 Agent 协调 |

> 警惕"为了工程化而工程化"。始终以业务痛点为导向，现有工具够用就不叠加。最适合团队的体系，是随着业务发展由工程师亲手打磨出来的那套务实工作流。

### 1.5 六个关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| CLAUDE.md 做重还是做轻 | **轻（53 行目录式）** | OpenAI 实践：AGENTS.md 只当目录用，详细内容按需加载 |
| Spec 写不写 | **中等+复杂写** | Spec Kit 实践：规格磨 1 小时，后面省 4 小时 |
| Rules 多还是少 | **少（3 个）** | 社区实测：规则越多思考成本越高，精简到核心 |
| 靠 prompt 约束还是机械化执行 | **prompt 约束为主** | 当前阶段足够；未来重要规则可迁移到 hooks |
| 单 Agent 还是多 Agent | **单 Agent 为主** | Mitchell Hashimoto 实践：一个人 + 一个 Agent 深度参与效率最高 |
| 工具多还是少 | **少而精** | Claude Code 内置 ~15 个工具即可覆盖绝大部分开发任务 |

---

## 三、核心理念

### 2.1 原生优先

> 90% 的场景用原生 Claude Code 就够了。过度工程化是最大的浪费。

| 复杂度 | 定义 | 策略 |
|--------|------|------|
| **简单** | 单文件修改，< 30 分钟 | 直接说需求，不走 workflow |
| **中等** | 新组件/新接口，30 分钟 - 2 小时 | brainstorming + spec + TDD |
| **复杂** | 新功能模块，> 2 小时 | 完整 workflow + spec + worktree + review |

### 2.2 规格驱动

> 规格是唯一的真相来源。AI 每次从 spec 文件读约束，不靠聊天记录。

- 中等+复杂任务必须先产出 spec 文件（`specs/active/`）
- 用户确认 spec 后再编码
- 验证通过后 spec 归档（`specs/archived/`），作为活文档保留

### 2.3 开发铁律

1. **没设计不写代码** — 动手前先确认文件、范围、方案
2. **没测试不写代码** — 先写失败测试，再写实现
3. **没验证不说完成** — 必须运行验证命令并贴出结果

### 2.4 上下文治理

> 168K token 用到 ~40% 时，Agent 输出质量开始明显下降（Smart Zone → Dumb Zone）。

实践指导：
- CLAUDE.md 保持精简（53 行），避免每次对话浪费上下文
- 详细内容放到子文档按需加载
- 长任务优先拆分，每个子任务在干净上下文中完成
- 如果对话已经很长，主动开新对话比在旧对话中继续更高效

---

## 四、体系架构

### 3.1 目录结构

```
项目根目录/
├── CLAUDE.md                       # [自动加载] 项目最高优先级指令（53 行）
└── .claude/
    ├── settings.json               # 主配置（模型、权限）
    ├── settings.local.json         # 本地配置（不提交，含密钥）
    ├── MEMORY.md                   # 知识库索引
    ├── commands/                   # 斜杠命令（注入上下文）
    │   ├── frontend.md             #   /frontend 前端模式
    │   ├── backend.md              #   /backend 后端模式
    │   ├── fullstack.md            #   /fullstack 全栈模式
    │   ├── spec.md                 #   /spec 强制产出 spec（不写代码）
    │   └── scan-todos.md           #   /scan-todos 扫描 TODO/FIXME（Loop 试点）
    ├── rules/                      # 条件规则（自动触发，索引见 INDEX.md）
    │   ├── INDEX.md                #   触发条件索引（可审计、可优化）
    │   ├── coding-standards.md     #   编码标准（合并了代码质量+架构规则）
    │   ├── git-safety.md           #   Git 安全规则
    │   └── superpowers-workflow.md #   工作流执行规则 + 调试规则
    ├── skills/                     # 工作流技能（完整流程编排）
    │   ├── frontend-workflow.md    #   前端完整工作流
    │   ├── backend-workflow.md     #   后端完整工作流
    │   ├── fullstack-workflow.md   #   全栈完整工作流
    │   └── code-review/            #   代码评审技能（6 维度 31 项）
    ├── reports/                    # 评审报告输出目录
    ├── specs/                      # 功能规格文档（Spec 驱动）
    │   ├── SPEC-GUIDE.md           #   Spec 使用指南
    │   ├── active/                 #   进行中的 spec
    │   └── archived/               #   已完成的 spec（活文档）
    ├── scripts/
    │   ├── init.sh                 # 初始化脚本（v5 格式）
    │   ├── verify.sh               # 验证脚本
    │   ├── health-check.sh         # 健康巡检脚本（7 项自动检查）
    │   └── auto-review.sh          # commit 后异步自动 review（Loop 试点）
    └── memory/                     # 项目知识库
        ├── architecture.md         #   架构文档
        ├── frontend-standards.md   #   前端规范
        ├── backend-standards.md    #   后端规范
        ├── business-logic.md       #   业务逻辑
        ├── superpowers-config.md   #   Superpowers 配置（按需加载）
        ├── learned-lessons.md      #   错误驱动的知识积累（持续进化）
        └── issues.md               #   问题记录
```

### 3.2 单项目 vs 多项目工作区

init.sh 支持两种场景，自动检测：

| 场景 | 检测条件 | 配置结构 |
|------|---------|---------|
| **单项目** | 根目录有 pom.xml / package.json / go.mod 等且无子项目 | 单层 `.claude/` |
| **多项目工作区** | 一级子目录包含多个项目标记文件 | 两层 `.claude/` |

#### 两层结构（工作区模式）

```
workspace/                          # 工作区根目录
├── CLAUDE.md                      # 工作区概览（列出所有子项目）
├── .claude/                       # ── 全局共享配置 ──
│   ├── rules/                     #   共享规则（git-safety, workflow, coding-standards）
│   ├── commands/                  #   共享命令（带子项目感知）
│   ├── skills/                    #   共享工作流
│   ├── memory/                    #   全局知识库（architecture, learned-lessons）
│   └── specs/                     #   全局 specs
│
├── java-api/                      # 子项目
│   ├── CLAUDE.md                  #   Java 专属指令
│   └── .claude/                   # ── Java 专属配置 ──
│       ├── rules/spring-boot.md   #     Spring Boot 分层规范
│       ├── memory/                #     Java 项目知识库
│       └── specs/                 #     Java 项目 specs
│
├── vue-web/                       # 子项目
│   ├── CLAUDE.md                  #   Vue 专属指令
│   └── .claude/                   # ── Vue 专属配置 ──
│       ├── rules/vue-standards.md #     Vue 组件规范
│       ├── memory/                #     前端项目知识库
│       └── specs/                 #     前端项目 specs
```

**工作方式：**
- `cd java-api` → 加载 Java 专属 rules + memory（Spring Boot 分层规范自动生效）
- `cd vue-web` → 加载 Vue 专属 rules + memory（Vue 组件规范自动生效）
- 在工作区根目录 → 加载全局配置，使用 `/fullstack` 跨项目协调

#### 技术栈专属 rules

| 技术栈 | Rule 文件 | 核心内容 |
|--------|----------|---------|
| Java/Spring Boot | `spring-boot.md` | Controller→Service→Mapper 分层、统一响应、事务管理 |
| Python/FastAPI | `python-api.md` | Router→Service→Model 分层、Pydantic 校验、异步规范 |
| Vue | `vue-standards.md` | Composition API、Pinia 状态管理、组件规范 |
| React | `react-standards.md` | Hooks 规范、组件设计、状态管理 |
| Go | `go-standards.md` | Handler→Service→Repository 分层、错误处理 |

### 3.3 四层配置体系

| 优先级 | 文件 | 作用 | 加载时机 |
|--------|------|------|---------|
| 1 | `CLAUDE.md` | 项目指令（53 行目录式） | 每次对话自动加载 |
| 2 | `commands/*.md` | 斜杠命令，注入模式约束 | 用户 `/命令名` 时 |
| 3 | `rules/*.md` | 条件规则 | 编辑代码/执行 git/跑 workflow 时自动触发 |
| 4 | `skills/*.md` | 工作流技能 | 按需加载，走完整流程时 |

**核心设计：** CLAUDE.md 只当目录用，详细内容分散到子文档按需加载，控制上下文消耗。

---

## 五、日常使用

### 4.1 简单任务（推荐 90% 场景）

直接说需求，不用切模式，不用走 workflow：

```
你: 把用户列表页面的分页改成每页20条
你: 修复登录接口返回500的问题
你: 写一个日期格式化的工具函数
你: 给这个方法加个参数校验
```

### 4.2 模式切换

| 命令 | 模式 | 适用场景 |
|------|------|----------|
| `/frontend` | 前端模式 | 页面开发、组件开发、样式调整 |
| `/backend` | 后端模式 | 接口开发、数据库操作、业务逻辑 |
| `/fullstack` | 全栈模式 | 新功能从 0 到 1、前后端联调 |
| `/spec` | Spec 模式 | 只想把需求理清楚，不立刻动手编码 |

支持 `$ARGUMENTS`：`/frontend 创建用户列表页面` 会将参数传入命令。

#### `/spec` 与 workflow 命令的区别

| 入口 | 行为 | 产出 |
|------|------|------|
| `/spec <需求>` | **只产出 spec 文件，不写代码** | `specs/active/[feature].md`（Proposed） |
| `/backend` `/frontend` `/fullstack` | 走完整 workflow（spec + 实现 + 验证 + 归档） | 完整代码 + 归档 spec |

`/spec` 是"先把事说清"，workflow 是"说清后把事做完"。典型场景：

- 只想先把需求理清楚，不想立刻动手
- 多人协作时先对齐需求再分发任务
- 想把 spec 作为给其他 AI 会话/同事的需求文档
- 不信任 AI 的复杂度判断，要强制产出 spec

### 4.3 中等任务示例

```
你: /backend
你: 创建用户积分入账接口，需要幂等和并发控制

AI: [进入 workflow 步骤 1]
    - 确认业务模块、数据表、接口
    - 在 specs/active/ 创建 user-points-credit.md（Proposed）
    - 让你确认 spec

你: 确认，幂等窗口改为24小时

AI: [状态改为 Applied]
    [进入 workflow 步骤 3：自底向上实现]
    - DAO → Service → Controller
    - 运行 mvn test，贴出结果
    - spec 移入 specs/archived/
```

### 4.4 复杂任务示例

```
你: /fullstack
你: 开发用户积分系统，含入账、扣减、过期、兑换四个模块

AI: [步骤 0] 判断为复杂任务
    [步骤 1] 需求澄清 + 产出 spec
    [步骤 2] 任务拆解与计划
    [步骤 3] 创建 git worktree 隔离
    [步骤 4] 自底向上实现（DB→DAO→Service→Controller→前端API→页面）
    [步骤 5] 联调验证
    [步骤 6] 代码审查
    [步骤 7] 收尾（更新知识库、合并分支、清理 worktree）
```

### 4.5 直接使用 Superpowers

除了走完整 workflow，也可以直接调用单个 Superpowers skill：

| 你想做什么 | 怎么说 |
|-----------|--------|
| 先理清需求再动手 | "帮我 brainstorm 一下这个功能" |
| 按计划执行实现 | "按这个计划实现" |
| 系统化排查 bug | "这个测试挂了，帮我 systematic-debugging" |
| 提交前检查代码 | "帮我 review 这段代码" |

---

## 六、代码评审

### 6.1 触发方式

- 在对话中提及"代码评审"、"code review"、"审查代码"
- workflow 步骤 6 自动触发（中等+复杂任务）

### 6.2 评审流程

评审分为 4 个步骤：

```
步骤1: 确定评审范围
  ├── 模式A：基于 git 提交记录（支持多选）
  └── 模式B：指定文件或目录

步骤2: 获取文件内容
  └── Read 工具 + 只读 git 命令

步骤3: 按维度逐项检查
  ├── 3.1 单文件逐项检查（7维度，含文件类型专属检查）
  ├── 3.2 跨文件关联分析（接口/表/组件变更→检查调用方）
  └── 3.3 变更影响面评估（局部/模块级/跨模块/全局）

步骤4: 选择输出格式并生成报告
  ├── MD → .claude/reports/code-review-{timestamp}.md
  └── Excel → .claude/reports/code-review-{timestamp}.xlsx
```

**关键约束：**
- 评审过程中只允许只读 git 命令，禁止所有写操作 git 命令
- settings.json 已预授权只读 git 命令，无需手动确认
- 提交选择支持多选，多个提交的变更文件自动去重合并

### 6.3 评审维度

| 优先级 | 维度 | 项数 |
|--------|------|------|
| 1 | 安全性 | 18 项（业务篡改、越权、注入、信息泄露等） |
| 2 | 正确性 | 5 项（功能逻辑、边界异常、数据一致性等） |
| 3 | 性能 | 4 项（查询、资源、缓存、批量） |
| 4 | 设计与架构 | 4 项（职责、接口、扩展性） |
| 5 | 可维护性 | 6 项（命名、复杂度、重复代码等） |
| 6 | 规范与一致性 | 3 项（编码规范、提交规范、配置管理） |
| 7 | 文件类型专属 | 按后缀激活（Java/Python/Go/Vue/React/SQL/XML/配置） |

### 9.4 输出格式

| 格式 | 文件 | 适用场景 |
|------|------|---------|
| **MD** | `.claude/reports/code-review-{timestamp}.md` | PR 评论、文档归档、GitHub/GitLab |
| **Excel** | `.claude/reports/code-review-{timestamp}.xlsx` | 团队分发、汇总统计、修复跟踪 |

Excel 文件包含 3 个 Sheet：
- **评审汇总** — 各维度通过/不通过统计
- **问题清单** — 文件+行号+问题描述+严重等级+修复建议+状态，按等级着色（红/橙/黄/绿）
- **评审信息** — 评审范围、日期、结果、提交、结论

### 9.5 问题等级

| 等级 | 处理方式 |
|------|---------|
| 高危/严重 | 必须修复，阻塞合并 |
| 中危 | 强烈建议修复 |
| 一般 | 建议改进 |
| 低危/建议 | 供参考 |

### 9.6 评审结论判定

| 结论 | 条件 |
|------|------|
| 不通过 | 存在任何高危/严重级别问题 |
| 有条件通过 | 存在中危级别问题，已确认修复计划 |
| 通过 | 仅有一般/建议级别问题或无问题 |

详细标准见 `skills/code-review/standards.md`。

### 6.3 评审维度

| 优先级 | 维度 | 项数 |
|--------|------|------|
| 1 | 安全性 | 18 项（业务篡改、越权、注入、信息泄露等） |
| 2 | 正确性 | 5 项（功能逻辑、边界异常、数据一致性等） |
| 3 | 性能 | 4 项（查询、资源、缓存、批量） |
| 4 | 设计与架构 | 4 项（职责、接口、扩展性） |
| 5 | 可维护性 | 6 项（命名、复杂度、重复代码等） |
| 6 | 规范与一致性 | 3 项（编码规范、提交规范、配置管理） |
| 7 | 文件类型专属 | 按后缀激活（Java/Python/Go/Vue/React/SQL/XML/配置） |

### 9.4 问题等级

| 等级 | 处理方式 |
|------|---------|
| 高危/严重 | 必须修复，阻塞合并 |
| 中危 | 强烈建议修复 |
| 一般 | 建议改进 |
| 低危/建议 | 供参考 |

### 9.5 评审结论判定

| 结论 | 条件 |
|------|------|
| 不通过 | 存在任何高危/严重级别问题 |
| 有条件通过 | 存在中危级别问题，已确认修复计划 |
| 通过 | 仅有一般/建议级别问题或无问题 |

详细标准见 `skills/code-review/standards.md`。

---

## 七、Spec 规格驱动

### 5.1 为什么需要 Spec

| 没有 Spec | 有 Spec |
|-----------|---------|
| AI 靠聊天记录理解需求，上下文丢失就自由发挥 | AI 每次从文件读约束，不会走样 |
| 设计变更没有记录，改了什么不清楚 | Delta Spec 记录每次增量变更 |
| 新人看代码理解决策，效率极低 | 新人看 spec 理解背景，3 分钟搞定 |

**实测效果：** 同一个管线，不写 spec 来回改了四版才定型；写完 spec 后 Claude 一次就生成了能通过全部测试的代码。前面磨的那 1 小时，后面全赚回来了。

### 5.2 生命周期

```
Propose（提案）→ Apply（实施）→ Archive（归档）
```

| 阶段 | 触发方式 | 做什么 |
|------|---------|--------|
| **Propose** | `/spec` 命令 或 workflow 步骤 1（中等+复杂） | 在 `specs/active/` 创建 spec 文件 |
| **Apply** | 用户确认 spec 后 | 状态改为 Applied，后续 Session 从文件读约束 |
| **Archive** | workflow 最后一步（验证通过后） | 移入 `specs/archived/`，作为活文档保留 |

### 5.2.1 三种触发 spec 的方式

| 方式 | 行为 | 适用 |
|------|------|------|
| `/spec <需求>` | **强制产出 spec，不进入实现** | 只想要 spec 文件 |
| `/backend` `/frontend` `/fullstack` + 需求 | 走完整 workflow，spec 是步骤 1 的产出 | 想直接做完 |
| 直接说"写个 spec" | AI 听懂就写，听不懂可能跳过 | 不推荐，依赖 AI 判断 |

**推荐用 `/spec`**：显式、确定、可预期，不依赖 AI 的复杂度判断。

### 5.3 Spec 文件模板

```markdown
# [功能名称] 规格

## 状态
Proposed | Applied | Completed

## 需求概述
[一句话描述做什么]

## 涉及文件
- 新增：[文件路径列表]
- 修改：[文件路径列表]

## 接口定义（如涉及 API）
- 路径、方法、请求参数、响应格式

## 数据模型变更（如涉及数据库）
- 表名、字段、索引

## 约束条件
- [硬性约束列表]

## 验收标准
- [ ] 标准 1
- [ ] 标准 2

## 变更记录
| 日期 | 变更内容 |
|------|---------|
| YYYY-MM-DD | 初始提案 |
```

### 5.4 Delta Spec 原则

不重写整个文档，只追加变更到"变更记录"表。实施中的设计变更必须同步更新 spec。

### 5.5 Spec 维护规则

- `specs/active/` 只保留当前进行中的 spec，完成后**必须归档**
- `specs/archived/` 按功能名归档，不删除（活文档，和代码一起提交 git）
- 归档 spec 的价值：新人 3 分钟理解决策背景 > 看代码 30 分钟

---

## 八、工作流详解

### 6.1 前端工作流

| 步骤 | 名称 | 触发条件 | 产出 |
|------|------|---------|------|
| 0 | 需求入口 | 所有任务 | 复杂度判断 |
| 1 | 需求澄清 + Spec | 中等+复杂 | `specs/active/[feature].md` |
| 2 | 任务拆解 | 复杂 | 任务计划 |
| 3 | 实现 | 所有任务 | 代码（读取 spec 作为约束） |
| 4 | 验证 + 归档 | 所有任务 | lint/test 结果 + spec 移入 archived |

**简单任务直接跳到步骤 3。**

### 6.2 后端工作流

| 步骤 | 名称 | 触发条件 | 产出 |
|------|------|---------|------|
| 0 | 需求入口 | 所有任务 | 复杂度判断 |
| 1 | 需求澄清 + Spec | 中等+复杂 | `specs/active/[feature].md` |
| 2 | 任务拆解 | 复杂 | 任务计划 |
| 3 | 自底向上实现 | 所有任务 | DAO → Service → Controller |
| 4 | 验证 + 归档 | 所有任务 | 构建/测试结果 + spec 移入 archived |

**实现顺序：DAO → Service → Controller，严格分层，禁止跨层。**

### 6.3 全栈工作流

| 步骤 | 名称 | 触发条件 | 产出 |
|------|------|---------|------|
| 0 | 需求入口 | 所有任务 | 复杂度判断 |
| 1 | 需求澄清 + Spec | 中等+复杂 | `specs/active/[feature].md` |
| 2 | 任务拆解 | 复杂 | 任务计划 |
| 3 | 工作空间隔离 | 复杂 | git worktree |
| 4 | 实现 | 所有任务 | DB → DAO → Service → Controller → 前端 API → 页面 |
| 5 | 联调验证 + 归档 | 所有任务 | 前后端验证结果 + spec 移入 archived |
| 6 | 代码审查 | 中等+复杂 | 审查报告 |
| 7 | 收尾 | 所有任务 | 知识库更新 + 分支合并 |

---

## 九、条件规则

规则在满足条件时自动触发，无需手动调用。

### 7.1 编码标准（`rules/coding-standards.md`）

| 触发条件 | 规则 |
|---------|------|
| 编辑任何源代码文件 | 不引入安全漏洞、不写多余注释、不超设计 |
| 创建/修改后端代码 | 严格分层、统一响应、异常统一处理 |
| 创建/修改前端代码 | PascalCase 命名、API 走 api/ 模块、处理三种状态 |

### 7.2 Git 安全（`rules/git-safety.md`）

| 触发条件 | 规则 |
|---------|------|
| 执行 git 命令 | 不 force push、不 rm -rf、不跳过 hooks、不提交密钥 |

### 7.3 工作流 + 调试（`rules/superpowers-workflow.md`）

| 触发条件 | 规则 |
|---------|------|
| 执行 workflow | 开发铁律（设计 → 测试 → 验证） |
| 遇到 bug/测试失败 | 先找根因再修，连续 3 次失败停下来审视架构 |

---

## 十、Superpowers 集成

### 8.1 配置位置

Superpowers 配置在 `memory/superpowers-config.md`，workflow 执行时按需加载，不占用日常对话上下文。

### 8.2 启用状态

| 阶段 | Skill | 状态 | 说明 |
|------|-------|------|------|
| 入口 | using-superpowers | 始终启用 | 自动判断走哪条流程 |
| 设计 | brainstorming | 条件启用 | 中等以上复杂度触发 |
| 规划 | writing-plans | 条件启用 | 复杂任务触发 |
| 隔离 | using-git-worktrees | 条件启用 | 复杂任务触发 |
| 执行 | subagent-driven-development | 条件启用 | 复杂任务触发 |
| 测试 | test-driven-development | 条件启用 | 中等以上复杂度触发 |
| 调试 | systematic-debugging | 始终启用 | 遇到 bug 自动触发 |
| 审查 | requesting/receiving-code-review | 条件启用 | 复杂任务触发 |
| 验证 | verification-before-completion | 始终启用 | 完成前必须验证 |
| 收尾 | finishing-a-development-branch | 条件启用 | 中等以上触发 |

### 8.3 修改配置

编辑 `memory/superpowers-config.md` 中的 JSON 注释块：

- `enabled` — 始终执行
- `disabled` — 始终跳过
- `conditional` — 按复杂度条件执行
- `manual` — 需用户明确调用才触发

---

## 十一、实战案例

### 10.1 后端案例：积分入账接口

```
你: /backend 创建积分入账接口，用户消费和签到得分，需要幂等
```

AI 进入 workflow 步骤 1，产出 spec：

```markdown
# 积分入账 规格

## 状态
Proposed

## 需求概述
实现积分入账接口，支持消费和签到两种场景，幂等 + 并发安全。

## 涉及文件
- 新增：service/PointsService.java, controller/PointsController.java
- 新增：mapper/PointsLedgerMapper.java

## 接口定义
- POST /api/points/credit
- 请求：{ userId, points, bizId, bizType, remark }
- 响应：{ code, message, data: { balance }, timestamp }

## 约束条件
- 幂等：通过 bizId + bizType 去重，窗口 24 小时
- 并发：乐观锁防止余额超扣
- 入账成功发送 MQ 事件

## 验收标准
- [ ] 相同 bizId+bizType 重复请求不重复入账
- [ ] 并发扣减不超扣
- [ ] 入账后余额正确
```

用户确认后，AI 自底向上实现（Mapper → Service → Controller），运行 `mvn test` 贴出结果，spec 归档。

### 10.2 前端案例：用户管理页面

```
你: /frontend 创建用户管理页面，包含列表、搜索、分页
```

AI 进入 workflow 步骤 1，产出 spec：

```markdown
# 用户管理页面 规格

## 状态
Proposed

## 需求概述
用户管理页面，支持列表展示、关键词搜索、分页、状态切换。

## 涉及文件
- 新增：views/UserManagement.vue
- 新增：api/user.js
- 修改：router/index.js

## 组件设计
- el-table 展示列表（姓名、邮箱、状态、操作）
- el-input 搜索框（支持姓名/邮箱模糊搜索）
- el-pagination 分页（默认每页 20 条）

## API 调用
- GET /api/users?page=1&size=20&keyword=xxx
- PUT /api/users/{id}/status

## 验收标准
- [ ] 搜索结果实时更新
- [ ] 分页切换无闪烁
- [ ] loading / error / empty 三种状态已处理
```

### 10.3 全栈案例：积分系统完整模块

```
你: /fullstack 开发积分系统，含入账、扣减、过期、兑换
```

AI 走完整 7 步流程：
1. 澄清需求（积分有效期？并发策略？兑换失败回滚？） → 产出 spec
2. 拆解为 7 个子任务（每个 < 15 分钟）
3. 创建 worktree 隔离
4. 自底向上实现（DB → DAO → Service → Controller → 前端）
5. 前后端联调验证
6. 代码审查
7. 收尾归档

---

## 十二、错误驱动学习

> Agent 犯了一个新类型错误 → 加一条规则 → 以后不再犯同类错误。

这是 Mitchell Hashimoto（Vagrant/Terraform 作者）的实践：AGENTS.md 每一行对应一个过去的失败案例。它不是静态文档，是持续进化的防错系统。

### 11.1 知识积累机制

项目维护 `memory/learned-lessons.md` 文件，记录 AI 犯过的典型错误：

| 编号 | 类型 | 错误现象 | 规避规则 |
|------|------|---------|---------|
| L-001 | 编码 | 先写实现再补测试 | 必须先写失败测试再写实现 |
| L-002 | 编码 | mock 所有依赖导致测试无意义 | 核心逻辑不能全部 mock |
| L-003 | 编码 | 修改编译产物或生成文件 | 编辑前确认不在 .gitignore 中 |
| L-004 | 流程 | 长任务上下文腐化 | 复杂任务拆分，主动开新对话 |
| L-005 | 流程 | 需求靠对话确认后遗忘 | 中等+复杂任务必须写 spec |
| L-006 | 流程 | 口头说"应该没问题" | 完成前必须运行验证命令 |
| L-007 | 架构 | Controller 层写业务逻辑 | 禁止跨层调用 |
| L-008 | Loop | 扫描类命令自指噪声(`/scan-todos` 试点踩坑) | 扫描时排除 `.claude/commands/`、`.claude/usage-guides/`,并对剩余结果做自指过滤 |
| L-009 | 流程 | 复杂项目编排时主会话 context 撑爆 | 按阶段切会话，阶段结束 `/handoff` 写 CURRENT.md 快照 |

### 11.2 记录规则

当 AI 犯了一个新的、有代表性的错误时：

0. **先按 [瓶颈定位指南](bottleneck-navigation.md) 排查瓶颈在哪一层** — 如果瓶颈在 Context（信息没给够），加 rule 没用；只在确认瓶颈在 Harness 层时，才进以下步骤
1. 在 `memory/learned-lessons.md` 新增条目（错误现象 + 根因 + 规避规则 + 日期）
2. **编码层面** → 考虑在 `rules/coding-standards.md` 中新增约束
3. **流程层面** → 考虑在 workflow 步骤中新增检查点
4. **架构层面** → 考虑更新 `memory/architecture.md` 分层约束

### 11.3 防止 rule 滥用

Harness 编码的是"模型此刻还做不到什么"的假设。Rule 不是越多越好 — 每条 rule 都增加思考成本，也可能限制本可以自动做的事。判断标准：

- ✅ **该加**：AI 反复犯同类错，且确认不是 Context 不足
- ❌ **不该加**：一次性的偶然失误（直接修正即可）
- ❌ **不该加**：Context 问题（改 spec / memory 更合适）
- 🟡 **该撤**：某条 rule 对应的错误已经不再犯（可以删 rule 减少负担）

完整触发条件索引见 `rules/INDEX.md`，方便审计每条 rule 是否仍有必要。

---

## 十三、健康巡检

### 13.1 运行健康检查

```bash
.claude/scripts/health-check.sh
```

### 13.2 检查项

| # | 检查项 | 正常标准 | 异常处理 |
|---|--------|---------|---------|
| 1 | CLAUDE.md 膨胀 | < 80 行（目标 < 60 行） | 将详细内容移到子文档 |
| 2 | Active Spec 积压 | < 3 个未归档 | 完成的 spec 移入 archived/ |
| 3 | 知识库更新时间 | < 90 天未更新 | 更新过时的文档 |
| 4 | v4 残留规则 | 无 code-quality.md / project-architecture.md | 删除旧文件 |
| 5 | Superpowers 配置位置 | memory/superpowers-config.md 存在 | 从 CLAUDE.md 迁移 |
| 6 | Spec 目录结构 | SPEC-GUIDE.md + active/ + archived/ | 补全缺失项 |
| 7 | 错误积累机制 | learned-lessons.md 存在 | 创建文件 |

### 13.3 巡检时机

- 每周一次定期运行
- 大功能完成后运行
- 团队新成员加入前运行

---

## 十四、知识库维护

| 时机 | 更新什么 |
|------|---------|
| 架构变更 | `memory/architecture.md` + `CLAUDE.md` 技术栈 |
| 新增规范 | `memory/frontend-standards.md` 或 `backend-standards.md` |
| 新增业务模块 | `memory/business-logic.md` |
| 解决重要问题 | `memory/issues.md`（记录根因和规避方式） |
| AI 反复犯同类错 | `memory/learned-lessons.md` 新增条目，必要时 `rules/` 新增约束 |
| 功能完成 | `specs/active/` → `specs/archived/` |

---

## 十五、常见问题

### Q1: CLAUDE.md 为什么只有 53 行？

> OpenAI 实践证明 AGENTS.md 当目录用比当百科好用。CLAUDE.md 每次对话自动加载，太长浪费上下文。详细内容放到子文档按需加载。当前 53 行只包含最核心的原则和文档地图。

### Q2: AI 不遵守规则怎么办？

> rules 是概率性约束，模型有可能忽略。两层防御：
> 1. 重要规则写进 rules（自动触发提醒）
> 2. 特别关键的（如拦截 .env 提交）配置到 settings.json 的 hooks 中做确定性拦截

### Q3: Spec 归档后还有用吗？

> 有用。归档的 spec 是活文档：新人看 spec 理解决策背景比看代码快 10 倍；历史 spec 追溯"为什么这么设计"；方便 Delta Spec 的变更追溯。

### Q4: 上下文太长 AI 开始变蠢怎么办？

> 这是上下文腐化（Dumb Zone）。解决方案：
> 1. 开新对话，比在旧对话中继续更高效
> 2. 长任务拆分，每个子任务独立完成
> 3. 依赖 spec 文件而非聊天记录来传递上下文

### Q5: 多项目工作区怎么工作？

> init.sh 自动检测子目录的项目标记文件（pom.xml、go.mod、package.json 等），进入工作区模式后创建两层 `.claude/`：
> - 工作区根目录：全局共享配置（共享 rules/commands/skills/memory）
> - 每个子项目：专属 `.claude/`（技术栈专属 rules + 项目 memory）
>
> 开发时 `cd` 到哪个子项目就加载哪个配置，Claude 自动感知对应技术栈的分层规范。

### Q5.1: 重复运行 init.sh 会覆盖已有配置吗？

> 不会。init.sh 所有文件都有保护机制（`if [ ! -f ]`），已有文件不会被覆盖，只会补全缺失项。已有 `.claude/` 时自动进入增量模式，无需交互确认。
>
> 适合的场景：模板升级后补全新文件、项目新增依赖后重新检测、工作区新增子项目。

### Q6: 和旧版（v4）的主要区别？

| 维度 | v4 | v5 |
|------|----|----|
| CLAUDE.md | 108 行，内嵌 Superpowers 配置 | 53 行，目录式 |
| Rules | 4 个文件 | 3 个文件（合并精简） |
| Spec 机制 | 无 | Propose → Apply → Archive 完整生命周期 |
| 核心原则 | 无明确分层 | 原生优先，90% 场景用原生 |
| 配置加载 | CLAUDE.md 全量加载 | 子文档按需加载 |
| Workflow 步骤 1 | 口头确认 | 产出 spec 文件 |
| 多项目支持 | 无 | v5.3 新增工作区模式 |
| 代码评审 | 基于 git diff | v5.5 支持多选提交、MD/Excel 双格式输出、只读 git 预授权 |

### Q7: 什么时候不用这套体系？

| 场景 | 建议 |
|------|------|
| 一次性脚本 | 直接写，跑通即可 |
| 探索性原型 | 快速验证可行性，不走 spec |
| 紧急 Hotfix | 先修复，事后补测试和 spec |

### Q8: `/spec` 和 `/backend` `/frontend` `/fullstack` 怎么选？

| 你的诉求 | 用哪个 |
|----------|--------|
| 只想把需求理清楚，不写代码 | `/spec` |
| 想直接做完一个中等/复杂功能 | `/backend` `/frontend` `/fullstack` |
| 多人协作，先对齐再分发 | `/spec` 写完分发 |
| 不信任 AI 的复杂度判断，要强制产出 spec | `/spec` |

`/spec` 产出 spec 文件后，可以接着说"开始实现"进入 workflow，也可以把 spec 文件交给别人实现。

### Q9: 已经在用 `/backend` 走 workflow，能跳过 spec 吗？

> 简单任务（< 30 分钟）可以跳过，AI 会直接做。
> 中等+复杂任务**必须**产出 spec — 这是 workflow 步骤 1 的强制产出。
> 如果只想跳过 workflow 但要 spec，用 `/spec` 命令。

### Q10: AI 效果不好怎么排查？

> 按 [瓶颈定位指南](bottleneck-navigation.md) 的顺序从内到外排查：
>
> 1. **Prompt 层** — 任务描述清楚吗？换个说法会不会好？
> 2. **Context 层** — 相关 spec/memory 给到了吗？上下文是不是太长导致腐化？
> 3. **Harness 层** — 这个错犯过吗？有对应 rule 吗？验证脚本能拦住吗？
> 4. **Loop 层** — 这个任务该自动化吗？是不是在反复手动驱动？
>
> **常见误判**：「AI 太笨」多数是 Context 没给够；「加条 rule 就好」多数是没定位就动手；「这套体系没用」多数是用错了层（简单任务上了完整 workflow，或复杂任务只用了原生）。

---

## 十五.五、团队推行问答

> 以下 FAQ 适用于向团队推行本体系时，解答同事或管理层的典型疑问。

### TQ1: 这套体系不就是 Claude Code + 一堆 Markdown 文件吗，为什么叫"Harness"？

> 叫什么名字不重要。"Harness（驾驭系统）"不是某个特定框架，而是指"让 AI 从不可控的聊天玩具变成可靠开发员工"的工程化体系。你们看到的 `CLAUDE.md` + `rules/` + `specs/` + Superpowers，组合在一起就已经是一个完整的轻量级 Harness 了。不需要额外引入重型平台。

### TQ2: 团队每个人的电脑是物理隔离的，怎么保证"统一的 Harness 环境"？

> 追求的不是物理上的"同一台机器"，而是逻辑上的"同一套标准"。所有规范配置（`CLAUDE.md`、`rules/`、`commands/`、`skills/`）都提交到 Git 仓库。任何新成员只要拉取代码，本地的 AI 就会自动读取这些配置文件，加载出完全一致的团队专属环境。**代码即配置，Git 即分发。**

### TQ3: 新员工入职怎么快速上手？

> 一行命令搞定：
>
> ```bash
> # 克隆项目后，直接启动 Claude Code，AI 自动加载团队配置
> claude
> ```
>
> 如果团队维护了独立的模板仓库，还可以用：
>
> ```bash
> npx degit github:yourteam/harness-templates .claude
> bash .claude/scripts/init.sh
> ```
>
> 就像给每位新员工发了一台预装了相同操作手册的电脑。

### TQ4: Superpowers 自带子代理（Subagent），还需要别的吗？

> Superpowers 的子代理解决的是**单项目内的任务并行**（如前端和后端同时开发），属于"内部调度"。对于绝大多数团队场景，这已经足够。
>
> 只有在极端场景（多异构模型调度、跨部门安全审计、极高并发资源抢占）下，才需要考虑更底层的独立编排平台。**把现有三件套（Claude Code + Superpowers + Spec）磨合到极致，就是最适合你们的方案。**

### TQ5: Brainstorming 和 Spec 是什么关系？有了 Brainstorming 还需要 Spec 吗？

> **互补关系，不是替代关系。**
>
> - **Brainstorming** = "把事想对" — 处理模糊地带、发散思维、理清方向
> - **Spec（`/spec`）** = "把事说清" — 将讨论结果沉淀为可追溯的结构化文档
> - **Superpowers Workflow** = "把事做稳" — TDD + 审查 + 验证确保代码质量
>
> 三者缺一不可。Brainstorming 是"头脑风暴会议室"，Spec 是"施工蓝图"，Superpowers 是"施工规范"。只开会不画图纸会跑偏，只画图纸不验收会翻车。

### TQ6: 什么时候不用这套体系？

> | 场景 | 建议 |
> |------|------|
> | 一次性脚本 | 直接写，跑通即可 |
> | 探索性原型 | 快速验证可行性，不走 spec |
> | 紧急 Hotfix | 先修复，事后补测试和 spec |
> | 五分钟以内的小改动 | 原生 Claude Code 直接做 |
>
> **核心原则：简单的事情简单做。** 过度工程化是最大的浪费。

---

## 十六、选型速查

| 场景 | 推荐方案 |
|------|---------|
| 小任务（5 分钟以内） | 原生 Claude Code |
| 个人项目日常开发 | 原生 + Superpowers |
| 中等任务（新组件/新接口） | workflow + spec |
| 多模块大项目 | 完整 workflow + spec + code-review |
| 多项目工作区（Java+Vue+Python） | init.sh 工作区模式，cd 到子项目开发 |
| 最不确定该选哪个 | 先试原生，不够再上 workflow |

> 核心原则：简单的事情简单做。选错不算坑，选了不敢换才是真坑。

---

## 十七、文件清单

### 17.1 单项目结构

```
CLAUDE.md                              # [53行] 项目指令（目录式）
.claude/
├── settings.json                      # [团队共享] 主配置
├── settings.local.json                # [个人本地] 密钥配置
├── MEMORY.md                          # 知识库索引
├── commands/                          # 斜杠命令
│   ├── frontend.md                    #   /frontend
│   ├── backend.md                     #   /backend
│   ├── fullstack.md                   #   /fullstack
│   └── spec.md                        #   /spec（强制产出 spec，不写代码）
├── rules/                             # 条件规则（自动触发）
│   ├── coding-standards.md            #   编码标准
│   ├── git-safety.md                  #   Git 安全
│   ├── superpowers-workflow.md        #   工作流 + 调试规则
│   └── [spring-boot.md / python-api.md / vue-standards.md / ...]  # 技术栈专属
├── skills/                            # 工作流技能
│   ├── frontend-workflow.md           #   前端工作流
│   ├── backend-workflow.md            #   后端工作流
│   ├── fullstack-workflow.md          #   全栈工作流
│   └── code-review/                   #   代码评审
│       ├── SKILL.md                   #   评审流程
│       └── standards.md               #   评审标准
├── reports/                           #   评审报告输出
│   ├── code-review-{timestamp}.md    #     MD 格式报告
│   └── code-review-{timestamp}.xlsx  #     Excel 格式报告
├── specs/                             # 功能规格
│   ├── SPEC-GUIDE.md                  #   Spec 使用指南
│   ├── active/                        #   进行中
│   └── archived/                      #   已完成
├── scripts/
│   ├── init.sh                        # 初始化脚本（v5.3 多项目支持）
│   ├── verify.sh                      # 验证脚本
│   └── health-check.sh                #   健康巡检（7 项自动检查）
└── memory/                            # 项目知识库
    ├── architecture.md                #   架构文档
    ├── frontend-standards.md          #   前端规范
    ├── backend-standards.md           #   后端规范
    ├── business-logic.md              #   业务逻辑
    ├── superpowers-config.md          #   Superpowers 配置
    ├── learned-lessons.md             #   错误积累（持续进化）
    └── issues.md                      #   问题记录
```

### 17.2 多项目工作区结构

```
CLAUDE.md                              # 工作区概览（列出所有子项目和技术栈）
.claude/                               # ── 全局共享 ──
├── settings.json                      #   共享配置
├── commands/                          #   共享命令（带子项目感知）
├── rules/                             #   共享规则（git-safety, workflow, coding-standards）
├── skills/                            #   共享工作流
├── memory/                            #   全局知识库（架构、错误积累）
├── specs/                             #   全局 specs
└── scripts/                           #   共享脚本

java-api/
├── CLAUDE.md                          # Java 专属指令
└── .claude/                           # ── Java 专属 ──
    ├── settings.json                  #   Java 构建权限
    ├── rules/spring-boot.md           #   Spring Boot 分层规范
    ├── memory/                        #   Java 项目知识库
    │   ├── architecture.md
    │   ├── backend-standards.md
    │   └── business-logic.md
    └── specs/

vue-web/
├── CLAUDE.md                          # Vue 专属指令
└── .claude/                           # ── Vue 专属 ──
    ├── settings.json                  #   npm 构建权限
    ├── rules/vue-standards.md         #   Vue 组件规范
    ├── memory/                        #   前端项目知识库
    │   ├── architecture.md
    │   ├── frontend-standards.md
    │   └── business-logic.md
    └── specs/
```
