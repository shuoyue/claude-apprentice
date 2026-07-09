#!/usr/bin/env bash
# handoff-context-check.sh — UserPromptSubmit hook
# context 用量超过配置阈值时，提示用户是否执行 /handoff
#
# 配置（$CLAUDE_PROJECT_DIR/.claude/ 下，均可选）：
#   .handoff-remind     开关（文件存在 = 开，默认关）
#   .handoff-threshold  阈值百分比（默认 50）
#   .handoff-window     窗口大小 token（默认 200000，GLM-5 / Claude）

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
[ -z "$PROJECT_DIR" ] && exit 0
BASE="$PROJECT_DIR/.claude"

# 开关：文件不存在则静默
[ -f "$BASE/.handoff-remind" ] || exit 0

# 阈值百分比（提取数字，默认 50）
THRESHOLD="50"
[ -f "$BASE/.handoff-threshold" ] && THRESHOLD="$(tr -dc '0-9' < "$BASE/.handoff-threshold")"
[ -z "$THRESHOLD" ] && THRESHOLD="50"

# 窗口大小（提取数字，默认 200000）
WINDOW="200000"
[ -f "$BASE/.handoff-window" ] && WINDOW="$(tr -dc '0-9' < "$BASE/.handoff-window")"
[ -z "$WINDOW" ] && WINDOW="200000"

# 定位当前 session transcript（项目路径编码：/ → -）
ENCODED="$(printf '%s' "$PROJECT_DIR" | sed 's:/:-:g')"
TRANSCRIPT="$(ls -t "$HOME/.claude/projects/$ENCODED"/*.jsonl 2>/dev/null | head -1)"
[ -z "$TRANSCRIPT" ] && exit 0

# 解析最新一条 assistant 消息的真实 context 用量（input + cache_creation + cache_read）
USED="$(tail -500 "$TRANSCRIPT" 2>/dev/null | python3 -c '
import sys, json
last = None
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
        msg = obj.get("message")
        if isinstance(msg, dict) and isinstance(msg.get("usage"), dict):
            last = msg["usage"]
    except Exception:
        pass
if last:
    print(last.get("input_tokens", 0)
          + last.get("cache_creation_input_tokens", 0)
          + last.get("cache_read_input_tokens", 0))
' 2>/dev/null)"
[ -z "$USED" ] && exit 0

# 整数百分比
PCT=$(( USED * 100 / WINDOW ))

if [ "$PCT" -ge "$THRESHOLD" ]; then
  printf '⚠️ [Context 提醒·自动] 当前 context 约 %s%%（%s / %s tokens），已达 %s%% 阈值。\n能力开始下降，建议先 /handoff 保存任务交接快照，再继续或 /clear 开新会话。请向用户确认是否现在执行 /handoff。\n' \
    "$PCT" "$USED" "$WINDOW" "$THRESHOLD"
fi

exit 0
