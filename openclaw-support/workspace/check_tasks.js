const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function checkTasks() {
  try {
    // Check PENDING/IN_PROGRESS tasks
    const result = await pool.query(`
      SELECT id, title, status, priority, assignee, requester, created_at 
      FROM shared.tasks 
      WHERE assignee = 'support_user' 
        AND status IN ('PENDING', 'IN_PROGRESS') 
      ORDER BY 
        CASE priority 
          WHEN 'P0' THEN 1 
          WHEN 'P1' THEN 2 
          WHEN 'P2' THEN 3 
          WHEN 'P3' THEN 4 
        END, 
        created_at ASC 
      LIMIT 10
    `);
    console.log('=== PENDING/IN_PROGRESS TASKS ===');
    console.log(JSON.stringify(result.rows, null, 2));
    
    // Check COMPLETED tasks in last 24 hours
    const completedResult = await pool.query(`
      SELECT id, title, status, priority, assignee, requester, result, created_at, updated_at 
      FROM shared.tasks 
      WHERE assignee = 'support_user' 
        AND status = 'COMPLETED'
        AND updated_at > NOW() - INTERVAL '24 hours'
      ORDER BY updated_at DESC 
      LIMIT 10
    `);
    console.log('\n=== COMPLETED TASKS (last 24h) ===');
    console.log(JSON.stringify(completedResult.rows, null, 2));
    console.log(JSON.stringify(result.rows, null, 2));
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    await pool.end();
  }
}

checkTasks();
