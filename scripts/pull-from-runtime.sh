#!/usr/bin/env bash
# pull-from-runtime.sh — 从运行时实例 (.claude/) 回传模板内容到 SSOT
#
# 警告: 此脚本只复制模板路径,不会自动处理脱敏。
# 必须人工 review 每个变更,确保没有项目特定内容或敏感信息。
#
# 用法:
#   ./scripts/pull-from-runtime.sh /path/to/.claude                    # dry-run（默认）
#   ./scripts/pull-from-runtime.sh /path/to/.claude --quick            # 短路模式（无修改则跳过）
#   ./scripts/pull-from-runtime.sh /path/to/.claude --apply            # 实际覆盖
#   ./scripts/pull-from-runtime.sh /path/to/.claude --file rules/INDEX.md   # 只看一个文件
#   ./scripts/pull-from-runtime.sh /path/to/.claude --state-file <path>     # 自定义 state 路径
#
# State 文件:
#   默认在 $RUNTIME/.sync-state.json,记录上次检查的时间/结果/假阳性名单/runtime mtime 快照
#   - 用于让 cron 触发时跳过无修改的检查（节省 token）
#   - 用于"一次标记永久静默"已知假阳性（如 usage-guide-v5.2~v5.7 历史版本）
#
# 行为:
#   - 对比 .claude/ 与 SSOT templates/ 的模板路径
#   - 把差异分成「真差异」和「已知假阳性」两类显示
#   - dry-run / apply 后都会更新 state 文件
#   - --apply 不会自动 commit / 升版本

set -eo pipefail
shopt -s nullglob 2>/dev/null || true

# ── 可回传的模板路径（与 GOVERNANCE.md 2.2 节一致）─────────────────
TEMPLATE_PATHS=(
  "rules"
  "skills"
  "commands"
  "workflow"
  "usage-guides"
  "scripts/auto-review.sh"
  "scripts/health-check.sh"
  "scripts/init.sh"
  "settings.json"
  "specs/SPEC-GUIDE.md"
)

# ── 参数解析 ───────────────────────────────────────────────────────
APPLY=false
QUICK=false
RUNTIME=""
SINGLE_FILE=""
STATE_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
    --quick) QUICK=true; shift ;;
    --file) SINGLE_FILE="$2"; shift 2 ;;
    --state-file) STATE_FILE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,28p' "$0"
      exit 0
      ;;
    *)
      if [[ -z "$RUNTIME" ]]; then
        RUNTIME="$1"
      else
        echo "未知参数: $1" >&2; exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$RUNTIME" ]]; then
  echo "用法: $0 <path-to-.claude> [--apply|--quick] [--file <rel>] [--state-file <path>]" >&2
  echo "示例: $0 ~/Documents/D/claude/.claude" >&2
  exit 1
fi

# ── 路径解析 ───────────────────────────────────────────────────────
RUNTIME="$(cd "$RUNTIME" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$SSOT_DIR/templates"
STATE_FILE="${STATE_FILE:-$RUNTIME/.sync-state.json}"

# ── 前置检查 ───────────────────────────────────────────────────────
if [[ ! -d "$RUNTIME" ]]; then
  echo "错误: 运行时路径不存在: $RUNTIME" >&2; exit 2
fi
if [[ ! -d "$TEMPLATES_DIR" ]]; then
  echo "错误: SSOT templates/ 不存在: $TEMPLATES_DIR" >&2; exit 2
fi

# ── State 读取（bash 数组形式）─────────────────────────────────────
STATE_EXISTS=false
STATE_LAST_CHECK=""
STATE_LAST_RESULT=""
STATE_CONSECUTIVE_NO_DIFF=0
STATE_RUNTIME_MTIME_EPOCH=0
STATE_HINT_THRESHOLD=7
KNOWN_FP=()

if [[ -f "$STATE_FILE" ]]; then
  STATE_EXISTS=true
  # 用 python 解析 JSON，输出 bash 可 eval 的格式
  eval "$(python3 -c "
import json
try:
    data = json.load(open('$STATE_FILE'))
    print('STATE_LAST_CHECK=' + repr(data.get('last_check_time', '')))
    print('STATE_LAST_RESULT=' + repr(data.get('last_check_result', '')))
    print('STATE_CONSECUTIVE_NO_DIFF=' + str(data.get('consecutive_no_diff', 0)))
    print('STATE_RUNTIME_MTIME_EPOCH=' + str(data.get('runtime_mtime_epoch', 0)))
    print('STATE_HINT_THRESHOLD=' + str(data.get('hint_threshold', 7)))
except Exception as e:
    import sys
    print('# state parse error: ' + str(e), file=sys.stderr)
