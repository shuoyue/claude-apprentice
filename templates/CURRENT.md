# 当前任务交接（CURRENT.md）

> 给下一会话失忆 AI 的接力棒。读此文件 + `@spec` + `@plan` 即可无缝接上。
> 由 `/handoff` 维护；`状态：进行中` 时 SessionStart hook 自动注入新会话。
> 任务完成改为 `状态：已完成` 并归档（移入 specs/archived 同名目录或删除）。

状态：模板

---

## 任务
- Spec：`specs/active/（spec 文件链接）`
- 目标：（一句话说明在做什么）

## 进度
- 阶段：（workflow step，如「后端实现 / step 4，b 自底向上第 3 项 Service 层」）
- 已完成：`[x] ...`
- 当前停在：（← 接力点，停在哪一句/哪个函数）
- Plan：`docs/superpowers/plans/（plan 链接）`

## 环境
- worktree：`.claude/worktrees/（分支名）` 或「当前分支」
- 未提交：`git status` 摘要（只列文件，不贴 diff）

## 关键决策
- （为什么这么做 + 日期，如「7/8 用户确认用 JWT 而非 session」）

## 下一步
- （具体动作 + 涉及文件路径，新会话照着做即可）

## 红线
- `@memory/*-standards.md`、相关 `rules/`
