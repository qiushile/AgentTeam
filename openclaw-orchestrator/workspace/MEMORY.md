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
- **完成时间**: 2026-06-30
- **项目状态**: 6部门交付物 100% 完成
- **文件位置**: workspace/projects/gpu-rental-platform/
- **技术栈**: Go 1.21 + Gin + PostgreSQL 15 + Redis 7 + Kubernetes
- **项目规模**: 60+ 文件, ~4,200 行 Go 代码, 16 个 API 端点, 8 个数据库表
- **6 个 Agent 部门**: PM/Dev/UI Designer/运营/客服/安全 — 全部完成
- **PM 交付物**: 市场调研报告、竞品分析矩阵、PRD v1.0
- **UI 交付物**: 品牌VI手册、设计系统文档
- **运营交付物**: 数据指标字典、埋点方案文档
- **客服交付物**: FAQ知识库(19条)、客服SOP手册
- **安全交付物**: 安全架构设计文档、合规检查清单
- **包含模块**: 前端官网、后端 API、计费 Worker、Docker 部署、架构图
- **架构图**: diagrams/ 目录下有 2 份 (OpenClaw 架构 HTML + GPU Cloud Excalidraw)

### 飞书通道故障
- **故障开始**: ~2026-06-12
- **错误信息**: "Channel is unavailable: feishu. Install the official external plugin with: openclaw plugins install @openclaw/feishu"
- **影响**: 每日任务验收报告、行业新闻推送均无法送达
- **修复方法**: 需运行 `openclaw plugins install @openclaw/feishu` 或 `openclaw doctor --fix`
- **状态**: 持续离线中（已通报多次）
