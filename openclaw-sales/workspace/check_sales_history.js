const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function checkSalesHistory() {
  try {
    await client.connect();

    // 检查 sales_user 的任务历史（包括已完成的）
    const completedTasksQuery = `
      SELECT id, title, status, created_at, updated_at, result
      FROM shared.tasks
      WHERE assignee = 'sales_user'
        AND status = 'COMPLETED'
      ORDER BY updated_at DESC
      LIMIT 10
    `;

    const result = await client.query(completedTasksQuery);

    console.log('\n=== sales_user 最近完成的任务 ===\n');
    console.log(`共找到 ${result.rows.length} 个已完成的任务\n`);

    if (result.rows.length > 0) {
      result.rows.forEach((task, index) => {
        console.log(`${index + 1}. 任务 ID: ${task.id}`);
        console.log(`   标题: ${task.title}`);
        console.log(`   完成时间: ${task.updated_at}`);
        if (task.result) {
          const resultPreview = task.result.substring(0, 150);
          console.log(`   结果: ${resultPreview}${task.result.length > 150 ? '...' : ''}`);
        }
        console.log('');
      });
    } else {
      console.log('暂无已完成的任务记录');
    }

    // 检查协作事件
    const eventsQuery = `
      SELECT event_type, from_role, to_role, message, created_at
      FROM shared.collaboration_events
      WHERE from_role = 'sales_user' OR to_role = 'sales_user'
      ORDER BY created_at DESC
      LIMIT 5
    `;

    const events = await client.query(eventsQuery);

    console.log('\n=== 最近的协作事件 ===\n');
    if (events.rows.length > 0) {
      events.rows.forEach((event, index) => {
        console.log(`${index + 1}. ${event.event_type} | ${event.from_role} -> ${event.to_role}`);
        console.log(`   时间: ${event.created_at}`);
        if (event.message) {
          console.log(`   消息: ${event.message.substring(0, 100)}`);
        }
        console.log('');
      });
    } else {
      console.log('暂无协作事件记录');
    }

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkSalesHistory();