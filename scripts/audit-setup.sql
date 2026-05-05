-- =====================================================
-- 审计系统安装脚本 (part 1: 创建 audit_db)
-- 执行: docker exec openclaw-postgres psql -U postgres -f /workspace/scripts/audit-setup.sql
-- =====================================================

-- 1. 创建审计专用数据库
SELECT '=== Step 1: Creating audit_db ===' AS info;

SELECT 'Database audit_db already exists, skipping' AS info
WHERE EXISTS (SELECT 1 FROM pg_database WHERE datname = 'audit_db');

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'audit_db') THEN
        CREATE DATABASE audit_db
            OWNER = postgres
            ENCODING = 'UTF8'
            LC_COLLATE = 'en_US.utf8'
            LC_CTYPE = 'en_US.utf8'
            TEMPLATE = template0;
    END IF;
END $$;

-- 2. 严格限制 audit_db 访问权限
-- 撤销所有用户的连接权限
REVOKE CONNECT ON DATABASE audit_db FROM PUBLIC;
-- 只允许 postgres 连接（sentinel 通过 postgres 查询）
GRANT CONNECT ON DATABASE audit_db TO postgres;

-- 3. 在 audit_db 中创建审计 schema 和表
\c audit_db

-- 创建审计 schema
CREATE SCHEMA IF NOT EXISTS audit;

-- 审计日志主表
CREATE TABLE IF NOT EXISTS audit.log (
    id              BIGSERIAL PRIMARY KEY,
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    db_user         VARCHAR(64) NOT NULL,              -- 执行操作的数据库用户
    operation       VARCHAR(10) NOT NULL,               -- INSERT / UPDATE / DELETE
    schema_name     VARCHAR(64) NOT NULL DEFAULT 'shared',
    table_name      VARCHAR(128) NOT NULL,
    old_data        JSONB,                              -- UPDATE/DELETE 时的旧值
    new_data        JSONB,                              -- INSERT/UPDATE 时的新值
    changed_fields  TEXT[],                             -- UPDATE 时哪些字段被修改了
    client_addr     INET,                               -- 客户端 IP
    client_port     INTEGER,                            -- 客户端端口
    application_name VARCHAR(128),                      -- 应用标识
    CONSTRAINT chk_operation CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

-- 按时间分区（月度分区表，避免单表过大）
-- 先创建当前月和接下来 2 个月的分区
DO $$
DECLARE
    start_date DATE;
    end_date DATE;
    partition_name TEXT;
    i INT;
BEGIN
    FOR i IN 0..5 LOOP
        start_date := DATE_TRUNC('month', CURRENT_DATE) + (i * INTERVAL '1 month');
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'audit_log_' || TO_CHAR(start_date, 'YYYY_MM');

        -- 检查分区是否已存在
        IF NOT EXISTS (
            SELECT 1 FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relname = partition_name AND n.nspname = 'audit'
        ) THEN
            EXECUTE format(
                'CREATE TABLE audit.%I PARTITION OF audit.log
                 FOR VALUES FROM (%L) TO (%L)',
                partition_name,
                start_date,
                end_date
            );
        END IF;
    END LOOP;
END $$;

-- 将 log 表改为分区表（如果已存在非分区表则跳过）
-- 注意：PostgreSQL 16 支持声明式分区
-- 如果 audit.log 已存在且不是分区表，需要特殊处理

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_audit_log_occurred_at ON audit.log(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_db_user ON audit.log(db_user);
CREATE INDEX IF NOT EXISTS idx_audit_log_table ON audit.log(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_operation ON audit.log(operation);
CREATE INDEX IF NOT EXISTS idx_audit_log_user_table ON audit.log(db_user, table_name, occurred_at DESC);

-- 创建审计专用视图（方便查询）
CREATE OR REPLACE VIEW audit.changes_summary AS
SELECT
    DATE_TRUNC('hour', occurred_at) AS hour,
    db_user,
    table_name,
    operation,
    COUNT(*) AS change_count
FROM audit.log
WHERE occurred_at > NOW() - INTERVAL '24 hours'
GROUP BY 1, 2, 3, 4
ORDER BY 1 DESC, 5 DESC;

-- 撤销所有用户对 audit schema 的访问
REVOKE ALL ON SCHEMA audit FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA audit FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA audit FROM PUBLIC;

-- 只有 postgres 可以读写审计数据
GRANT ALL ON SCHEMA audit TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA audit TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA audit TO postgres;
GRANT ALL ON SCHEMA audit TO sentinel_user;
GRANT ALL ON ALL TABLES IN SCHEMA audit TO sentinel_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA audit TO sentinel_user;

-- 创建审计数据清理函数（保留 90 天）
CREATE OR REPLACE FUNCTION audit.cleanup_old_data(retention_days INT DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM audit.log
    WHERE occurred_at < NOW() - (retention_days || ' days')::INTERVAL;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建审计查询函数
CREATE OR REPLACE FUNCTION audit.get_user_changes(
    p_db_user VARCHAR,
    p_from TIMESTAMPTZ DEFAULT NOW() - INTERVAL '24 hours',
    p_to TIMESTAMPTZ DEFAULT NOW(),
    p_table VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id BIGINT,
    occurred_at TIMESTAMPTZ,
    db_user VARCHAR,
    operation VARCHAR,
    table_name VARCHAR,
    old_data JSONB,
    new_data JSONB,
    changed_fields TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT l.id, l.occurred_at, l.db_user, l.operation,
           l.table_name, l.old_data, l.new_data, l.changed_fields
    FROM audit.log l
    WHERE l.db_user = p_db_user
      AND l.occurred_at BETWEEN p_from AND p_to
      AND (p_table IS NULL OR l.table_name = p_table)
    ORDER BY l.occurred_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT '=== audit_db setup complete ===' AS info;
