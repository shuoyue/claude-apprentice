# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Team collaboration features (shared spec workspace)
- Cursor native support
- Web UI generator (configure .claude/ visually)

---

## [1.2.0] — 2026-07-09

### Added — 会话交接协议（切会话连续性）

复杂项目不在一个会话干完，编排 context 必然撑爆（L-004）。新增 CURRENT.md 快照机制：每阶段 `/handoff` 落盘当前状态，新会话 SessionStart hook 自动注入，保证切会话后连续接上。

- **`templates/CURRENT.md`**（新增）— 任务级交接快照模板（任务/进度/环境/关键决策/下一步/红线）
- **`templates/commands/handoff.md` + `handoff-auto.md`**（新增）— `/handoff` 写快照、`/handoff-auto` 条件提醒
- **`templates/scripts/handoff-context-check.sh`**（新增）— UserPromptSubmit hook，检测 context 用量提醒交接
- **`templates/settings.json`** — 三 hook：SessionStart 注入 CURRENT.md / PreCompact 压缩前提醒 / UserPromptSubmit context 检查
- **`templates/workflow/WORKFLOW-GUIDE.md`** — 新增「会话交接协议」节与四文件重建 SOP
- **`templates/CLAUDE.md`** — 文档地图加 CURRENT.md 行
- **`templates/memory/learned-lessons.md`** — L-009（编排 context 必爆，靠落盘重建而非记忆）

### Added — sync state 可配置化

- **`scripts/pull-from-runtime.sh`** — 新增 `hint_threshold` state 字段（默认 7），降频提示阈值可配置；想静默设 999
- **`scripts/README.md` / `GOVERNANCE.md`** — 文档化 state 字段

### Changed — 版本升级

- 内容版本 v5.8 → **v5.9**（usage-guide 同步改名 v5.9）
- npm 包版本 1.1.2 → **1.2.0**（MINOR：新增模板/hooks/命令）
- 修正 SSOT `templates/CLAUDE.md` 误标 v1.0 的双轨版本号 bug（应为内容版本 v5.9，见 GOVERNANCE §3）

---

## [1.1.2] — 2026-07-01

### Fixed — Network Fallback Doc

First-day real-user feedback from mainland China: the curl one-liner in README failed with `SSL: no alternative certificate subject name matches target host name 'raw.githubusercontent.com'`. Root cause: GFW DNS poisoning + macOS curl using LibreSSL 3.3 with an incomplete CA bundle — curl intermittently resolves to a poisoned IP and cannot validate the cert.

- **`README.md`** — Added a blockquote under the curl install command listing two fallback options when SSL fails:
  - **A. npx** (recommended, goes through npm protocol instead of HTTPS curl)
  - **B. git clone** (git uses its own SSL implementation, more tolerant than curl)

> Deliberately omitted `curl -k` (skip cert verification) — that's a security risk in untrusted network environments.

---

## [1.1.1] — 2026-07-01

### Fixed — Install UX

First-day real-user feedback: `apprentice init` succeeded but `apprentice doctor` returned `command not found`. Root cause: README recommended `npx claude-apprentice init`, but npx does not register a global `apprentice` command, and the "next step" hint told users to run `apprentice doctor` directly.

- **`bin/apprentice.js`** — Rewrote the "next step" hint at the end of `init` to show both options:
  - `npx claude-apprentice doctor` (recommended, no install)
  - `apprentice doctor` (requires `npm install -g claude-apprentice`)
- **`install.sh`** — Same fix applied to the curl-based installer's completion message.
- **`README.md`** — "CLI commands" section now explicitly shows two usage modes (npx vs global install) instead of just `apprentice <cmd>`.

---

## [1.1.0] — 2026-06-29

### Added — Governance
- **SSOT governance doc** (`GOVERNANCE.md`)
  - Defines single source of truth (claude-apprentice) and runtime instance role (.claude/)
  - Dual versioning policy: content version (v5.x) vs npm package version (1.x.x)
  - Change flow: experiment → consolidate → publish → consume
  - Anti-patterns and decision log

