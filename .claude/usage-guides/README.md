# AI 驱动全栈开发 — 使用手册版本索引

## 版本列表

| 版本 | 文件 | 日期 | 主要变更 |
|------|------|------|---------|
| v5.8 | [usage-guide-v5.8.md](usage-guide-v5.8.md) | 2026-06-22 | 瓶颈定位指南、Loop 层试点（`/scan-todos`、`auto-review.sh`）、Rules 触发索引、错误驱动闭环 |
| v5.7 | [usage-guide-v5.7.md](usage-guide-v5.7.md) | 2026-06-02 | 评审增强；新增 `/spec` 命令（强制产出 spec，不进入实现）；FAQ 新增 Q8/Q9 |
| v5.6 | [usage-guide-v5.6.md](usage-guide-v5.6.md) | 2026-06-01 | 章节重组：初始化提到第一节、5分钟上手加入初始化引导、代码评审前置 |
| v5.5 | [usage-guide-v5.5.md](usage-guide-v5.5.md) | 2026-06-01 | 代码评审增强：多选提交、MD/Excel 双格式输出、reports 目录 |
| v5.4 | [usage-guide-v5.4.md](usage-guide-v5.4.md) | 2026-06-01 | 代码评审流程重构：开放只读 git 命令、settings.json 预授权 |
| v5.3 | [usage-guide-v5.3.md](usage-guide-v5.3.md) | 2026-05-29 | 多项目工作区、技术栈专属 rules、深度检测自动填充、增量更新模式 |
| v5.2 | [usage-guide-v5.2.md](usage-guide-v5.2.md) | 2026-05-28 | 新增健康巡检、错误驱动学习机制、init.sh v5 兼容 |
| v5.1 | [usage-guide-v5.1.md](usage-guide-v5.1.md) | 2026-05-27 | 原生优先理念、Spec 驱动、四层配置、CLAUDE.md 精简 |
| v4 | [usage-guide-v4.md](usage-guide-v4.md) | 2026-05-18 | 初版完整体系：workflow、rules、skills、知识库 |

## 版本演进

### v4 → v5.1

- CLAUDE.md 从 108 行精简到 53 行（目录式）
- Rules 从 4 个合并为 3 个
- 新增 Spec 机制（Propose → Apply → Archive）
- 确立"原生优先"核心原则
- Superpowers 配置从 CLAUDE.md 移到 memory/

### v5.1 → v5.2

- 新增第十三节"健康巡检"（health-check.sh 7 项自动检查）
- 第十一节"错误驱动学习"扩充为完整机制（7 条初始教训）
- init.sh 更新为 v5 格式（生成 learned-lessons.md、superpowers-config.md）
- 修复 verify.sh 知识库检查拼写错误

### v5.7 → v5.8

- 新增瓶颈定位指南 `.claude/usage-guides/bottleneck-navigation.md`(Prompt/Context/Harness/Loop 四层模型 + 排查顺序)
- 第二节演进线从三条扩成四条,加入 Loop Engineering
- 新增 `/scan-todos` slash command(Loop 层首个试点,扫描 TODO/FIXME 产出报告)
- 新增 `.claude/scripts/auto-review.sh`(commit 后异步自动 review,可独立调用或配 hook)
- 新增 `.claude/rules/INDEX.md`(Rules 触发条件索引,让规则可审计)
- 第十二节错误驱动学习加"加 rule 前先定位瓶颈"闭环
- FAQ 新增 Q10:效果不好怎么排查
- CLAUDE.md 复杂度分级表加 Prompt/Context/Harness/Loop 四列

### v5.6 → v5.7

- 代码评审新增维度七：文件类型专属检查（Java/Python/Go/Vue/React/SQL/XML/配置文件各一套检查项）
- 代码评审步骤 3 增加跨文件关联分析（接口→调用方、表结构→DAO、组件→引用方）
- 新增流程定义文件 workflow/WORKFLOW-GUIDE.md（后端/前端/全栈标准流程、阶段产物、通用规则）
- verify.sh 新增 --baseline save/diff 基线对比功能（防止 AI 推卸责任）
- init.sh 新增 generate_workflow() 函数
- health-check.sh 新增第 9 项流程定义检查

### v5.5 → v5.6

- 章节结构重组：初始化新项目从第十二节提到第一节，5 分钟上手加入初始化引导
- 代码评审从第九节提前到第六节（日常使用之后）
- 新章节顺序：快速上手 → 初始化 → 哲学 → 核心理念 → 架构 → 日常使用 → 代码评审 → Spec → 工作流 → 规则 → Superpowers → 案例 → 错误学习 → 巡检 → 知识库 → FAQ → 选型 → 文件清单

### v5.4 → v5.5

- 代码评审支持多选提交，多个提交的变更文件自动去重合并统一评审
- 评审报告支持 MD 和 Excel 双格式输出，用户选择后生成文件到 `.claude/reports/`
- Excel 报告含 3 个 Sheet（评审汇总、问题清单、评审信息），问题等级按颜色区分
- 新增 `.claude/reports/` 输出目录
- 第九节全面重写：评审流程、输出格式、问题等级、结论判定独立为小节

### v5.3 → v5.4

- 代码评审流程重构：开放只读 git 命令（git show/diff/log/diff-tree）用于评审上下文获取
- settings.json 预授权只读 git 命令，评审时不再弹出权限确认
- 评审过程禁止所有写操作的 git 命令（commit/push/checkout/reset/merge 等）
- 支持选择最近一次提交或从最近 10 次提交中选择
- SKILL.md 步骤 2 更新：明确列出允许的只读 git 命令清单

### v5.2 → v5.3

- init.sh 新增多项目工作区支持（--workspace / --project / --scan / 自动检测）
- 新增两层 .claude/ 结构：工作区全局共享 + 子项目技术栈专属
- 新增 5 种技术栈专属 rules（Java/Spring Boot、Python/FastAPI、Vue、React、Go）
- 第三节新增"单项目 vs 多项目工作区"架构说明
- 第十二节全面重写为多项目初始化指南
- 第十五节新增 Q5 多项目工作区问答
- 第十七节拆分为单项目和工作区两种文件清单
