const { Client } = require('pg');
async function check() {
  const url = 'postgresql://postgres:root_super_password@postgres-db:5432/openclaw_db';
  const client = new Client({ connectionString: url, connectionTimeoutMillis: 5000 });
  try {
    await client.connect();
    const result = await client.query(`SELECT id, title, status, assignee, priority, created_at FROM shared.tasks WHERE assignee = 'spatial_user' AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') ORDER BY created_at DESC`);
    if (result.rows.length === 0) { console.log('NO_PENDING_TASKS'); }
    else { console.log('PENDING_TASKS_FOUND'); result.rows.forEach(r => console.log(`  [${r.status}] ${r.title} (${r.priority})`)); }
  } catch (e) { console.log('DB_ERROR:', e.message); } finally { await client.end(); }
}
check();
