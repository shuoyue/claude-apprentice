生成或更新当前任务的会话交接快照，写入 `.claude/CURRENT.md`。

## 做什么

把「当前任务的真实状态」按 CURRENT.md 的六段结构填入（**不留占位符**）：

- **任务** — Spec 链接 + 一句话目标
- **进度** — 当前 workflow 阶段 + 已完成项 + **停在哪个接力点** + plan 链接
- **环境** — worktree/分支 + `git status` 摘要（只列文件）
- **关键决策** — 为什么这么做（带日期）
- **下一步** — 具体动作 + 涉及文件（新会话照着做即可）
- **红线** — 引用 `memory/` 规范

## 要求

- 第一行状态必须是 `状态：进行中`（SessionStart hook 据此判断是否注入新会话）
- 严格指针式、**< 50 行**，不复制 spec/plan 全文，只放「当前快照」
- git 细节让新会话自己 `git status` 查，这里只记 worktree 位置
- spec 是静态真相，plan 是静态拆解，CURRENT 只补「现在停在哪 + 下一步」

## 何时用

- 主动切会话前（防爆）
- workflow 每个阶段结束（保连续）
- 任务完成时改为 `状态：已完成` 并归档

## 连续性闭环

```
本会话 /handoff → CURRENT.md(进行中) → /clear
                                      ↓
        新会话 SessionStart hook 自动注入 CURRENT.md
                                      ↓
        读 @spec @plan → 从「下一步」接着做
```

## 自动提醒（可选）

不想每次手动记 `/handoff`？开启 context 超阈值自动提醒：

- `/handoff-auto on` — 开启：context 接近上限（自动压缩前）提示你是否 /handoff
- `/handoff-auto off` — 关闭（默认）

机制：PreCompact hook 检测开关文件 `.claude/.handoff-remind`，开启时注入提示，AI 转达你确认。**只提醒不自动写**，执行权在你。

$ARGUMENTS
