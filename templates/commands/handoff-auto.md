配置「context 超阈值自动提醒 /handoff」。可选功能，默认关闭。

## 用法

| 命令 | 作用 |
|------|------|
| `/handoff-auto on` | 开启提醒 |
| `/handoff-auto off` | 关闭（默认）|
| `/handoff-auto threshold 50` | 设置阈值百分比（默认 50）|
| `/handoff-auto window 200000` | 设置窗口大小 token（默认 200000）|
| `/handoff-auto status` | 查看当前配置 |

## 你要做的（按 `$ARGUMENTS`）

- `on` → `touch .claude/.handoff-remind`
- `off` → `rm -f .claude/.handoff-remind`
- `threshold N` → `echo N > .claude/.handoff-threshold`（N 取 1–99）
- `window N` → `echo N > .claude/.handoff-window`
- `status` 或无参数 → 读三个配置文件，报告：开关 / 阈值 / 窗口

执行后向用户确认结果。

## 配置文件（`.claude/` 下，存在即生效）

- `.handoff-remind` — 开关（存在 = 开）
- `.handoff-threshold` — 阈值百分比（默认 50）
- `.handoff-window` — 窗口 token（默认 200000）

## 机制：两层提醒，共用开关

1. **阈值提醒**（UserPromptSubmit hook，`scripts/handoff-context-check.sh`）：每次用户提交时算 context 用量，超阈值提示。用量来自 transcript 的 `message.usage`（真实 input + cache）。
2. **压缩前提醒**（PreCompact hook）：context 接近上限自动压缩前兜底提示（~92%）。

## 推荐阈值

| 任务类型 | 阈值 |
|---------|------|
| 复杂 / 高质量（架构、多文件）| 40 |
| 常规编码 | **50（默认）** |
| 简单 / 机械 | 70 |

> 窗口按模型：GLM-5 / Claude = 200000，GLM-5.2 = 1000000。换模型记得 `/handoff-auto window` 校准。

$ARGUMENTS
