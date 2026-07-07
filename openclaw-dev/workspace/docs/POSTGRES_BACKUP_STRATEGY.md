# PostgreSQL 数据库备份策略

## 1. 概述

本文档定义研发部 PostgreSQL 数据库（172.23.0.20:5432）的备份与恢复策略。

## 2. 备份方案

### 2.1 全量备份 (Full Backup)
- **频率**: 每日凌晨 02:00 执行
- **工具**: `pg_dump --format=custom --compress=9`
- **保留**: 7 天本地 + 30 天远程归档
- **存储路径**: `/backups/daily/dev_db_$(date +%Y%m%d_%H%M%S).dump`

```bash
pg_dump -h 172.23.0.20 -U postgres -Fc -Z 9 -f /backups/daily/dev_db_$(date +%Y%m%d_%H%M%S).dump dev_db
```

### 2.2 增量备份 (WAL Archive)
- **模式**: WAL (Write-Ahead Log) 连续归档
- **频率**: 实时流复制
- **保留**: 7 天

### 2.3 关键表热备份
- **频率**: 每小时
- **目标表**: `shared.tasks`, `shared.collaboration_events`, `dev_schema.*`
- **格式**: SQL insert 语句

```bash
pg_dump -h 172.23.0.20 -U postgres --data-only --table='shared.*' --table='dev_schema.*' -f /backups/hourly/$(date +%Y%m%d_%H%M%S).sql dev_db
```

## 3. 恢复策略

### 3.1 场景分级

| 场景 | RTO | RPO | 恢复方式 |
|------|-----|-----|---------|
| 单表误删/数据损坏 | < 5 分钟 | < 1 小时 | 热备份恢复 |
| 数据库整体故障 | < 30 分钟 | < 24 小时 | 全量备份恢复 |
| 灾难恢复 (硬件故障) | < 2 小时 | < 24 小时 | 异地备份恢复 |

### 3.2 恢复流程

```bash
# 1. 停止应用连接
# 2. 恢复全量备份
pg_restore -h 172.23.0.20 -U postgres -d dev_db --clean --if-exists /backups/daily/dev_db_YYYYMMDD_HHMMSS.dump

# 3. 恢复增量 WAL（如需要）
# 4. 验证数据完整性
# 5. 恢复应用连接
```

## 4. 自动化脚本

### 4.1 备份脚本 (backup.sh)

```bash
#!/bin/bash
BACKUP_DIR="/backups/daily"
mkdir -p $BACKUP_DIR

# 全量备份
pg_dump -h 172.23.0.20 -U postgres -Fc -Z 9 -f $BACKUP_DIR/dev_db_$(date +%Y%m%d_%H%M%S).dump dev_db

# 清理 7 天前的备份
find $BACKUP_DIR -name "*.dump" -mtime +7 -delete

echo "Backup completed: $(date)"
```

### 4.2 crontab 配置

```cron
# 每日凌晨 2 点全量备份
0 2 * * * /usr/local/bin/backup.sh >> /var/log/pg_backup.log 2>&1

# 每小时热备份关键表
0 * * * * pg_dump -h 172.23.0.20 -U postgres --data-only --table='shared.*' --table='dev_schema.*' -f /backups/hourly/$(date +\%Y\%m\%d_\%H\%M\%S).sql dev_db
```

## 5. 验证与演练

### 5.1 备份验证
- 每次备份后自动校验文件大小 > 0
- 每周随机选取一个备份文件进行 `pg_restore --list` 验证

### 5.2 恢复演练
- 频率: 每月一次
- 内容: 在测试环境完整恢复最新备份
- 记录: RTO 实际用时、数据完整性校验结果

## 6. 监控告警

| 指标 | 阈值 | 告警级别 |
|------|------|---------|
| 备份失败 | 连续 1 次失败 | P0 (立即处理) |
| 备份文件大小 | < 上次 50% | P1 (1 小时内) |
| 磁盘空间 | < 20% 剩余 | P1 (1 小时内) |
| 恢复演练超时 | > 1 小时 | P2 (当日处理) |

---

> 创建时间: 2026-07-08
> 创建者: 研发部高级研发专家
> 状态: 待评审
