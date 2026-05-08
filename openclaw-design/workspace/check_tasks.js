const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 2,
  connectionTimeoutMillis: 10000,
});

async function checkTasks() {
  const client = await pool.connect();
  try {
    // 查询分配给 design_user 的未完成任务
    const tasksResult = await client.query(`
      SELECT id, title, description, status, priority, created_at 
      FROM shared.tasks 
      WHERE assignee = 'design_user' 
      AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') 
      ORDER BY created_at DESC
    `);

    console.log('=== 待处理任务 ===');
    if (tasksResult.rows.length === 0) {
      console.log('暂无分配给 design_user 的未完成任务');
    } else {
      tasksResult.rows.forEach(task => {
        console.log(`\n[${task.id}] ${task.title}`);
        console.log(`   状态: ${task.status} | 优先级: ${task.priority || 'NORMAL'}`);
        console.log(`   描述: ${task.description ? task.description.substring(0, 100) : '无'}...`);
        console.log(`   创建时间: ${task.created_at}`);
      });
    }

    // 检查最近提交的设计稿
    const artifactsResult = await client.query(`
      SELECT id, title, artifact_type, created_at, metadata
      FROM shared.shared_artifacts 
      WHERE created_by = 'design_user' 
      ORDER BY created_at DESC 
      LIMIT 5
    `);

    console.log('\n=== 最近提交的设计稿 ===');
    if (artifactsResult.rows.length === 0) {
      console.log('暂无已提交的设计稿');
    } else {
      artifactsResult.rows.forEach(art => {
        console.log(`\n[${art.id}] ${art.title}`);
        console.log(`   类型: ${art.artifact_type} | 创建时间: ${art.created_at}`);
      });
    }

  } catch (err) {
    console.error('查询错误:', err.message);
  } finally {
    client.release();
    await pool.end();
  }
}

checkTasks();
