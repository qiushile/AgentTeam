# 研发部 6 个月工作计划 (2026.08 – 2027.01)

> 制定日期: 2026-08-22  
> 制定者: 研发部高级研发专家 (dev_user)  
> 状态: 草案

---

## 一、现状评估

### 已完成资产 (截至 2026-07-27)
- **技术文档**: 20+ 篇（数据库策略、CI/CD、安全基线、监控告警、API 文档、Onboarding、事件 SOP、OpenTelemetry 指南等）
- **ROADMAP**: 22/22 全部完成
- **数据库**: dev_db (shared + dev_schema, 6 张表正常运行)
- **Agent 体系**: 22 个专业子 Agent（安全、前端、后端、数据、运维、移动、嵌入式、区块链、文档）

### 当前阻塞项
| 问题 | 紧急度 | 说明 |
|---|---|---|
| FEISHU_APP_ID/SECRET 为占位值 | 🔴 P0 | 飞书消息推送完全失效，无法向创始人汇报 |
| 无新任务输入 26 天 | 🟡 P1 | Agent 处于空转待机状态 |
| DB IP 漂移 (172.23.0.2 ↔ .20) | 🟡 P1 | 偶尔连接中断，已实现自动发现 |

---

## 二、总体策略

> **「修复通道 → 稳固基建 → 能力扩展 → 实战交付」**

- **Phase 1 (2026.08-09)**: 修复飞书推送通道，稳固数据库连接，建立自动化任务流转
- **Phase 2 (2026.09-10)**: 技术文档审查，安全审计与加固，CI/CD 实战化部署
- **Phase 3 (2026.10-12)**: OpenTelemetry 部署，AI 辅助开发工具链，微服务通信 PoC
- **Phase 4 (2027.01)**: Agent 协作优化，2027 路线图制定

---

## Phase 1: 基础设施修复与自动化 (2026.08 – 2026.09)

### 1.1 飞书消息通道修复 (P0) 🔴
**目标**: 恢复向创始人的异步消息推送

- [ ] 获取有效的飞书应用 App ID / App Secret
- [ ] 更新环境变量 `FEISHU_APP_ID` / `FEISHU_APP_SECRET`
- [ ] 验证 tenant_access_token 获取与消息发送
- [ ] 配置自动心跳汇报推送（每日 07:00 工作日）
- [ ] 配置任务状态变更实时通知

**负责人**: dev_user（需创始人配合提供凭证）  
**预计耗时**: 凭证到位后 1 天  
**交付物**: 飞书消息发送成功验证 + 自动推送机制

### 1.2 DB 连接稳定性增强 (P1)
**目标**: 消除 IP 漂移导致的连接中断

- [ ] 编写 DB 健康检查脚本（每 30 分钟执行）
- [ ] 部署 PgBouncer 连接池（连接复用、故障转移）
- [ ] 配置 DNS 域名或 Docker network alias 替代硬编码 IP
- [ ] DB 连接失败自动重试机制（指数退避）

**负责人**: dev_user  
**预计耗时**: 3 天  
**交付物**: `scripts/db-health-monitor.js` + PgBouncer 配置

### 1.3 任务调度自动化 (P2)
- [ ] 封装 shared.tasks 与 dev_schema.dev_tasks 统一查询 API
- [ ] 实现任务优先级调度器（P0 > P1 > P2 > P3）
- [ ] 任务超时告警（IN_PROGRESS > 48h 无更新自动标记风险）
- [ ] 自动创建周期性巡检任务

**负责人**: dev_user  
**预计耗时**: 5 天  
**交付物**: Node.js 任务调度模块

---

## Phase 2: 技术债务清理与质量提升 (2026.09 – 2026.10)

### 2.1 技术文档体系审查 (P1)
- [ ] 逐篇审查现有 20+ 文档，标记过期/需更新内容
- [ ] 补充缺失的运维手册（Runbook）
  - DB 故障恢复 Runbook
  - Agent 重启/恢复 Runbook
  - 飞书连接问题排查 Runbook
- [ ] 统一文档格式（Markdown lint + 模板）
- [ ] 添加文档版本变更记录（Changelog）

**负责人**: dev_user + dev-technical-writer  
**预计耗时**: 5 天  
**交付物**: 文档审计报告 + 更新后的文档集

### 2.2 安全审计与加固 (P0) 🔴
- [ ] 数据库权限审计（dev_user 权限最小化）
- [ ] 依赖包漏洞扫描（npm audit / outdated）
- [ ] OpenClaw 配置安全审查（暴露端口、凭证存储）
- [ ] 编写安全事件响应 Playbook

**负责人**: dev_user + dev-security-engineer  
**预计耗时**: 5 天  
**交付物**: 安全审计报告 + 加固措施清单 + Playbook

