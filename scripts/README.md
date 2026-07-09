# scripts/

SSOT 维护脚本（给**体系维护者**用，不是终端用户的工具）。

终端用户的工具是 `bin/apprentice.js`（CLI），与本目录无关。

---

## 脚本清单

### `pull-from-runtime.sh`

**用途：** 从运行时实例 `.claude/` 把模板内容回传到 SSOT `templates/`。这是 `.claude/ → SSOT` 方向的同步工具，与 `apprentice update`（SSOT → .claude/）方向相反。

**用法：**

```bash
# 1. dry-run（默认），列出差异
./scripts/pull-from-runtime.sh /path/to/your/.claude

# 2. quick 模式（推荐用于定时任务），无修改时立即跳过
./scripts/pull-from-runtime.sh /path/to/your/.claude --quick

# 3. 只看某个文件
./scripts/pull-from-runtime.sh /path/to/your/.claude --file rules/INDEX.md

# 4. 实际覆盖（不会自动 commit）
./scripts/pull-from-runtime.sh /path/to/your/.claude --apply

# 5. 自定义 state 文件路径
./scripts/pull-from-runtime.sh /path/to/your/.claude --state-file /custom/path.json
```

**行为：**

- 默认 dry-run，必须 `--apply` 才写入
- 只覆盖**模板路径**：`rules/`、`skills/`、`commands/`、`workflow/`、`usage-guides/`、`scripts/*`、`settings.json`、`specs/SPEC-GUIDE.md`
- 不动运行时状态：`MEMORY.md`、`memory/learned-lessons.md`（增量）、`reports/`、`settings.local.json`、`specs/active/`、`specs/archived/`
- `--apply` 后输出 10 步发布 checklist，但**不会自动执行**
- `--apply` 时**只覆盖真差异**，假阳性不会被覆盖

### State 文件机制（重要）

脚本默认在 `$RUNTIME/.sync-state.json` 维护状态文件，包含：

```json
{
  "last_check_time": "2026-06-30T09:03:00+08:00",
  "last_check_result": "no_diff",
  "last_real_diff_count": 0,
  "last_real_diff_files": [],
  "consecutive_no_diff": 5,
  "known_false_positives": ["usage-guides/usage-guide-v5.2.md", ...],
  "runtime_mtime_epoch": 1782349323,
  "hint_threshold": 7
}
```

**三大作用：**

1. **`--quick` 短路**：定时任务先用 `--quick` 跑，扫描 `.claude/` 模板路径的最新 mtime，与 state 中的 `runtime_mtime_epoch` 比较，无修改直接跳过完整 dry-run，**省 90% token**
2. **假阳性记忆化**：`known_false_positives` 数组中的文件，下次扫描时自动归类为"假阳性"，不再计入"真差异"，避免噪音刷屏（如 `usage-guide-v5.2~v5.7.md` 历史版本）
3. **降频建议**：`consecutive_no_diff` ≥ `hint_threshold`（默认 7）时，提示用户考虑降低检查频率

**手动编辑 state**：

- **假阳性名单**：如果某文件被错误归类为假阳性，或想把新发现的假阳性加入静默名单，直接编辑 `known_false_positives` 数组
- **降频阈值**：调整 `hint_threshold`（默认 `7`）。如果已切换到较低频节奏（如每周），可以调低（如 `4`）让提示更早出现；如果想让它闭嘴，设成 `999`

**重要约束：**

- 工具会列出所有差异，但**判断哪些值得回传必须靠人**
- 常见假阳性（首次出现时手动加入 state）：
  - 历史版本归档（如 `usage-guide-v5.2.md ~ v5.7.md`，SSOT 只保留最新版）
  - 含真实人名/公司名/密钥的示例（要脱敏）
  - 项目特定的 specs 和 learned-lessons 案例

**关联文档：** [GOVERNANCE.md 第 4.1 节](../GOVERNANCE.md#41-实验--沉淀日常)

---

## 维护约定

- 新增脚本必须更新本 README
- 所有脚本必须支持 `--help` 和 dry-run（默认不写入）
- 涉及跨仓库操作的脚本，必须打印"下一步 checklist"而不是自动执行
