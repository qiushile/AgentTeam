-- =====================================================
-- 审计系统 Step 3: 在 openclaw_db 中安装 dblink + 审计触发器
-- 执行: docker exec openclaw-postgres psql -U postgres -d openclaw_db -f scripts/audit-setup-3-triggers.sql
-- =====================================================

-- 1. 安装 dblink 扩展（用于跨数据库写入 audit_db）
CREATE EXTENSION IF NOT EXISTS dblink;

-- 2. 创建审计写入函数 (SECURITY DEFINER，以 postgres 身份连接 audit_db)
-- 此函数通过 dblink 将变更记录写入 audit_db.audit.log
-- team 用户看不到此函数的定义（密码隐藏）
CREATE OR REPLACE FUNCTION audit_write(
    p_db_user TEXT,
    p_operation TEXT,
    p_schema_name TEXT,
    p_table_name TEXT,
    p_old_data JSONB,
    p_new_data JSONB,
    p_changed_fields TEXT[]
) RETURNS VOID AS $$
BEGIN
    PERFORM dblink_exec(
        'host=127.0.0.1 port=5432 dbname=audit_db user=postgres password=root_super_password',
        format(
            $$INSERT INTO audit.log (db_user, operation, schema_name, table_name, old_data, new_data, changed_fields, client_addr, client_port, application_name)
              VALUES (%L, %L, %L, %L, %L, %L, %L, inet_client_addr(), inet_client_port(), current_setting('application_name', true))$$,
            p_db_user, p_operation, p_schema_name, p_table_name, p_old_data, p_new_data, p_changed_fields
        )
    );
EXCEPTION WHEN OTHERS THEN
    -- 审计写入失败不阻断业务操作，仅记录警告
    RAISE WARNING 'audit_write failed: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 撤销 public 执行权限
REVOKE EXECUTE ON FUNCTION audit_write(TEXT, TEXT, TEXT, TEXT, JSONB, JSONB, TEXT[]) FROM PUBLIC;

-- 3. 创建触发器函数
CREATE OR REPLACE FUNCTION shared.audit_capture() RETURNS TRIGGER AS $$
DECLARE
    changed TEXT[];
    key TEXT;
    old_json JSONB;
    new_json JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        new_json := to_jsonb(NEW);
        PERFORM audit_write(
            CURRENT_USER, 'INSERT', TG_TABLE_SCHEMA, TG_TABLE_NAME,
            NULL, new_json, NULL
        );
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        old_json := to_jsonb(OLD);
        new_json := to_jsonb(NEW);
        -- 计算变更字段
        changed := ARRAY[]::TEXT[];
        FOR key IN SELECT jsonb_object_keys(old_json) LOOP
            IF old_json->>key IS DISTINCT FROM new_json->>key THEN
                changed := array_append(changed, key);
            END IF;
        END LOOP;
        -- 检查新增字段
        FOR key IN SELECT jsonb_object_keys(new_json) LOOP
            IF NOT old_json ? key THEN
                changed := array_append(changed, key);
            END IF;
        END LOOP;

        PERFORM audit_write(
            CURRENT_USER, 'UPDATE', TG_TABLE_SCHEMA, TG_TABLE_NAME,
            old_json, new_json, changed
        );
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        old_json := to_jsonb(OLD);
        PERFORM audit_write(
            CURRENT_USER, 'DELETE', TG_TABLE_SCHEMA, TG_TABLE_NAME,
            old_json, NULL, NULL
        );
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 4. 授予所有 team 用户审计函数执行权限
GRANT EXECUTE ON FUNCTION audit_write(TEXT, TEXT, TEXT, TEXT, JSONB, JSONB, TEXT[])
    TO orchestrator_user, dev_user, pm_user, design_user, ads_user,
       sales_user, marketing_user, project_user, qa_user, support_user,
       spatial_user, expert_user, game_user, academic_user, finance_user,
       hr_user, legal_user, supply_chain_user;

-- 5. 在所有 shared.* 表上挂载审计触发器
-- 注意：只挂载到实际表上（不包括视图）

-- (1) tasks
DROP TRIGGER IF EXISTS audit_tasks ON shared.tasks;
CREATE TRIGGER audit_tasks
    AFTER INSERT OR UPDATE OR DELETE ON shared.tasks
    FOR EACH ROW EXECUTE FUNCTION shared.audit_capture();

-- (2) collaboration_events
DROP TRIGGER IF EXISTS audit_collaboration_events ON shared.collaboration_events;
CREATE TRIGGER audit_collaboration_events
    AFTER INSERT OR UPDATE OR DELETE ON shared.collaboration_events
    FOR EACH ROW EXECUTE FUNCTION shared.audit_capture();

-- (3) knowledge_base
DROP TRIGGER IF EXISTS audit_knowledge_base ON shared.knowledge_base;
CREATE TRIGGER audit_knowledge_base
    AFTER INSERT OR UPDATE OR DELETE ON shared.knowledge_base
    FOR EACH ROW EXECUTE FUNCTION shared.audit_capture();

-- (4) department_registry
DROP TRIGGER IF EXISTS audit_department_registry ON shared.department_registry;
CREATE TRIGGER audit_department_registry
    AFTER INSERT OR UPDATE OR DELETE ON shared.department_registry
    FOR EACH ROW EXECUTE FUNCTION shared.audit_capture();

-- (5) agent_heartbeats
DROP TRIGGER IF EXISTS audit_agent_heartbeats ON shared.agent_heartbeats;
CREATE TRIGGER audit_agent_heartbeats
    AFTER INSERT OR UPDATE OR DELETE ON shared.agent_heartbeats
    FOR EACH ROW EXECUTE FUNCTION shared.audit_capture();

-- (6) inter_agent_messages
DROP TRIGGER IF EXISTS audit_inter_agent_messages ON shared.inter_agent_messages;
CREATE TRIGGER audit_inter_agent_messages
    AFTER INSERT OR UPDATE OR DELETE ON shared.inter_agent_messages
    FOR EACH ROW EXECUTE FUNCTION shared.audit_capture();

-- (7) shared_artifacts
DROP TRIGGER IF EXISTS audit_shared_artifacts ON shared.shared_artifacts;
CREATE TRIGGER audit_shared_artifacts
    AFTER INSERT OR UPDATE OR DELETE ON shared.shared_artifacts
    FOR EACH ROW EXECUTE FUNCTION shared.audit_capture();

-- (8) task_comments
DROP TRIGGER IF EXISTS audit_task_comments ON shared.task_comments;
CREATE TRIGGER audit_task_comments
    AFTER INSERT OR UPDATE OR DELETE ON shared.task_comments
    FOR EACH ROW EXECUTE FUNCTION shared.audit_capture();

SELECT 'Step 3 complete: dblink installed, triggers attached to all shared tables' AS info;
