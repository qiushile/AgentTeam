const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function findUsers() {
  try {
    const result = await pool.query(`
      SELECT * FROM shared.team_directory 
      LIMIT 10
    `);
    console.log('Team directory:', JSON.stringify(result.rows, null, 2));
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    await pool.end();
  }
}

findUsers();
