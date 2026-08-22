#!/usr/bin/env node
/**
 * Task Scheduler Library (task-scheduler.js)
 * 
 * 功能:
 * 1. 统一查询 shared.tasks + dev_schema.dev_tasks
 * 2. 任务优先级调度 (P0 > P1 > P2 > P3)
 * 3. 超时告警 (IN_PROGRESS > 48h 自动标记)
 * 4. 周期性巡检任务创建
 * 
 * 使用: 
 *   const scheduler = require('./lib/task-scheduler');
 *   const tasks = await scheduler.getPendingTasks();
 *   const overdue = await scheduler.getOverdueTasks();
 * 
 * 验收标准:
 * - 查询响应 < 500ms
 * - 超时任务 100% 被标记
 * - 优先级排序正确
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// ==================== 配置 ====================

const CONFIG_PATH = path.resolve(__dirname, '..', '.dev-config.json');
const LOG_PATH = path.resolve(__dirname, '..', 'logs', 'task-scheduler.log');

const PRIORITY_ORDER = { 'P0': 0, 'P1': 1, 'P2': 2, 'P3': 3, 'HIGH': 0, 'MEDIUM': 1, 'LOW': 2, 'CRITICAL': 0 };
const OVERDUE_THRESHOLD_HOURS = 48;

// ==================== 日志 ====================

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function log(message, level = 'INFO') {
  const timestamp = new Date().toISOString();
  const line = `[${timestamp}] [${level}] ${message}`;
  console.log(line);
  ensureDir(path.dirname(LOG_PATH));
  fs.appendFileSync(LOG_PATH, line + '\n');
}

// ==================== 数据库连接 ====================

function loadConfig() {
  try {
    const data = fs.readFileSync(CONFIG_PATH, 'utf8');
    return JSON.parse(data);
  } catch (e) {
    log(`Failed to load config: ${e.message}`, 'ERROR');
    return null;
  }
}

async function getDbClient() {
  const config = loadConfig();
  if (!config) throw new Error('Cannot load DB config');
  
  const password = process.env[config.env_var_password] || '';
  return new Client({
    host: config.db_host,
    port: config.db_port,
    database: config.db_name,
    user: config.db_user,
    password
  });
}

// ==================== 统一任务查询 ====================

/**
 * 获取所有待处理任务 (shared.tasks + dev_schema.dev_tasks)
 * 按优先级排序 (P0 > P1 > P2 > P3)，同优先级按创建时间
 * 
 * 注意: shared.tasks 没有 priority 列，使用 CASE 从标题推导优先级
 * 
 * @param {string|null} assignee - 可选，过滤指定负责人
 * @returns {Array} 排序后的任务列表
 */
async function getPendingTasks(assignee = null) {
  const client = await getDbClient();
  const startTime = Date.now();
  
  try {
    await client.connect();
    
    // 查询 shared.tasks (无 priority 列，从标题推导)
    const sharedParams = [];
    let sharedWhere = "WHERE status IN ('PENDING', 'IN_PROGRESS')";
    if (assignee) {
      sharedWhere += ' AND assignee = $1';
      sharedParams.push(assignee);
    }
    
    const sharedResult = await client.query(`
      SELECT 
        'shared' as source, id, title, description, assignee, requester, status, result, created_at, updated_at,
        CASE 
          WHEN title ILIKE '%紧急%' OR title ILIKE '%critical%' OR title ILIKE '%p0%' THEN 'P0'
          WHEN title ILIKE '%重要%' OR title ILIKE '%urgent%' OR title ILIKE '%p1%' THEN 'P1'
          WHEN title ILIKE '%低%' OR title ILIKE '%low%' OR title ILIKE '%p3%' THEN 'P3'
          ELSE 'P2'
        END as priority
      FROM shared.tasks 
      ${sharedWhere}
      ORDER BY created_at
    `, sharedParams);
    
    // 查询 dev_schema.dev_tasks (有 priority 列)
    const devParams = [];
    let devWhere = "WHERE status IN ('PENDING', 'IN_PROGRESS')";
    if (assignee) {
      devWhere += ' AND assignee = $1';
      devParams.push(assignee);
    }
    
    const devResult = await client.query(`
      SELECT 
        'dev' as source, id, title, description, assignee, requester, status, result, created_at, updated_at,
        COALESCE(priority, 'P2') as priority
      FROM dev_schema.dev_tasks 
      ${devWhere}
      ORDER BY created_at
    `, devParams);
    
    // 合并 + 按优先级排序
    const allTasks = [...sharedResult.rows, ...devResult.rows];
    allTasks.sort((a, b) => {
      const pA = PRIORITY_ORDER[a.priority] ?? 2;
      const pB = PRIORITY_ORDER[b.priority] ?? 2;
      if (pA !== pB) return pA - pB;
      return new Date(a.created_at) - new Date(b.created_at);
    });
    
    const elapsed = Date.now() - startTime;
    log(`Query completed: ${allTasks.length} tasks found (${elapsed}ms)`);
    
    if (elapsed > 500) {
      log(`⚠️ Query took ${elapsed}ms (target: <500ms)`, 'WARN');
    }
    
    return allTasks;
  } finally {
    try { await client.end(); } catch {}
  }
}

