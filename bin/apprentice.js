#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PKG = require('../package.json');
const TEMPLATES_DIR = path.join(__dirname, '..', 'templates');

// ── Helpers ──────────────────────────────────────────────────────────

function log(msg) { console.log(`  ${msg}`); }
function ok(msg) { console.log(`\x1b[32m  ✓\x1b[0m ${msg}`); }
function warn(msg) { console.log(`\x1b[33m  ⚠\x1b[0m ${msg}`); }
function err(msg) { console.error(`\x1b[31m  ✗\x1b[0m ${msg}`); }

function copyDir(src, dest) {
  if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src)) {
    if (entry === '.DS_Store') continue;
    const srcPath = path.join(src, entry);
    const destPath = path.join(dest, entry);
    if (fs.statSync(srcPath).isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      if (!fs.existsSync(destPath)) {
        fs.copyFileSync(srcPath, destPath);
      }
    }
  }
}

function getTargetDir() {
  return process.cwd();
}

// ── Commands ─────────────────────────────────────────────────────────

function cmdInit(args) {
  const target = getTargetDir();
  const claudeDir = path.join(target, '.claude');

  log(`目标目录: ${target}`);
  log('');

  // 1. 复制模板文件到 .claude/（增量：已有文件不覆盖）
  ok('复制模板文件...');
  copyDir(TEMPLATES_DIR, claudeDir);

  // 2. 复制 CLAUDE.md 到项目根目录
  const rootClaude = path.join(TEMPLATES_DIR, 'CLAUDE.md');
  const targetClaude = path.join(target, 'CLAUDE.md');
  if (fs.existsSync(rootClaude) && !fs.existsSync(targetClaude)) {
    fs.copyFileSync(rootClaude, targetClaude);
    ok('创建 CLAUDE.md');
  } else if (fs.existsSync(targetClaude)) {
    warn('CLAUDE.md 已存在，跳过');
  }

  // 3. 创建 reports 目录
  const reportsDir = path.join(claudeDir, 'reports');
  if (!fs.existsSync(reportsDir)) {
    fs.mkdirSync(reportsDir, { recursive: true });
    ok('创建 reports/ 目录');
  }

  // 4. 执行 init.sh
  const initSh = path.join(claudeDir, 'scripts', 'init.sh');
  if (fs.existsSync(initSh)) {
    log('');
    ok('执行 init.sh ...');
    log('');
    try {
      execSync(`bash "${initSh}"`, { cwd: target, stdio: 'inherit' });
    } catch (e) {
      warn('init.sh 执行中出现警告（可忽略）');
    }
  }

  log('');
  ok('初始化完成！');
  log('');
  log('下一步:');
  log('  1. 检查 CLAUDE.md 中的技术栈信息');
  log('  2. 补充 .claude/memory/business-logic.md');
  log('  3. 运行健康检查（任选其一）:');
  log('');
  log('     npx claude-apprentice doctor    # 推荐，免安装');
  log('     apprentice doctor               # 需先 npm install -g claude-apprentice');
}

function cmdUpdate() {
  const target = getTargetDir();
  const claudeDir = path.join(target, '.claude');

  if (!fs.existsSync(claudeDir)) {
    err('.claude/ 目录不存在，请先运行 apprentice init');
    process.exit(1);
  }

  log('增量更新...');
  copyDir(TEMPLATES_DIR, claudeDir);

  const initSh = path.join(claudeDir, 'scripts', 'init.sh');
  if (fs.existsSync(initSh)) {
    log('');
    try {
      execSync(`bash "${initSh}"`, { cwd: target, stdio: 'inherit' });
    } catch (e) {
      warn('init.sh 执行中出现警告（可忽略）');
    }
  }

  log('');
  ok('更新完成！');
}

function cmdDoctor() {
  const target = getTargetDir();
  const checkSh = path.join(target, '.claude', 'scripts', 'health-check.sh');

  if (!fs.existsSync(checkSh)) {
    err('.claude/scripts/health-check.sh 不存在，请先运行 apprentice init');
    process.exit(1);
  }

  log('运行健康检查...');
  log('');
  try {
    execSync(`bash "${checkSh}"`, { cwd: target, stdio: 'inherit' });
  } catch (e) {
    // health-check.sh may exit with non-zero on failures
  }
}

function cmdVersion() {
  console.log(`claude-apprentice v${PKG.version}`);
}

function cmdHelp() {
  console.log(`
\x1b[1mclaude-apprentice\x1b[0m v${PKG.version} — Train Claude Code into a reliable apprentice

\x1b[1m用法:\x1b[0m
  apprentice <command> [options]

\x1b[1m命令:\x1b[0m
  init                初始化当前项目（复制模板 + 运行 init.sh）
  update              增量更新（不覆盖已有文件）
  doctor              运行健康检查
  version             显示版本号
  help                显示帮助信息

\x1b[1m使用方式:\x1b[0m
  # npx 直接运行（推荐）
  npx claude-apprentice init

  # curl 一键安装（非 Node.js 用户）
  curl -fsSL https://raw.githubusercontent.com/shuoyue/claude-apprentice/main/install.sh | bash

  # 本地开发
  node bin/apprentice.js init

\x1b[1m文档:\x1b[0m
  https://github.com/shuoyue/claude-apprentice
`);
}

// ── Main ─────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const command = args[0];

switch (command) {
  case 'init':
    cmdInit(args.slice(1));
    break;
  case 'update':
    cmdUpdate();
    break;
  case 'doctor':
    cmdDoctor();
    break;
  case 'version':
  case '-v':
  case '--version':
    cmdVersion();
    break;
  case 'help':
  case '-h':
  case '--help':
  case undefined:
    cmdHelp();
    break;
  default:
    err(`未知命令: ${command}`);
    console.log('运行 apprentice help 查看可用命令');
    process.exit(1);
}
