# Claude Code AI 辅助开发配置

## 模式
单项目模式

## 项目信息
- 名称：claude-apprentice
- 类型：frontend
- 语言：JavaScript/TypeScript

## 架构说明

| 目录 | 用途 | 触发方式 |
|------|------|----------|
| `CLAUDE.md` | 项目最高优先级指令 | 自动加载 |
| `commands/` | 斜杠命令（模式切换） | 用户输入 `/` 前缀 |
| `rules/` | 条件规则（自动触发） | 编辑代码时自动生效 |
| `skills/` | 工作流技能 | 用户 `/skill-name` 调用 |
| `memory/` | 项目知识库 | 被规则和命令引用 |



## 使用方式

| 命令 | 说明 |
|------|------|
| `/frontend` | 前端开发模式 |
| `/backend` | 后端开发模式 |
| `/fullstack` | 全栈协调模式 |

## 验证配置

```bash
apprentice doctor
```

---

**初始化日期:** 2026-07-01
