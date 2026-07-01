#!/usr/bin/env bash
#
# 自动 review 最近一次 commit
#
# 用法:
#   .claude/scripts/auto-review.sh                 # review HEAD
#   .claude/scripts/auto-review.sh <commit-hash>   # review 指定 commit
#
# 配置为 Claude Code PostToolUse hook(异步触发,不阻塞 commit):
#
# 在 .claude/settings.json 加:
#
#   {
#     "hooks": {
#       "PostToolUse": [
#         {
#           "matcher": "Bash",
#           "hooks": [
#             {
#               "type": "command",
#               "command": "bash .claude/scripts/auto-review.sh"
#             }
#           ]
#         }
#       ]
#     }
#   }
#
# Hook 触发时,通过 stdin 收到 JSON 载荷(含 tool_name 和 command),
# 脚本判断是否为 git commit,非 commit 命令直接退出 0。
#
# 不想配 hook 时,也可手动调用,或在 Claude Code 对话里说:
#   "review 上次 commit"
#

set -euo pipefail

# 从 hook 触发时,判断是不是 git commit
if [ ! -t 0 ]; then
  PAYLOAD="$(cat 2>/dev/null || true)"
  if echo "$PAYLOAD" | grep -q '"tool_name":"Bash"' 2>/dev/null; then
    if ! echo "$PAYLOAD" | grep -Eq 'git commit' 2>/dev/null; then
      exit 0
    fi
  fi
fi

# 确定要 review 的 commit
COMMIT="${1:-HEAD}"

# 确认在 git 仓库内
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[auto-review] 不在 git 仓库内,跳过" >&2
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
REPORT_DIR="$REPO_ROOT/.claude/reports"
mkdir -p "$REPORT_DIR"

# 检查 ocr 是否可用
if ! command -v ocr >/dev/null 2>&1; then
  echo "[auto-review] ocr CLI 未安装,跳过自动 review" >&2
  echo "[auto-review] 备选:在 Claude Code 对话里说 'review 上次 commit'" >&2
  exit 0
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$REPORT_DIR/auto-review-$TIMESTAMP.md"

echo "[auto-review] Reviewing commit $COMMIT..."
ocr review "$COMMIT" --output "$REPORT" 2>&1 || {
  echo "[auto-review] review 失败,请手动检查 $COMMIT" >&2
  exit 1
}

echo "[auto-review] 报告已生成: $REPORT"
