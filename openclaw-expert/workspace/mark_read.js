const { Pool } = require('pg');
async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  await pool.query("UPDATE shared.inter_agent_messages SET is_read = true WHERE to_agent = 'expert_user' OR to_agent IS NULL");
  console.log('Messages marked as read');
  await pool.end();
}
main();