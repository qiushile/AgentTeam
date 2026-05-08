const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function checkSalesSchema() {
  try {
    await client.connect();

    // 查询 sales_schema 中的所有表
    const tablesQuery = `
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'sales_schema'
      ORDER BY table_name
    `;

    const result = await client.query(tablesQuery);

    console.log('\n=== sales_schema 中的表 ===');
    console.log(`共找到 ${result.rows.length} 个表\n`);

    result.rows.forEach((row, index) => {
      console.log(`${index + 1}. ${row.table_name}`);
    });

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkSalesSchema();