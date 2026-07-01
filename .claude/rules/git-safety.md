<important if="running git commands or creating commits">
Git 安全规则：

- 不执行 `git push --force`
- 不执行 `rm -rf`
- 不跳过 hooks（不使用 --no-verify）
- 创建新 commit 而非 amend（除非明确要求）
- 不提交含密钥的文件（.env、credentials 等）
</important>
