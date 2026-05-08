const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function getIncompleteTasks() {
  try {
    await client.connect();

    // 查询分配给 sales_user 的未完成任务
    const tasksQuery = `
      SELECT id, title, description, status, priority, created_at, updated_at
      FROM shared.tasks
      WHERE assignee = 'sales_user'
      AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED')
      ORDER BY priority DESC, created_at ASC
    `;

    const result = await client.query(tasksQuery);
    console.log(JSON.stringify(result.rows, null, 2));

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

getIncompleteTasks();