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
