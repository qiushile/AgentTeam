const { Client } = require('pg');

async function checkTasks() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL
  });

  try {
    await client.connect();
    
    const result = await client.query(`
      SELECT id, title, status, priority, created_at, due_date
      FROM shared.tasks 
      WHERE assignee = 'spatial_user' 
        AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED')
      ORDER BY 
        CASE priority WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 WHEN 'LOW' THEN 3 ELSE 4 END,
        created_at DESC
    `);

    if (result.rows.length === 0) {
      console.log('NO_PENDING_TASKS');
    } else {
      result.rows.forEach((row, i) => {
        console.log(`Task ${i+1}: [${row.priority}] ${row.title} (${row.status}) Due: ${row.due_date}`);
      });
    }

  } catch (err) {
    console.error('DB Error:', err.message);
  } finally {
    await client.end();
  }
}

checkTasks();
