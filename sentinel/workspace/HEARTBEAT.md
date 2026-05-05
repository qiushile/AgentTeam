# HEARTBEAT.md

# Keep this file empty (or with only comments) to skip heartbeat API calls.

# Add tasks below when you want the agent to check something periodically.

---

## Agent 团队健康检查（每 5-10 分钟）

运行 `/opt/openclaw-team/monitor/heartbeat-trigger.sh` 检查 docker 容器状态。

**检查内容：**
- 3 个 agent 容器是否运行（orchestrator/dev/pm）
- 端口 18789/18790/18791 是否可访问
- 最近 5 分钟日志是否有错误
- 资源使用情况
- PostgreSQL 数据库状态

**告警规则：**
- CRITICAL（立即通知）：容器宕机、端口不可用、数据库异常
- WARNING（记录）：重启次数过多、错误日志增多
- HEALTHY（静默）：一切正常

**状态文件：** `/opt/openclaw-team/monitor/health-state.json`

---

## PostgreSQL 审计异常检查（每 30 分钟）

运行以下 SQL 检查审计库中最近 30 分钟的异常变更：

```bash
docker exec openclaw-postgres psql -U postgres -d audit_db -t -c "
SELECT count(*) FROM audit.log WHERE occurred_at > NOW() - INTERVAL '30 minutes' AND operation = 'DELETE';
"
```

**告警规则：**
- 大量 DELETE（>5 次/30分钟）→ WARNING
- 敏感表（department_registry, agent_heartbeats）被修改 → WARNING

---

## 每日汇报（每天一次）

运行 `/opt/openclaw-team/monitor/daily-report.sh` 生成每日汇报。

**检查内容：**
- Git 代码仓库状态（未提交变更、未推送提交）
- 最近 10 条提交记录
- Docker 容器状态（orchestrator/dev/pm/postgres）
- 端口可用性（18789/18790/18791/5432）
- 健康状态文件内容
- 推荐操作（需要提交的变更、需要推送的提交、需要处理的异常）

**汇报规则：**
- 每天生成一次汇总报告
- 有变更时推荐哪些应该提交到代码仓库
- 汇总表格展示整体状态
- 报告保存到 `/opt/openclaw-team/monitor/daily-report-YYYY-MM-DD.md`

**状态文件：** `/opt/openclaw-team/monitor/daily-report-state.json`
