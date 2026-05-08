const { Client } = require('pg');

// Parse DATABASE_URL
const dbUrl = new URL(process.env.DATABASE_URL);
const client = new Client({
  host: dbUrl.hostname,
  port: dbUrl.port || 5432,
  database: dbUrl.pathname.slice(1),
  user: dbUrl.username,
  password: dbUrl.password
});

async function query() {
  try {
    await client.connect();
    const result = await client.query(`
      SELECT * 
      FROM shared.tasks 
      WHERE assignee = 'design_user' 
      AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') 
      ORDER BY created_at DESC
    `);
    
    // Update TODO tasks to IN_PROGRESS
    for (const task of result.rows) {
      if (task.status === 'TODO' || task.status === 'PENDING') {
        await client.query(`
          UPDATE shared.tasks 
          SET status = 'IN_PROGRESS', updated_at = NOW()
          WHERE id = $1
        `, [task.id]);
        console.log(`Updated task ${task.id} to IN_PROGRESS`);
      }
    }
    
    console.log(JSON.stringify(result.rows, null, 2));
    await client.end();
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

query();
