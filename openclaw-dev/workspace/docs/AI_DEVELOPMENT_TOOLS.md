# 内部 AI 辅助开发工具指南

## 一、Code Completion 工具评估

### 主流方案对比

| 维度 | GitHub Copilot | Codeium | CodeGeeX | Tabnine |
|------|---------------|---------|----------|---------|
| **定价** | $10/用户/月 | 免费 (个人) / $12/用户/月 (企业) | 免费 | $12/用户/月 |
| **模型** | OpenAI Codex | 自研 | 清华自研 | 自研 |
| **IDE 支持** | VS Code, JetBrains, Vim | VS Code, JetBrains, Vim | VS Code, JetBrains | VS Code, JetBrains |
| **代码补全** | ✅ 优秀 | ✅ 优秀 | ✅ 良好 | ✅ 良好 |
| **对话模式** | ✅ Chat | ✅ Chat | ✅ Chat | ❌ |
| **私有化部署** | ❌ (仅企业版) | ✅ (企业版) | ✅ (开源可自部署) | ✅ (企业版) |
| **中文支持** | ✅ | ✅ | ✅ (原生中文优化) | ✅ |
| **合规性** | 代码可能来自训练集 | 训练集声明无 GPL | 开源训练 | 训练集声明安全 |

### 推荐方案

> **CodeGeeX** (适合当前团队):
> - 完全免费，可私有化部署
> - 原生中文优化，国内网络友好
> - 开源可审计，无合规风险
> - VS Code / JetBrains 插件成熟

---

## 二、内部知识库 RAG 搭建

### 架构设计

```
┌──────────────────────────────────────────────────────┐
│                    Developer Portal                   │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │
│  │  Code Search  │  │  Q&A Chat   │  │  Doc Gen   │  │
│  └──────┬───────┘  └──────┬───────┘  └─────┬──────┘  │
│         │                 │                │         │
└─────────┼─────────────────┼────────────────┼─────────┘
          │                 │                │
          ▼                 ▼                ▼
┌──────────────────────────────────────────────────────┐
│                  AI Gateway Layer                     │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  │
│  │ Prompt Mgmt │  │ Rate Limit  │  │ Audit Log    │  │
│  └─────────────┘  └─────────────┘  └──────────────┘  │
└──────────────────────────┬───────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
    ┌──────────┐    ┌──────────┐    ┌──────────────┐
    │ Embedding│    │  Vector  │    │  LLM Backend │
    │ Service  │    │   DB     │    │ (Qwen/GPT-4) │
    └────┬─────┘    └────┬─────┘    └──────────────┘
         │               │
         ▼               ▼
    ┌─────────────────────────┐
    │     Knowledge Base       │
    │  ├─ API 文档             │
    │  ├─ 架构决策记录 (ADR)   │
    │  ├─ 故障处理 SOP         │
    │  ├─ 代码规范             │
    │  └─ 项目 README          │
    └─────────────────────────┘
```

### 技术选型

| 组件 | 方案 | 说明 |
|------|------|------|
| **Embedding** | text-embedding-3-small / BGE-M3 | 中文向量模型 |
| **Vector DB** | pgvector (PostgreSQL 扩展) | 复用现有 PG 集群 |
| **LLM** | Qwen2.5 / GPT-4o | 通过 OpenClaw 网关 |
| **框架** | LangChain / LlamaIndex | RAG 编排 |
| **UI** | Open WebUI / 自定义前端 | 开发者入口 |

### pgvector 集成 (推荐)

```sql
-- 启用 pgvector 扩展
CREATE EXTENSION IF NOT EXISTS vector;

-- 创建知识库表
CREATE TABLE IF NOT EXISTS dev_schema.knowledge_chunks (
    id BIGSERIAL PRIMARY KEY,
    source VARCHAR(255) NOT NULL,         -- 来源文件
    content TEXT NOT NULL,                 -- 文本内容
    embedding vector(1536),               -- 向量 (OpenAI embedding)
    metadata JSONB,                        -- 元数据 (作者, 日期, 标签)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 创建向量索引 (IVFFlat)
CREATE INDEX IF NOT EXISTS idx_knowledge_embedding
    ON dev_schema.knowledge_chunks
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

-- 相似度搜索
SELECT id, source, content, metadata,
       1 - (embedding <=> $1) AS similarity
FROM dev_schema.knowledge_chunks
ORDER BY embedding <=> $1
LIMIT 5;
```

---

## 三、自动化测试生成

### 方案一: AI 生成单元测试

