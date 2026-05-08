const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function checkSalesData() {
  try {
    await client.connect();

    // 检查最近 24 小时内的 sales_user 任务
    const recentTasksQuery = `
      SELECT
        id,
        title,
        status,
        created_at,
        updated_at
      FROM shared.tasks
      WHERE assignee = 'sales_user'
      AND updated_at >= NOW() - INTERVAL '24 hours'
      ORDER BY updated_at DESC
    `;

    const result = await client.query(recentTasksQuery);

    console.log(`最近24小时内的销售任务数: ${result.rows.length}`);
    console.log('');

    if (result.rows.length > 0) {
      console.log('任务详情:');
      result.rows.forEach((task, index) => {
        console.log(`${index + 1}. [${task.status}] ${task.title}`);
        console.log(`   创建时间: ${task.created_at}`);
        console.log(`   更新时间: ${task.updated_at}`);
        console.log('');
      });
    }

    // 统计所有 sales_user 任务的状态分布
    const statusStatsQuery = `
      SELECT
        status,
        COUNT(*) as count
      FROM shared.tasks
      WHERE assignee = 'sales_user'
      GROUP BY status
      ORDER BY count DESC
    `;

    const statsResult = await client.query(statusStatsQuery);
    console.log('所有销售任务状态统计:');
    statsResult.rows.forEach(row => {
      console.log(`  ${row.status}: ${row.count} 个`);
    });

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkSalesData();