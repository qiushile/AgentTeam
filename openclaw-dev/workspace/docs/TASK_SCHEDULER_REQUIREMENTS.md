# 任务调度系统需求分析

> 制定日期: 2026-08-22  
> 版本: v1.0  
> 状态: 初稿完成

---

## 一、背景

研发部当前存在两个独立的任务表：
- **shared.tasks** — 跨部门协作任务（shared schema，无 priority 列）
- **dev_schema.dev_tasks** — 研发部专属任务（dev_schema，有 priority 列）

需要统一查询、优先级排序和自动化调度。

## 二、核心需求

### 2.1 统一任务查询 (FR-01)
- 同时查询 `shared.tasks` 和 `dev_schema.dev_tasks`
- 合并结果集，按优先级排序 (P0 > P1 > P2 > P3)
- 支持按负责人过滤
- **查询响应 < 500ms**

### 2.2 优先级推导 (FR-02)
`shared.tasks` 无 priority 列，需从标题关键词推导：
- 紧急/critical/p0 → P0
- 重要/urgent/p1 → P1
- 低/low/p3 → P3
- 其他 → P2 (默认)

### 2.3 超时告警 (FR-03)
- IN_PROGRESS 状态超过 48 小时自动标记
- 记录告警日志
- 可选飞书通知（需凭证）

### 2.4 任务状态管理 (FR-04)
- 支持 PENDING → IN_PROGRESS → COMPLETED 状态流转
- 更新 result 字段
- 自动更新 updated_at

### 2.5 统计信息 (FR-05)
- 按状态分组统计
- 按来源 (shared/dev) 分组统计
- 计算完成率

## 三、非功能需求

| 指标 | 目标 | 验收方式 |
|---|---|---|
| 查询响应时间 | < 500ms | 日志记录每次查询耗时 |
| 超时检测准确率 | 100% | 所有超时任务被标记 |
| 可用性 | ≥ 99.9% | 依赖 DB 可用性 |

## 四、现有实现验证

已通过 `lib/task-scheduler.js` 实现以下功能：
- ✅ `getPendingTasks(assignee?)` — 统一查询 + 排序 (实测 32-85ms)
- ✅ `getOverdueTasks()` — 超时检测
- ✅ `updateTaskStatus(source, taskId, status, result?)` — 状态更新
- ✅ `createDevTask(task)` — 任务创建
- ✅ `getTaskStats()` — 统计信息
- ✅ CLI 接口: list / overdue / stats / create

## 五、后续扩展

| 功能 | 优先级 | 说明 |
|---|---|---|
| 任务依赖链 | P2 | A 完成后自动触发 B |
| 定时任务创建 | P2 | 周期性自动创建巡检任务 |
| 任务标签筛选 | P2 | 基于 tags 字段筛选 |
| Web Dashboard | P3 | 可视化任务看板 |

---

> 最后更新: 2026-08-22  
> 实现: `lib/task-scheduler.js`
