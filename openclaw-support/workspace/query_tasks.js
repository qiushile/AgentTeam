const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function main() {
  const result = await pool.query(`
    SELECT id, title, description, status, priority, created_at, assignee, requester 
    FROM shared.tasks 
    WHERE assignee = 'support_user' AND status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') 
    ORDER BY created_at
  `);
  console.log(JSON.stringify(result.rows, null, 2));
  await pool.end();
}

main();
