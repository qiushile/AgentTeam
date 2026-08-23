# 任务调度统一查询封装设计

> 设计日期: 2026-08-22  
> 版本: v1.0  
> 状态: 已实现

---

## 一、问题描述

研发部有两个独立的任务表：
- `shared.tasks` — 跨部门协作任务（无 priority 列）
- `dev_schema.dev_tasks` — 研发专属任务（有 priority 列）

需要统一查询接口，屏蔽底层差异，提供一致的 API。

## 二、API 设计

### 2.1 核心接口

```javascript
const scheduler = require('./lib/task-scheduler');

// 1. 获取所有待处理任务（按优先级排序）
const tasks = await scheduler.getPendingTasks();
// 可选：按负责人过滤
const myTasks = await scheduler.getPendingTasks('dev_user');

// 2. 获取超时任务（IN_PROGRESS > 48h）
const overdue = await scheduler.getOverdueTasks();

// 3. 更新任务状态
await scheduler.updateTaskStatus('dev', 1, 'COMPLETED', '任务完成');

// 4. 创建新任务
const id = await scheduler.createDevTask({
  title: '安全审计',
  description: 'Phase 2.2 任务',
  assignee: 'dev_user',
  priority: 'P0'
});

// 5. 获取统计信息
const stats = await scheduler.getTaskStats();
```

### 2.2 返回数据格式

```javascript
{
  source: 'dev' | 'shared',   // 数据来源
  id: number,                 // 任务 ID
  title: string,              // 标题
  description: string | null, // 描述
  assignee: string | null,    // 负责人
  requester: string | null,   // 请求方
  status: 'PENDING' | 'IN_PROGRESS' | 'COMPLETED',
  priority: 'P0' | 'P1' | 'P2' | 'P3',
  result: string | null,      // 结果
  created_at: Date,
  updated_at: Date
}
```

## 三、优先级推导逻辑

`shared.tasks` 无 priority 列，使用 SQL CASE 推导：

```sql
CASE 
  WHEN title ILIKE '%紧急%' OR title ILIKE '%critical%' OR title ILIKE '%p0%' THEN 'P0'
  WHEN title ILIKE '%重要%' OR title ILIKE '%urgent%' OR title ILIKE '%p1%' THEN 'P1'
  WHEN title ILIKE '%低%' OR title ILIKE '%low%' OR title ILIKE '%p3%' THEN 'P3'
  ELSE 'P2'
END as priority
```

## 四、排序逻辑

```
P0 (紧急) → P1 (重要) → P2 (普通) → P3 (低)
              ↓
        同优先级按 created_at 升序
```

## 五、CLI 接口

```bash
node lib/task-scheduler.js list [--assignee=xxx]  # 查询待处理任务
node lib/task-scheduler.js overdue                 # 查询超时任务
node lib/task-scheduler.js stats                   # 查看统计
node lib/task-scheduler.js create "标题" "描述" "负责人" "优先级"
```

## 六、性能指标

| 操作 | 目标 | 实测 | 状态 |
|---|---|---|---|
| 统一查询 | < 500ms | 32-85ms | ✅ |
| 超时检测 | < 200ms | ~50ms | ✅ |
| 统计查询 | < 200ms | ~40ms | ✅ |

## 七、已实现

- ✅ `getPendingTasks(assignee?)` — 统一查询 + 排序
- ✅ `getOverdueTasks()` — 超时检测 (48h 阈值)
- ✅ `updateTaskStatus(source, id, status, result?)` — 状态更新
- ✅ `createDevTask(task)` — 任务创建
- ✅ `getTaskStats()` — 统计信息
- ✅ CLI 接口 (list/overdue/stats/create)

---

> 最后更新: 2026-08-22  
> 实现: `lib/task-scheduler.js`
