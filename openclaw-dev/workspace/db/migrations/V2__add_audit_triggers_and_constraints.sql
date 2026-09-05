-- V2__add_audit_triggers_and_constraints.sql
-- Add audit triggers, check constraints, and helper functions
-- Created: 2026-09-06

-- ============================================
-- Helper function: auto-update updated_at
-- ============================================
CREATE OR REPLACE FUNCTION dev_schema.fn_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION shared.fn_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Triggers: auto-update updated_at columns
-- ============================================

-- shared.tasks
DROP TRIGGER IF EXISTS trg_tasks_updated_at ON shared.tasks;
CREATE TRIGGER trg_tasks_updated_at
    BEFORE UPDATE ON shared.tasks
    FOR EACH ROW
    EXECUTE FUNCTION shared.fn_update_updated_at();

-- dev_schema.dev_tasks
DROP TRIGGER IF EXISTS trg_dev_tasks_updated_at ON dev_schema.dev_tasks;
CREATE TRIGGER trg_dev_tasks_updated_at
    BEFORE UPDATE ON dev_schema.dev_tasks
    FOR EACH ROW
    EXECUTE FUNCTION dev_schema.fn_update_updated_at();

-- dev_schema.dev_projects
DROP TRIGGER IF EXISTS trg_dev_projects_updated_at ON dev_schema.dev_projects;
CREATE TRIGGER trg_dev_projects_updated_at
    BEFORE UPDATE ON dev_schema.dev_projects
    FOR EACH ROW
    EXECUTE FUNCTION dev_schema.fn_update_updated_at();

-- ============================================
-- Check constraints: status enums
-- ============================================

ALTER TABLE shared.tasks
    ADD CONSTRAINT chk_tasks_status
    CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'BLOCKED'));

ALTER TABLE shared.tasks
    ADD CONSTRAINT chk_tasks_priority
    CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT'));

ALTER TABLE dev_schema.dev_tasks
    ADD CONSTRAINT chk_dev_tasks_status
    CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'BLOCKED'));

ALTER TABLE dev_schema.dev_tasks
    ADD CONSTRAINT chk_dev_tasks_priority
    CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT'));

ALTER TABLE dev_schema.dev_projects
    ADD CONSTRAINT chk_dev_projects_status
    CHECK (status IN ('ACTIVE', 'PAUSED', 'ARCHIVED', 'CANCELLED'));

ALTER TABLE dev_schema.dev_code_reviews
    ADD CONSTRAINT chk_code_review_status
    CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'REJECTED'));

ALTER TABLE dev_schema.dev_code_reviews
    ADD CONSTRAINT chk_code_review_score
    CHECK (score IS NULL OR (score >= 1 AND score <= 10));

ALTER TABLE dev_schema.dev_deployments
    ADD CONSTRAINT chk_deployment_status
    CHECK (status IN ('PENDING', 'DEPLOYING', 'SUCCESS', 'FAILED', 'ROLLED_BACK'));

ALTER TABLE dev_schema.dev_deployments
    ADD CONSTRAINT chk_deployment_env
    CHECK (environment IN ('dev', 'staging', 'prod'));

-- ============================================
-- Foreign key: dev_code_reviews -> dev_tasks
-- ============================================
-- Note: Using ON DELETE SET NULL to preserve review history
ALTER TABLE dev_schema.dev_code_reviews
    ADD CONSTRAINT fk_code_review_task
    FOREIGN KEY (task_id) REFERENCES dev_schema.dev_tasks(id) ON DELETE SET NULL;

-- ============================================
-- Foreign key: dev_deployments -> dev_projects
-- ============================================
ALTER TABLE dev_schema.dev_deployments
    ADD CONSTRAINT fk_deployment_project
    FOREIGN KEY (project_id) REFERENCES dev_schema.dev_projects(id) ON DELETE SET NULL;

-- ============================================
-- Foreign key: collaboration_events -> tasks
-- ============================================
ALTER TABLE shared.collaboration_events
    ADD CONSTRAINT fk_collab_event_task
    FOREIGN KEY (task_id) REFERENCES shared.tasks(id) ON DELETE CASCADE;
