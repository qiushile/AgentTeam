const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://design_user:design_pass_123@postgres-db:5432/openclaw_db'
});

async function checkArtifacts() {
  try {
    const result = await pool.query(`
      SELECT id, task_id, owner, artifact_type, title, metadata, created_at, updated_at
      FROM shared.shared_artifacts 
      WHERE owner = 'design_user' 
      ORDER BY updated_at DESC
      LIMIT 10
    `);
    
    console.log(JSON.stringify(result.rows, null, 2));
  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    await pool.end();
  }
}

checkArtifacts();
