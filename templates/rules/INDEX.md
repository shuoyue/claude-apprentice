# Rules 触发条件索引

> 让规则可审计、可优化。每条 rule 在什么条件下触发,一目了然。

## 当前规则

| 规则文件 | 触发条件 | 规则要点 |
|---------|---------|---------|
| `coding-standards.md` | `editing any source code file` | 不引入安全漏洞、不超设计、不写多余注释、命名清晰 |
| `coding-standards.md` | `creating or modifying backend code` | Controller→Service→DAO 分层,统一响应,异常统一处理 |
| `coding-standards.md` | `creating or modifying frontend code` | PascalCase 命名,API 走 `api/` 模块,处理 loading/error/empty |
| `git-safety.md` | `running git commands or creating commits` | 不 force push、不 rm -rf、不跳 hooks、不提交密钥 |
| `superpowers-workflow.md` | `executing any workflow skill` | 没设计不写代码、没测试不写代码、没验证不说完成 |
| `superpowers-workflow.md` | `encountering a bug or test failure` | 先找根因再修,连续 3 次失败停下来审视架构 |

## 颗粒度设计

当前覆盖五个场景:
- **后端代码** — 分层、规范
- **前端代码** — 组件、API 调用
- **Git 操作** — 安全红线
- **Workflow 执行** — 开发铁律
- **调试** — 根因优先

更细的颗粒度(按语言/框架)由 `init.sh` 自动生成的技术栈专属 rules 处理:

| 技术栈 | Rule 文件 |
|--------|----------|
| Java/Spring Boot | `spring-boot.md` |
| Python/FastAPI | `python-api.md` |
| Vue | `vue-standards.md` |
| React | `react-standards.md` |
| Go | `go-standards.md` |

## 是否需要进一步细化?

| 触发场景 | 当前条件 | 评估 |
|---------|---------|------|
| 编辑代码(通用) | `editing any source code file` | ✅ 兜底通用,保持 |
| 后端代码 | `creating or modifying backend code` | ✅ 颗粒度合适 |
| 前端代码 | `creating or modifying frontend code` | ✅ 颗粒度合适 |
| Git 操作 | `running git commands or creating commits` | ✅ 颗粒度合适 |

**结论:** 当前颗粒度合适,不需要进一步细化。`editing any source code file` 是兜底通用规则,不该按语言拆(那是技术栈专属 rules 的事)。

## 维护规则

- 新增 rule 时,在 `learned-lessons.md` 记录对应的错误案例
- 删除 rule 前,确认 `learned-lessons.md` 里对应的错误已不再犯
- 触发条件改动时,同步更新本索引
- 加新 rule 前,先查 `bottleneck-navigation.md` 确认瓶颈确实在 Harness 层

## 与其他文档的关系

```
learned-lessons.md  ←  错误登记(为什么有这条 rule)
       ↓
rules/*.md          ←  规则本身(规则是什么)
       ↓
INDEX.md            ←  规则索引(什么时候触发)— 本文件
       ↓
bottleneck-navigation.md  ←  元认知(该不该加 rule)
```
