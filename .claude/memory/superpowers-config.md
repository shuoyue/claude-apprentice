# Superpowers 配置

## 启用状态

| 阶段 | Skill | 状态 | 说明 |
|------|-------|------|------|
| 入口 | using-superpowers | 始终启用 | 自动判断走哪条流程 |
| 设计 | brainstorming | 条件启用 | 中等以上复杂度触发 |
| 规划 | writing-plans | 条件启用 | 复杂任务触发 |
| 隔离 | using-git-worktrees | 条件启用 | 复杂任务触发 |
| 执行 | subagent-driven-development | 条件启用 | 复杂任务触发 |
| 测试 | test-driven-development | 条件启用 | 中等以上复杂度触发 |
| 调试 | systematic-debugging | 始终启用 | 遇到 bug 自动触发 |
| 审查 | requesting/receiving-code-review | 条件启用 | 复杂任务触发 |
| 验证 | verification-before-completion | 始终启用 | 完成前必须验证 |
| 收尾 | finishing-a-development-branch | 条件启用 | 中等以上触发 |

## JSON 配置块

<!-- superpowers-config
{
  "enabled": [
    "verification-before-completion",
    "systematic-debugging"
  ],
  "disabled": [],
  "conditional": {
    "brainstorming": "complexity >= medium",
    "writing-plans": "complexity >= complex",
    "test-driven-development": "complexity >= medium",
    "using-git-worktrees": "complexity >= complex",
    "subagent-driven-development": "complexity >= complex",
    "requesting-code-review": "complexity >= complex",
    "receiving-code-review": "complexity >= complex",
    "finishing-a-development-branch": "complexity >= medium",
    "dispatching-parallel-agents": "manual"
  },
  "complexity": {
    "simple": "单文件修改、样式调整、文案修改（< 30 分钟）",
    "medium": "新组件、新接口、多文件变更（30 分钟 - 2 小时）",
    "complex": "新功能模块、跨前后端、多表多接口（> 2 小时）"
  }
}
-->

> 修改配置：编辑上方 JSON 注释块。workflow skills 执行时会读取此文件。