// ==================== 超时告警 ====================

/**
 * 获取超时任务 (IN_PROGRESS > 48h 无更新)
 * 
 * @returns {Array} 超时任务列表
 */
async function getOverdueTasks() {
  const client = await getDbClient();
  
  try {
    await client.connect();
    
    const threshold = `NOW() - INTERVAL '${OVERDUE_THRESHOLD_HOURS} hours'`;
    
    // shared.tasks 超时
    const sharedOverdue = await client.query(`
      SELECT 'shared' as source, id, title, assignee, status, updated_at, created_at,
             EXTRACT(EPOCH FROM (NOW() - updated_at)) / 3600 as hours_since_update
      FROM shared.tasks 
      WHERE status = 'IN_PROGRESS' AND updated_at < ${threshold}
      ORDER BY updated_at
    `);
    
    // dev_schema.dev_tasks 超时
    const devOverdue = await client.query(`
      SELECT 'dev' as source, id, title, assignee, status, updated_at, created_at,
             EXTRACT(EPOCH FROM (NOW() - updated_at)) / 3600 as hours_since_update
      FROM dev_schema.dev_tasks 
      WHERE status = 'IN_PROGRESS' AND updated_at < ${threshold}
      ORDER BY updated_at
    `);
    
    const overdue = [...sharedOverdue.rows, ...devOverdue.rows];
    
    if (overdue.length > 0) {
      log(`⚠️ Found ${overdue.length} overdue task(s):`, 'WARN');
      overdue.forEach(t => {
        log(`  - [${t.source}] #${t.id} "${t.title}" (${t.assignee}) - ${Math.round(t.hours_since_update)}h since update`, 'WARN');
      });
    } else {
      log(`No overdue tasks found`);
    }
    
    return overdue;
  } finally {
    try { await client.end(); } catch {}
  }
}

// ==================== 任务状态更新 ====================

/**
 * 更新任务状态
 * 
 * @param {string} source - 'shared' 或 'dev'
 * @param {number} taskId - 任务 ID
 * @param {string} status - 新状态
 * @param {string|null} result - 可选，结果描述
 */
async function updateTaskStatus(source, taskId, status, result = null) {
  const client = await getDbClient();
  
  try {
    await client.connect();
    
    const table = source === 'shared' ? 'shared.tasks' : 'dev_schema.dev_tasks';
    
    if (result) {
      await client.query(`
        UPDATE ${table} SET status = $1, result = $2, updated_at = NOW() WHERE id = $3
      `, [status, result, taskId]);
    } else {
      await client.query(`
        UPDATE ${table} SET status = $1, updated_at = NOW() WHERE id = $2
      `, [status, taskId]);
    }
    
    log(`Task #${taskId} (${source}) updated to ${status}`);
  } finally {
    try { await client.end(); } catch {}
  }
}

// ==================== 任务创建 ====================

/**
 * 创建 dev_schema.dev_tasks 任务
 * 
 * @param {Object} task - 任务对象 { title, description, assignee, priority, tags }
 * @returns {number} 新任务 ID
 */
async function createDevTask(task) {
  const client = await getDbClient();
  
  try {
    await client.connect();
    
    const result = await client.query(`
      INSERT INTO dev_schema.dev_tasks (title, description, assignee, priority, status, created_at, updated_at)
      VALUES ($1, $2, $3, $4, 'PENDING', NOW(), NOW())
      RETURNING id
    `, [task.title, task.description || null, task.assignee || 'dev_user', task.priority || 'P2']);
    
    const newId = result.rows[0].id;
    log(`Created dev_task #${newId}: "${task.title}" (priority: ${task.priority || 'P2'})`);
    return newId;
  } finally {
    try { await client.end(); } catch {}
  }
}