### Changed
- Simplified to two-repository model (SSOT + runtime instance); tsc-toolkit frozen as snapshot, no longer maintained

---

## [1.0.0] — 2026-06-22

First public release. Open-sourced from internal v5.7.

### Added — Core Workflow
- **Spec-driven development** (`commands/spec.md`)
  - Lifecycle: PROPOSE → APPLY → SHIP → ARCHIVE
  - Template with `Why`, `Scope`, `API`, `Acceptance Criteria`, `Risks`
  - Delta spec support for incremental changes
- **6-phase workflow** (`workflow/WORKFLOW-GUIDE.md`)
  - Brainstorm → Plan → TDD → Validate → Self-Review → Hand-off
  - Specialized entry points: `/frontend`, `/backend`, `/fullstack`
- **6-dimension code review** (`skills/code-review/`)
  - Security (18), Correctness (5), Performance (4), Design (4), Maintainability (6), Convention (3)
  - Severity levels: CRITICAL / HIGH / MEDIUM / LOW
  - Markdown + Excel export

### Added — Memory System
- **Error-driven knowledge base** (`memory/learned-lessons.md`)
  - Format: Symptom / Root cause / Rule
  - 8 seed lessons (L-001 ~ L-008)
- **Project memory** (`memory/architecture.md`)
  - System map, invariants, critical paths, conventions, gotchas

### Added — Discipline Layer
- **Coding standards** (`rules/coding-standards.md`)
  - Universal, type safety, function hygiene, file hygiene, testing, git
- **Git safety** (`rules/git-safety.md`)
  - Forbidden destructive ops (force push, hard reset, branch -D)
  - Branch naming, commit message format, pre-commit hook rules

### Added — Tooling
- **CLI** (`bin/apprentice.js`)
  - `init`, `update`, `doctor`, `version`, `help`
  - Zero-dependency (Node >= 14)
  - Auto project type detection (Java/Node/Go/Python/Rust/Generic)
- **One-line installer** (`install.sh`)
  - `curl | bash` workflow
  - Git clone preferred, curl fallback
  - Auto-backup existing `.claude/`
- **Health check** (`scripts/health-check.sh`)
  - Standalone — runs anywhere without Node

### Added — Documentation
- **README.md** — full feature overview with quick start
- **LICENSE** — MIT
- **CHANGELOG.md** — this file
- **CONTRIBUTING.md** — contribution guidelines (TODO)

### Migration
Project is a clean-slate open-source version of an internal tool (`tsc-toolkit`) that was iterated through v5.2 → v5.7. All proprietary/company-specific references have been removed.

### Lessons Carried Over
8 seed lessons (L-001 ~ L-008) distilled from ~50 hours of real-world Claude Code usage across Java Spring, Vue/React frontend, and Node.js backend projects.

---

## Version History (Pre-open-source)

These versions were internal and not publicly released. Documented here for context.

### v5.7 (internal, 2026-06-10)
- Refined workflow phases
- Added 6-dimension code review (was 5)
- Fixed: spec drift problem (specs going stale)

### v5.6 (internal, 2026-05-22)
- Added project type auto-detection
- Added multi-project workspace support
- Added health check command

### v5.5 (internal, 2026-05-01)
- Refactored `learned-lessons.md` format
- Added L-005 ~ L-007
- Added git safety rules

### v5.4 (internal, 2026-04-12)
- Added spec-driven development lifecycle
- Added delta spec support

### v5.3 (internal, 2026-03-20)
- Compressed CLAUDE.md from 200+ lines to 53 lines
- Moved knowledge to memory/

### v5.2 (internal, 2026-03-01)
- Initial 4-layer architecture (CLAUDE.md + commands + rules + skills)

### Pre-v5.2
- Chaos. No structure. AI freelanced constantly. Many late nights.

---

[Unreleased]: https://github.com/shuoyue/claude-apprentice/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/shuoyue/claude-apprentice/releases/tag/v1.0.0
