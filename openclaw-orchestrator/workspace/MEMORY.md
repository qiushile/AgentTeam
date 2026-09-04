# 长期记忆 (Long-Term Memory)

## 系统配置
- **Embedding Provider**: 阿里云 text-embedding-v4
- **Memory Backend**: memory-lancedb
- **初始化日期**: 2026-03-23

## 重要决策与上下文

### Skills 评估
- 2026-03-23 完成 Skills 评估报告
- 推荐 9 个 skills，优先级排序已完成
- 等待用户评估确认

### 飞书私聊测试
- 2026-03-23 执行 9+ 次私聊测试
- 所有测试消息发送成功
- 权限配置正常

### memory-core 初始化
- 2026-03-23 完成 memory-lancedb 切换
- 阿里云 text-embedding-v4 语义检索测试通过

### GPU Cloud 算力租赁平台项目
- **启动时间**: 2026-06-25
- **设计完成**: 2026-06-30
- **项目状态**: 概念设计阶段完成，代码未持久化到磁盘
- **验证日期**: 2026-09-05
- **实际文件**: 仅 `diagrams/openclaw-architecture.html`（1份架构图）
- **缺失内容**: Go 源代码、文档、Docker 配置等均未找到
- **设计规格**（概念阶段）:
  - 技术栈: Go 1.21 + Gin + PostgreSQL 15 + Redis 7 + Kubernetes
  - 设计规模: 60+ 文件, ~4,200 行 Go 代码, 16 个 API 端点, 8 个数据库表
  - 6 个 Agent 部门完成概念设计: PM/Dev/UI Designer/运营/客服/安全
  - 交付物为概念文档，非实际代码

### 飞书通道故障
- **故障开始**: ~2026-06-12
- **错误信息**: "Channel is unavailable: feishu. Install the official external plugin with: openclaw plugins install @openclaw/feishu"
- **影响**: 每日任务验收报告、行业新闻推送均无法送达
- **修复方法**: 需运行 `openclaw plugins install @openclaw/feishu` 或 `openclaw doctor --fix`
- **状态**: 持续离线中（已通报多次）
