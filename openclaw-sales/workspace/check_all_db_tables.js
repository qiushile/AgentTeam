const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function checkAllTables() {
  try {
    await client.connect();

    // 查看所有 schema 中的表
    const tablesQuery = `
      SELECT table_schema, table_name
      FROM information_schema.tables
      WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
      ORDER BY table_schema, table_name
    `;

    const result = await client.query(tablesQuery);

    console.log('\n=== 所有业务表 ===\n');

    if (result.rows.length === 0) {
      console.log('未找到任何业务表');
    } else {
      let currentSchema = '';
      result.rows.forEach((row) => {
        if (row.table_schema !== currentSchema) {
          console.log(`Schema: ${row.table_schema}`);
          currentSchema = row.table_schema;
        }
        console.log(`  - ${row.table_name}`);
      });
    }

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkAllTables();