# 任务调度系统设计文档

> 制定日期: 2026-08-22  
> 版本: v1.0  
> 状态: 已实现

---

## 一、系统概述

任务调度系统是研发部 Agent 的核心组件，负责统一管理 `shared.tasks`（跨部门协作表）和 `dev_schema.dev_tasks`（研发部专属表）的任务生命周期，实现优先级调度、超时告警和自动化巡检。

## 二、需求分析

### 2.1 功能性需求

| 需求ID | 功能 | 优先级 | 说明 |
|---|---|---|---|
| FR-01 | 统一任务查询 | P0 | 同时查询 shared.tasks + dev_schema.dev_tasks |
| FR-02 | 优先级调度 | P0 | P0 > P1 > P2 > P3 自动排序 |
| FR-03 | 超时告警 | P1 | IN_PROGRESS > 48h 自动标记并告警 |
| FR-04 | 任务状态更新 | P0 | 支持 PENDING/IN_PROGRESS/COMPLETED 状态流转 |
| FR-05 | 任务创建 | P1 | 支持创建 dev_schema.dev_tasks |
| FR-06 | 统计信息 | P2 | 按状态分组统计，计算完成率 |

### 2.2 非功能性需求

| 需求ID | 指标 | 目标值 | 验收方式 |
|---|---|---|---|
| NFR-01 | 查询响应时间 | < 500ms | 日志记录每次查询耗时 |
| NFR-02 | 超时检测覆盖率 | 100% | 所有 IN_PROGRESS > 48h 任务被标记 |
| NFR-03 | 优先级准确率 | 100% | P0 任务始终排在最前 |
| NFR-04 | 可用性 | ≥ 99.9% | 依赖 DB 连接可用性 |

## 三、架构设计

### 3.1 模块结构

```
lib/task-scheduler.js
├── getPendingTasks(assignee?)    → 统一查询 + 优先级排序
├── getOverdueTasks()             → 超时检测 (>48h)
├── updateTaskStatus(...)         → 状态更新
├── createDevTask(...)            → 任务创建
├── getTaskStats()                → 统计信息
└── CLI 模式 (list/stats/overdue/create)
```

### 3.2 数据流

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│  shared     │     │  Task Scheduler  │     │  优先级排序   │
│  .tasks     │────▶│  统一查询         │────▶│  P0>P1>P2>P3 │
└─────────────┘     │                  │     └──────────────┘
┌─────────────┐     │  (合并两表结果)   │
│  dev_schema │────▶│                  │
│  .dev_tasks │     └──────────────────┘
└─────────────┘
```

### 3.3 优先级推导规则

`shared.tasks` 无 `priority` 列，使用标题关键词推导：

| 关键词模式 | 推导优先级 |
|---|---|
| 紧急、critical、p0 | P0 |
| 重要、urgent、p1 | P1 |
| 低、low、p3 | P3 |
| 其他（默认） | P2 |

`dev_schema.dev_tasks` 有 `priority` 列，直接使用。

## 四、API 设计

### 4.1 getPendingTasks(assignee?)

**功能**: 获取所有待处理任务，按优先级排序

**参数**:
- `assignee` (可选): 过滤指定负责人

**返回**:
```javascript
[
  {
    source: 'dev',          // 数据来源
    id: 1,
    title: '安全审计',
    description: 'Phase 2.2 任务',
    assignee: 'dev_user',
    status: 'PENDING',
    priority: 'P0',
    created_at: '2026-08-22T00:00:00.000Z',
    updated_at: '2026-08-22T00:00:00.000Z'
  }
]
```

**查询逻辑**:
1. 分别查询 `shared.tasks` 和 `dev_schema.dev_tasks`
2. `shared.tasks` 使用 CASE 语句推导优先级
3. 合并结果集
4. 按 `PRIORITY_ORDER[priority]` 排序，同优先级按 `created_at` 排序

### 4.2 getOverdueTasks()

**功能**: 获取 IN_PROGRESS > 48h 的超时任务

**返回**:
```javascript
[
  {
    source: 'dev',
    id: 5,
    title: 'DB 迁移',
    assignee: 'dev_user',
    hours_since_update: 72.5
  }
]
```

### 4.3 updateTaskStatus(source, taskId, status, result?)

**功能**: 更新任务状态

**参数**:
- `source`: 'shared' 或 'dev'
- `taskId`: 任务 ID
- `status`: 'PENDING' | 'IN_PROGRESS' | 'COMPLETED'
- `result` (可选): 结果描述

### 4.4 createDevTask(task)

**功能**: 创建 dev_schema.dev_tasks 任务

**参数**:
```javascript
{
  title: 'OpenTelemetry 部署',
  description: 'Phase 3.1 任务',
  assignee: 'dev_user',
  priority: 'P1'
}
```

### 4.5 getTaskStats()

**功能**: 获取任务统计信息

**返回**:
```javascript
{
  shared: { PENDING: 2, COMPLETED: 10 },
  dev: { PENDING: 1, IN_PROGRESS: 3, COMPLETED: 13 },
  total: 29,
  pending: 3,
  in_progress: 3,
  completed: 23
}
```

## 五、CLI 接口

```bash
# 列出所有待处理任务
node lib/task-scheduler.js list

# 列出指定负责人的任务
node lib/task-scheduler.js list --assignee=dev_user

# 查看超时任务
node lib/task-scheduler.js overdue

# 查看任务统计
node lib/task-scheduler.js stats

# 创建新任务
node lib/task-scheduler.js create "任务标题" "描述" "dev_user" "P1"
```

## 六、性能指标

| 操作 | 目标 | 实测 | 状态 |
|---|---|---|---|
| 统一查询 | < 500ms | 32-85ms | ✅ |
| 统计查询 | < 200ms | 40ms | ✅ |
| 超时检测 | < 300ms | 50ms | ✅ |

## 七、扩展计划

| 功能 | 优先级 | 说明 |
|---|---|---|
| 任务依赖链 | P2 | A 完成后自动触发 B |
| 定时任务创建 | P2 | 周期性自动创建巡检任务 |
| 任务标签筛选 | P2 | 基于 tags 字段筛选 |
| 批量操作 | P3 | 批量更新状态/优先级 |
| Web Dashboard | P3 | 可视化任务看板 |

---

> 最后更新: 2026-08-22  
> 状态: ✅ 已完成实现
