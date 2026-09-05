-- V1__baseline_schema.sql
-- Baseline migration capturing initial database state
-- Created: 2026-09-06
-- Purpose: Establish shared and dev_schema tables for Flyway versioning

-- ============================================
-- Schema: shared (跨部门协作表)
-- ============================================

CREATE SCHEMA IF NOT EXISTS shared;
GRANT ALL ON SCHEMA shared TO dev_user;

-- shared.tasks
CREATE TABLE IF NOT EXISTS shared.tasks (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    assignee TEXT,
    requester TEXT,
    status TEXT NOT NULL DEFAULT 'PENDING',
    priority TEXT NOT NULL DEFAULT 'NORMAL',
    tags TEXT[],
    result TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- shared.collaboration_events
CREATE TABLE IF NOT EXISTS shared.collaboration_events (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES shared.tasks(id),
    from_role TEXT,
    to_role TEXT,
    event_type TEXT,
    payload JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

GRANT ALL ON ALL TABLES IN SCHEMA shared TO dev_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA shared TO dev_user;

-- ============================================
-- Schema: dev_schema (研发部专属表)
-- ============================================

CREATE SCHEMA IF NOT EXISTS dev_schema;
GRANT ALL ON SCHEMA dev_schema TO dev_user;

-- dev_schema.dev_tasks
CREATE TABLE IF NOT EXISTS dev_schema.dev_tasks (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    assignee TEXT DEFAULT 'dev_user',
    requester TEXT,
    status TEXT DEFAULT 'PENDING',
    priority TEXT DEFAULT 'NORMAL',
    tags TEXT[],
    result TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- dev_schema.dev_projects
CREATE TABLE IF NOT EXISTS dev_schema.dev_projects (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'ACTIVE',
    tech_stack TEXT[],
    repo_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- dev_schema.dev_code_reviews
CREATE TABLE IF NOT EXISTS dev_schema.dev_code_reviews (
    id SERIAL PRIMARY KEY,
    task_id INTEGER,
    reviewer TEXT,
    status TEXT DEFAULT 'PENDING',
    comments TEXT,
    score INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- dev_schema.dev_deployments
CREATE TABLE IF NOT EXISTS dev_schema.dev_deployments (
    id SERIAL PRIMARY KEY,
    project_id INTEGER,
    version TEXT,
    environment TEXT,
    status TEXT DEFAULT 'PENDING',
    notes TEXT,
    deployed_at TIMESTAMP DEFAULT NOW()
);

GRANT ALL ON ALL TABLES IN SCHEMA dev_schema TO dev_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA dev_schema TO dev_user;

-- ============================================
-- Indexes (shared)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_tasks_assignee ON shared.tasks(assignee);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON shared.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_requester ON shared.tasks(requester);
CREATE INDEX IF NOT EXISTS idx_collab_events_task ON shared.collaboration_events(task_id);
CREATE INDEX IF NOT EXISTS idx_collab_events_type ON shared.collaboration_events(event_type);

-- ============================================
-- Indexes (dev_schema)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_dev_tasks_assignee ON dev_schema.dev_tasks(assignee);
CREATE INDEX IF NOT EXISTS idx_dev_tasks_status ON dev_schema.dev_tasks(status);
CREATE INDEX IF NOT EXISTS idx_dev_tasks_priority ON dev_schema.dev_tasks(priority);
CREATE INDEX IF NOT EXISTS idx_dev_projects_status ON dev_schema.dev_projects(status);
CREATE INDEX IF NOT EXISTS idx_dev_deployments_env ON dev_schema.dev_deployments(environment);
CREATE INDEX IF NOT EXISTS idx_dev_deployments_status ON dev_schema.dev_deployments(status);
CREATE INDEX IF NOT EXISTS idx_dev_code_reviews_status ON dev_schema.dev_code_reviews(status);
