# 数据库迁移脚本

## 目录结构

```
db/
├── migrations/              # Versioned migrations (V1, V2...)
│   ├── V1__baseline_schema.sql
│   └── V2__add_audit_triggers_and_constraints.sql
├── seeds/                   # Repeatable seed data (R__)
├── config/                  # Environment configs
│   ├── flyway.conf
│   ├── flyway-dev.conf
│   ├── flyway-staging.conf
│   └── flyway-prod.conf
└── README.md
```

## 命名规范

| 类型 | 前缀 | 示例 | 说明 |
|------|------|------|------|
| Versioned | `V` | `V3__add_indexes.sql` | 执行一次，不可修改 |
| Repeatable | `R` | `R__seed_data.sql` | 内容变更时重新执行 |

### 规则

1. 版本号严格递增: `V1` → `V2` → `V3` (或 `V1.0` → `V1.1` → `V2.0`)
2. 双下划线 `__` 分隔版本号和描述
3. 描述用下划线分隔单词: `add_users_table`
4. 每个迁移只做一件事
5. 已执行的迁移脚本**禁止修改**

## 创建新迁移

```bash
# 确定下一个版本号
flyway -configFiles=db/config/flyway-dev.conf info

# 手动创建文件 (替换 VERSION 和 DESCRIPTION)
touch db/migrations/V3__your_description_here.sql
```

### 迁移模板

```sql
-- V{VERSION}__{DESCRIPTION}.sql
-- Created: YYYY-MM-DD
-- Purpose: 简要说明本次变更目的

BEGIN;

-- 你的 DDL/DML 语句
-- 示例:
-- ALTER TABLE shared.tasks ADD COLUMN deadline TIMESTAMPTZ;

COMMIT;
```

## 执行迁移

```bash
# 开发环境
flyway -configFiles=db/config/flyway-dev.conf migrate

# Staging
flyway -configFiles=db/config/flyway-staging.conf migrate

# 生产 (先 dryRun 审查，再执行)
flyway -configFiles=db/config/flyway-prod.conf migrate -dryRunOutput=/tmp/migration.sql
# 审查 /tmp/migration.sql 后执行:
flyway -configFiles=db/config/flyway-prod.conf migrate
```

## Docker 运行

```bash
docker run --rm \
  -v $(pwd)/db/migrations:/flyway/sql \
  -v $(pwd)/db/config:/flyway/conf \
  -e FLYWAY_URL=jdbc:postgresql://172.23.0.14:5432/dev_db \
  -e FLYWAY_USER=dev_user \
  -e FLYWAY_PASSWORD=xxx \
  flyway/flyway:10 \
  -configFiles=/flyway/conf/flyway-dev.conf migrate
```

## 回滚

Flyway 社区版不支持自动回滚。手动回滚流程：

1. 创建回滚迁移: `V{next}__rollback_{description}.sql`
2. 编写反向 SQL
3. 在测试库验证
4. 在生产库执行

## CI/CD 集成

详见 `.github/workflows/db-migrations.yml` (待创建)

---

> 创建: 2026-09-06
> 状态: ✅ 已集成
