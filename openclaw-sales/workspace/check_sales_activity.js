const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function checkSalesActivity() {
  try {
    await client.connect();

    // 查询销售相关的协作事件（最近7天）
    const eventsQuery = `
      SELECT id, from_role, to_role, event_type, message, created_at
      FROM shared.collaboration_events
      WHERE from_role = 'sales_user' OR to_role = 'sales_user'
      AND created_at >= NOW() - INTERVAL '7 days'
      ORDER BY created_at DESC
      LIMIT 10
    `;

    const result = await client.query(eventsQuery);

    console.log('=== 最近7天的销售协作事件 ===');
    console.log(`共找到 ${result.rows.length} 条事件\n`);

    if (result.rows.length > 0) {
      result.rows.forEach(event => {
        console.log(`事件ID: ${event.id}`);
        console.log(`发起方: ${event.from_role}`);
        console.log(`接收方: ${event.to_role}`);
        console.log(`事件类型: ${event.event_type}`);
        console.log(`消息: ${event.message || '(无)'}`);
        console.log(`时间: ${event.created_at}`);
        console.log('---');
      });
    } else {
      console.log('没有找到最近7天的销售协作事件');
    }

    // 检查提交的交付物
    const artifactsQuery = `
      SELECT id, submitter_role, title, created_at
      FROM shared.artifacts
      WHERE submitter_role = 'sales_user'
      AND created_at >= NOW() - INTERVAL '7 days'
      ORDER BY created_at DESC
      LIMIT 10
    `;

    const artifactsResult = await client.query(artifactsQuery);

    console.log('\n=== 最近7天提交的交付物 ===');
    console.log(`共找到 ${artifactsResult.rows.length} 个交付物\n`);

    if (artifactsResult.rows.length > 0) {
      artifactsResult.rows.forEach(artifact => {
        console.log(`交付物ID: ${artifact.id}`);
        console.log(`标题: ${artifact.title}`);
        console.log(`提交时间: ${artifact.created_at}`);
        console.log('---');
      });
    } else {
      console.log('没有找到最近7天提交的交付物');
    }

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkSalesActivity();