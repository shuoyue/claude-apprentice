# CLAUDE.md

**体系版本:** v1.0 | **更新日期:** 2026-06-22

## 技术栈

- 前端：待填写
- 后端：待填写
- 数据库：待填写

## 核心原则：原生优先

简单任务（改变量、修 bug、写工具函数）直接说需求，不走 workflow。
复杂任务（新功能模块、多文件变更）才上 workflow 和 Spec。

> 90% 的场景用原生 Claude Code 就够了。过度工程化是最大的浪费。

## 开发铁律

1. **没设计不写代码** — 动手前先确认文件、范围、方案
2. **没测试不写代码** — 先写失败测试，再写实现
3. **没验证不说完成** — 必须运行验证命令并贴出结果

## 模式切换

| 命令 | 用途 |
|------|------|
| `/frontend` | 前端开发 |
| `/backend` | 后端开发 |
| `/fullstack` | 全栈协调 |

## 核心约束

- 后端分层：Controller → Service → DAO，禁止跨层
- 前端 API 调用走 `api/` 模块
- RESTful 统一响应：`{ code, message, data, timestamp }`
- 所有外部输入必须校验，不引入安全漏洞

## 文档地图

| 目录 | 用途 | 何时读 |
|------|------|--------|
| `.claude/rules/` | 自动触发的编码规则（索引见 `rules/INDEX.md`） | 编辑代码时自动生效 |
| `.claude/skills/` | 完整工作流编排 | 走 workflow 时按需加载 |
| `.claude/memory/` | 项目知识库（架构、规范、业务，含 `learned-lessons.md` 错误登记册） | 需要项目上下文时引用 |
| `.claude/specs/` | 功能规格文档 | 中等+复杂任务时创建和引用 |
| `.claude/scripts/` | 初始化和验证脚本 | 新项目接入时使用 |
| `.claude/reports/` | 代码评审报告输出 | 评审完成后自动生成 |
| `.claude/usage-guides/` | 操作手册（v1.0） | 查阅体系用法时引用 |
| `.claude/usage-guides/bottleneck-navigation.md` | **瓶颈定位指南** | AI 效果不好时按层排查 |

## 复杂度分级

| 级别 | 定义 | 策略 | Prompt | Context | Harness | Loop |
|------|------|------|--------|---------|---------|------|
| 简单 | 单文件修改，< 30 分钟 | 原生，不走 workflow | 基础描述 | 当前文件 | rules 自动触发 | 不需要 |
| 中等 | 新组件/新接口，30 分钟 - 2 小时 | brainstorming + spec + TDD | 完整描述 | + 相关 spec | + 验证脚本 | 通常不需要 |
| 复杂 | 新功能模块，> 2 小时 | 完整 workflow + spec + worktree + review | 完整描述 | 全量 spec | 完整 workflow | 探索试点 |

> AI 效果不好时,先按 [瓶颈定位指南](.claude/usage-guides/bottleneck-navigation.md) 排查瓶颈在哪一层,不要一上来就加 rule。
