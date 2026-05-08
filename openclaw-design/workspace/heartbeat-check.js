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

async function check() {
  try {
    await client.connect();
    
    // 1. Check for new design tasks
    const tasksResult = await client.query(`
      SELECT id, title, status, priority, created_at 
      FROM shared.tasks 
      WHERE assignee = 'design_user' 
      AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') 
      ORDER BY created_at DESC
    `);
    
    // 2. Check for artifacts needing iteration
    const artifactsResult = await client.query(`
      SELECT * 
      FROM shared.shared_artifacts 
      LIMIT 5
    `);
    
    console.log('=== PENDING TASKS ===');
    console.log(JSON.stringify(tasksResult.rows, null, 2));
    
    console.log('\n=== ARTIFACTS NEEDING ATTENTION ===');
    console.log(JSON.stringify(artifactsResult.rows, null, 2));
    
    await client.end();
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

check();
