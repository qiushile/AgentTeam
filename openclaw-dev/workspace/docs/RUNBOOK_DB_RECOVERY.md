# DB 故障恢复 Runbook

> 创建日期: 2026-08-24  
> 维护者: 研发部高级研发专家 (dev_user)  
> 触发条件: DB 连接失败、数据丢失、性能异常

---

## 一、故障诊断流程

### Step 1: 确认故障类型

```bash
# 运行健康检查
node scripts/db-health-monitor.js
```

| 输出 | 故障类型 | 处理流程 |
|---|---|---|
| ✅ Connection successful | 无故障 | 无需操作 |
| ❌ Connection refused | DB 服务宕机 | 转 Step 2 |
| ❌ Authentication failed | 凭证失效 | 转 Step 3 |
| ❌ Database does not exist | DB 丢失 | 转 Step 4 |
| ⚠️ 慢查询 | 性能问题 | 转 Step 5 |

### Step 2: DB 服务宕机恢复

```bash
# 2.1 扫描子网寻找 PostgreSQL
for i in $(seq 1 254); do
  timeout 1 bash -c "echo >/dev/tcp/172.23.0.$i/5432" 2>/dev/null && echo "Found: 172.23.0.$i"
done

# 2.2 如果找到新 IP，更新配置
# 编辑 .dev-config.json，更新 db_host 为新 IP

# 2.3 如果未找到任何 PG 实例，检查 Docker 状态
docker ps -a | grep postgres

# 2.4 重启 PostgreSQL 容器
docker start postgres  # 或对应容器名
```

### Step 3: 凭证失效恢复

```bash
# 3.1 检查环境变量
echo "DEV_DB_PASS env: ${DEV_DB_PASS:+SET}"

# 3.2 检查 .dev-config.json 中的 env_var_password 引用
cat .dev-config.json

# 3.3 如果密码变更，更新 Docker 环境变量
docker exec postgres psql -U postgres -c "ALTER USER dev_user WITH PASSWORD 'new_password';"

# 3.4 更新环境变量并重新加载
export DEV_DB_PASS='new_password'
```

### Step 4: 数据库丢失恢复

```bash
# 4.1 检查数据库是否存在
PGPASSWORD=$DEV_DB_PASS psql -h 172.23.0.20 -U dev_user -l | grep dev_db

# 4.2 如果不存在，从备份恢复
# 查找最新备份文件
ls -lt /backups/dev_db/ | head -5

# 恢复数据库
PGPASSWORD=$DEV_DB_PASS psql -h 172.23.0.20 -U dev_user -d dev_db < /backups/dev_db/latest.sql

# 4.3 如果无备份，重新创建 schema 和表
# 参考 HEARTBEAT.md 中的「首次运行初始化」SQL
```

### Step 5: 性能问题排查

```bash
# 5.1 查看慢查询日志
PGPASSWORD=$DEV_DB_PASS psql -h 172.23.0.20 -U dev_user -d dev_db -c "
  SELECT query, calls, total_time, mean_time, rows
  FROM pg_stat_statements
  ORDER BY mean_time DESC
  LIMIT 10;
"

# 5.2 查看当前活跃连接
PGPASSWORD=$DEV_DB_PASS psql -h 172.23.0.20 -U dev_user -d dev_db -c "
  SELECT count(*) FROM pg_stat_activity WHERE state = 'active';
"

# 5.3 查看锁等待
PGPASSWORD=$DEV_DB_PASS psql -h 172.23.0.20 -U dev_user -d dev_db -c "
  SELECT blocked_locks.pid AS blocked_pid,
         blocking_locks.pid AS blocking_pid,
         blocked_activity.query AS blocked_query
  FROM pg_catalog.pg_locks blocked_locks
  JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
  JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
  WHERE NOT blocked_locks.granted;
"
```

---

## 二、快速恢复命令

| 场景 | 命令 | 预计恢复时间 |
|---|---|---|
| IP 漂移 | `node scripts/db-health-monitor.js`（自动检测+更新） | < 5 分钟 |
| 服务重启 | `docker start postgres` | < 2 分钟 |
| 凭证更新 | 更新环境变量 + 重启服务 | < 1 分钟 |
| 数据恢复 | `psql < backup.sql` | 5-30 分钟 |
| Schema 重建 | 执行 HEARTBEAT.md 初始化 SQL | < 5 分钟 |

---

## 三、预防措施

1. **DB 健康监控**: `scripts/db-health-monitor.js` 每 30 分钟自动执行
2. **自动 IP 发现**: 连接失败时自动扫描子网
3. **连接池**: 使用 PgBouncer 减少连接开销
4. **定期备份**: 每日自动备份（需配置）
5. **权限收紧**: dev_user 仅保留必要权限

---

> 最后更新: 2026-08-24  
> 下次审查: 2026-09-24