### 2.3 CI/CD 流水线实战化 (P1)
- [ ] 基于现有 `docs/CICD_PIPELINE.md` 搭建实际流水线
- [ ] 配置自动化测试触发与报告
- [ ] 蓝绿部署方案验证
- [ ] 代码审查自动化集成（ESLint + SonarQube）

**负责人**: dev_user + dev-devops-automator  
**预计耗时**: 7 天  
**交付物**: 可运行的 CI/CD 流水线配置

---

## Phase 3: 能力扩展与工具链升级 (2026.10 – 2026.12)

### 3.1 OpenTelemetry 实际部署 (P1)
- [ ] 部署 OpenTelemetry Collector (DaemonSet)
- [ ] 部署 Grafana Tempo (Trace Backend)
- [ ] Node.js 服务接入自动插桩（基于 `docs/OPENTELEMETRY_GUIDE.md`）
- [ ] Grafana Dashboard 搭建（Traces + SLO）
- [ ] 配置告警规则（P0/P1/P2 分级）

**负责人**: dev_user  
**预计耗时**: 7 天  
**交付物**: 可观测性栈运行实例 + Dashboard

### 3.2 AI 辅助开发工具链 (P1)
- [ ] Code completion 工具评估（基于 `docs/AI_DEVELOPMENT_TOOLS.md`）
- [ ] 内部知识库 RAG 搭建（pgvector + embedding）
- [ ] 自动化测试生成 PoC
- [ ] AI 代码审查集成

**负责人**: dev_user + dev-ai-engineer  
**预计耗时**: 10 天  
**交付物**: AI 辅助开发环境 + 效果评估报告

### 3.3 微服务通信优化 PoC (P2)
- [ ] gRPC vs REST 对比基准测试
- [ ] 服务网格 (Istio) 方案调研与 PoC
- [ ] 消息队列选型压测（Kafka / RabbitMQ / Redis Streams）
- [ ] 输出推荐方案与实施路线

**负责人**: dev_user + dev-backend-architect  
**预计耗时**: 10 天  
**交付物**: 通信优化方案 + 性能基准报告

---

## Phase 4: 规模化与标准化 (2027.01)

### 4.1 Agent 协作优化 (P2)
- [ ] 优化 22 个专业子 Agent 的调度效率
- [ ] 建立跨部门协作 SLA
- [ ] 任务交付质量评分机制

**交付物**: Agent 协作优化方案

### 4.2 2027 年度技术路线图 (P2)
- [ ] 总结 2026 H2 成果与不足
- [ ] 制定 2027 年度技术路线图
- [ ] 确定技术债清理优先级

**交付物**: `DEV_ROADMAP_2027.md`

---

## 资源需求清单

| 资源 | 状态 | 说明 |
|---|---|---|
| 飞书应用凭证 | 🔴 阻塞中 | 需创始人提供 App ID + App Secret |
| PostgreSQL 访问 | ✅ 正常 | 当前连接 172.23.0.20:5432 |
| Agent 调度 | ✅ 可用 | 22 专业子 Agent |
| 文档产出 | ✅ 可用 | Markdown 技术文档 |
| Docker/容器 | ⏳ 待确认 | 部署 OTel/PgBouncer 需要 |

---

## 时间线

```
2026.08 ████████ Phase 1.1 飞书通道修复 (P0)
2026.08 ████████ Phase 1.2 DB 稳定性增强 (P1)
2026.09 ████████ Phase 1.3 任务调度自动化 (P2)
2026.09 ████████ Phase 2.1 文档审查 (P1)
2026.10 ████████ Phase 2.2 安全审计 (P0)
2026.10 ████████ Phase 2.3 CI/CD 实战化 (P1)
2026.10 ████████ Phase 3.1 OpenTelemetry 部署 (P1)
2026.11 ████████ Phase 3.2 AI 工具链 (P1)
2026.12 ████████ Phase 3.3 微服务通信 PoC (P2)
2027.01 ████████ Phase 4.1 Agent 协作优化 (P2)
2027.01 ████████ Phase 4.2 2027 路线图 (P2)
```

---

## 风险矩阵

| 风险 | 概率 | 影响 | 应对措施 |
|---|---|---|---|
| 飞书凭证无法获取 | 中 | 高 | 降级为本地日志记录 + 创始人主动查询 |
| DB IP 持续漂移 | 低 | 中 | PgBouncer + 自动发现脚本 |
| Agent 调度异常 | 低 | 高 | 自动重启 + 告警 |
| 长期无任务输入 | 高 | 低 | 空闲降级策略（已降至每日 1 次） |

---

> 本文档由研发部 Agent 自动生成，等待创始人审批后开始执行。
> 最后更新: 2026-08-22
