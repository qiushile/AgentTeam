# Heartbeat Configuration

## 数据库连接回退策略
1. 尝试配置的主机:端口 (172.23.0.20:5432)
2. 若连接被拒绝，扫描 172.23.0.1-254:5432 寻找开放端口
3. 若找到新 IP，更新本文档中的 Host 配置
4. 若 3 次扫描（90 分钟）均未找到，通过飞书告警创始人

## 研发任务进度扫描与接单（工作日早上 9:30 触发）
schedule: "30 9 * * 1-5"
model: "fast"
task: |
  1. 查询 `dev_schema.dev_tasks` 和 `shared.tasks` 检查是否有 PENDING 任务。
  2. 如果有新任务，将其更新为 `IN_PROGRESS` 并汇报初步处理计划。
  3. 检查是否有已完成的任务并准备提交产物。

## 空闲行为优先级（无 PENDING 任务时严格执行，替代 HEARTBEAT_OK）
1. **检查 dev_schema 是否存在**：不存在则立即创建（含 4 张表 + 权限）
2. **检查 DEV_ROADMAP_2026H2.md**：有未完成项则创建为 dev_tasks 并执行
3. **产出技术文档**：数据库策略、代码规范、CI/CD、监控、安全、性能等
4. **向创始人飞书汇报**已完成的工作，并询问下一步方向
5. **仅当以上 1-4 全部确认完成后**，回复 HEARTBEAT_OK

## 空闲降级策略
- 无任务超过 24 小时：降为每 4 小时巡检一次
- 无任务超过 72 小时：降为每日巡检一次
- 降级前通过飞书通知创始人
- 新任务到达时立即恢复每 30 分钟巡检

## 自主工作授权
你有权：
- 在 dev_schema.dev_tasks 中创建 assignee='dev_user' 的任务
- 无需等待批准即可执行这些任务
- 完成后通过飞书异步汇报
- 优先级：安全 > 基础设施 > 文档 > 优化

## 每日巡检（每小时）
schedule: "14 * * * *"
task: |
  1. 检查 PostgreSQL 连接（172.23.0.20:5432）。
  2. 查询 shared.tasks 和 dev_schema.dev_tasks 的待处理任务。
  3. 有任务则处理，无任务则执行「空闲行为优先级」。

## 数据库状态
- Host: 读取 `.dev-config.json` 中的 `db_host` 和 `db_port`
- 当前值: 172.23.0.20:5432 (Docker 容器，IP 可能漂移)
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

## 首次运行初始化
若 dev_schema 不存在，执行：
```sql
CREATE SCHEMA IF NOT EXISTS dev_schema;
GRANT ALL ON SCHEMA dev_schema TO dev_user;
CREATE TABLE IF NOT EXISTS dev_schema.dev_tasks (...);
CREATE TABLE IF NOT EXISTS dev_schema.dev_projects (...);
CREATE TABLE IF NOT EXISTS dev_schema.dev_code_reviews (...);
CREATE TABLE IF NOT EXISTS dev_schema.dev_deployments (...);
GRANT ALL ON ALL TABLES IN SCHEMA dev_schema TO dev_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA dev_schema TO dev_user;
```
