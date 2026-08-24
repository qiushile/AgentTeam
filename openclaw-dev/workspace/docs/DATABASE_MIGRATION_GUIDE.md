# 数据库迁移与版本管理指南

## 一、工具选型对比

### Flyway vs Liquibase

| 维度 | Flyway | Liquibase |
|------|--------|-----------|
| **迁移方式** | 纯 SQL (约定优于配置) | XML/YAML/JSON/SQL (灵活) |
| **回滚** | 仅企业版支持 | 开源支持 (rollback 标签) |
| **学习曲线** | 低 (SQL 即迁移脚本) | 中 (需掌握 changelog 语法) |
| **多环境** | 支持 | 支持 |
| **分支合并** | 需手动处理冲突 | 内置 merge 支持 |
| **社区活跃度** | 高 (Redgate 支持) | 高 |
| **CI/CD 集成** | 优秀 | 优秀 |
| **推荐场景** | 小型团队、SQL 优先 | 大型团队、需要回滚/可视化 |

### 结论

> **推荐 Flyway** (适合当前团队规模):
> - SQL 脚本驱动，开发门槛低
> - 约定优于配置，减少认知负担
> - 社区版功能已满足 90% 需求
> - 回滚可通过编写反向 SQL 脚本实现

---

## 二、Flyway 项目结构

```
db/
├── migrations/
│   ├── V1__initial_schema.sql
│   ├── V2__add_users_table.sql
│   ├── V3__add_orders_table.sql
│   ├── V4__add_indexes.sql
│   └── V5__alter_orders_status.sql
├── seeds/
│   ├── R__seed_users.sql          # Repeatable - 幂等数据填充
│   └── R__seed_products.sql
├── config/
│   ├── flyway-dev.conf
│   ├── flyway-staging.conf
│   └── flyway-prod.conf
├── flyway.conf                     # 默认配置
└── README.md
```

### 命名规范

```
V{version}__{description}.sql      # Versioned migration (执行一次)
R__{description}.sql               # Repeatable migration (内容变更时执行)
```

- 版本号递增: V1, V2, V3... 或 V1.0, V1.1, V2.0...
- 描述用下划线分隔，如 `add_users_table`
- `__` (双下划线) 分隔版本号和描述

---

## 三、迁移脚本示例

### V1__initial_schema.sql

