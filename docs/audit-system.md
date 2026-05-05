# PostgreSQL 审计系统文档

## 概述

PostgreSQL 审计系统用于监控和记录团队中所有 Agent 成员对数据库的变更操作，
实现对 INSERT、UPDATE、DELETE 操作的完整追溯。

## 架构

```
┌─────────────────────────────────────────────────┐
│                    openclaw_db                   │
│  ┌──────────────────────────────────────────┐   │
│  │              shared schema                │   │
│  │  ┌─────────┐ ┌──────────┐ ┌───────────┐  │   │
│  │  │ tasks   │ │ kb       │ │ messages  │  │   │
│  │  │ (8张表) │ │ ...      │ │ ...       │  │   │
│  │  └────┬────┘ └────┬─────┘ └─────┬─────┘  │   │
│  │       │           │             │         │   │
│  │  ┌────▼───────────▼─────────────▼─────┐   │   │
│  │  │      audit_capture TRIGGER         │   │   │
│  │  │  (AFTER INSERT/UPDATE/DELETE)      │   │   │
│  │  └──────────────┬─────────────────────┘   │   │
│  │                 │                         │   │
│  │  ┌──────────────▼─────────────────────┐   │   │
│  │  │       audit_write FUNCTION         │   │   │
│  │  │  (SECURITY DEFINER / postgres)     │   │   │
│  │  └──────────────┬─────────────────────┘   │   │
│  └─────────────────┼─────────────────────────┘   │
│                    │ dblink                      │
└────────────────────┼─────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────┐
│                    audit_db                       │
│  ┌──────────────────────────────────────────┐    │
│  │            audit schema                   │    │
│  │  ┌────────────────────────────────────┐  │    │
│  │  │  audit.log                         │  │    │
│  │  │  - id, occurred_at, db_user        │  │    │
│  │  │  - operation (INSERT/UPDATE/DELETE) │  │    │
│  │  │  - schema_name, table_name         │  │    │
│  │  │  - old_data (JSONB), new_data      │  │    │
│  │  │  - changed_fields (TEXT[])         │  │    │
│  │  │  - client_addr, client_port        │  │    │
│  │  └────────────────────────────────────┘  │    │
│  └──────────────────────────────────────────┘    │
│  仅 postgres 可访问，团队用户被拒绝连接            │
└──────────────────────────────────────────────────┘
```

## 核心组件

### 1. 审计数据库 (`audit_db`)

- 独立的 PostgreSQL 数据库
- 仅 `postgres` 超级用户可连接
- 所有团队用户（`*_user`）被 `REVOKE CONNECT`

### 2. 审计日志表 (`audit.log`)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | 自增主键 |
| occurred_at | TIMESTAMPTZ | 变更发生时间 |
| db_user | VARCHAR(64) | 执行变更的数据库用户 |
| operation | VARCHAR(10) | INSERT / UPDATE / DELETE |
| schema_name | VARCHAR(64) | 被操作的 schema |
| table_name | VARCHAR(128) | 被操作的表 |
| old_data | JSONB | 变更前完整数据（UPDATE/DELETE） |
| new_data | JSONB | 变更后完整数据（INSERT/UPDATE） |
| changed_fields | TEXT[] | UPDATE 时具体变更的字段名 |
| client_addr | INET | 客户端 IP |
| client_port | INTEGER | 客户端端口 |
| application_name | VARCHAR(128) | 应用标识 |

### 3. 审计触发器

- 在 `shared` schema 下所有 8 张表上挂载
- 触发时机：`AFTER INSERT OR UPDATE OR DELETE`
- 触发器函数：`shared.audit_capture()`

### 4. dblink 跨库写入

- 函数：`public.audit_write()` (SECURITY DEFINER)
- 以 postgres 身份连接 audit_db 写入审计记录
- 失败时仅 RAISE WARNING，不阻断业务操作

## 覆盖的表

