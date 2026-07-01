#!/usr/bin/env bash
set -euo pipefail

# ── claude-apprentice 一键安装脚本 ────────────────────────────────────
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/shuoyue/claude-apprentice/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/shuoyue/claude-apprentice/main/install.sh | bash -s -- v1.0.0
# ─────────────────────────────────────────────────────────────────────

VERSION="${1:-latest}"
TARGET="$(pwd)"
REPO_RAW="https://raw.githubusercontent.com/shuoyue/claude-apprentice"
REPO_GIT="https://github.com/shuoyue/claude-apprentice.git"
BRANCH="main"

if [ "$VERSION" != "latest" ]; then
  BRANCH="$VERSION"
fi

echo ""
echo "  claude-apprentice Installer"
echo "  版本: $VERSION"
echo "  目标: $TARGET"
echo ""

# ── 检查依赖 ──────────────────────────────────────────────────────────

command -v curl >/dev/null 2>&1 || { echo "  ✗ 需要 curl"; exit 1; }

# ── 下载模板文件 ──────────────────────────────────────────────────────

CLAUDE_DIR="$TARGET/.claude"

echo "  下载模板文件..."

# 方法: 用 git clone（如果可用）或 curl 逐个下载
if command -v git >/dev/null 2>&1; then
  TMP_DIR=$(mktemp -d)
  git clone --depth 1 --branch "$BRANCH" \
    "$REPO_GIT" "$TMP_DIR" 2>/dev/null || {
    echo "  ✗ 克隆失败，请检查仓库地址和版本号"
    rm -rf "$TMP_DIR"
    exit 1
  }

  # 复制 templates/ 到 .claude/（已有文件不覆盖）
  if [ -d "$TMP_DIR/templates" ]; then
    mkdir -p "$CLAUDE_DIR"
    # 用 cp -n（不覆盖）复制文件
    cp -rn "$TMP_DIR/templates/"* "$CLAUDE_DIR/" 2>/dev/null || true
    cp -rn "$TMP_DIR/templates/."* "$CLAUDE_DIR/" 2>/dev/null || true

    # 复制 CLAUDE.md 到项目根目录
    if [ -f "$TMP_DIR/templates/CLAUDE.md" ] && [ ! -f "$TARGET/CLAUDE.md" ]; then
      cp "$TMP_DIR/templates/CLAUDE.md" "$TARGET/CLAUDE.md"
    fi
  fi

  rm -rf "$TMP_DIR"

else
  echo "  ✗ 需要 git 来下载模板文件"
  echo "  请安装 git 或使用 npx 方式: npx claude-apprentice init"
  exit 1
fi

# ── 创建必要目录 ──────────────────────────────────────────────────────

mkdir -p "$CLAUDE_DIR/reports"

# ── 运行 init.sh ─────────────────────────────────────────────────────

INIT_SH="$CLAUDE_DIR/scripts/init.sh"
if [ -f "$INIT_SH" ]; then
  echo ""
  echo "  执行 init.sh ..."
  echo ""
  bash "$INIT_SH" || true
fi

# ── 完成 ──────────────────────────────────────────────────────────────

echo ""
echo "  ✓ 安装完成！"
echo ""
echo "  下一步:"
echo "    1. 检查 CLAUDE.md 中的技术栈信息"
echo "    2. 补充 .claude/memory/business-logic.md"
echo "    3. 运行健康检查（任选其一）:"
echo ""
echo "       npx claude-apprentice doctor    # 推荐，免安装"
echo "       apprentice doctor               # 需先 npm install -g claude-apprentice"
echo ""
echo "  文档: https://github.com/shuoyue/claude-apprentice"
echo ""