```sql
-- 创建核心业务表
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(32) NOT NULL DEFAULT 'user',
    status VARCHAR(16) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS projects (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    owner_id BIGINT NOT NULL REFERENCES users(id),
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_projects_status ON projects(status);

-- 创建审计触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at
    BEFORE UPDATE ON projects
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### V2__add_tasks_table.sql

```sql
-- 创建任务表
CREATE TABLE tasks (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(256) NOT NULL,
    description TEXT,
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    assignee_id BIGINT REFERENCES users(id),
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    priority VARCHAR(16) NOT NULL DEFAULT 'medium',
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_priority ON tasks(priority);

CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### R__seed_data.sql (幂等填充)

```sql
-- 使用 INSERT ... ON CONFLICT 确保幂等
INSERT INTO users (username, email, password_hash, role)
VALUES 
    ('admin', 'admin@example.com', '$2b$12$...', 'admin'),
    ('dev_user', 'dev@example.com', '$2b$12$...', 'developer')
ON CONFLICT (username) DO UPDATE SET
    email = EXCLUDED.email,
    role = EXCLUDED.role;
```

---

## 四、配置文件

### flyway.conf (默认)

```properties
# 数据库连接 (优先读取环境变量)
flyway.url=jdbc:postgresql://${DB_HOST:-172.23.0.20}:${DB_PORT:-5432}/${DB_NAME:-dev_db}
flyway.user=${DB_USER:-dev_user}
flyway.password=${DB_PASSWORD:-}

# 迁移配置
flyway.locations=filesystem:db/migrations,filesystem:db/seeds
flyway.schemas=public
flyway.table=flyway_schema_history
flyway.validateOnMigrate=true
flyway.outOfOrder=false
flyway.baselineOnMigrate=true
flyway.baselineVersion=0
flyway.baselineDescription=baseline

# SQL 配置
flyway.sqlMigrationPrefix=V
flyway.repeatableSqlMigrationPrefix=R
flyway.sqlMigrationSeparator=__
flyway.sqlMigrationSuffixes=.sql

# 输出
flyway.outputQueryResults=true
```

### docker-compose 集成

```yaml
# docker-compose.migration.yml
version: '3.8'
services:
  flyway:
    image: flyway/flyway:10
    command: migrate
    volumes:
      - ./db/migrations:/flyway/sql
      - ./db/flyway.conf:/flyway/conf/flyway.conf
    environment:
      - FLYWAY_URL=jdbc:postgresql://db:5432/dev_db
      - FLYWAY_USER=dev_user
      - FLYWAY_PASSWORD=${DB_PASSWORD}
    depends_on:
      - db
```

---

## 五、CI/CD 集成

### GitHub Actions

```yaml
# .github/workflows/db-migrations.yml
name: Database Migrations

on:
  push:
    paths:
      - 'db/migrations/**/*.sql'
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Start PostgreSQL
        uses: ikalnytskyi/action-setup-postgres@v6
        with:
          postgres-version: '16'
          username: dev_user
          password: test_pass
          database: test_db
          port: 5432
      
      - name: Run Flyway Migrate
        uses: docker://flyway/flyway:10
        with:
          args: >-
            -url=jdbc:postgresql://localhost:5432/test_db
            -user=dev_user
            -password=test_pass
            -locations=filesystem:db/migrations
            migrate
      
      - name: Validate
        uses: docker://flyway/flyway:10
        with:
          args: >-
            -url=jdbc:postgresql://localhost:5432/test_db
            -user=dev_user
            -password=test_pass
            -locations=filesystem:db/migrations
            validate
```

---

## 六、回滚策略

### Flyway 社区版 (手动回滚)

```sql
-- V6__add_column.sql (正向迁移)
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- V7__rollback_add_column.sql (回滚迁移)
ALTER TABLE users DROP COLUMN IF EXISTS phone;
```

### 回滚脚本规范

```
V{next_version}__rollback_{original_description}.sql
```

### 回滚流程

1. 发现问题 → 停止部署
2. 编写回滚 SQL 脚本
3. 测试回滚脚本 (在测试库执行)
4. 在生产库执行回滚
5. 记录回滚原因到 ADR

---

## 七、最佳实践

### DO

- ✅ 每次迁移只做一件事
- ✅ 迁移脚本不可修改 (一旦执行)
- ✅ 使用事务包裹 DDL (`BEGIN; ... COMMIT;`)
- ✅ 使用 `IF NOT EXISTS` / `IF EXISTS`
- ✅ 先测试再部署
- ✅ 版本号只增不减

### DON'T

- ❌ 不要修改已执行的迁移脚本
- ❌ 不要在迁移中写业务逻辑
- ❌ 不要跳过版本号
- ❌ 不要依赖迁移执行顺序 (除版本号外)
- ❌ 不要在迁移中使用硬编码数据

---

## 八、操作手册

### 常用命令

```bash
# 执行迁移
flyway -configFiles=db/flyway.conf migrate

# 验证迁移状态
flyway -configFiles=db/flyway.conf validate

# 查看迁移历史
flyway -configFiles=db/flyway.conf info

# 清理数据库 (仅开发环境!)
flyway -configFiles=db/flyway.conf clean

# 修复元数据 (跳过失败的迁移)
flyway -configFiles=db/flyway.conf repair

# 创建新迁移
flyway -configFiles=db/flyway.conf -target=V10 migrate
```

### Docker 运行

```bash
docker run --rm \
  -v $(pwd)/db/migrations:/flyway/sql \
  -e FLYWAY_URL=jdbc:postgresql://172.23.0.20:5432/dev_db \
  -e FLYWAY_USER=dev_user \
  -e FLYWAY_PASSWORD=dev_pass_123 \
  flyway/flyway:10 migrate
```

---

## 九、多环境策略

| 环境 | 执行方式 | 验证策略 |
|------|---------|---------|
| **dev** | 自动 (docker-compose up) | validateOnMigrate=true |
| **staging** | CI 自动部署 | validate + dryRun |
| **prod** | 手动审批 + 自动执行 | validate + dryRun + backup |

### dryRun (生产预检)

```bash
flyway -configFiles=db/flyway-prod.conf migrate -dryRunOutput=/tmp/migration.sql
# 审查 /tmp/migration.sql 确认无误后执行
flyway -configFiles=db/flyway-prod.conf migrate
```

---

> 创建时间: 2026-07-27
> 创建者: 研发部高级研发专家
> 状态: 完成

---
> 最后更新: 2026-08-24
> 更新者: 研发部高级研发专家
> 变更: 文档审查 - 添加 Changelog、状态更新
