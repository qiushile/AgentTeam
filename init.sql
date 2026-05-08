CREATE DATABASE openclaw_db;
\c openclaw_db;

-- 1. 安装核心扩展 (用于向量检索和模糊检索)
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. 创建公共 Schema
CREATE SCHEMA shared;

-- ==========================================
-- 建立跨 Agent 协作表
-- ==========================================

-- (1) 任务管理表：用于跨 Agent 分发、追踪和交接任务
CREATE TABLE shared.tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    priority VARCHAR(10) DEFAULT 'P2',       -- 优先级: P0, P1, P2, P3
    tags TEXT[],                             -- 标签数组
    requester VARCHAR(50) NOT NULL,          -- 需求发起方 (必须存真实DB用户名: 如 'pm_user')
    assignee VARCHAR(50) NOT NULL,           -- 接收处理方 (必须存真实DB用户名: 如 'dev_user')
    status VARCHAR(50) DEFAULT 'PENDING',    -- 状态: PENDING, IN_PROGRESS, REVIEW, COMPLETED, FAILED
    result TEXT,                             -- 最终执行结果或交付内容
    context_embedding vector(1536),          -- 任务上下文向量，用于相似任务搜索
    due_date TIMESTAMP,                      -- 截止时间
    parent_task_id INTEGER REFERENCES shared.tasks(id) ON DELETE CASCADE, -- 父任务关联
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP                             -- 任务完成时间
);

