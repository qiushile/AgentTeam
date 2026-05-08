const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://design_user:design_pass_123@postgres-db:5432/openclaw_db'
});

async function sendReport() {
  try {
    // 插入协作事件记录
    const result = await pool.query(`
      INSERT INTO shared.collaboration_events 
      (from_role, to_role, event_type, message, created_at, description)
      VALUES ($1, $2, $3, $4, NOW(), $5)
      RETURNING id;
    `, [
      'design_user',
      'founder',
      'DAILY_CHECK_REPORT',
      JSON.stringify({
        date: '2026-04-15',
        pending_tasks: 2,
        tasks: [
          { id: 28, title: '【紧急】向创始人报到', status: 'IN_PROGRESS', priority: 'URGENT' },
          { id: 46, title: '飞书私聊联系创始人', status: 'IN_PROGRESS', priority: 'HIGH' }
        ]
      }),
      '每日任务兜底检查报告 - 2026-04-15'
    ]);

    console.log('✅ Report recorded via collaboration_events, event id:', result.rows[0].id);
  } catch (err) {
    console.error('❌ Error:', err.message);
  } finally {
    await pool.end();
  }
}

sendReport();
