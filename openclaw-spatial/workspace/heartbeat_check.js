const { Client } = require('pg');

async function heartbeatCheck() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL
  });

  try {
    await client.connect();
    
    const result = await client.query(`
      SELECT id, title, description, status, assignee, priority, 
             created_at, due_date, result
      FROM shared.tasks 
      WHERE assignee = 'spatial_user' 
        AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED')
      ORDER BY 
        CASE priority 
          WHEN 'HIGH' THEN 1 
          WHEN 'MEDIUM' THEN 2 
          WHEN 'LOW' THEN 3 
          ELSE 4 
        END,
        created_at DESC
    `);

    if (result.rows.length === 0) {
      console.log('NO_PENDING_TASKS');
    } else {
      console.log('PENDING_TASKS:');
      result.rows.forEach((row, i) => {
        console.log(`--- Task ${i + 1} ---`);
        console.log(`ID: ${row.id}`);
        console.log(`Title: ${row.title}`);
        console.log(`Status: ${row.status}`);
        console.log(`Priority: ${row.priority}`);
        console.log(`Description: ${row.description}`);
        console.log(`Created: ${row.created_at}`);
        console.log(`Due: ${row.due_date}`);
        console.log('');
      });
    }

  } catch (err) {
    console.error('Database error:', err.message);
  } finally {
    await client.end();
  }
}

heartbeatCheck();
