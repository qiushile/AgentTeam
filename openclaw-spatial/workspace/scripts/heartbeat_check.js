const {Client} = require('pg');

async function run() {
  const c = new Client({connectionString: process.env.DATABASE_URL});
  await c.connect();
  
  try {
    // Query 1: Get tasks for spatial_user
    const tasksResult = await c.query(
      `SELECT id, title, description, status, assignee, requester, priority, created_at, updated_at 
       FROM shared.tasks 
       WHERE assignee = 'spatial_user' 
       ORDER BY created_at DESC 
       LIMIT 10`
    );
    
    // Query 2: Get spatial_schema tables
    const tablesResult = await c.query(
      `SELECT tablename FROM pg_tables WHERE schemaname = 'spatial_schema'`
    );
    
    // Query 3: Check collaboration events
    const eventsResult = await c.query(
      `SELECT id, event_type, from_role, to_role, task_id, message, created_at 
       FROM shared.collaboration_events 
       WHERE to_role = 'spatial_user' 
       ORDER BY created_at DESC 
       LIMIT 5`
    );
    
    console.log('=== TASKS FOR SPATIAL_USER ===');
    console.log(JSON.stringify(tasksResult.rows, null, 2));
    
    console.log('\n=== SPATIAL SCHEMA TABLES ===');
    console.log(JSON.stringify(tablesResult.rows, null, 2));
    
    console.log('\n=== RECENT COLLABORATION EVENTS ===');
    console.log(JSON.stringify(eventsResult.rows, null, 2));
    
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    await c.end();
  }
}

run();