" 2>/dev/null || true)"

  # 读 known_false_positives 到 bash 数组
  while IFS= read -r line; do
    [[ -n "$line" ]] && KNOWN_FP+=("$line")
  done < <(python3 -c "
import json
try:
    data = json.load(open('$STATE_FILE'))
    for fp in data.get('known_false_positives', []):
        print(fp)
except Exception:
    pass
" 2>/dev/null || true)
fi

# ── 跨平台获取文件 mtime（epoch 秒）────────────────────────────────
get_mtime() {
  local f="$1"
  if stat -f '%m' "$f" >/dev/null 2>&1; then
    stat -f '%m' "$f"
  elif stat -c '%Y' "$f" >/dev/null 2>&1; then
    stat -c '%Y' "$f"
  else
    echo 0
  fi
}

# ── State 写入函数（提前定义，quick 模式也要用）────────────────────
write_state_after_check() {
  local result="$1"
  local consecutive="$2"
  local mtime_epoch="$3"
  local real_count="$4"
  local all_count="$5"

  local real_files=()
  [[ ${#REAL_CHANGED[@]} -gt 0 ]] && real_files+=("${REAL_CHANGED[@]}")
  [[ ${#REAL_ADDED[@]} -gt 0 ]] && real_files+=("${REAL_ADDED[@]}")
  local all_files=()
  [[ ${#CHANGED_FILES[@]} -gt 0 ]] && all_files+=("${CHANGED_FILES[@]}")
  [[ ${#ADDED_FILES[@]} -gt 0 ]] && all_files+=("${ADDED_FILES[@]}")

  local real_json="[]"
  if [[ ${#real_files[@]} -gt 0 ]]; then
    real_json=$(printf '%s\n' "${real_files[@]}" | python3 -c "
import sys, json
lines=[l for l in sys.stdin.read().splitlines() if l]
print(json.dumps(lines, ensure_ascii=False))
" 2>/dev/null || echo "[]")
  fi

  local all_json="[]"
  if [[ ${#all_files[@]} -gt 0 ]]; then
    all_json=$(printf '%s\n' "${all_files[@]}" | python3 -c "
import sys, json
lines=[l for l in sys.stdin.read().splitlines() if l]
print(json.dumps(lines, ensure_ascii=False))
" 2>/dev/null || echo "[]")
  fi

  local fp_json="[]"
  if [[ ${#KNOWN_FP[@]} -gt 0 ]]; then
    fp_json=$(printf '%s\n' "${KNOWN_FP[@]}" | python3 -c "
import sys, json
lines=[l for l in sys.stdin.read().splitlines() if l]
print(json.dumps(lines, ensure_ascii=False))
" 2>/dev/null || echo "[]")
  fi

  python3 -c "
import json, sys
from datetime import datetime
state = {
    'version': 1,
    'last_check_time': datetime.now().astimezone().isoformat(timespec='seconds'),
    'last_check_result': sys.argv[1],
    'last_real_diff_count': int(sys.argv[4]),
    'last_all_diff_count': int(sys.argv[5]),
    'last_real_diff_files': json.loads(sys.argv[6]),
    'last_all_diff_files': json.loads(sys.argv[7]),
    'consecutive_no_diff': int(sys.argv[2]),
    'known_false_positives': json.loads(sys.argv[8]),
    'runtime_mtime_epoch': int(sys.argv[3]),
    'hint_threshold': int(sys.argv[10]) if len(sys.argv) > 10 else 7,
}
with open(sys.argv[9], 'w') as f:
    json.dump(state, f, indent=2, ensure_ascii=False)
    f.write('\n')
" "$result" "$consecutive" "$mtime_epoch" "$real_count" "$all_count" "$real_json" "$all_json" "$fp_json" "$STATE_FILE" "$STATE_HINT_THRESHOLD"
}

# ── Quick 模式：检查 .claude/ 模板路径是否有新修改 ─────────────────
if $QUICK && $STATE_EXISTS && [[ -z "$SINGLE_FILE" ]] && ! $APPLY; then
  current_max=0
  for rel in "${TEMPLATE_PATHS[@]}"; do
    path="$RUNTIME/$rel"
    [[ -e "$path" ]] || continue
    if [[ -d "$path" ]]; then
      while IFS= read -r f; do
        m=$(get_mtime "$f")
        [[ "$m" -gt "$current_max" ]] && current_max=$m
      done < <(find "$path" -type f -not -name ".DS_Store")
    else
      m=$(get_mtime "$path")
      [[ "$m" -gt "$current_max" ]] && current_max=$m
    fi
  done

  if [[ "$current_max" -le "$STATE_RUNTIME_MTIME_EPOCH" ]]; then
    # 无修改，短路退出
    echo "━━━ pull-from-runtime (QUICK) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ 自上次检查（${STATE_LAST_CHECK:-未知}）以来 .claude/ 模板路径无修改"
    echo "  连续无差异次数: $((STATE_CONSECUTIVE_NO_DIFF + 1))"
    if [[ $((STATE_CONSECUTIVE_NO_DIFF + 1)) -ge $STATE_HINT_THRESHOLD ]]; then
      echo ""
      echo "  💡 已连续 ${STATE_HINT_THRESHOLD}+ 次无差异，建议考虑降低检查频率（如改成每周）"
    fi
    # 更新 consecutive_no_diff，写 state
    write_state_after_check "no_diff" $((STATE_CONSECUTIVE_NO_DIFF + 1)) "$STATE_RUNTIME_MTIME_EPOCH" 0 0
    exit 0
  fi
fi

MODE_LABEL="DRY-RUN（不会写入，加 --apply 实际覆盖）"
if $APPLY; then MODE_LABEL="APPLY（实际覆盖 SSOT，但不 commit）"; fi

echo "━━━ pull-from-runtime ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  模式:    $MODE_LABEL"
echo "  Runtime: $RUNTIME"
echo "  SSOT:    $TEMPLATES_DIR"
echo "  State:   $STATE_FILE ($([ ${#KNOWN_FP[@]} -gt 0 ] && echo "已知 ${#KNOWN_FP[@]} 个假阳性" || echo "无假阳性记录"))"
[[ -n "$SINGLE_FILE" ]] && echo "  过滤:    仅 $SINGLE_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 检查差异，分类到 real / false_positive ─────────────────────────
CHANGED_FILES=()
ADDED_FILES=()
REAL_CHANGED=()
REAL_ADDED=()
FP_CHANGED=()
FP_ADDED=()

is_false_positive() {
  local f="$1"
  [[ ${#KNOWN_FP[@]} -eq 0 ]] && return 1
  for fp in "${KNOWN_FP[@]}"; do
    if [[ "$f" == "$fp" ]]; then return 0; fi
  done
  return 1
}

for rel in "${TEMPLATE_PATHS[@]}"; do
  src_base="$RUNTIME/$rel"
  dst_base="$TEMPLATES_DIR/$rel"

  if [[ ! -e "$src_base" ]]; then continue; fi

  if [[ -n "$SINGLE_FILE" ]]; then
    if [[ "$rel" != "$SINGLE_FILE" && "$rel" != "$(dirname "$SINGLE_FILE")" ]]; then
      continue
    fi
  fi

  if [[ -d "$src_base" ]]; then
    while IFS= read -r -d '' f; do
      rel_path="${f#$RUNTIME/}"
      dst="$TEMPLATES_DIR/$rel_path"
      if [[ ! -f "$dst" ]]; then
        ADDED_FILES+=("$rel_path")
        if is_false_positive "$rel_path"; then FP_ADDED+=("$rel_path")
        else REAL_ADDED+=("$rel_path"); echo "  [add] $rel_path"; fi
      elif ! diff -q "$f" "$dst" >/dev/null 2>&1; then
        CHANGED_FILES+=("$rel_path")
        added=$(diff "$dst" "$f" 2>/dev/null | grep -c '^>') || added=0
        removed=$(diff "$dst" "$f" 2>/dev/null | grep -c '^<') || removed=0
        if is_false_positive "$rel_path"; then FP_CHANGED+=("$rel_path")
        else
          REAL_CHANGED+=("$rel_path")
          echo "  [mod] $rel_path  (+${added} -${removed})"
        fi
      fi
    done < <(find "$src_base" -type f -not -name ".DS_Store" -print0)
  else
    if [[ ! -f "$src_base" ]]; then continue; fi
    if [[ ! -f "$dst_base" ]]; then
      ADDED_FILES+=("$rel")
      if is_false_positive "$rel"; then FP_ADDED+=("$rel")
      else REAL_ADDED+=("$rel"); echo "  [add] $rel"; fi
    elif ! diff -q "$src_base" "$dst_base" >/dev/null 2>&1; then
      CHANGED_FILES+=("$rel")
      added=$(diff "$dst_base" "$src_base" 2>/dev/null | grep -c '^>') || added=0
      removed=$(diff "$dst_base" "$src_base" 2>/dev/null | grep -c '^<') || removed=0
      if is_false_positive "$rel"; then FP_CHANGED+=("$rel")
      else
        REAL_CHANGED+=("$rel")
        echo "  [mod] $rel  (+${added} -${removed})"
      fi
    fi
  fi
done

REAL_TOTAL=$((${#REAL_CHANGED[@]} + ${#REAL_ADDED[@]}))
ALL_TOTAL=$((${#CHANGED_FILES[@]} + ${#ADDED_FILES[@]}))
FP_TOTAL=$((${#FP_CHANGED[@]} + ${#FP_ADDED[@]}))

# 计算 runtime mtime 快照（用于下次 quick 模式）
RUNTIME_MTIME_NOW=0
for rel in "${TEMPLATE_PATHS[@]}"; do
  path="$RUNTIME/$rel"
  [[ -e "$path" ]] || continue
  if [[ -d "$path" ]]; then
    while IFS= read -r f; do
      m=$(get_mtime "$f")
      [[ "$m" -gt "$RUNTIME_MTIME_NOW" ]] && RUNTIME_MTIME_NOW=$m
    done < <(find "$path" -type f -not -name ".DS_Store")
  else
    m=$(get_mtime "$path")
    [[ "$m" -gt "$RUNTIME_MTIME_NOW" ]] && RUNTIME_MTIME_NOW=$m
  fi
done

echo ""
echo "━━━ 总结 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  真差异: $REAL_TOTAL    已知假阳性: $FP_TOTAL    总计: $ALL_TOTAL"

if [[ $FP_TOTAL -gt 0 ]]; then
  echo ""
  echo "  🟡 已知假阳性（已自动过滤，不参与回传决策）:"
  for f in "${FP_CHANGED[@]}" "${FP_ADDED[@]}"; do
    echo "    $f"
  done
fi

# 决定 result 和 consecutive
if [[ $REAL_TOTAL -eq 0 ]]; then
  RESULT="no_diff"
  CONSECUTIVE=$((STATE_CONSECUTIVE_NO_DIFF + 1))
else
  RESULT="has_diff"
  CONSECUTIVE=0
fi

# dry-run 模式：写 state 后输出建议
if ! $APPLY; then
  write_state_after_check "$RESULT" "$CONSECUTIVE" "$RUNTIME_MTIME_NOW" "$REAL_TOTAL" "$ALL_TOTAL"

  if [[ $REAL_TOTAL -eq 0 ]]; then
    echo ""
    echo "  ✓ 无真差异需回传（$FP_TOTAL 个假阳性已静默，连续 $CONSECUTIVE 次无差异）"
    if [[ $CONSECUTIVE -ge $STATE_HINT_THRESHOLD ]]; then
      echo "  💡 已连续 ${STATE_HINT_THRESHOLD}+ 次无差异，建议考虑降低检查频率（如改成每周）"
    fi
    exit 0
  fi

  echo ""
  echo "  这是 dry-run。下一步建议:"
  echo "    1. 对每个真差异文件人工 review:"
  echo "       diff \$SSOT/templates/<file> \$RUNTIME/<file>"
  echo "    2. 确认无项目特定内容/敏感信息后，运行:"
  echo "       $0 $RUNTIME --apply"
  echo "    3. 完成 apply 后，进入 SSOT 走发布流程（见 GOVERNANCE.md 第 5 节）"
  exit 0
fi

# ── APPLY 模式：实际拷贝 ───────────────────────────────────────────
echo ""
echo "  正在覆盖 SSOT（仅真差异，假阳性不会被覆盖）..."
for f in "${REAL_CHANGED[@]}" "${REAL_ADDED[@]}"; do
  src="$RUNTIME/$f"
  dst="$TEMPLATES_DIR/$f"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "    ✓ $f"
done

write_state_after_check "applied" 0 "$RUNTIME_MTIME_NOW" "$REAL_TOTAL" "$ALL_TOTAL"

echo ""
echo "━━━ 完成 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  接下来你**必须**手动做（脚本不会自动做）:"
echo ""
echo "  1. cd $SSOT_DIR"
echo "  2. git diff                              # 逐文件 review"
echo "  3. 检查是否含项目特定内容/敏感信息（人名、公司名、密钥、内部案例）"
echo "  4. 如需脱敏，手动编辑 templates/<file>"
echo "  5. 判断变更级别（MAJOR/MINOR/PATCH）→ 决定新版本号"
echo "  6. 更新 CHANGELOG.md"
echo "  7. 更新 package.json 的 version"
echo "  8. git add . && git commit -m \"release: v1.x.x\""
echo "  9. git tag v1.x.x && git push --tags && git push"
echo " 10. npm publish"
echo ""
echo "  ⚠️  跳过 review 直接 commit 是反模式（见 GOVERNANCE.md 第 7 节）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
