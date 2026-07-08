# 故障处理 SOP (Standard Operating Procedure)

## 1. 故障分级

| 级别 | 定义 | 响应时间 | 升级路径 |
|------|------|---------|---------|
| P0 - 致命 | 服务完全不可用，数据丢失 | 5 分钟 | 创始人 → 全员 |
| P1 - 严重 | 核心功能受损，影响大部分用户 | 15 分钟 | 技术负责人 → 创始人 |
| P2 - 警告 | 非核心功能异常，性能下降 | 1 小时 | 技术负责人 |
| P3 - 信息 | 趋势预警，容量规划 | 当日 | 研发团队 |

## 2. 故障响应流程

```
发现 → 确认 → 通报 → 止损 → 修复 → 验证 → 复盘
```

### 2.1 发现
- 监控告警自动触发
- 用户反馈
- 巡检发现

### 2.2 确认
1. 确认故障范围和影响
2. 判断故障级别 (P0-P3)
3. 记录故障时间线

### 2.3 通报
```
飞书群消息模板:
🚨 故障通报 [P级别]
时间: YYYY-MM-DD HH:MM
影响: [服务/功能]
现象: [描述]
处理人: [姓名]
预计恢复: [时间]
```

### 2.4 止损 (优先级最高)
| 场景 | 止损措施 |
|------|---------|
| 数据库连接耗尽 | 重启 pgBouncer / 杀掉空闲连接 |
| 服务无响应 | 重启服务实例 |
| 错误率飙升 | 回滚最近部署 |
| 磁盘空间不足 | 清理日志 / 扩容 |

### 2.5 修复
- 找到根因并实施修复
- 在测试环境验证修复方案
- 灰度发布到生产

### 2.6 验证
- 监控指标恢复正常
- 核心功能冒烟测试通过
- 确认无连带影响

### 2.7 复盘 (故障后 24 小时内)
- 根本原因分析 (5 Whys)
- 时间线回顾
- 改进措施制定
- 更新相关 SOP

## 3. 常见故障处理手册

### 3.1 PostgreSQL 连接耗尽
```bash
# 1. 查看当前连接
psql -h 172.23.0.20 -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# 2. 杀掉空闲连接
psql -h 172.23.0.20 -U postgres -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'idle' AND query_start < now() - interval '30 minutes'
  AND datname = 'dev_db';
"

# 3. 检查 max_connections
psql -h 172.23.0.20 -U postgres -c "SHOW max_connections;"

# 4. 如果需要临时增加
# 修改 postgresql.conf: max_connections = 200
# pg_ctl reload
```

### 3.2 服务无响应
```bash
# 1. 检查进程状态
docker ps | grep dev-api

# 2. 查看日志
docker logs dev-api --tail 100

# 3. 重启服务
docker restart dev-api

# 4. 检查健康状态
curl -sf http://localhost:3000/health || echo "UNHEALTHY"
```

### 3.3 磁盘空间不足
```bash
# 1. 检查磁盘使用
df -h

# 2. 查找大文件
find / -type f -size +100M -exec ls -lh {} \;

# 3. 清理旧日志
find /var/log -name "*.log" -mtime +7 -delete

# 4. 清理 Docker 无用资源
docker system prune -af
```

### 3.4 数据库锁死
```sql
-- 1. 查看锁等待
SELECT blocked.pid, blocked.query, blocking.pid, blocking.query
FROM pg_stat_activity blocked
JOIN pg_locks bl ON blocked.pid = bl.pid AND NOT bl.granted
JOIN pg_stat_activity blocking ON blocking.pid = (
  SELECT pid FROM pg_locks WHERE relation = bl.relation AND granted = true LIMIT 1
);

-- 2. 终止阻塞者
SELECT pg_terminate_backend(pid) FROM pg_stat_activity 
WHERE pid IN (SELECT pid FROM pg_locks WHERE NOT granted);
```

## 4. 联系人

| 角色 | 姓名 | 联系方式 |
|------|------|---------|
| 创始人 | 邱世乐 | 飞书 |
| 技术负责人 | [待定] | 飞书 |
| 值班工程师 | [轮值] | 飞书 |

## 5. 故障复盘模板

### 故障报告
- **故障编号**: INC-YYYY-NNN
- **故障级别**: P0/P1/P2/P3
- **发生时间**: YYYY-MM-DD HH:MM
- **恢复时间**: YYYY-MM-DD HH:MM
- **持续时长**: XX 分钟
- **影响范围**: [描述]

### 5 Whys 分析
1. **为什么发生?** → ...
2. **为什么会这样?** → ...
3. **为什么会这样?** → ...
4. **为什么会这样?** → ...
5. **根因?** → ...

### 改进措施
| # | 措施 | 负责人 | 截止日期 | 状态 |
|---|------|-------|---------|------|
| 1 | | | | 待处理 |

---

> 创建时间: 2026-07-08
> 创建者: 研发部高级研发专家
> 状态: 待评审
