const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function checkDatabaseStructure() {
  try {
    await client.connect();

    console.log('\n=== 所有 Schema ===');
    const schemasResult = await client.query(`
      SELECT schema_name
      FROM information_schema.schemata
      WHERE schema_name NOT IN ('pg_catalog', 'information_schema')
      ORDER BY schema_name;
    `);
    schemasResult.rows.forEach(row => {
      console.log(`  - ${row.schema_name}`);
    });

    console.log('\n=== shared Schema 中的表 ===');
    const sharedTables = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'shared'
      ORDER BY table_name;
    `);
    sharedTables.rows.forEach(row => {
      console.log(`  - ${row.table_name}`);
    });

    // 查询最近的任务活动
    console.log('\n=== 最近 7 天的任务活动 ===');
    const recentActivity = await client.query(`
      SELECT
        assignee,
        COUNT(*) as task_count,
        COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_count,
        COUNT(CASE WHEN status IN ('PENDING', 'IN_PROGRESS') THEN 1 END) as pending_count
      FROM shared.tasks
      WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
      GROUP BY assignee
      ORDER BY task_count DESC;
    `);
    recentActivity.rows.forEach(row => {
      console.log(`  ${row.assignee}: 总计 ${row.task_count} 个任务，已完成 ${row.completed_count}，待处理 ${row.pending_count}`);
    });

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkDatabaseStructure();