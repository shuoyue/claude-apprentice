#!/bin/bash
#
# claude-apprentice 健康巡检脚本
# 用法: .claude/scripts/health-check.sh
#
# 检查项：未归档 spec、知识库过时、CLAUDE.md 膨胀、rules 一致性、错题本、报告目录
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

WARN=0
ERR=0

warn() { echo -e "${YELLOW}[WARN]${NC} $1"; WARN=$((WARN + 1)); }
err()  { echo -e "${RED}[ERR]${NC} $1"; ERR=$((ERR + 1)); }
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# ── 跨平台日期差计算 ─────────────────────────────────────────────────
# 用法: days_since "YYYY-MM-DD"
# 输出: 距今天的天数（失败返回 -1）
days_since() {
  local date_str="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
from datetime import datetime, date
try:
    d = datetime.strptime('$date_str', '%Y-%m-%d').date()
    print((date.today() - d).days)
except Exception:
    print(-1)
" 2>/dev/null || echo -1
  elif command -v python >/dev/null 2>&1; then
    python -c "
from datetime import datetime, date
try:
    d = datetime.strptime('$date_str', '%Y-%m-%d').date()
    print((date.today() - d).days)
except Exception:
    print(-1)
" 2>/dev/null || echo -1
  elif [[ "$(uname)" == "Darwin" ]]; then
    # macOS BSD date
    local now_ts then_ts
    now_ts=$(date +%s)
    then_ts=$(date -j -f "%Y-%m-%d" "$date_str" +%s 2>/dev/null || echo 0)
    if [ "$then_ts" -gt 0 ]; then
      echo $(( (now_ts - then_ts) / 86400 ))
    else
      echo -1
    fi
  else
    # Linux GNU date
    local now_ts then_ts
    now_ts=$(date +%s)
    then_ts=$(date -d "$date_str" +%s 2>/dev/null || echo 0)
    if [ "$then_ts" -gt 0 ]; then
      echo $(( (now_ts - then_ts) / 86400 ))
    else
      echo -1
    fi
  fi
}

echo "=== claude-apprentice 健康巡检 ==="
echo ""

# ===== 1. CLAUDE.md 行数检查 =====
info "1. CLAUDE.md 膨胀检查"
if [ -f "CLAUDE.md" ]; then
    LINES=$(wc -l < CLAUDE.md)
    if [ "$LINES" -gt 80 ]; then
        warn "CLAUDE.md 当前 ${LINES} 行，超过 80 行阈值（目标 < 60 行）"
        echo "  建议：将详细内容移到子文档，CLAUDE.md 只保留目录和核心约束"
    else
        ok "CLAUDE.md ${LINES} 行，在合理范围内"
    fi
else
    err "CLAUDE.md 不存在"
fi

# ===== 2. Active Spec 积压检查 =====
info "2. Active Spec 积压检查"
if [ -d ".claude/specs/active" ]; then
    ACTIVE_COUNT=$(find .claude/specs/active -name "*.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$ACTIVE_COUNT" -gt 3 ]; then
        warn "specs/active/ 下有 ${ACTIVE_COUNT} 个未归档 spec"
        echo "  建议：已完成的 spec 应归档到 specs/archived/"
    elif [ "$ACTIVE_COUNT" -eq 0 ]; then
        ok "没有未归档的 spec"
    else
        ok "specs/active/ 下有 ${ACTIVE_COUNT} 个进行中的 spec"
    fi
else
    warn "specs/active/ 目录不存在"
fi

# ===== 3. 知识库过时检查 =====
info "3. 知识库更新时间检查"
if [ -d ".claude/memory" ]; then
    for f in architecture.md frontend-standards.md backend-standards.md business-logic.md; do
        if [ -f ".claude/memory/$f" ]; then
            LAST_UPDATE=$(grep "最后更新" ".claude/memory/$f" 2>/dev/null | head -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "unknown")
            if [ "$LAST_UPDATE" != "unknown" ] && [ "$LAST_UPDATE" != "待填写" ]; then
                DAYS_SINCE=$(days_since "$LAST_UPDATE")
                if [ "$DAYS_SINCE" -ge 0 ] && [ "$DAYS_SINCE" -gt 90 ]; then
                    warn "memory/$f 已 ${DAYS_SINCE} 天未更新（最后: $LAST_UPDATE）"
                fi
            fi
        fi
    done
    ok "知识库时间检查完成"
else
    err "memory/ 目录不存在"
fi

# ===== 4. Rules 一致性检查 =====
info "4. Rules 一致性检查"
for rule in coding-standards.md git-safety.md superpowers-workflow.md; do
    if [ ! -f ".claude/rules/$rule" ]; then
        err "缺少核心规则文件: rules/$rule"
    fi
done
ok "Rules 一致性检查完成"

# ===== 5. Superpowers 配置位置检查 =====
info "5. Superpowers 配置位置检查"
if [ -f ".claude/memory/superpowers-config.md" ]; then
    ok "superpowers-config.md 在正确位置（memory/）"
else
    warn "memory/superpowers-config.md 不存在，Superpowers 配置可能还在 CLAUDE.md 中"
    echo "  建议：将配置移到 memory/superpowers-config.md，CLAUDE.md 保持精简"
fi

# ===== 6. Spec 目录结构检查 =====
info "6. Spec 目录结构检查"
if [ -d ".claude/specs" ] && [ -f ".claude/specs/SPEC-GUIDE.md" ]; then
    ok "Spec 目录结构完整（SPEC-GUIDE.md + active/ + archived/）"
else
    warn "Spec 目录结构不完整"
    echo "  建议：确保 specs/SPEC-GUIDE.md、specs/active/、specs/archived/ 都存在"
fi

# ===== 7. 错误积累检查 =====
info "7. 错误积累机制检查"
if [ -f ".claude/memory/learned-lessons.md" ]; then
    LESSON_COUNT=$(grep -c "^### L-" ".claude/memory/learned-lessons.md" 2>/dev/null || echo 0)
    ok "learned-lessons.md 存在，已积累 ${LESSON_COUNT} 条教训"
else
    warn "learned-lessons.md 不存在"
    echo "  建议：创建 memory/learned-lessons.md 记录 AI 常犯错误和规避规则"
fi

# ===== 8. Reports 目录检查 =====
info "8. Reports 输出目录检查"
if [ -d ".claude/reports" ]; then
    REPORT_COUNT=$(find .claude/reports -name "*.md" -o -name "*.xlsx" 2>/dev/null | wc -l | tr -d ' ')
    ok "reports/ 目录存在，已有 ${REPORT_COUNT} 份报告"
else
    warn "reports/ 目录不存在"
    echo "  建议：运行 init.sh 补全，或手动 mkdir -p .claude/reports"
fi

# ===== 9. 流程定义文件检查 =====
info "9. 流程定义文件检查"
if [ -f ".claude/workflow/WORKFLOW-GUIDE.md" ]; then
    ok "workflow/WORKFLOW-GUIDE.md 存在"
else
    warn "缺少 workflow/WORKFLOW-GUIDE.md"
    echo "  建议：运行 init.sh 补全，或手动创建流程定义文件"
fi

# ===== 汇总 =====
echo ""
echo "========================================"
if [ "$ERR" -gt 0 ]; then
    echo -e "${RED}发现 ${ERR} 个错误，${WARN} 个警告${NC}"
elif [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}发现 ${WARN} 个警告，0 个错误${NC}"
else
    echo -e "${GREEN}所有检查通过！体系健康状态良好。${NC}"
fi
echo "========================================"
