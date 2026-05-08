const { Client } = require('pg');

// Parse DATABASE_URL
const dbUrl = new URL(process.env.DATABASE_URL);
const client = new Client({
  host: dbUrl.hostname,
  port: dbUrl.port || 5432,
  database: dbUrl.pathname.slice(1),
  user: dbUrl.username,
  password: dbUrl.password
});

async function query() {
  try {
    await client.connect();
    const result = await client.query(`
      SELECT * 
      FROM shared.artifacts 
      ORDER BY created_at DESC
      LIMIT 5
    `);
    console.log(JSON.stringify(result.rows, null, 2));
    await client.end();
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

query();
