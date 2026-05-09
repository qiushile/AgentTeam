---
name: chinese-docx-pipeline
trigger: "生成中文Word文档(.docx)、会议纪要、需求文档、将Markdown转为DOCX"
description: "从MD生成客户级规范中文DOCX的完整管道——pandoc转换 + XML层后处理，确保宋体、无横线、无斜体、无蓝色、表格带边框。"
---

## 中文DOCX生成管道

### 1. MD源文件编写规则
- **禁止** `---` 横线（pandoc会转成段落边框）
- **禁止** emoji、斜体语法
- 标题用 `#` `##` `###`，表格用标准Markdown表格
- MD文件进入git追踪

### 2. pandoc转换
```bash
pandoc input.md -o output.docx --reference-doc=reference.docx
```

### 3. XML层后处理（必须执行）
解压 `output.docx`（zip格式），处理 `word/document.xml` 和 `word/styles.xml`：

| 清理目标 | XML模式 | 说明 |
|----------|---------|------|
| 横线 | `<w:pBdr[^>]*>.*?</w:pBdr>` | 段落边框 |
| 横线 | `<w:bottom[^>]*w:val="single"[^>]*/>` | 单下划线 |
| 分页控制 | `<w:keepNext/>` | 与下段同页 |
| 分页控制 | `<w:keepLines/>` | 段中不分页 |
| 主题色 | `<w:(?:themeColor|themeTint|themeShade|themeFill)[^>]*/>` | Word默认渲染为蓝色 |
| 强制黑色 | `<w:color w:val="[^"]*"/>` → `<w:color w:val="000000"/>` | 所有颜色替换为纯黑 |
| 斜体 | `<w:i(?:Cs)? w:val="[^"]*"[^>]*/>` | 移除斜体标记 |
| 列表编号 | `<w:numPr>.*?</w:numPr>` | 序号前的黑点/数字 |
| 修订标记 | `<w:rsid[^>]*/>` | 编辑追踪标记 |
| 表格边框 | `<w:tblBorders>.*?</w:tblBorders>` | 替换为黑色单线边框（sz=4, color=000000） |

同时设置默认语言：`<w:lang w:val="zh-CN"/>`

### 4. 字体设置
- 正文/表格：宋体 (SimSun) 11pt
- 标题：微软雅黑 (Microsoft YaHei) 黑色
- 在 `reference.docx` 和 `styles.xml` 中统一配置

### 5. 目录结构
```
project-docs/
├── .gitignore          # 内容: docx-output/
├── procurement-platform/
│   └── *.md
├── wholesale/
│   ├── *.md
│   └── docx-output/
│       └── *.docx
```

### 6. 验证清单
生成后检查：横线0、keepNext0、keepLines0、主题色0、斜体0、列表编号0、表格边框已加、语言zh-CN。
