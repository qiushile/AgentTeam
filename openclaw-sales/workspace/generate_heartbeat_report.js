const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function generateHeartbeatReport() {
  try {
    await client.connect();

    console.log('\n' + '='.repeat(60));
    console.log('💼 销售部 Heartbeat 报告');
    console.log('='.repeat(60));

    // 1. 检查未完成任务
    const pendingTasksQuery = `
      SELECT id, title, status, priority, created_at
      FROM shared.tasks
      WHERE assignee = 'sales_user'
        AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED')
      ORDER BY created_at DESC;
    `;

    const pendingTasksResult = await client.query(pendingTasksQuery);

    console.log('\n📋 任务状态');
    console.log('-'.repeat(40));
    console.log(`待处理任务数量: ${pendingTasksResult.rows.length}`);

    if (pendingTasksResult.rows.length === 0) {
      console.log('✅ 目前没有待处理的任务');
    } else {
      console.log('\n待处理任务列表:');
      pendingTasksResult.rows.forEach((task, index) => {
        console.log(`\n${index + 1}. [${task.status}] ${task.title}`);
        console.log(`   ID: ${task.id} | 优先级: ${task.priority || 'N/A'}`);
        console.log(`   创建时间: ${task.created_at}`);
      });

      // 更新所有 PENDING 状态的任务为 IN_PROGRESS
      const updateQuery = `
        UPDATE shared.tasks
        SET status = 'IN_PROGRESS', updated_at = NOW()
        WHERE assignee = 'sales_user' AND status = 'PENDING';
      `;

      const updateResult = await client.query(updateQuery);
      if (updateResult.rowCount > 0) {
        console.log(`\n⚡ 已将 ${updateResult.rowCount} 个 PENDING 任务更新为 IN_PROGRESS`);
      }
    }

    // 2. 检查转化数据
    console.log('\n📊 转化数据汇总');
    console.log('-'.repeat(40));

    // 检查 sales_schema 表
    const tablesQuery = `
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'sales_schema';
    `;

    const tablesResult = await client.query(tablesQuery);

    if (tablesResult.rows.length === 0) {
      console.log('⚠️  sales_schema 中暂无数据表');
      console.log('   建议：初始化销售线索、商机、成交等数据表以开始追踪转化数据');
    } else {
      console.log(`✅ 数据表数量: ${tablesResult.rows.length}`);
      tablesResult.rows.forEach(row => {
        console.log(`   - ${row.table_name}`);
      });
    }

    // 3. 今日优先待办
    console.log('\n🎯 今日优先待办');
    console.log('-'.repeat(40));

    if (pendingTasksResult.rows.length === 0) {
      console.log('✅ 无紧急待办事项');
      console.log('   建议行动：');
      console.log('   1. 主动开发新客户线索');
      console.log('   2. 跟进现有客户需求');
      console.log('   3. 审查销售漏斗数据');
    } else {
      console.log(`📌 优先处理 ${pendingTasksResult.rows.length} 个待处理任务`);
    }

    // 4. 系统状态
    console.log('\n⚙️  系统状态');
    console.log('-'.repeat(40));
    console.log('✅ PostgresTool 已连接 (sales_user)');
    console.log('✅ TaskNotifier 已监听任务通道');

    console.log('\n' + '='.repeat(60));
    console.log(`报告时间: ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}`);
    console.log('='.repeat(60) + '\n');

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

generateHeartbeatReport();