```python
# test_generator.py
import openai
import ast
import os

PROMPT_TEMPLATE = """
You are a senior test engineer. Generate comprehensive unit tests for the following {language} code.

Requirements:
1. Cover normal cases, edge cases, and error cases
2. Use {test_framework} framework
3. Include mock/stub where necessary
4. Add clear test descriptions
5. Follow AAA pattern (Arrange-Act-Assert)

Code:
```{language}
{code}
```
"""

def generate_tests(file_path, language="python", test_framework="pytest"):
    with open(file_path, 'r') as f:
        code = f.read()
    
    prompt = PROMPT_TEMPLATE.format(
        language=language,
        test_framework=test_framework,
        code=code
    )
    
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.3,
        max_tokens=2000
    )
    
    # Extract test code from response
    test_code = response.choices[0].message.content
    test_dir = os.path.join(os.path.dirname(file_path), 'tests')
    os.makedirs(test_dir, exist_ok=True)
    test_file = os.path.join(test_dir, f'test_{os.path.basename(file_path)}')
    
    with open(test_file, 'w') as f:
        f.write(test_code)
    
    return test_file
```

### 方案二: Jest + AI (Node.js)

```javascript
// scripts/generate-tests.js
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

async function generateTestsForFile(filePath) {
  const code = fs.readFileSync(filePath, 'utf8');
  
  const prompt = `为以下 Node.js 代码生成 Jest 单元测试:
- 覆盖正常流程、边界条件、错误处理
- 使用 jest.mock 模拟外部依赖
- 每个 test 有清晰的描述

代码:
\`\`\`javascript
${code}
\`\`\``;
  
  // 调用 AI 服务 (通过 OpenClaw 或直接 API)
  const response = await callAI(prompt);
  
  const testDir = path.join(path.dirname(filePath), '__tests__');
  fs.mkdirSync(testDir, { recursive: true });
  
  const testFile = path.join(testDir, path.basename(filePath).replace('.js', '.test.js'));
  fs.writeFileSync(testFile, response);
  
  console.log(`✅ Generated tests: ${testFile}`);
}

// 批量处理
const srcDir = process.argv[2] || 'src';
fs.readdirSync(srcDir, { recursive: true })
  .filter(f => f.endsWith('.js') && !f.includes('__tests__'))
  .forEach(f => generateTestsForFile(path.join(srcDir, f)));
```

### 方案三: CI 自动触发

```yaml
# .github/workflows/auto-tests.yml
name: AI Test Generation

on:
  pull_request:
    paths: ['src/**/*.js', 'src/**/*.py']

jobs:
  generate-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check for missing tests
        id: check
        run: |
          MISSING=""
          for file in $(git diff --name-only ${{ github.event.pull_request.base.sha }} ${{ github.sha }} | grep -E '\.(js|py)$'); do
            test_file="${file%.js}.test.js"
            if [ ! -f "$test_file" ]; then
              test_file="${file%.py}_test.py"
            fi
            if [ ! -f "$test_file" ]; then
              MISSING="$MISSING $file"
            fi
          done
          echo "missing=$MISSING" >> $GITHUB_OUTPUT
      
      - name: Generate tests with AI
        if: steps.check.outputs.missing != ''
        run: |
          for file in ${{ steps.check.outputs.missing }}; do
            node scripts/generate-tests.js $file
          done
      
      - name: Run generated tests
        run: npm test || pytest --tb=short
      
      - name: Create PR with tests
        uses: peter-evans/create-pull-request@v6
        with:
          title: "🤖 Auto-generated tests for ${{ steps.check.outputs.missing }}"
          branch: auto-tests-${{ github.event.pull_request.number }}
```

---

## 四、实施路线图

| 阶段 | 内容 | 周期 | 优先级 |
|------|------|------|--------|
| **Phase 1** | CodeGeeX 插件部署 + 团队培训 | 1 周 | HIGH |
| **Phase 2** | 内部知识库 RAG 搭建 (pgvector) | 2 周 | HIGH |
| **Phase 3** | AI 代码审查集成到 CI | 1 周 | MEDIUM |
| **Phase 4** | 自动化测试生成流水线 | 2 周 | MEDIUM |
| **Phase 5** | 效果评估 + 持续优化 | 持续 | - |

### 成本估算

| 项目 | 月成本 |
|------|--------|
| CodeGeeX (自部署) | ~¥0 (开源) |
| Embedding API | ~¥50-200 (按调用量) |
| LLM API (Qwen) | ~¥100-500 (按 token) |
| 向量存储 (pgvector) | ~¥0 (复用现有 PG) |
| **合计** | **~¥150-700/月** |

---

> 创建时间: 2026-07-27
> 创建者: 研发部高级研发专家
> 状态: 完成
