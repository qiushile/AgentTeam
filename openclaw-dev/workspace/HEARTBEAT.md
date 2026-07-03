# Heartbeat Configuration

## 研发任务进度扫描与接单（工作日早上 9:30 触发）
schedule: "30 9 * * 1-5"
model: "fast"
task: |
  1. 查询 `dev_schema.dev_tasks` 和 `shared.tasks` 检查是否有 PENDING 任务。
  2. 如果有新任务，将其更新为 `IN_PROGRESS` 并汇报初步处理计划。
  3. 检查是否有已完成的任务并准备提交产物。
  4. 无任务时主动执行研发基建、代码质量优化、技术债务清理。

## 每日巡检（每小时）
schedule: "14 * * * *"
task: |
  1. 检查 PostgreSQL 连接（172.23.0.20:5432）。
  2. 查询 shared.tasks 和 dev_schema.dev_tasks 的待处理任务。
  3. 有任务则处理，无任务则 HEARTBEAT_OK。

## 数据库状态
- Host: 172.23.0.20:5432 (Docker 容器，IP 可能漂移)
- Database: dev_db
- Schemas: shared, dev_schema, public
- Tables:
  - shared.tasks
  - shared.collaboration_events
  - dev_schema.dev_tasks
  - dev_schema.dev_projects
  - dev_schema.dev_code_reviews
  - dev_schema.dev_deployments
- Users: dev_user, postgres
