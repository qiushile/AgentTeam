#!/usr/bin/env node
/**
 * dev-task.js - Task management helper
 * Usage:
 *   node dev-task.js list                    - List all tasks
 *   node dev-task.js pending                 - List pending tasks
 *   node dev-task.js start <id>              - Set task to IN_PROGRESS
 *   node dev-task.js done <id> "<result>"    - Set task to COMPLETED with result
 *   node dev-task.js create "<title>" "<desc>" [priority] - Create new task
 */
const { Client } = require('/home/node/.openclaw/extensions/postgres-tool/node_modules/pg');
const fs = require('fs');
const path = require('path');

const configPath = path.join(__dirname, '..', '.dev-config.json');
const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));

const action = process.argv[2];

async function getClient() {
  const c = new Client({
    host: config.db_host,
    port: config.db_port,
    user: config.db_user,
    password: process.env[config.env_var_password],
    database: config.db_name,
    connectionTimeoutMillis: 3000,
  });
  await c.connect();
  return c;
}

(async () => {
  const c = await getClient();
  try {
    if (action === 'list' || action === 'pending') {
      const where = action === 'pending' ? "WHERE status NOT IN ('COMPLETED','FAILED','CANCELLED')" : '';
      const r = await c.query(`SELECT id, title, priority, status FROM dev_schema.dev_tasks ${where} ORDER BY id`);
      r.rows.forEach(row => console.log(`[${row.id}] ${row.title} [${row.priority}/${row.status}]`));
      console.log(`\nTotal: ${r.rows.length} task(s)`);
    } else if (action === 'start') {
      const id = process.argv[3];
      await c.query(`UPDATE dev_schema.dev_tasks SET status='IN_PROGRESS', updated_at=NOW() WHERE id=${id}`);
      console.log(`Task ${id} => IN_PROGRESS`);
    } else if (action === 'done') {
      const id = process.argv[3];
      const result = process.argv.slice(4).join(' ');
      await c.query(`UPDATE dev_schema.dev_tasks SET status='COMPLETED', result='${result}', updated_at=NOW() WHERE id=${id}`);
      console.log(`Task ${id} => COMPLETED`);
    } else if (action === 'create') {
      const title = process.argv[3] || 'Untitled';
      const desc = process.argv[4] || '';
      const priority = process.argv[5] || 'NORMAL';
      const r = await c.query(`INSERT INTO dev_schema.dev_tasks (title, description, assignee, priority) VALUES ('${title}', '${desc}', 'dev_user', '${priority}') RETURNING id`);
      console.log(`Created task ${r.rows[0].id}: ${title}`);
    } else {
      console.log('Usage: dev-task.js [list|pending|start <id>|done <id> "<result>"|create "<title>" "<desc>" [priority]]');
    }
  } finally {
    await c.end();
  }
})();
