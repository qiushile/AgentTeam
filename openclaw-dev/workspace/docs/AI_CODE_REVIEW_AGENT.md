# AI 代码审查 Agent 原型

## 1. 概述

基于 LLM 的自动化代码审查工具，集成到 CI/CD 流程中。

## 2. 架构设计

```
Pull Request → Webhook → Code Review Agent → 审查报告 → PR 评论
                           ↓
                    LLM API (通义千问/GPT-4)
```

## 3. 实现方案

### 3.1 触发机制
- GitHub Pull Request webhook
- 当 PR 创建或更新时触发

### 3.2 代码提取
```bash
# 获取 PR 变更
gh pr view <number> --json files
gh pr diff <number>
```

### 3.3 审查 Prompt
```
你是一位资深代码审查员。请审查以下代码变更:

文件: ${filename}
变更:
\`\`\`${language}
${diff}
\`\`\`

审查维度:
1. **安全性**: SQL注入、XSS、CSRF、敏感数据泄露、不安全依赖
2. **性能**: N+1查询、内存泄漏、不必要的计算、缺少缓存
3. **可维护性**: 命名规范、函数长度、重复代码、注释质量
4. **最佳实践**: 错误处理、类型安全、API设计

输出格式:
- 问题级别: 🔴 Critical / 🟡 Warning / ℹ️ Info
- 文件行号
- 问题描述
- 修复建议 (含代码示例)
```

### 3.4 结果处理
```javascript
// 解析 LLM 输出，格式化为 PR 评论
const review = parseLLMOutput(llmResponse);
await github.pulls.createReview({
  owner, repo, pull_number,
  body: formatReview(review),
  event: 'COMMENT'
});
```

## 4. 审查规则配置

```json
{
  "rules": {
    "security": {
      "no-eval": "禁止使用 eval()",
      "no-hardcoded-secrets": "禁止硬编码密钥",
      "parameterized-queries": "使用参数化查询"
    },
    "performance": {
      "no-n-plus-1": "避免 N+1 查询",
      "index-usage": "确保查询使用索引"
    },
    "style": {
      "naming-convention": "遵循 camelCase/snake_case",
      "max-function-length": "函数不超过 50 行"
    }
  },
  "thresholds": {
    "critical": "阻断合并",
    "warning": "建议修改",
    "info": "可选优化"
  }
}
```

## 5. 集成到 CI/CD

```yaml
# .github/workflows/ai-review.yml
name: AI Code Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Get PR Diff
        run: gh pr diff ${{ github.event.pull_request.number }} > diff.txt
      - name: AI Review
        run: node scripts/ai-review.js
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
```

## 6. 效果评估

| 指标 | 目标 |
|------|------|
| 问题发现率 | > 70% (与人工审查对比) |
| 误报率 | < 20% |
| 审查速度 | < 30 秒/PR |
| 开发者满意度 | > 4/5 |

---

> 创建时间: 2026-07-09
> 创建者: 研发部高级研发专家
> 状态: 原型设计完成，待实现
