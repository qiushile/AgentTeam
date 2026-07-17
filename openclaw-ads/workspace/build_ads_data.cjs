const { Client } = require('pg');
const client = new Client({
  host: 'postgres-db', port: 5432, database: 'openclaw_db',
  user: 'postgres', password: 'root_super_password'
});

client.connect().then(async () => {
  // Insert campaigns
  const campaigns = [
    ['Google Search - Brand Defense', 'google', 150.00, '2026-06-01', '2026-12-31'],
    ['Google Search - Competitor', 'google', 200.00, '2026-06-01', '2026-12-31'],
    ['Google Search - Generic', 'google', 300.00, '2026-06-01', '2026-12-31'],
    ['Meta - Prospecting', 'meta', 250.00, '2026-06-15', '2026-12-31'],
    ['Meta - Retargeting', 'meta', 100.00, '2026-06-15', '2026-12-31'],
    ['TikTok - Brand Awareness', 'tiktok', 150.00, '2026-07-01', '2026-12-31'],
    ['Bing - Supplemental', 'bing', 50.00, '2026-06-01', '2026-12-31'],
  ];
  
  console.log('=== Inserting Campaigns ===');
  for (const [name, platform, budget, start, end] of campaigns) {
    const res = await client.query(
      'INSERT INTO ads_schema.campaigns (campaign_name, platform, daily_budget, start_date, end_date, status) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id',
      [name, platform, budget, start, end, 'active']
    );
    console.log(`  ✅ #${res.rows[0].id}: ${name} (${platform}, $${budget}/day)`);
  }

  // Insert ad groups
  console.log('\n=== Inserting Ad Groups ===');
  const adGroups = [
    [1, 'Brand - Exact Match', 2.50],
    [1, 'Brand - Phrase Match', 2.00],
    [2, 'Competitor A', 3.50],
    [2, 'Competitor B', 3.00],
    [2, 'Competitor C', 2.80],
    [3, 'Product Category - Broad', 1.80],
    [3, 'Product Category - Exact', 2.20],
    [3, 'Long-tail Keywords', 1.50],
    [4, 'Interest - Tech Enthusiasts', null],
    [4, 'Interest - Business Owners', null],
    [4, 'Lookalike 1%', null],
    [5, 'Website Visitors 30d', null],
    [5, 'Cart Abandoners', null],
    [6, 'UGC Video - V1', null],
    [6, 'UGC Video - V2', null],
    [7, 'Bing Generic', 0.80],
  ];
  
  for (const [campId, name, cpc] of adGroups) {
    const res = await client.query(
      'INSERT INTO ads_schema.ad_groups (campaign_id, ad_group_name, status, max_cpc) VALUES ($1, $2, $3, $4) RETURNING id',
      [campId, name, 'active', cpc]
    );
    console.log(`  ✅ #${res.rows[0].id}: ${name} (Campaign #${campId})`);
  }

  // Insert keywords
  console.log('\n=== Inserting Keywords ===');
  const keywords = [
    [1, '品牌名', 'exact', 2.50, 10, 45000, 12000, 800, 24000],
    [1, '品牌名 官网', 'exact', 2.00, 9, 32000, 9500, 650, 19000],
    [1, '品牌名 购买', 'phrase', 2.20, 8, 28000, 7800, 520, 17200],
    [3, '竞品A 替代', 'exact', 3.50, 7, 15000, 3200, 180, 11200],
    [3, '竞品B vs', 'exact', 3.00, 7, 12000, 2800, 150, 8400],
    [3, '竞品C 对比', 'phrase', 2.80, 6, 10000, 2200, 120, 6160],
    [6, '产品类型 推荐', 'broad', 1.80, 7, 85000, 18000, 900, 32400],
    [6, '最佳 产品类别', 'exact', 2.20, 8, 62000, 14000, 750, 30800],
    [7, '产品类型 价格', 'phrase', 1.50, 6, 95000, 22000, 1100, 33000],
    [7, '产品类别 评测', 'phrase', 1.60, 7, 48000, 11000, 550, 17600],
    [7, '便宜 产品类型', 'broad', 1.20, 5, 72000, 15000, 600, 18000],
  ];
  
  for (const [agId, kw, match, cpc, qs, imp, clicks, conv, cost] of keywords) {
    await client.query(
      'INSERT INTO ads_schema.keywords (ad_group_id, keyword, match_type, max_cpc, quality_score, impressions, clicks, conversions, cost) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)',
      [agId, kw, match, cpc, qs, imp, clicks, conv, cost]
    );
    console.log(`  ✅ ${kw} (${match}, CPC $${cpc}, QS ${qs})`);
  }

  // Insert creatives
  console.log('\n=== Inserting Creatives ===');
  const creatives = [
    [14, 'video', '夏季大促 | 限时5折起', '立即抢购，错过再等一年！免费 shipping', 250000, 8500, 3.40, 420],
    [14, 'video', '用户真实评价 | 5星好评', '看看他们怎么说，超过10,000+满意客户', 180000, 7200, 4.00, 380],
    [15, 'video', '前后对比 | 效果看得见', '使用前后对比，真实效果展示', 220000, 9100, 4.14, 510],
    [15, 'image', '产品展示 | 精美视觉', '高品质产品图片，突出核心卖点', 150000, 4500, 3.00, 220],
    [13, 'video', 'UGC测评 | 真实体验', '博主真实使用体验分享', 320000, 15000, 4.69, 680],
    [13, 'video', '教程 | 如何使用', '3分钟学会正确使用，新手友好', 180000, 6800, 3.78, 310],
  ];
  
  for (const [agId, type, headline, desc, imp, clicks, ctr, conv] of creatives) {
    await client.query(
      'INSERT INTO ads_schema.creatives (ad_group_id, creative_type, headline, description, impressions, clicks, ctr, conversions) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
      [agId, type, headline, desc, imp, clicks, ctr, conv]
    );
    console.log(`  ✅ ${type}: ${headline} (CTR ${ctr}%, ${conv} conv)`);
  }

  // Generate 30 days of performance data
  console.log('\n=== Generating 30-Day Performance Data ===');
  const campaignPerf = {
    1: { imp: 45000, click: 12000, conv: 800, spend: 24000, rev: 72000 },
    2: { imp: 37000, click: 8200, conv: 450, spend: 25800, rev: 63000 },
    3: { imp: 25000, click: 6000, conv: 420, spend: 12600, rev: 63000 },
    4: { imp: 30000, click: 9000, conv: 360, spend: 18000, rev: 45000 },
    5: { imp: 20000, click: 7500, conv: 520, spend: 10400, rev: 36400 },
    6: { imp: 15000, click: 4500, conv: 180, spend: 6750, rev: 16200 },
    7: { imp: 8000, click: 2400, conv: 96, spend: 1920, rev: 5760 },
  };

  for (let day = 0; day < 30; day++) {
    const date = new Date(2026, 5, 15 + day);
    const dateStr = date.toISOString().split('T')[0];
    const dow = date.getDay();
    const wknd = (dow === 0 || dow === 6) ? 0.85 : 1.0;
    
    for (const [campId, base] of Object.entries(campaignPerf)) {
      const dImp = Math.round(base.imp / 30 * wknd * (0.9 + Math.random() * 0.2));
      const dClick = Math.round(base.click / 30 * wknd * (0.9 + Math.random() * 0.2));
      const dConv = Math.round(base.conv / 30 * wknd * (0.85 + Math.random() * 0.3));
      const dSpend = +(base.spend / 30 * (0.9 + Math.random() * 0.2)).toFixed(2);
      const dRev = +(base.rev / 30 * wknd * (0.85 + Math.random() * 0.3)).toFixed(2);
      const cpc = dClick > 0 ? +(dSpend / dClick).toFixed(2) : 0;
      const ctr = dImp > 0 ? +((dClick / dImp) * 100).toFixed(2) : 0;
      const cvr = dClick > 0 ? +((dConv / dClick) * 100).toFixed(2) : 0;
      const roas = dSpend > 0 ? +(dRev / dSpend).toFixed(2) : 0;
      
      await client.query(
        'INSERT INTO ads_schema.performance_daily (campaign_id, date, impressions, clicks, conversions, spend, revenue, cpc, ctr, cvr, roas) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)',
        [campId, dateStr, dImp, dClick, dConv, dSpend, dRev, cpc, ctr, cvr, roas]
      );
    }
  }
  console.log('  ✅ Generated 30 days x 7 campaigns = 210 performance records');

  // Create and complete task
  const task = await client.query(
    "INSERT INTO shared.tasks (title, description, priority, requester, assignee, status, tags, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW()) RETURNING id, title",
    ['构建 ads_schema 数据库与模拟投放数据', '创建 ads_schema 包含 5 张表，填充 7 个 Campaign、16 个 Ad Group、11 个关键词、6 个素材、210 条 30 天性能数据，模拟真实投放场景', 'HIGH', 'ads_user', 'ads_user', 'IN_PROGRESS', ['database', 'data-setup', 'self-drive']]
  );
  console.log(`\n📋 Task created: #${task.rows[0].id}: ${task.rows[0].title}`);

  await client.query(
    "UPDATE shared.tasks SET status = 'COMPLETED', result = $1, completed_at = NOW() WHERE id = $2",
    ['完成 ads_schema 建设：5张表 + 7个Campaign + 16个Ad Group + 11个关键词 + 6个素材 + 210条30天性能数据。覆盖 Google/Meta/TikTok/Bing 四大平台。', task.rows[0].id]
  );

  await client.query(
    "INSERT INTO shared.collaboration_events (task_id, from_role, to_role, event_type, message) VALUES ($1, 'ads_user', 'ads_user', 'DELIVERED_TO_REQUESTER', 'ads_schema 建设完成')",
    [task.rows[0].id]
  );

  // Summary
  const counts = await client.query(`
    SELECT 'campaigns' as tbl, count(*) FROM ads_schema.campaigns
    UNION ALL SELECT 'ad_groups', count(*) FROM ads_schema.ad_groups
    UNION ALL SELECT 'keywords', count(*) FROM ads_schema.keywords
    UNION ALL SELECT 'creatives', count(*) FROM ads_schema.creatives
    UNION ALL SELECT 'performance_daily', count(*) FROM ads_schema.performance_daily
  `);
  
  console.log('\n========== 最终统计 ==========');
  counts.rows.forEach(r => console.log(`  ${r.tbl}: ${r.count} rows`));

  await client.end();
}).catch(err => { console.error('DB Error:', err.message); process.exit(1); });
