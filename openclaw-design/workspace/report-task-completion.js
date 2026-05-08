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

async function report() {
  try {
    await client.connect();
    
    // Add collaboration event for RECEIVED_ACK
    await client.query(`
      INSERT INTO shared.collaboration_events 
      (task_id, from_role, to_role, event_type, message, created_at)
      VALUES ($1, $2, $3, $4, $5, NOW())
    `, [46, 'design_user', 'orchestrator_user', 'RECEIVED_ACK', '设计部已接单，开始处理任务']);
    
    // Add collaboration event for task 28
    await client.query(`
      INSERT INTO shared.collaboration_events 
      (task_id, from_role, to_role, event_type, message, created_at)
      VALUES ($1, $2, $3, $4, $5, NOW())
    `, [28, 'design_user', 'orchestrator_user', 'RECEIVED_ACK', '设计部已接单并更新为IN_PROGRESS']);
    
    // Add report about Feishu limitation
    await client.query(`
      INSERT INTO shared.collaboration_events 
      (task_id, from_role, to_role, event_type, message, created_at)
      VALUES ($1, $2, $3, $4, $5, NOW())
    `, [46, 'design_user', 'design_user', 'STATUS_UPDATE', '尝试向创始人发送飞书私聊时遇到open_id跨应用限制。任务状态：已查询2项待处理任务，已将任务28从TODO更新为IN_PROGRESS。']);
    
    console.log('Collaboration events recorded successfully');
    await client.end();
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

report();
