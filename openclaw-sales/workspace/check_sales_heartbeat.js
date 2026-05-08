const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function checkSalesTasks() {
  try {
    await client.connect();

    // 查询最近7天的任务（包括各种状态）
    const tasksQuery = `
      SELECT id, title, description, status, assignee, created_at, updated_at
      FROM shared.tasks
      WHERE assignee = 'sales_user'
      AND created_at >= NOW() - INTERVAL '7 days'
      ORDER BY created_at DESC
    `;

    const result = await client.query(tasksQuery);

    console.log('=== 最近7天的销售任务 ===');
    console.log(`共找到 ${result.rows.length} 条任务\n`);

    if (result.rows.length > 0) {
      result.rows.forEach(task => {
        console.log(`任务ID: ${task.id}`);
        console.log(`标题: ${task.title}`);
        console.log(`状态: ${task.status}`);
        console.log(`创建时间: ${task.created_at}`);
        console.log(`更新时间: ${task.updated_at}`);
        console.log('---');
      });
    } else {
      console.log('没有找到最近7天的销售任务');
    }

    // 检查是否有线索相关的记录
    const leadTasksQuery = `
      SELECT id, title, status, created_at
      FROM shared.tasks
      WHERE (title ILIKE '%线索%' OR description ILIKE '%线索%' OR title ILIKE '%客户%' OR description ILIKE '%客户%')
      AND created_at >= NOW() - INTERVAL '7 days'
      ORDER BY created_at DESC
      LIMIT 10
    `;

    const leadTasksResult = await client.query(leadTasksQuery);

    console.log('\n=== 线索/客户相关的任务 ===');
    console.log(`共找到 ${leadTasksResult.rows.length} 条相关任务\n`);

    if (leadTasksResult.rows.length > 0) {
      leadTasksResult.rows.forEach(task => {
        console.log(`任务ID: ${task.id} | 标题: ${task.title} | 状态: ${task.status} | 创建: ${task.created_at}`);
      });
    } else {
      console.log('没有找到线索/客户相关的任务');
    }

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkSalesTasks();