const { Client } = require('pg');
async function check() {
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  try {
    await client.connect();
    
    const tasks = await client.query(`
      SELECT id, title, assignee, status, due_date, priority,
             EXTRACT(DAY FROM NOW() - updated_at) as days_since_update,
             EXTRACT(DAY FROM due_date - NOW()) as days_until_due
      FROM shared.tasks
      WHERE status IN ('IN_PROGRESS', 'PENDING')
      ORDER BY due_date ASC
    `);
    
    if (tasks.rows.length === 0) {
      console.log('NO_TASKS');
    } else {
      for (const t of tasks.rows) {
        console.log(`#${t.id} | ${t.title} | ${t.assignee} | ${t.status} | Due: ${t.due_date} | Until: ${parseFloat(t.days_until_due).toFixed(1)}d | Updated: ${parseFloat(t.days_since_update).toFixed(1)}d ago`);
      }
    }
    
    const events = await client.query(`
      SELECT event_type, from_role, message, created_at
      FROM shared.collaboration_events
      WHERE created_at > NOW() - INTERVAL '2 hours'
      ORDER BY created_at DESC
    `);
    
    if (events.rows.length > 0) {
      console.log('\nRecent events:');
      for (const e of events.rows) {
        console.log(`[${e.created_at}] ${e.event_type} from ${e.from_role}: ${(e.message || '').substring(0, 80)}`);
      }
    }
  } catch(e) { console.error(e.message); }
  finally { await client.end(); }
}
check();
