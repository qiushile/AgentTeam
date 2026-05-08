import pkg from 'pg';
const { Pool } = pkg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 1,
  idleTimeoutMillis: 1000,
  connectionTimeoutMillis: 5000
});

async function checkTasks() {
  let client;
  
  try {
    client = await pool.connect();
    
    // 先检查表结构
    const columnsResult = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_schema = 'shared' AND table_name = 'tasks'
      ORDER BY ordinal_position
    `);
    
    console.log('TABLE_COLUMNS:');
    columnsResult.rows.forEach(col => {
      console.log(`  ${col.column_name} (${col.data_type})`);
    });
    console.log('');
    
    // 查询分配给 ads_user 的未完成任务
    const tasksResult = await client.query(`
      SELECT id, title, description, assignee, requester, status, priority, created_at, due_date
      FROM shared.tasks
      WHERE assignee = 'ads_user' AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED')
      ORDER BY 
        CASE priority 
          WHEN 'HIGH' THEN 1 
          WHEN 'MEDIUM' THEN 2 
          WHEN 'LOW' THEN 3 
          ELSE 4 
        END,
        created_at ASC
    `);
    
    if (tasksResult.rows.length === 0) {
      console.log('NO_PENDING_TASKS');
    } else {
      console.log('PENDING_TASKS_FOUND');
      tasksResult.rows.forEach(row => {
        console.log(JSON.stringify({
          task_id: row.task_id,
          title: row.title,
          description: row.description,
          status: row.status,
          priority: row.priority,
          requester: row.requester,
          created_at: row.created_at,
          due_date: row.due_date
        }));
      });
    }
    
  } catch (e) {
    console.error('ERROR:', e.message);
  } finally {
    if (client) client.release();
    await pool.end();
  }
}

checkTasks();
