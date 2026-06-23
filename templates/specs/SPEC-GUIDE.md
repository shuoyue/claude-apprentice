# Spec 规格驱动开发指南

## 核心理念

**规格是唯一的真相来源。** AI 每次从 spec 文件读约束，不靠聊天记录。

## 目录结构

```
specs/
├── SPEC-GUIDE.md          # 本指南
├── active/                # 进行中的 spec（当前任务约束）
│   └── [feature-name].md  # 每个功能一个文件
└── archived/              # 已完成的 spec（历史记录）
    └── [feature-name].md  # 归档后只读，不修改
```

## 生命周期

```
Propose（提案）→ Apply（实施）→ Archive（归档）
```

### Propose：生成规格草案

触发条件：中等+复杂任务进入 workflow 步骤 1（需求澄清）时。

产出：在 `specs/active/` 下创建 spec 文件，包含：

```markdown
# [功能名称] 规格

## 状态
Proposed | Applied | Completed

## 需求概述
[一句话描述做什么]

## 涉及文件
- 新增：[文件路径列表]
- 修改：[文件路径列表]

## 接口定义（如涉及 API）
- 路径、方法、请求参数、响应格式

## 数据模型变更（如涉及数据库）
- 表名、字段、索引

## 约束条件
- [硬性约束列表]

## 验收标准
- [ ] 标准 1
- [ ] 标准 2

## 变更记录
| 日期 | 变更内容 |
|------|---------|
| YYYY-MM-DD | 初始提案 |
```

### Apply：锁定规格，开始实施

- 用户确认 spec 后，状态改为 `Applied`
- 后续所有 AI Session 从这个文件读约束
- 实施过程中的设计变更必须同步更新 spec 的变更记录

### Archive：归档完成

- 任务完成 + 验证通过后，状态改为 `Completed`
- 将 spec 从 `active/` 移到 `archived/`
- 归档的 spec 作为活文档，新人可以快速理解决策背景

## Delta Spec 原则

不重写整个文档，只记录增量变更。每次修改追加到"变更记录"表。

## 何时写 Spec

| 复杂度 | 是否写 Spec | 说明 |
|--------|------------|------|
| 简单 | 否 | 直接做 |
| 中等 | 是 | 写简要 spec，确认后实施 |
| 复杂 | 是 | 写完整 spec，含接口定义和数据模型 |

## Spec 与 Workflow 的关系

```
workflow 步骤 1（需求澄清）
  → 产出 specs/active/[feature].md（Propose）
  → 用户确认

workflow 步骤 3+（实施）
  → 读取 spec 文件作为约束
  → 设计变更同步更新 spec

workflow 步骤 5（验证/收尾）
  → spec 移入 specs/archived/（Archive）
```