| 表名 | 说明 |
|------|------|
| shared.tasks | 任务管理 |
| shared.collaboration_events | 协作事件 |
| shared.knowledge_base | 知识库 |
| shared.department_registry | 部门注册 |
| shared.agent_heartbeats | Agent 心跳 |
| shared.inter_agent_messages | Agent 间消息 |
| shared.shared_artifacts | 共享产物 |
| shared.task_comments | 任务评论 |

## 使用方式

### 监控审计变更

```bash
# 查看最近 1 小时的变更
bash /opt/openclaw-team/monitor/audit-monitor.sh "1 hour"

# 查看最近 24 小时的变更
bash /opt/openclaw-team/monitor/audit-monitor.sh "24 hours"

# 追溯特定 Agent 的变更
bash /opt/openclaw-team/monitor/audit-user-trail.sh dev_user "24 hours"
bash /opt/openclaw-team/monitor/audit-user-trail.sh pm_user "7 days"
```

### 直接查询审计数据库

```bash
# 查看所有变更
docker exec openclaw-postgres psql -U postgres -d audit_db -c \
  "SELECT * FROM audit.log ORDER BY occurred_at DESC LIMIT 20;"

# 查看某用户的变更
docker exec openclaw-postgres psql -U postgres -d audit_db -c \
  "SELECT * FROM audit.get_user_changes('dev_user', NOW() - INTERVAL '24 hours');"

# 查看某表的变更
docker exec openclaw-postgres psql -U postgres -d audit_db -c \
  "SELECT * FROM audit.log WHERE table_name = 'tasks' 
   AND occurred_at > NOW() - INTERVAL '1 hour' ORDER BY occurred_at DESC;"

# 查看变更字段详情
docker exec openclaw-postgres psql -U postgres -d audit_db -c \
  "SELECT db_user, operation, table_name, changed_fields,
          jsonb_pretty(old_data) AS before,
          jsonb_pretty(new_data) AS after
   FROM audit.log WHERE operation = 'UPDATE'
   ORDER BY occurred_at DESC LIMIT 10;"
```

### 数据清理

```bash
# 清理 90 天前的数据（默认）
docker exec openclaw-postgres psql -U postgres -d audit_db -c \
  "SELECT audit.cleanup_old_data();"

# 清理 30 天前的数据
docker exec openclaw-postgres psql -U postgres -d audit_db -c \
  "SELECT audit.cleanup_old_data(30);"
```

## 安全特性

1. **数据库隔离**：audit_db 对团队用户不可见（REVOKE CONNECT）
2. **最小权限**：审计函数仅授予 EXECUTE 权限，不暴露函数定义
3. **不可篡改**：团队用户只有审计写入权限，无法读取或删除审计记录
4. **业务无感**：审计写入失败不阻断正常业务操作（EXCEPTION 捕获）

## 文件清单

| 文件 | 说明 |
|------|------|
| `init.sql` (末尾) | 审计系统初始化 SQL |
| `scripts/audit-setup-1-create-db.sql` | 创建审计数据库 |
| `scripts/audit-setup-2-audit-schema.sql` | 审计 schema 和表 |
| `scripts/audit-setup-3-triggers.sql` | dblink 和触发器 |
| `scripts/audit-create-function.sql` | audit_write 函数 |
| `monitor/audit-monitor.sh` | 审计变更监控脚本 |
| `monitor/audit-user-trail.sh` | 用户变更追溯脚本 |

## 故障排查

### 触发器未生效

```bash
# 检查触发器是否存在
docker exec openclaw-postgres psql -U postgres -d openclaw_db -c "
SELECT trigger_name, event_object_table FROM information_schema.triggers
WHERE trigger_name LIKE 'audit_%';"
```

### 审计函数不存在

```bash
# 重新创建
docker cp /opt/openclaw-team/scripts/audit-create-function.sql openclaw-postgres:/tmp/
docker exec openclaw-postgres psql -U postgres -d openclaw_db -f /tmp/audit-create-function.sql
```

### dblink 连接失败

```bash
# 测试 dblink 连接
docker exec openclaw-postgres psql -U postgres -d openclaw_db -c "
SELECT dblink_exec('host=127.0.0.1 port=5432 dbname=audit_db user=postgres password=root_super_password', 'SELECT 1');"
```
