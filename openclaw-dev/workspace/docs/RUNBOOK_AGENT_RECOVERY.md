# Agent 重启/恢复 Runbook

> 创建日期: 2026-08-24  
> 维护者: 研发部高级研发专家 (dev_user)  
> 触发条件: Agent 无响应、心跳失败、会话异常

---

## 一、故障诊断流程

### Step 1: 确认 Agent 状态

```bash
# 1.1 检查 OpenClaw 状态
openclaw status

# 1.2 检查 Gateway 状态
openclaw gateway status

# 1.3 检查进程状态
ps aux | grep openclaw | grep -v grep
```

### Step 2: Agent 无响应

**症状**: 心跳超时、消息不回复

```bash
# 2.1 检查日志
tail -100 ~/.openclaw/logs/gateway.log

# 2.2 重启 Gateway
openclaw gateway restart

# 2.3 验证恢复
openclaw status
```

### Step 3: 数据库连接丢失

**症状**: DB 查询失败、任务无法更新

```bash
# 3.1 运行 DB 健康检查
node scripts/db-health-monitor.js

# 3.2 如果 IP 漂移，等待自动修复（5 分钟内）
# 或手动更新 .dev-config.json

# 3.3 验证恢复
node lib/task-scheduler.js stats
```

### Step 4: 飞书消息推送失败

**症状**: `tenant_access_token code: 10003`

```bash
# 4.1 检查环境变量
env | grep FEISHU_APP_ID
env | grep FEISHU_APP_SECRET

# 4.2 如果为占位值 (cli_xxxx)，需要创始人提供有效凭证
# 4.3 更新环境变量后重启 Gateway
openclaw gateway restart
```

### Step 5: 磁盘空间不足

**症状**: 写入失败、日志报错 No space left

```bash
# 5.1 检查磁盘使用
df -h

# 5.2 清理日志
find ~/.openclaw/logs -name "*.log" -mtime +7 -delete

# 5.3 清理旧会话
# 通过 OpenClaw 管理界面或 API
```

---

## 二、快速恢复命令

| 场景 | 命令 | 预计恢复时间 |
|---|---|---|
| Gateway 重启 | `openclaw gateway restart` | < 30 秒 |
| DB 连接恢复 | 自动（健康监控） | < 5 分钟 |
| 凭证更新 | 更新 env + restart | < 1 分钟 |
| 磁盘清理 | `find ... -delete` | < 5 分钟 |

---

## 三、预防措施

1. **心跳监控**: 每 30 分钟自动心跳检查
2. **日志轮转**: 定期清理 7 天以上日志
3. **磁盘监控**: 定期检查磁盘使用率
4. **配置备份**: `.dev-config.json` 和 HEARTBEAT.md 已版本化

---

> 最后更新: 2026-08-24  
> 下次审查: 2026-09-24
