const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function generateSalesHeartbeatReport() {
  try {
    await client.connect();

    const now = new Date();
    const yesterdayStart = new Date(now);
    yesterdayStart.setDate(now.getDate() - 1);
    yesterdayStart.setHours(0, 0, 0, 0);

    const yesterdayEnd = new Date(now);
    yesterdayEnd.setDate(now.getDate() - 1);
    yesterdayEnd.setHours(23, 59, 59, 999);

    console.log('=== 销售部心跳报告 ===');
    console.log(`报告时间: ${now.toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}`);
    console.log(`统计周期: ${yesterdayStart.toLocaleString('zh-CN')} - ${yesterdayEnd.toLocaleString('zh-CN')}`);
    console.log('');

    // 1. 检查新任务（昨日新增）
    const newTasksQuery = `
      SELECT
        COUNT(*) as count,
        json_agg(json_build_object('id', id, 'title', title, 'created_at', created_at)) as tasks
      FROM shared.tasks
      WHERE assignee = 'sales_user'
      AND created_at >= $1 AND created_at <= $2
    `;

    const newTasksResult = await client.query(newTasksQuery, [yesterdayStart, yesterdayEnd]);
    const newTasksCount = newTasksResult.rows[0].count;
    const newTasks = newTasksResult.rows[0].tasks || [];

    console.log('1. 新增任务情况');
    console.log(`   昨日新增任务数: ${newTasksCount}`);

    if (newTasks.length > 0) {
      console.log('   新增任务列表:');
      newTasks.forEach(task => {
        console.log(`     - [${task.id}] ${task.title}`);
      });
    }
    console.log('');

    // 2. 检查任务完成情况（昨日完成）
    const completedTasksQuery = `
      SELECT
        COUNT(*) as count,
        json_agg(json_build_object('id', id, 'title', title, 'updated_at', updated_at)) as tasks
      FROM shared.tasks
      WHERE assignee = 'sales_user'
      AND status = 'COMPLETED'
      AND updated_at >= $1 AND updated_at <= $2
    `;

    const completedTasksResult = await client.query(completedTasksQuery, [yesterdayStart, yesterdayEnd]);
    const completedCount = completedTasksResult.rows[0].count;
    const completedTasks = completedTasksResult.rows[0].tasks || [];

    console.log('2. 任务完成情况');
    console.log(`   昨日完成任务数: ${completedCount}`);

    if (completedTasks.length > 0) {
      console.log('   完成任务列表:');
      completedTasks.forEach(task => {
        console.log(`     - [${task.id}] ${task.title}`);
      });
    }
    console.log('');

    // 3. 当前待处理任务
    const pendingTasksQuery = `
      SELECT
        id,
        title,
        status,
        created_at,
        updated_at
      FROM shared.tasks
      WHERE assignee = 'sales_user'
      AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED')
      ORDER BY created_at ASC
      LIMIT 10
    `;

    const pendingTasksResult = await client.query(pendingTasksQuery);
    const pendingTasks = pendingTasksResult.rows;

    console.log('3. 当前待处理任务');
    console.log(`   待处理任务数: ${pendingTasks.length}`);

    if (pendingTasks.length > 0) {
      console.log('   待处理任务列表:');
      pendingTasks.forEach((task, index) => {
        console.log(`     ${index + 1}. [${task.status}] ${task.title}`);
        console.log(`        创建时间: ${new Date(task.created_at).toLocaleString('zh-CN')}`);
      });
    } else {
      console.log('   ✅ 无待处理任务');
    }
    console.log('');

    // 4. 转化数据汇总
    console.log('4. 昨日关键转化数据');
    console.log(`   新增线索: ${newTasksCount}`);
    console.log(`   任务完成: ${completedCount}`);
    console.log(`   转化率: ${newTasksCount > 0 ? ((completedCount / newTasksCount) * 100).toFixed(2) + '%' : 'N/A'}`);
    console.log('');

    // 5. 今日高优待办
    console.log('5. 今日高优待办清单');
    if (pendingTasks.length > 0) {
      console.log(`   - 优先处理 ${pendingTasks.length} 项待处理任务`);
      pendingTasks.forEach(task => {
        console.log(`     * ${task.title}`);
      });
    } else {
      console.log('   ✅ 今日无紧急待办，保持待命状态');
    }

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

generateSalesHeartbeatReport();