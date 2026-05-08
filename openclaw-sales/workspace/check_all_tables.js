const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function checkTables() {
  try {
    await client.connect();

    // 查询所有表
    const tables = await client.query(`
      SELECT table_schema, table_name
      FROM information_schema.tables
      WHERE table_type = 'BASE TABLE'
      ORDER BY table_schema, table_name;
    `);
    
    console.log('\n=== 数据库中的所有表 ===');
    tables.rows.forEach(t => {
      console.log(`${t.table_schema}.${t.table_name}`);
    });

    await client.end();
  } catch (error) {
    console.error('错误:', error.message);
    process.exit(1);
  }
}

checkTables();