// ==================== 统计信息 ====================

/**
 * 获取任务统计信息
 * 
 * @returns {Object} 统计对象
 */
async function getTaskStats() {
  const client = await getDbClient();
  
  try {
    await client.connect();
    
    const shared = await client.query(`
      SELECT status, count(*) FROM shared.tasks GROUP BY status
    `);
    
    const dev = await client.query(`
      SELECT status, count(*) FROM dev_schema.dev_tasks GROUP BY status
    `);
    
    const stats = {
      shared: {},
      dev: {},
      total: 0,
      pending: 0,
      in_progress: 0,
      completed: 0
    };
    
    shared.rows.forEach(r => {
      stats.shared[r.status] = parseInt(r.count);
      stats.total += parseInt(r.count);
      if (r.status === 'PENDING') stats.pending += parseInt(r.count);
      if (r.status === 'IN_PROGRESS') stats.in_progress += parseInt(r.count);
      if (r.status === 'COMPLETED') stats.completed += parseInt(r.count);
    });
    
    dev.rows.forEach(r => {
      stats.dev[r.status] = parseInt(r.count);
      stats.total += parseInt(r.count);
      if (r.status === 'PENDING') stats.pending += parseInt(r.count);
      if (r.status === 'IN_PROGRESS') stats.in_progress += parseInt(r.count);
      if (r.status === 'COMPLETED') stats.completed += parseInt(r.count);
    });
    
    return stats;
  } finally {
    try { await client.end(); } catch {}
  }
}

// ==================== 导出 ====================

module.exports = {
  getPendingTasks,
  getOverdueTasks,
  updateTaskStatus,
  createDevTask,
  getTaskStats,
  PRIORITY_ORDER,
  OVERDUE_THRESHOLD_HOURS
};

// ==================== CLI 模式 ====================

if (require.main === module) {
  const command = process.argv[2];
  
  async function runCli() {
    switch (command) {
      case 'list':
        const assignee = process.argv[3] ? process.argv[3].replace('--assignee=', '') : null;
        const tasks = await getPendingTasks(assignee);
        console.log(`\nPending/In-Progress Tasks (${tasks.length}):`);
        console.log('─'.repeat(80));
        tasks.forEach(t => {
          console.log(`  [${t.source}] #${t.id} [${t.priority}] ${t.status.padEnd(12)} ${t.assignee || 'unassigned'} | ${t.title}`);
        });
        break;
        
      case 'overdue':
        const overdue = await getOverdueTasks();
        console.log(`\nOverdue Tasks (${overdue.length}):`);
        console.log('─'.repeat(80));
        overdue.forEach(t => {
          console.log(`  [${t.source}] #${t.id} ${t.status.padEnd(12)} ${t.assignee || 'unassigned'} | ${Math.round(t.hours_since_update)}h | ${t.title}`);
        });
        break;
        
      case 'stats':
        const stats = await getTaskStats();
        console.log('\nTask Statistics:');
        console.log('─'.repeat(40));
        console.log(`  Total:       ${stats.total}`);
        console.log(`  Pending:     ${stats.pending}`);
        console.log(`  In Progress: ${stats.in_progress}`);
        console.log(`  Completed:   ${stats.completed}`);
        console.log('\n  Shared tasks:', JSON.stringify(stats.shared));
        console.log('  Dev tasks:   ', JSON.stringify(stats.dev));
        break;
        
      case 'create':
        const title = process.argv[3];
        if (!title) {
          console.log('Usage: node task-scheduler.js create "task title" [description] [assignee] [priority]');
          process.exit(1);
        }
        const id = await createDevTask({
          title,
          description: process.argv[4] || null,
          assignee: process.argv[5] || 'dev_user',
          priority: process.argv[6] || 'P2'
        });
        console.log(`Created task #${id}`);
        break;
        
      default:
        console.log('Task Scheduler CLI');
        console.log('');
        console.log('Usage:');
        console.log('  node task-scheduler.js list [--assignee=xxx]  - List pending tasks');
        console.log('  node task-scheduler.js overdue                 - List overdue tasks');
        console.log('  node task-scheduler.js stats                   - Show task statistics');
        console.log('  node task-scheduler.js create "title" [desc] [assignee] [priority]');
        process.exit(0);
    }
  }
  
  runCli().catch(e => {
    console.error('Error:', e.message);
    process.exit(1);
  });
}
