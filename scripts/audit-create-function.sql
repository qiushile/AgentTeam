CREATE EXTENSION IF NOT EXISTS dblink;

CREATE OR REPLACE FUNCTION public.audit_write(
    p_db_user TEXT,
    p_operation TEXT,
    p_schema_name TEXT,
    p_table_name TEXT,
    p_old_data JSONB,
    p_new_data JSONB,
    p_changed_fields TEXT[],
    p_client_addr INET,
    p_client_port INTEGER
) RETURNS VOID AS $func$
DECLARE
    conn_str TEXT := 'host=127.0.0.1 port=5432 dbname=audit_db user=postgres password=root_super_password';
    sql TEXT;
    addr_str TEXT;
    port_str TEXT;
BEGIN
    addr_str := CASE WHEN p_client_addr IS NULL THEN 'NULL' ELSE quote_literal(p_client_addr::text) END;
    port_str := CASE WHEN p_client_port IS NULL THEN 'NULL' ELSE p_client_port::text END;

    sql := format(
        'INSERT INTO audit.log (db_user, operation, schema_name, table_name, old_data, new_data, changed_fields, client_addr, client_port, application_name) VALUES (%L, %L, %L, %L, %L, %L, %L, %s, %s, current_setting(%L, true))',
        p_db_user, p_operation, p_schema_name, p_table_name,
        p_old_data, p_new_data, p_changed_fields,
        addr_str, port_str, 'application_name'
    );

    PERFORM dblink_exec(conn_str, sql);
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'audit_write failed: %', SQLERRM;
END;
$func$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION public.audit_write(TEXT,TEXT,TEXT,TEXT,JSONB,JSONB,TEXT[],INET,INTEGER) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.audit_write(TEXT,TEXT,TEXT,TEXT,JSONB,JSONB,TEXT[],INET,INTEGER)
    TO orchestrator_user, dev_user, pm_user, design_user, ads_user,
       sales_user, marketing_user, project_user, qa_user, support_user,
       spatial_user, expert_user, game_user, academic_user, finance_user,
       hr_user, legal_user, supply_chain_user;
