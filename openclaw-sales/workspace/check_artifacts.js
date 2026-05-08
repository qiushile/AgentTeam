const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

async function checkArtifactsStructure() {
  try {
    await client.connect();

    // 查询 artifacts 表的结构
    const structureQuery = `
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_schema = 'shared'
      AND table_name = 'artifacts'
      ORDER BY ordinal_position
    `;

    const result = await client.query(structureQuery);

    console.log('=== shared.artifacts 表结构 ===');
    result.rows.forEach(col => {
      console.log(`${col.column_name}: ${col.data_type}`);
    });

    // 查询最近7天的所有交付物（不分角色）
    const artifactsQuery = `
      SELECT * FROM shared.artifacts
      WHERE created_at >= NOW() - INTERVAL '7 days'
      ORDER BY created_at DESC
      LIMIT 10
    `;

    const artifactsResult = await client.query(artifactsQuery);

    console.log('\n=== 最近7天的交付物 ===');
    console.log(`共找到 ${artifactsResult.rows.length} 个交付物\n`);

    if (artifactsResult.rows.length > 0) {
      artifactsResult.rows.forEach(artifact => {
        console.log(JSON.stringify(artifact, null, 2));
        console.log('---');
      });
    } else {
      console.log('没有找到最近7天的交付物');
    }

    await client.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkArtifactsStructure();