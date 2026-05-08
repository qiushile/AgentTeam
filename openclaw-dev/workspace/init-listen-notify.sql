-- =============================================================================
-- PostgreSQL LISTEN/NOTIFY 初始化脚本
-- 用途：为多部门协作提供任务实时通知机制
-- 执行者：数据库管理员 (root/dba)
-- 执行时间：数据库初始化/首次部署时
-- =============================================================================
-- 协议约定 (与 postgres-tool/index.js 对齐):
--   - 扁平 payload 格式: {"type": "EVENT_TYPE", "task_id": N, ...}
--   - 使用 'type' 键名 (不是 'event')
--   - 事件类型: TASK_ASSIGNED, TASK_COMPLETED, TASK_FAILED, TASK_IN_PROGRESS
-- =============================================================================

-- 删除已存在的对象（用于重置/升级）
DROP TRIGGER IF EXISTS tasks_notify_trigger ON shared.tasks;
DROP FUNCTION IF EXISTS notify_task_change();

-- 1. 创建通知函数 (扁平格式, 与 JS postgres-tool 协议对齐)
CREATE OR REPLACE FUNCTION notify_task_change()
RETURNS trigger AS $$
DECLARE
  notify_payload jsonb;
  dept_code TEXT;
BEGIN
  -- 根据操作类型构建通知内容
  IF TG_OP = 'INSERT' THEN
    -- 任务创建 = 任务分配
    notify_payload = jsonb_build_object(
      'type', 'TASK_ASSIGNED',
      'task_id', NEW.id,
      'assignee', NEW.assignee,
      'requester', NEW.requester,
      'title', NEW.title,
      'priority', NEW.priority,
      'timestamp', NOW()
    );
    -- 全局频道
    PERFORM pg_notify('task_channel', notify_payload::text);
    -- 部门专属频道
    dept_code = REPLACE(NEW.assignee, '_user', '');
    PERFORM pg_notify('task_' || dept_code, notify_payload::text);

  ELSIF TG_OP = 'UPDATE' THEN
    -- 状态变更时通知
    IF OLD.status != NEW.status THEN

      -- 任务完成: 通知 requester
      IF NEW.status = 'COMPLETED' THEN
        notify_payload = jsonb_build_object(
          'type', 'TASK_COMPLETED',
          'task_id', NEW.id,
          'assignee', NEW.assignee,
          'requester', NEW.requester,
          'title', NEW.title,
          'result', NEW.result,
          'timestamp', NOW()
        );
        PERFORM pg_notify('task_channel', notify_payload::text);
        dept_code = REPLACE(NEW.requester, '_user', '');
        PERFORM pg_notify('task_' || dept_code, notify_payload::text);

      -- 任务失败/拒绝: 通知 requester
      ELSIF NEW.status = 'FAILED' OR NEW.status = 'REJECTED' THEN
        notify_payload = jsonb_build_object(
          'type', 'TASK_FAILED',
          'task_id', NEW.id,
          'assignee', NEW.assignee,
          'requester', NEW.requester,
          'title', NEW.title,
          'result', NEW.result,
          'timestamp', NOW()
        );
        PERFORM pg_notify('task_channel', notify_payload::text);
        dept_code = REPLACE(NEW.requester, '_user', '');
        PERFORM pg_notify('task_' || dept_code, notify_payload::text);

      -- 任务进行中: 全局通知
      ELSIF NEW.status = 'IN_PROGRESS' THEN
        notify_payload = jsonb_build_object(
          'type', 'TASK_IN_PROGRESS',
          'task_id', NEW.id,
          'assignee', NEW.assignee,
          'requester', NEW.requester,
          'title', NEW.title,
          'timestamp', NOW()
        );
        PERFORM pg_notify('task_channel', notify_payload::text);

      -- 重新分配: 通知新 assignee
      ELSIF NEW.status = 'PENDING' AND (OLD.assignee IS DISTINCT FROM NEW.assignee) THEN
        notify_payload = jsonb_build_object(
          'type', 'TASK_ASSIGNED',
          'task_id', NEW.id,
          'assignee', NEW.assignee,
          'requester', NEW.requester,
          'title', NEW.title,
          'priority', NEW.priority,
          'timestamp', NOW()
        );
        PERFORM pg_notify('task_channel', notify_payload::text);
        dept_code = REPLACE(NEW.assignee, '_user', '');
        PERFORM pg_notify('task_' || dept_code, notify_payload::text);
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. 绑定触发器到任务表 (带递归保护)
CREATE TRIGGER tasks_notify_trigger
AFTER INSERT OR UPDATE ON shared.tasks
FOR EACH ROW
WHEN (PG_TRIGGER_DEPTH() = 0)
EXECUTE FUNCTION notify_task_change();

-- =============================================================================
-- 测试通知
-- =============================================================================
-- SELECT pg_notify('task_channel', '{"type": "TEST", "task_id": 0}');
-- UPDATE shared.tasks SET status = status WHERE id = 1;
-- SELECT * FROM pg_catalog.pg_stat_activity WHERE query LIKE '%LISTEN%';
-- =============================================================================
