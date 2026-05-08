const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function main() {
  const result = await pool.query(`
    SELECT id, title, status, assignee, requester, created_at
    FROM shared.tasks 
    ORDER BY created_at DESC
    LIMIT 20
  `);
  console.log(JSON.stringify(result.rows, null, 2));
  await pool.end();
}

main();
