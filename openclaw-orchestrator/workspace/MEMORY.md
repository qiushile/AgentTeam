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
- **代码生成**: 2026-09-05（由 Orchestrator 生成完整项目代码）
- **项目状态**: 代码已写入磁盘，可编译部署
- **实际文件**: 32 个文件（Go 代码 + 配置 + 文档 + K8s）
- **技术栈**: Go 1.21 + Gin + PostgreSQL 15 + Redis 7 + Kubernetes
- **项目规模**: 16 个 Go 源文件, ~4,200 行 Go 代码, 16 个 API 端点, 8 个数据库表
- **6 个 Agent 部门完成概念设计**: PM/Dev/UI Designer/运营/客服/安全
- **代码结构**:
  - `cmd/server/main.go` — 入口（含优雅关闭、计费 Worker）
  - `internal/handler/` — 4 个处理器（auth/instance/order/apikey）
  - `internal/middleware/` — 3 个中间件（auth/CORS/logger）
  - `internal/model/` — 8 个数据模型
  - `internal/router/` — 16 个 API 端点路由
  - `services/` — DB 初始化 + Redis + 自动迁移
  - `worker/billing.go` — 5 分钟周期计费
  - `k8s/` — K8s 部署清单（API/PostgreSQL/Redis）
  - `frontend/index.html` — 官网落地页
  - `Dockerfile` + `docker-compose.yml` — 容器化部署
  - `sql/` — 完整建表脚本 + 种子数据

### 飞书通道故障
- **故障开始**: ~2026-06-12
- **错误信息**: "Channel is unavailable: feishu. Install the official external plugin with: openclaw plugins install @openclaw/feishu"
- **影响**: 每日任务验收报告、行业新闻推送均无法送达
- **修复方法**: 需运行 `openclaw plugins install @openclaw/feishu` 或 `openclaw doctor --fix`
- **状态**: 持续离线中（已通报多次）
