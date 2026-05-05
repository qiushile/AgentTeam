-- =====================================================
-- 审计系统 Step 1: 创建 audit_db 数据库 + 限制访问
-- 执行: docker exec openclaw-postgres psql -U postgres -f scripts/audit-setup-1-create-db.sql
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'audit_db') THEN
        CREATE DATABASE audit_db
            OWNER = postgres
            ENCODING = 'UTF8'
            LC_COLLATE = 'en_US.utf8'
            LC_CTYPE = 'en_US.utf8'
            TEMPLATE = template0;
        RAISE NOTICE 'audit_db created';
    ELSE
        RAISE NOTICE 'audit_db already exists, skipping';
    END IF;
END $$;

-- 严格限制 audit_db 访问：只有 postgres 可以连接
REVOKE CONNECT ON DATABASE audit_db FROM PUBLIC;
GRANT CONNECT ON DATABASE audit_db TO postgres;

SELECT 'Step 1 complete: audit_db created and access restricted' AS info;
