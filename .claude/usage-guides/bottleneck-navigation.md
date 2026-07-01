# 瓶颈定位指南

> AI 效果不好时,先判断瓶颈在哪一层,不要一上来就加 rule。

## 四层瓶颈模型

源自业界共识:每当模型变强,系统瓶颈就往外移一层。从模型的输入往外,依次是:

| 层次 | 瓶颈在哪 | 解决什么 | 我们体系的对应物 |
|------|---------|---------|----------------|
| **Prompt** | 你怎么说 | 意图表达 | `rules/*.md` 自动注入约束 + CLAUDE.md |
| **Context** | 你给什么 | 信息供给 | `memory/` + `specs/` + 复杂度分级控制喂量 |
| **Harness** | 模型外的环境 | 工程化纠错 | `scripts/` 验证 + workflow 强制 + `learned-lessons.md` 闭环 |
| **Loop** | 你本人 | 自动驱动循环 | `/loop` skill + `commands/scan-todos.md`(试点) |

四层是**层层包含**关系:Prompt ⊂ Context ⊂ Harness ⊂ Loop。不是替代,是叠加。

公式:`Agent = 模型 + Harness`。模型决定上限,Harness 决定落地。

## 排查顺序(从内到外)

效果不好时,按这个顺序排查,不要跳步:

### Step 1: Prompt 层 — 意图是否清楚?

**症状:** AI 完全跑偏,做的事跟你想的不是一件事

**自查:**
- 任务描述有没有明确"做什么 + 改哪里 + 输出什么"
- 约束(边界、格式、保留什么)说清楚了吗
- 同一件事换个说法会不会效果更好

**修复方向:** 改 prompt,或在 `rules/` 加更明确的约束

### Step 2: Context 层 — 信息是否齐全?

**症状:** AI 理解任务,但做出来跟项目其他地方冲突,或重复造轮子

**自查:**
- 相关的 spec 文档给到了吗
- memory 里的架构、规范引用了吗
- 上下文是不是太长导致 context rot(超过 40% 后质量下降)

**修复方向:**
- 信息不够 → 补 spec、引用 memory
- 信息太杂 → 拆任务、主动开新对话

### Step 3: Harness 层 — 环境是否防错?

**症状:** AI 老犯同样的错,每次都得手动纠正

**自查:**
- 这个错以前犯过吗(查 `learned-lessons.md`)
- 有对应的 rule 吗?rule 触发了吗
- 验证脚本能不能拦住

**修复方向:**
- 犯过但没记 → 写进 `learned-lessons.md`
- 记了但没 rule → 加 rule 到 `rules/`
- 有 rule 但没拦住 → 考虑迁移到 `settings.json` hooks(确定性拦截)

### Step 4: Loop 层 — 是不是该自动化?

**症状:** 同一类任务反复手动驱动,耗时费力

**自查:**
- 这个任务有固定模式吗
- 能不能让 AI 自己定时跑
- 输入输出能不能标准化

**修复方向:**
- 写成 slash command(如 `commands/scan-todos.md`)
- 用 `/loop` skill 配定时
- 配 hook 自动触发

## 常见误判

| 误判 | 实际情况 |
|------|---------|
| "AI 太笨了" | 多数是 Context 没给够,不是模型问题 |
| "加条 rule 就好了" | Rule 是 Harness 层,如果瓶颈在 Context,加 rule 没用 |
| "这个任务做不了" | 可能只是没拆细,每个子任务在干净上下文里做 |
| "这套体系没用" | 多数是用了错的层 — 简单任务用了完整 workflow,复杂任务只用了原生 |

## 真实排查案例

以下三个案例分别对应 Prompt / Context / Harness 三层,全部来自本体系的真实场景。

### 案例 1:Prompt 层 — 同件事换个说法,效果差 10 倍

**现象:** 让 AI"加搜索功能",它给网页加了搜索框;但实际需求是给 API 加搜索参数

**误判:** 以为模型理解能力差,反复强调"按需求做"

**实际瓶颈:** Prompt — 任务描述模糊,"搜索功能"有歧义(可指 UI,也可指 API)

**修复:** 改成"给 `/api/users` 加 `keyword` 参数,支持按姓名/邮箱模糊搜索,返回分页结果" → AI 一次就做对

**教训:** Prompt 没说清之前,别急着上更重的工具。先问自己:换个说法会不会更好?

---

### 案例 2:Context 层 — CLAUDE.md 膨胀让 AI "不守规矩"

**现象:** AI 有时守规矩有时不守,行为不稳定。同一个项目,同一个任务,每次结果不一样

**误判:** 以为规则不够严,不断往 CLAUDE.md 加更多约束(53 → 108 行),结果**更糟**

**实际瓶颈:** Context — 文件太长导致 context rot,AI 在大量规则中抓不住重点,反而忽略关键约束

**修复:** 精简 CLAUDE.md(108 → 53 行,目录式),详细内容移到 `rules/` 和 `memory/` 按需加载。AI 行为立刻稳定

**教训:** "AI 不守规矩"多数是 Context 没给准(给得太多反而抓不住),不是规则不够严。**加 rule 前,先想想是不是该删 rule。**

---

### 案例 3:Harness 层 — `/scan-todos` 自指噪声

**现象:** 跑 `/scan-todos` 扫到 12 条匹配,全是命令文档自身的 `TODO`/`FIXME` 字样,真实待办 = 0

**误判:** 一度以为项目代码太干净,或扫描范围错了

**实际瓶颈:** Harness — 命令设计有缺陷,没排除命令文档所在目录(`.claude/commands/`、`.claude/usage-guides/`),扫描器扫到了自己头上

**修复(三步闭环):**
1. **沉淀 lesson** — 在 `learned-lessons.md` 新建"Loop 层错误"分类,加 L-008
2. **改进环境** — `scan-todos.md` 升级到 v2:排除目录 + 自指过滤规则 + 情况 A/B 双模板
3. **同步索引** — `usage-guide-v5.8.md` 11.1 表格加 L-008 行

**教训:** Loop 层试点跑一次就暴露工程问题 — 这正是 Loop 的价值,不是失败。跑试点踩坑 → 沉淀 lesson → 改进环境,这就是 Mitchell Hashimoto 的复利思维。**这种坑只发生一次,下次结构上就不可能再犯。**

---

## 复杂度分级 × 四层对照

| 级别 | Prompt | Context | Harness | Loop |
|------|--------|---------|---------|------|
| 简单 | ✅ 基础描述 | ✅ 当前文件 | ⚙️ rules 自动触发 | ❌ 不需要 |
| 中等 | ✅ 完整描述 | ✅ + 相关 spec + memory | ⚙️ + 验证脚本 + learned-lessons | ❌ 通常不需要 |
| 复杂 | ✅ 完整描述 | ✅ + 全量 spec | ⚙️ + 完整 workflow + worktree | ✅ 探索试点 |

## 参考

- [Prompt/Context/Harness/Loop 原文](https://mp.weixin.qq.com/s/eeB14yOtDU6akQUp0Mkauw)
- `.claude/memory/learned-lessons.md` — 错误登记册
- `.claude/rules/INDEX.md` — Rules 触发条件索引
