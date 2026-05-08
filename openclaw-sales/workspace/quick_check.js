const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

async function quickCheck() {
  try {
    const client = await pool.connect();

    // 快速检查待处理任务
    const result = await client.query(`
      SELECT id, title, status, priority, created_at
      FROM shared.tasks
      WHERE assignee = 'sales_user' AND status = 'PENDING'
      ORDER BY created_at DESC
    `);

    console.log(`待处理任务数量: ${result.rows.length}`);
    if (result.rows.length > 0) {
      result.rows.forEach(task => {
        console.log(`ID ${task.id}: ${task.title} [${task.priority}]`);
      });
    } else {
      console.log('无待处理任务');
    }

    client.release();
  } catch (err) {
    console.error('检查失败:', err.message);
  } finally {
    await pool.end();
  }
}

quickCheck();