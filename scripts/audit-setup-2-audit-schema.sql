-- =====================================================
-- 审计系统 Step 2: 在 audit_db 中创建审计 schema、表和函数
-- 执行: docker exec openclaw-postgres psql -U postgres -d audit_db -f scripts/audit-setup-2-audit-schema.sql
-- =====================================================

-- 创建审计 schema
CREATE SCHEMA IF NOT EXISTS audit;

-- 审计日志表（记录所有 DML 变更）
CREATE TABLE IF NOT EXISTS audit.log (
    id              BIGSERIAL PRIMARY KEY,
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    db_user         VARCHAR(64) NOT NULL,
    operation       VARCHAR(10) NOT NULL,
    schema_name     VARCHAR(64) NOT NULL DEFAULT 'shared',
    table_name      VARCHAR(128) NOT NULL,
    old_data        JSONB,
    new_data        JSONB,
    changed_fields  TEXT[],
    client_addr     INET,
    client_port     INTEGER,
    application_name VARCHAR(128),
    CONSTRAINT chk_operation CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_audit_occurred_at ON audit.log(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_db_user ON audit.log(db_user);
CREATE INDEX IF NOT EXISTS idx_audit_table ON audit.log(table_name, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_operation ON audit.log(operation);
CREATE INDEX IF NOT EXISTS idx_audit_user_table ON audit.log(db_user, table_name, occurred_at DESC);

-- 撤销所有用户访问（仅 postgres 可读写）
REVOKE ALL ON SCHEMA audit FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA audit FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA audit FROM PUBLIC;

GRANT USAGE ON SCHEMA audit TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA audit TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA audit TO postgres;

-- 数据清理函数（默认保留 90 天）
CREATE OR REPLACE FUNCTION audit.cleanup_old_data(retention_days INT DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM audit.log WHERE occurred_at < NOW() - (retention_days || ' days')::INTERVAL;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 按用户查询变更
CREATE OR REPLACE FUNCTION audit.get_user_changes(
    p_db_user VARCHAR,
    p_from TIMESTAMPTZ DEFAULT NOW() - INTERVAL '24 hours',
    p_to TIMESTAMPTZ DEFAULT NOW(),
    p_table VARCHAR DEFAULT NULL
) RETURNS TABLE (
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

-- 最近变更概览
CREATE OR REPLACE VIEW audit.recent_changes AS
SELECT id, occurred_at, db_user, operation, table_name, changed_fields
FROM audit.log
WHERE occurred_at > NOW() - INTERVAL '1 hour'
ORDER BY occurred_at DESC;

SELECT 'Step 2 complete: audit schema, tables, and functions created in audit_db' AS info;
