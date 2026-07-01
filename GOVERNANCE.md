# Governance — 两仓库统一与迭代流程

> 本文件定义 claude-apprentice 体系的**单一事实来源（SSOT）**、运行时实例角色、变更与发布流程。
> 任何对 templates/ 的变更都应遵循本文件。

**生效日期:** 2026-06-29
**主版本:** 体系内容 v5.8 / npm 包 1.x

---

## 1. 体系定位

本体系基于"三件套"构建：

| 件 | 角色 |
|----|------|
| Claude Code | 执行底盘（文件读写、工具调用） |
| Superpowers | 行为纪律（TDD、调试、code review） |
| Spec | 规格对齐（结构化需求文档作为共享锚点） |

核心原则：**90% 的场景用原生 Claude Code 就够了。过度工程化是最大的浪费。**

---

## 2. 两仓库角色

| 仓库 | 角色 | 触达用户 | URL |
|------|------|---------|-----|
| **claude-apprentice** | **SSOT（单一事实来源）** | 公开 | github.com/shuoyue/claude-apprentice |
| **.claude/**（任意项目内） | 运行时实例 | 单个开发者 | 本地目录 |

### 2.1 SSOT（claude-apprentice）

- 唯一可主动修改 templates/ 的仓库
- 所有内容变更先在这里合入，再流向下游
- 公开发布到 npm（`npx claude-apprentice init`）

### 2.2 .claude/（运行时实例）

- 通过 `apprentice init` 或 `apprentice update` 从 SSOT 拉取模板
- 区分两类内容：
  - **模板内容**（来自 SSOT）：rules/、skills/、commands/、specs/SPEC-GUIDE.md、workflow/、usage-guides/、scripts/、CLAUDE.md、settings.json — 这些可以随时被 `update` 覆盖
  - **运行时状态**（本地累积，**不被 SSOT 覆盖**）：MEMORY.md、memory/learned-lessons.md（项目内增量）、reports/、settings.local.json、specs/active/、specs/archived/

---

## 3. 双轨版本号

体系使用**两套独立的版本号**，分别代表不同维度，**不要混淆**：

| 版本 | 出现在 | 含义 | 节奏 |
|------|--------|------|------|
| **体系内容版本**（v5.8） | `CLAUDE.md` 顶部、`usage-guides/usage-guide-v{X.Y}.md` | 使用手册的迭代版本 | 每次有重大文档/workflow 变更时 +0.1 |
| **npm 包版本**（1.x.x） | `package.json`、`CHANGELOG.md`、git tag | 软件发布版本，遵循 SemVer | 见第 5 节 |

**示例：**
- v5.8 的内容可以打包成 npm 1.0.0 发布（首次公开发布时的状态）
- 后续小改进：内容版本到 v5.9，npm 包升到 1.1.0

---

## 4. 变更流程

### 4.1 实验 → 沉淀（日常）

```
  .claude/ (实验场)
       │
       │  ① 在具体项目里试改 rules/skills/commands
       │  ② 验证有效后，用 pull-from-runtime.sh 列出差异
       ▼
  claude-apprentice/ (SSOT)
       │
       │  ③ 人工 review 每个差异（脱敏、判断是否值得回传）
       │  ④ --apply 覆盖 templates/
       │  ⑤ 更新 usage-guide 版本号（如 v5.8 → v5.9）
       │  ⑥ 更新 CHANGELOG.md
       │  ⑦ 升 package.json 版本号
       │  ⑧ commit + push + npm publish
       ▼
  下游项目消费
       │
       │  npx claude-apprentice init    （新项目）
       │  npx claude-apprentice update  （已有项目）
```

**回传工具：**

```bash
# 在 SSOT 仓库根目录运行
./scripts/pull-from-runtime.sh /path/to/your/.claude             # dry-run，列差异
./scripts/pull-from-runtime.sh /path/to/your/.claude --quick     # 定时任务用，无修改时立即跳过
./scripts/pull-from-runtime.sh /path/to/your/.claude --apply     # 实际覆盖
./scripts/pull-from-runtime.sh /path/to/your/.claude --file rules/INDEX.md  # 只看一个文件
```

工具只覆盖**模板路径**（rules/skills/commands/workflow/usage-guides/scripts/specs.SPEC-GUIDE.md/settings.json），不会动运行时状态。

**State 文件机制（节省 token 的关键）：**

脚本在 `$RUNTIME/.sync-state.json` 维护状态，三大作用：

1. **`--quick` 短路**：定时任务（如每日 9:03 cron）先用 `--quick` 跑，无修改直接跳过 dry-run，省 90% token
2. **假阳性记忆化**：`known_false_positives` 数组里的文件不再刷屏（如历史版本 v5.2~v5.7）
3. **降频建议**：连续 7 次 no_diff 时提示降频

详见 [scripts/README.md](scripts/README.md#state-文件机制重要)。

**回传规则：**
- ✅ 可回传：通用规则、workflow、scripts、skill 模板、usage-guide
- ❌ 不可回传：项目特定业务逻辑、含真实公司/人名/数据的示例、敏感的 learned-lessons 案例（脱敏后可）
- ❌ 不可回传：历史版本归档（如 `usage-guide-v5.2.md` 这类已被新版替代的旧文件，SSOT 只保留最新版）

**重要：** 工具会列出所有差异，但**判断哪些值得回传必须靠人**。常见假阳性：
- 本地实验性的、未成熟的内容
- 项目特定的 specs（active/archived）
- 历史版本文件（v5.2~v5.7 这类）

### 4.2 运行时实例更新

在任意项目中：

```bash
# 首次接入
npx claude-apprentice init

# 模板更新（覆盖模板内容，保留运行时状态）
npx claude-apprentice update
```

如果 `update` 行为不足以覆盖本地实验污染，可手动从 SSOT 拉取单个文件覆盖。

---

## 5. npm 包版本节奏（SemVer）

| 变更类型 | SemVer | 示例 |
|---------|--------|------|
| 向后不兼容的模板结构变更 | MAJOR | 新增必填字段、目录结构重组 |
| 新增模板文件、新增 skill、usage-guide 升级 | MINOR | 新增 commands/xxx.md、v5.8 → v5.9 |
| 修复错别字、小调整、文档润色 | PATCH | 修正 README 描述、修复脚本 bug |

每次发布前必须：
1. 更新 `CHANGELOG.md`
2. 更新 `package.json` 的 `version`
3. 打 git tag（`v1.x.x`）
4. `npm publish`

---

## 6. 健康检查

任何仓库修改后，运行：

```bash
# SSOT 自检
cd claude-apprentice && bin/apprentice.js doctor

# .claude/ 运行时自检
cd your-project && .claude/scripts/health-check.sh
```

---

## 7. 反模式（不要这样做）

| 反模式 | 为什么不好 | 正确做法 |
|--------|----------|---------|
| 把 .claude/ 的实验直接 push 到 SSOT | 可能含项目特定内容或污染 | 先脱敏、提取通用部分 |
| 跳过 CHANGELOG 直接发版 | 无法追溯变更 | 每次升版本前先写 CHANGELOG |
| 混淆 v5.8 和 1.0.0 版本号 | 无法判断变更级别 | 内容版本和包版本独立维护 |
| 修改 .claude/settings.json 而非 settings.local.json | update 时会被覆盖，丢失本地插件配置 | 本地化配置放 settings.local.json |

---

## 8. 决策记录

- **2026-06-24** — 确立 claude-apprentice 为 SSOT。理由：已有 CHANGELOG、SemVer、npm 发布基础，最成熟。
- **2026-06-24** — 双轨版本号策略。理由：内容迭代（v5.x）和软件发布（1.x.x）节奏不同，强行统一会让版本号失去信息量。
- **2026-06-29** — tsc-toolkit 退出迭代流程，体系改为两仓库模型（SSOT + 运行时实例）。tsc-toolkit 物理保留作为冻结快照，不再维护。理由：双分发渠道（内网+开源）维护成本高于收益，单 SSOT + 公开 npm 即可覆盖所有用户。