-- (2) 协作事件/消息表：跟踪交互过程，如通知用户、确认收到、提交结果等
CREATE TABLE shared.collaboration_events (
    id SERIAL PRIMARY KEY,
    task_id integer REFERENCES shared.tasks(id) ON DELETE CASCADE,
    from_role VARCHAR(50),
    to_role VARCHAR(50),
    event_type VARCHAR(50), -- 事件类型：如 'RECEIVED_ACK', 'NOTIFIED_USER', 'DELIVERED_TO_REQUESTER'
    message TEXT,           -- 具体的通知文本或沟通内容
    description TEXT,       -- 事件描述
    sender VARCHAR(50),     -- 发送方 (冗余字段，便于查询)
    target_agent VARCHAR(50), -- 目标 Agent
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- (3) 共享知识/资产表：跨部门共享方案、文档、模板等
CREATE TABLE shared.knowledge_base (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    department VARCHAR(50) NOT NULL,         -- 来源部门
    category VARCHAR(50),                    -- 知识分类 (如 'PRD', 'API_DOC', 'DESIGN_FILE')
    tags TEXT[],
    content_embedding vector(1536),          -- 内容向量用于语义检索
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- (4) 部门元数据注册表：记录联邦内各组织信息，帮助 Orchestrator 路由
CREATE TABLE shared.department_registry (
    code VARCHAR(50) PRIMARY KEY,            -- 部门代码 (与 username 对应去前缀，如 pm)
    db_username VARCHAR(50) NOT NULL UNIQUE, -- 真实 DB 用户名 (如 pm_user)
    name VARCHAR(100) NOT NULL,              -- 显示名称
    capabilities TEXT,                       -- 职责或能力描述
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 为触发器更新 updated_at
-- ==========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_shared_tasks_modtime
    BEFORE UPDATE ON shared.tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shared_kb_modtime
    BEFORE UPDATE ON shared.knowledge_base
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- 建立性能索引
-- ==========================================
CREATE INDEX idx_tasks_assignee_status ON shared.tasks(assignee, status);
CREATE INDEX idx_tasks_requester ON shared.tasks(requester);
CREATE INDEX idx_tasks_status_priority ON shared.tasks(status, priority);
CREATE INDEX idx_tasks_created_at ON shared.tasks(created_at DESC);
CREATE INDEX idx_events_task_id_created ON shared.collaboration_events(task_id, created_at DESC);
CREATE INDEX idx_kb_department_category ON shared.knowledge_base(department, category);

-- GIN 索引：支持按标签数组高效搜索
CREATE INDEX idx_tasks_tags ON shared.tasks USING gin (tags);
CREATE INDEX idx_kb_tags ON shared.knowledge_base USING gin (tags);

-- 向量索引 (HNSW)
CREATE INDEX idx_kb_embedding ON shared.knowledge_base USING hnsw (content_embedding vector_cosine_ops);
CREATE INDEX idx_tasks_embedding ON shared.tasks USING hnsw (context_embedding vector_cosine_ops);

-- ==========================================
-- 增强通知函数 (Agent 团队运行时依赖)
-- ==========================================

-- 部门级任务通知：按 assignee/requester 推送到对应部门频道
CREATE OR REPLACE FUNCTION shared.notify_task_to_department()
RETURNS TRIGGER AS $$
DECLARE
  payload jsonb;
  assignee_channel TEXT;
  requester_channel TEXT;
BEGIN
  payload = jsonb_build_object(
    'task_id', NEW.id,
    'title', NEW.title,
    'status', NEW.status,
    'priority', NEW.priority,
    'assignee', NEW.assignee,
    'requester', NEW.requester,
    'action', TG_OP,
    'timestamp', NOW()
  );

  IF TG_OP = 'INSERT' THEN
    assignee_channel = 'task_' || REPLACE(NEW.assignee, '_user', '');
    PERFORM pg_notify(assignee_channel, payload::text);
    PERFORM pg_notify('task_channel', payload::text);
  ELSIF TG_OP = 'UPDATE' THEN
    assignee_channel = 'task_' || REPLACE(NEW.assignee, '_user', '');
    PERFORM pg_notify(assignee_channel, payload::text);
    IF NEW.status IN ('COMPLETED', 'FAILED', 'REJECTED', 'CANCELLED') THEN
      requester_channel = 'task_' || REPLACE(NEW.requester, '_user', '');
      IF requester_channel != assignee_channel THEN
        PERFORM pg_notify(requester_channel, payload::text);
      END IF;
    END IF;
    PERFORM pg_notify('task_channel', payload::text);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 协作事件通知：双向推送 + 全局广播
CREATE OR REPLACE FUNCTION shared.notify_collaboration_event()
RETURNS TRIGGER AS $$
DECLARE
  payload jsonb;
BEGIN
  payload = jsonb_build_object(
    'event_id', NEW.id,
    'task_id', NEW.task_id,
    'from_role', NEW.from_role,
    'to_role', NEW.to_role,
    'event_type', NEW.event_type,
    'message', NEW.message,
    'description', NEW.description,
    'action', TG_OP,
    'timestamp', NOW()
  );
  IF NEW.to_role IS NOT NULL THEN
    PERFORM pg_notify('collab_' || REPLACE(NEW.to_role, '_user', ''), payload::text);
  END IF;
  IF NEW.from_role IS NOT NULL AND NEW.from_role != NEW.to_role THEN
    PERFORM pg_notify('collab_' || REPLACE(NEW.from_role, '_user', ''), payload::text);
  END IF;
  PERFORM pg_notify('collab_channel', payload::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER collaboration_event_notifier
  AFTER INSERT ON shared.collaboration_events
  FOR EACH ROW EXECUTE FUNCTION shared.notify_collaboration_event();

-- Agent 间消息通知：点对点 + 全局广播
CREATE OR REPLACE FUNCTION shared.notify_inter_agent_message()
RETURNS TRIGGER AS $$
DECLARE
  payload jsonb;
BEGIN
  payload = jsonb_build_object(
    'message_id', NEW.id,
    'from_agent', NEW.from_agent,
    'to_agent', NEW.to_agent,
    'channel', NEW.channel,
    'msg_type', NEW.msg_type,
    'payload', NEW.payload,
    'ref_task_id', NEW.ref_task_id,
    'action', TG_OP,
    'timestamp', NOW()
  );
  IF NEW.to_agent IS NOT NULL THEN
    PERFORM pg_notify('msg_' || REPLACE(NEW.to_agent, '_user', ''), payload::text);
  END IF;
  PERFORM pg_notify('msg_channel', payload::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 共享产物通知：通知 requester 验收
CREATE OR REPLACE FUNCTION shared.notify_shared_artifact()
RETURNS TRIGGER AS $$
DECLARE
  payload jsonb;
  task_requester TEXT;
  task_assignee TEXT;
BEGIN
  SELECT requester, assignee INTO task_requester, task_assignee
  FROM shared.tasks WHERE id = NEW.task_id;
  payload = jsonb_build_object(
    'artifact_id', NEW.id,
    'task_id', NEW.task_id,
    'owner', NEW.owner,
    'artifact_type', NEW.artifact_type,
    'title', NEW.title,
    'action', TG_OP,
    'timestamp', NOW()
  );
  IF task_requester IS NOT NULL THEN
    PERFORM pg_notify('artifact_' || REPLACE(task_requester, '_user', ''), payload::text);
  END IF;
  IF task_assignee IS NOT NULL AND task_assignee != task_requester THEN
    PERFORM pg_notify('artifact_' || REPLACE(task_assignee, '_user', ''), payload::text);
  END IF;
  PERFORM pg_notify('artifact_channel', payload::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER shared_artifact_notifier
  AFTER INSERT ON shared.shared_artifacts
  FOR EACH ROW EXECUTE FUNCTION shared.notify_shared_artifact();

-- 任务评论通知：通知 assignee 和 requester
CREATE OR REPLACE FUNCTION shared.notify_task_comment()
RETURNS TRIGGER AS $$
DECLARE
  payload jsonb;
  task_assignee TEXT;
  task_requester TEXT;
BEGIN
  SELECT assignee, requester INTO task_assignee, task_requester
  FROM shared.tasks WHERE id = NEW.task_id;
  payload = jsonb_build_object(
    'comment_id', NEW.id,
    'task_id', NEW.task_id,
    'author', NEW.author,
    'content', NEW.content,
    'parent_comment_id', NEW.parent_comment_id,
    'action', TG_OP,
    'timestamp', NOW()
  );
  IF task_assignee IS NOT NULL AND task_assignee != NEW.author THEN
    PERFORM pg_notify('comment_' || REPLACE(task_assignee, '_user', ''), payload::text);
  END IF;
  IF task_requester IS NOT NULL AND task_requester != NEW.author AND task_requester != task_assignee THEN
    PERFORM pg_notify('comment_' || REPLACE(task_requester, '_user', ''), payload::text);
  END IF;
  PERFORM pg_notify('comment_channel', payload::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER task_comment_notifier
  AFTER INSERT ON shared.task_comments
  FOR EACH ROW EXECUTE FUNCTION shared.notify_task_comment();

-- ==========================================
-- 3. 创建所有部门用户及专属 Schema (User is Owner)
-- ==========================================

-- 指挥中枢 (Orchestrator)
CREATE USER orchestrator_user WITH PASSWORD 'orchestrator_pass_123';
CREATE SCHEMA orchestrator_schema AUTHORIZATION orchestrator_user;
ALTER ROLE orchestrator_user SET search_path TO orchestrator_schema, shared, public;

-- 研发部 (Dev)
CREATE USER dev_user WITH PASSWORD 'dev_pass_123';
CREATE SCHEMA dev_schema AUTHORIZATION dev_user;
ALTER ROLE dev_user SET search_path TO dev_schema, shared, public;

-- 产品部 (PM)
CREATE USER pm_user WITH PASSWORD 'pm_pass_123';
CREATE SCHEMA pm_schema AUTHORIZATION pm_user;
ALTER ROLE pm_user SET search_path TO pm_schema, shared, public;

-- 设计部 (Design)
CREATE USER design_user WITH PASSWORD 'design_pass_123';
CREATE SCHEMA design_schema AUTHORIZATION design_user;
ALTER ROLE design_user SET search_path TO design_schema, shared, public;

-- 投放部 (Ads)
CREATE USER ads_user WITH PASSWORD 'ads_pass_123';
CREATE SCHEMA ads_schema AUTHORIZATION ads_user;
ALTER ROLE ads_user SET search_path TO ads_schema, shared, public;

-- 销售部 (Sales)
CREATE USER sales_user WITH PASSWORD 'sales_pass_123';
CREATE SCHEMA sales_schema AUTHORIZATION sales_user;
ALTER ROLE sales_user SET search_path TO sales_schema, shared, public;

-- 市场部 (Marketing)
CREATE USER marketing_user WITH PASSWORD 'marketing_pass_123';
CREATE SCHEMA marketing_schema AUTHORIZATION marketing_user;
ALTER ROLE marketing_user SET search_path TO marketing_schema, shared, public;

-- 项目部 (Project)
CREATE USER project_user WITH PASSWORD 'project_pass_123';
CREATE SCHEMA project_schema AUTHORIZATION project_user;
ALTER ROLE project_user SET search_path TO project_schema, shared, public;

-- 测试部 (QA)
CREATE USER qa_user WITH PASSWORD 'qa_pass_123';
CREATE SCHEMA qa_schema AUTHORIZATION qa_user;
ALTER ROLE qa_user SET search_path TO qa_schema, shared, public;

-- 支撑部 (Support)
CREATE USER support_user WITH PASSWORD 'support_pass_123';
CREATE SCHEMA support_schema AUTHORIZATION support_user;
ALTER ROLE support_user SET search_path TO support_schema, shared, public;

-- 空间部 (Spatial)
CREATE USER spatial_user WITH PASSWORD 'spatial_pass_123';
CREATE SCHEMA spatial_schema AUTHORIZATION spatial_user;
ALTER ROLE spatial_user SET search_path TO spatial_schema, shared, public;

-- 专家组 (Expert)
CREATE USER expert_user WITH PASSWORD 'expert_pass_123';
CREATE SCHEMA expert_schema AUTHORIZATION expert_user;
ALTER ROLE expert_user SET search_path TO expert_schema, shared, public;

-- 游戏部 (Game)
CREATE USER game_user WITH PASSWORD 'game_pass_123';
CREATE SCHEMA game_schema AUTHORIZATION game_user;
ALTER ROLE game_user SET search_path TO game_schema, shared, public;

-- 学术部 (Academic)
CREATE USER academic_user WITH PASSWORD 'academic_pass_123';
CREATE SCHEMA academic_schema AUTHORIZATION academic_user;
ALTER ROLE academic_user SET search_path TO academic_schema, shared, public;

-- 财务部 (Finance)
CREATE USER finance_user WITH PASSWORD 'finance_pass_123';
CREATE SCHEMA finance_schema AUTHORIZATION finance_user;
ALTER ROLE finance_user SET search_path TO finance_schema, shared, public;

-- 人事部 (HR)
CREATE USER hr_user WITH PASSWORD 'hr_pass_123';
CREATE SCHEMA hr_schema AUTHORIZATION hr_user;
ALTER ROLE hr_user SET search_path TO hr_schema, shared, public;

-- 合规部 (Legal)
CREATE USER legal_user WITH PASSWORD 'legal_pass_123';
CREATE SCHEMA legal_schema AUTHORIZATION legal_user;
ALTER ROLE legal_user SET search_path TO legal_schema, shared, public;

-- 供应链部 (Supply Chain)
CREATE USER supply_chain_user WITH PASSWORD 'supply_chain_pass_123';
CREATE SCHEMA supply_chain_schema AUTHORIZATION supply_chain_user;
ALTER ROLE supply_chain_user SET search_path TO supply_chain_schema, shared, public;

-- ==========================================
-- 预填部门注册信息
-- ==========================================
INSERT INTO shared.department_registry (code, db_username, name, capabilities) VALUES
('orchestrator', 'orchestrator_user', '指挥中枢', '意图识别、总体任务拆解、路由分发、资源协调'),
('dev', 'dev_user', '研发部', '全栈系统开发、架构设计、技术实现与代码审查'),
('pm', 'pm_user', '产品部', '市场调研、竞品分析、需求定义、PRD撰写、产品路线图管理'),
('design', 'design_user', '设计部', 'UI/UX设计、交互原型制作、品牌视觉输出、设计资产管理'),
('qa', 'qa_user', '测试部', '自动化测试用例编写、质量保障、缺陷追踪与性能测试'),
('ads', 'ads_user', '投放部', '广告投放策略制定、ROI分析、跨平台账户优化与素材测试'),
('sales', 'sales_user', '销售部', '线索转化、B2B客户跟进、营收增长、销售话术优化'),
('marketing', 'marketing_user', '市场部', '品牌推广、社群运营、内容营销与市场活动策划'),
('project', 'project_user', '项目部', '项目进度推进、资源分配、风险管理与跨部门协调'),
('support', 'support_user', '支撑部', '客户成功、工单处理、用户支持与常见问题知识库维护'),
('spatial', 'spatial_user', '空间部', 'AR/VR/XR 开发、三维资产管理、空间交互设计'),
('expert', 'expert_user', '专家组', '复杂难题攻坚、高管战略参谋、架构审计与行业技术前瞻'),
('game', 'game_user', '游戏部', '游戏引擎(Unity/UE)开发、数值平衡、关卡设计与核心玩法迭代'),
('academic', 'academic_user', '学术部', '学术前沿调研、论文库检索、知识沉淀与学术合规审计'),
('finance', 'finance_user', '财务部', '预算控制、报销审计、财务分析、税务合规及资金调度策略'),
('hr', 'hr_user', '人事部', '人才画像、简历初筛、面试协调、绩效考核管理与企业文化建设'),
('legal', 'legal_user', '合规部', '合同合规审查、知识产权保护、法律风险评估及隐私政策审计'),
('supply-chain', 'supply_chain_user', '供应链部', '供应商管理、物流跟踪、仓储优化与跨国贸易合规');

-- ==========================================
-- 统一授予所有用户对 shared 的基础权限
-- ==========================================
GRANT USAGE ON SCHEMA shared TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;
GRANT CREATE ON SCHEMA shared TO orchestrator_user;

-- 对 shared 表授权
GRANT SELECT, INSERT, UPDATE, DELETE ON shared.tasks TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;
ALTER TABLE shared.tasks OWNER TO orchestrator_user;
GRANT TRIGGER ON shared.tasks TO orchestrator_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON shared.collaboration_events TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;
GRANT TRIGGER ON shared.collaboration_events TO orchestrator_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON shared.knowledge_base TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;
GRANT TRIGGER ON shared.knowledge_base TO orchestrator_user;
GRANT SELECT ON shared.department_registry TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;
GRANT INSERT, UPDATE ON shared.department_registry TO orchestrator_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA shared TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;

-- 团队全貌视图：注册信息 + 在线状态
CREATE VIEW shared.team_directory AS
SELECT 
  d.code,
  d.name AS dept_name,
  d.capabilities,
  d.db_username,
  h.status AS online_status,
  h.last_seen_at,
  h.current_task_id
FROM shared.department_registry d
LEFT JOIN shared.agent_heartbeats h ON d.db_username = h.db_username
WHERE d.is_active = true;
GRANT SELECT ON shared.team_directory TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;

-- 共享产物兼容视图 (部分 Agent 通过此视图访问 shared_artifacts)
CREATE VIEW shared.artifacts AS
SELECT id, task_id, owner, artifact_type, title, content, metadata, created_at, updated_at
FROM shared.shared_artifacts;
GRANT SELECT ON shared.artifacts TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;

-- ==========================================
-- 新增：设置 shared schema 的默认权限
-- 确保未来在 shared 新建的表/序列，其他人也有权限访问
-- ==========================================
ALTER DEFAULT PRIVILEGES IN SCHEMA shared
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO
    orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA shared
    GRANT USAGE, SELECT ON SEQUENCES TO
    orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;

-- 授予 pg_notify 权限，使得各部门都可以发送和监听事件
GRANT EXECUTE ON FUNCTION pg_notify(text, text) TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;

-- ==========================================
-- 开启并设置行级安全 (RLS) 
-- (当前限定每个部门只能看/改自己负责或发起的任务)
-- ==========================================
ALTER TABLE shared.tasks ENABLE ROW LEVEL SECURITY;

-- 允许 orchestrator (指挥中枢) 查看并管理所有任务
CREATE POLICY orchestrator_task_policy ON shared.tasks
    FOR ALL
    TO orchestrator_user
    USING (true)
    WITH CHECK (true);

-- 其他各部门：只能看到 assignee 或 requester 等于当前登录账号名 (CURRENT_USER) 的任务
-- 这要求应用端填写的 assignee 必须是完整的数据库用户名，如 'dev_user'
CREATE POLICY department_task_policy ON shared.tasks
    FOR ALL
    TO dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user
    USING (
        assignee = CURRENT_USER
        OR requester = CURRENT_USER
    )
    WITH CHECK (
        assignee = CURRENT_USER
        OR requester = CURRENT_USER
    );

-- ==========================================
-- 多 Agent 协作增强表 (心跳、消息队列、产物、讨论)
-- ==========================================

-- (5) Agent 心跳表：用于 Orchestrator 判断路由目标是否在线
CREATE TABLE shared.agent_heartbeats (
    db_username VARCHAR(50) PRIMARY KEY,     -- 对应真实 DB 用户名
    last_seen_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'online',     -- online / busy / offline
    current_task_id INTEGER REFERENCES shared.tasks(id),
    metadata JSONB,                          -- 可扩展: 版本号、模型、负载等
    agent_id VARCHAR(50),                    -- Agent 标识符
    last_heartbeat TIMESTAMP,                -- 最近一次心跳时间
    capabilities JSONB,                      -- Agent 能力描述
    current_load INTEGER                     -- 当前负载
);

-- (6) 跨 Agent 异步消息队列：轻量级点对点或广播通信
CREATE TABLE shared.inter_agent_messages (
    id SERIAL PRIMARY KEY,
    from_agent VARCHAR(50) NOT NULL,         -- 发送方 DB 用户名
    to_agent VARCHAR(50),                    -- 接收方 (NULL = 广播)
    channel VARCHAR(50) DEFAULT 'default',   -- 频道 (如 'task_updates', 'alerts')
    msg_type VARCHAR(50) NOT NULL,           -- 类型 (如 'REQUEST', 'RESPONSE', 'NOTIFY')
    payload JSONB NOT NULL,                  -- 消息体
    ref_task_id INTEGER REFERENCES shared.tasks(id),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- (7) 跨部门共享产物表：存放 PRD、设计稿、测试报告等交付物
CREATE TABLE shared.shared_artifacts (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES shared.tasks(id),
    owner VARCHAR(50) NOT NULL,              -- 产出方 DB 用户名
    artifact_type VARCHAR(50) NOT NULL,      -- 类型: 'PRD', 'DESIGN', 'CODE', 'TEST_REPORT'
    title VARCHAR(255) NOT NULL,
    content TEXT,                            -- 正文或存储链接
    metadata JSONB,                          -- 扩展字段 (格式、大小等)
    artifact_url VARCHAR(500),               -- 产物外部链接
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- (8) 任务讨论表：执行过程中的多轮对话和 Feedback
CREATE TABLE shared.task_comments (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES shared.tasks(id) ON DELETE CASCADE,
    author VARCHAR(50) NOT NULL,             -- 评论者 DB 用户名
    content TEXT NOT NULL,
    parent_comment_id INTEGER REFERENCES shared.task_comments(id), -- 楼中楼
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 增强表触发器与索引
-- ==========================================
-- ==========================================
-- 为共享产物更新 update_time
-- ==========================================
CREATE TRIGGER update_shared_artifacts_modtime
    BEFORE UPDATE ON shared.shared_artifacts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 消息提醒触发器 (使用上面定义的增强版 shared.notify_inter_agent_message)
CREATE TRIGGER inter_agent_message_notifier
  AFTER INSERT ON shared.inter_agent_messages
  FOR EACH ROW EXECUTE FUNCTION shared.notify_inter_agent_message();

-- 索引
CREATE INDEX idx_heartbeats_status ON shared.agent_heartbeats(status);
CREATE INDEX idx_messages_to_unread ON shared.inter_agent_messages(to_agent, is_read) WHERE NOT is_read;
CREATE INDEX idx_messages_channel ON shared.inter_agent_messages(channel, created_at DESC);
CREATE INDEX idx_artifacts_task ON shared.shared_artifacts(task_id);
CREATE INDEX idx_artifacts_type ON shared.shared_artifacts(artifact_type);
CREATE INDEX idx_comments_task ON shared.task_comments(task_id, created_at);

-- ==========================================
-- 增强表的基础授权
-- （因有 DEFAULT PRIVILEGES，其实这部分可以省略，
--   但为了向后兼容对现有存在的表显式赋权更为保险）
-- ==========================================
GRANT SELECT, INSERT, UPDATE, DELETE ON shared.agent_heartbeats TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;
GRANT TRIGGER ON shared.agent_heartbeats TO orchestrator_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON shared.inter_agent_messages TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;
GRANT TRIGGER ON shared.inter_agent_messages TO orchestrator_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON shared.shared_artifacts TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;
GRANT TRIGGER ON shared.shared_artifacts TO orchestrator_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON shared.task_comments TO orchestrator_user, dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user;
GRANT TRIGGER ON shared.task_comments TO orchestrator_user;


-- ==========================================
-- 为新表开启行级安全 (RLS)
-- ==========================================

ALTER TABLE shared.agent_heartbeats ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared.inter_agent_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared.shared_artifacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared.task_comments ENABLE ROW LEVEL SECURITY;

-- Orchestrator 完全管理所有新表
CREATE POLICY orchestrator_heartbeats_policy ON shared.agent_heartbeats FOR ALL TO orchestrator_user USING (true) WITH CHECK (true);
CREATE POLICY orchestrator_messages_policy ON shared.inter_agent_messages FOR ALL TO orchestrator_user USING (true) WITH CHECK (true);
CREATE POLICY orchestrator_artifacts_policy ON shared.shared_artifacts FOR ALL TO orchestrator_user USING (true) WITH CHECK (true);
CREATE POLICY orchestrator_comments_policy ON shared.task_comments FOR ALL TO orchestrator_user USING (true) WITH CHECK (true);

-- 部门用户权限：
-- 1. Heartbeats: 可看所有，只能改自己的
CREATE POLICY dept_heartbeats_select ON shared.agent_heartbeats FOR SELECT TO dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user USING (true);
CREATE POLICY dept_heartbeats_modify ON shared.agent_heartbeats FOR ALL TO dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user USING (db_username = CURRENT_USER) WITH CHECK (db_username = CURRENT_USER);

-- 2. Messages: 只能看发给自己的、自己发的，或者广播消息 (to_agent IS NULL)
CREATE POLICY dept_messages_policy ON shared.inter_agent_messages FOR ALL TO dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user USING (from_agent = CURRENT_USER OR to_agent = CURRENT_USER OR to_agent IS NULL) WITH CHECK (from_agent = CURRENT_USER);

-- 3. Artifacts: 任何人都可以查看和评论关联任务的产物，但只有 Owner 能改
CREATE POLICY dept_artifacts_select ON shared.shared_artifacts FOR SELECT TO dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user USING (true);
CREATE POLICY dept_artifacts_modify ON shared.shared_artifacts FOR ALL TO dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user USING (owner = CURRENT_USER) WITH CHECK (owner = CURRENT_USER);

-- 4. Comments: 任何人都可以查看，只有 Author 能改
CREATE POLICY dept_comments_select ON shared.task_comments FOR SELECT TO dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user USING (true);
CREATE POLICY dept_comments_modify ON shared.task_comments FOR ALL TO dev_user, pm_user, design_user, ads_user, sales_user, marketing_user, project_user, qa_user, support_user, spatial_user, expert_user, game_user, academic_user, finance_user, hr_user, legal_user, supply_chain_user USING (author = CURRENT_USER) WITH CHECK (author = CURRENT_USER);

-- ==========================================
-- 审计系统：独立审计数据库 + dblink 触发器
-- 所有 shared.* 表的 INSERT/UPDATE/DELETE 自动记录到 audit_db
-- 团队用户无法访问 audit_db，实现对成员行为的完全追溯
-- ==========================================

-- 创建独立审计数据库（仅 postgres 可连接）
SELECT 'Creating audit_db if not exists...' AS info;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'audit_db') THEN
        CREATE DATABASE audit_db OWNER postgres ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8' TEMPLATE template0;
    END IF;
END $$;

-- 限制 audit_db 访问
REVOKE CONNECT ON DATABASE audit_db FROM PUBLIC;
GRANT CONNECT ON DATABASE audit_db TO postgres;

-- 安装 dblink（跨数据库写入审计记录）
CREATE EXTENSION IF NOT EXISTS dblink;

-- 审计写入函数（SECURITY DEFINER，以 postgres 身份写入 audit_db）
CREATE OR REPLACE FUNCTION public.audit_write(
    p_db_user TEXT, p_operation TEXT, p_schema_name TEXT, p_table_name TEXT,
    p_old_data JSONB, p_new_data JSONB, p_changed_fields TEXT[],
    p_client_addr INET, p_client_port INTEGER
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
        p_old_data, p_new_data, p_changed_fields, addr_str, port_str, 'application_name'
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

-- 审计触发器函数
CREATE OR REPLACE FUNCTION shared.audit_capture() RETURNS TRIGGER AS $$
DECLARE
    changed TEXT[];
    key TEXT;
    old_json JSONB;
    new_json JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        new_json := to_jsonb(NEW);
        PERFORM audit_write(CURRENT_USER::TEXT, 'INSERT', TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT,
            NULL::JSONB, new_json, NULL::TEXT[], inet_client_addr(), inet_client_port());
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        old_json := to_jsonb(OLD); new_json := to_jsonb(NEW);
        changed := ARRAY[]::TEXT[];
        FOR key IN SELECT jsonb_object_keys(old_json) LOOP
            IF old_json->>key IS DISTINCT FROM new_json->>key THEN changed := array_append(changed, key); END IF;
        END LOOP;
        FOR key IN SELECT jsonb_object_keys(new_json) LOOP
            IF NOT old_json ? key THEN changed := array_append(changed, key); END IF;
        END LOOP;
        PERFORM audit_write(CURRENT_USER::TEXT, 'UPDATE', TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT,
            old_json, new_json, changed, inet_client_addr(), inet_client_port());
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        old_json := to_jsonb(OLD);
        PERFORM audit_write(CURRENT_USER::TEXT, 'DELETE', TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT,
            old_json, NULL::JSONB, NULL::TEXT[], inet_client_addr(), inet_client_port());
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 在所有 shared.* 表上挂载审计触发器
DO $$
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN SELECT table_name FROM information_schema.tables WHERE table_schema = 'shared' AND table_type = 'BASE TABLE' LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS audit_%I ON shared.%I', tbl.table_name, tbl.table_name);
        EXECUTE format('CREATE TRIGGER audit_%I AFTER INSERT OR UPDATE OR DELETE ON shared.%I FOR EACH ROW EXECUTE FUNCTION shared.audit_capture()', tbl.table_name, tbl.table_name);
    END LOOP;
END $$;

