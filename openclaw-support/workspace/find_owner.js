const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function findOwnerOpenId() {
  try {
    // Try to find user with role 'owner' or specific to this department
    const result = await pool.query(`
      SELECT id, username, role, metadata 
      FROM openclaw.users 
      WHERE role = 'owner' 
         OR username LIKE '%世乐%' 
         OR username LIKE '%qiushile%'
      LIMIT 5
    `);
    console.log('Users found:', JSON.stringify(result.rows, null, 2));
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    await pool.end();
  }
}

findOwnerOpenId();
