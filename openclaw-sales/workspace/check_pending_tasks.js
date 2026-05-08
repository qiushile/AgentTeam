const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function getPendingTasks() {
  try {
    await client.connect();

    // 查询分配给 sales_user 的未完成任务（按照 HEARTBEAT.md 要求）
    const tasksQuery = `
      SELECT id, title, description, status, priority, created_at, updated_at
      FROM shared.tasks
      WHERE assignee = 'sales_user'
        AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED')
      ORDER BY created_at DESC
    `;

    const result = await client.query(tasksQuery);

    console.log('\n=== 分配给 sales_user 的未完成任务 ===');
    console.log(`共找到 ${result.rows.length} 个任务\n`);

    if (result.rows.length === 0) {
      console.log('✅ 目前没有待处理的任务');
    } else {
      result.rows.forEach((task, index) => {
        console.log(`${index + 1}. 任务 ID: ${task.id}`);
        console.log(`   标题: ${task.title}`);
        console.log(`   状态: ${task.status}`);
        console.log(`   优先级: ${task.priority || 'N/A'}`);
        console.log(`   创建时间: ${task.created_at}`);
        console.log(`   描述: ${task.description.substring(0, 100)}${task.description.length > 100 ? '...' : ''}`);
        console.log('');
      });
    }

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

getPendingTasks();