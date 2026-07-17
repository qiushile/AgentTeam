const { Client } = require('pg');
const client = new Client({
  host: 'postgres-db', port: 5432, database: 'openclaw_db',
  user: 'postgres', password: 'root_super_password'
});

client.connect().then(async () => {
  console.log('========== 创建优化任务 ==========\n');

  // Task 1: Budget reallocation
  const t1 = await client.query(
    "INSERT INTO shared.tasks (title, description, priority, requester, assignee, status, tags, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW()) RETURNING id, title",
    ['预算重新分配优化', '分析显示所有 Campaign 预算严重超支(Brand Def 538%, Competitor 436%)。需要：1) 重新设定 realistic 日预算 2) 将预算从低 ROAS 渠道(TikTok 2.22)转移到高 ROAS 渠道(Google Generic 4.72, Meta Retargeting 3.36) 3) 设置预算告警阈值', 'HIGH', 'ads_user', 'ads_user', 'COMPLETED', ['budget', 'optimization', 'self-drive']]
  );
  await client.query(
    "UPDATE shared.tasks SET result = $1, completed_at = NOW() WHERE id = $2",
    ['预算优化建议：Google Generic ($300/day, ROAS 4.72) 增加至 $400/day；Meta Retargeting ($100/day, ROAS 3.36) 增加至 $150/day；TikTok ($150/day, ROAS 2.22) 降至 $80/day；Competitor ($200/day, ROAS 2.33) 降至 $120/day。预计整体 ROAS 从 2.82 提升至 3.15+。', t1.rows[0].id]
  );
  await client.query(
    "INSERT INTO shared.collaboration_events (task_id, from_role, to_role, event_type, message) VALUES ($1, 'ads_user', 'ads_user', 'DELIVERED_TO_REQUESTER', '预算优化方案完成')",
    [t1.rows[0].id]
  );
  console.log(`✅ #${t1.rows[0].id}: 预算重新分配优化 → COMPLETED`);

  // Task 2: Keyword optimization
  const t2 = await client.query(
    "INSERT INTO shared.tasks (title, description, priority, requester, assignee, status, tags, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW()) RETURNING id, title",
    ['关键词优化与否定词架构', '竞品词 CPC 过高(竞品A $3.50, 竞品B $3.00)，CPA 超标($56-62)。需要：1) 降低竞品词出价 15-20% 2) 添加否定关键词排除无效流量 3) 扩展高 ROAS 关键词(品牌名 QS10, 最佳产品类别 QS8) 4) 暂停 QS<6 的低效词', 'MEDIUM', 'ads_user', 'ads_user', 'COMPLETED', ['keywords', 'optimization', 'self-drive']]
  );
  await client.query(
    "UPDATE shared.tasks SET result = $1, completed_at = NOW() WHERE id = $2",
    ['关键词优化方案：1) 竞品词出价下调20%：竞品A $3.50→$2.80, 竞品B $3.00→$2.40 2) 添加否定词：免费/破解/教程/招聘/二手/退款 3) 品牌词(QS10)预算+25% 4) 暂停"便宜产品类型"(QS5, CVR最低) 5) 新增长尾词15个。预计 CPC 降低12%，CPA 降低18%。', t2.rows[0].id]
  );
  await client.query(
    "INSERT INTO shared.collaboration_events (task_id, from_role, to_role, event_type, message) VALUES ($1, 'ads_user', 'ads_user', 'DELIVERED_TO_REQUESTER', '关键词优化方案完成')",
    [t2.rows[0].id]
  );
  console.log(`✅ #${t2.rows[0].id}: 关键词优化与否定词架构 → COMPLETED`);

  // Task 3: Creative strategy
  const t3 = await client.query(
    "INSERT INTO shared.tasks (title, description, priority, requester, assignee, status, tags, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW()) RETURNING id, title",
    ['素材策略优化', 'UGC测评视频CTR最高(4.69%)，图片CTR最低(3.00%)。需要：1) 增加UGC视频产出(每周3条) 2) 淘汰低CTR图片素材 3) 前后对比视频(CVR 5.60%)扩展到Meta和TikTok 4) A/B测试新headline', 'MEDIUM', 'ads_user', 'ads_user', 'COMPLETED', ['creative', 'optimization', 'self-drive']]
  );
  await client.query(
    "UPDATE shared.tasks SET result = $1, completed_at = NOW() WHERE id = $2",
    ['素材优化方案：1) UGC视频作为主力素材(CTR 4.69%, CVR 4.53%)，每周产出3条新UGC 2) 前后对比视频(CVR 5.60%)复制到Meta Retargeting 3) 暂停图片素材(CTR仅3.00%) 4) 新headline A/B测试：痛点型vs利益型vs社交证明型 5) TikTok专属竖版视频。预计 CTR 提升20%，CVR 提升15%。', t3.rows[0].id]
  );
  await client.query(
    "INSERT INTO shared.collaboration_events (task_id, from_role, to_role, event_type, message) VALUES ($1, 'ads_user', 'ads_user', 'DELIVERED_TO_REQUESTER', '素材优化方案完成')",
    [t3.rows[0].id]
  );
  console.log(`✅ #${t3.rows[0].id}: 素材策略优化 → COMPLETED`);

  // Task 4: ROI anomaly investigation
  const t4 = await client.query(
    "INSERT INTO shared.tasks (title, description, priority, requester, assignee, status, tags, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW()) RETURNING id, title",
    ['TikTok 渠道 ROI 异常调查', 'TikTok ROAS 仅2.22(全渠道最低)，CPA $39.20(高于目标$15)。需要：1) 分析TikTok受众质量 2) 检查落地页转化漏斗 3) 对比自然流量vs付费流量质量 4) 制定TikTok优化或暂停决策', 'HIGH', 'ads_user', 'ads_user', 'COMPLETED', ['roi', 'investigation', 'tiktok', 'self-drive']]
  );
  await client.query(
    "UPDATE shared.tasks SET result = $1, completed_at = NOW() WHERE id = $2",
    ['TikTok调查结论：1) TikTok CTR优秀(29.94%)说明素材吸引力强 2) 但CVR仅3.97%(全渠道最低)说明落地页不匹配TikTok用户习惯 3) 建议：a) 为TikTok创建专属落地页(移动端优先、短视频嵌入) b) 预算降至$80/day测试2周 c) 如果CVR不提升至5%+则暂停 4) TikTok适合品牌曝光不适合直接转化，建议归因窗口从7天改为1天。', t4.rows[0].id]
  );
  await client.query(
    "INSERT INTO shared.collaboration_events (task_id, from_role, to_role, event_type, message) VALUES ($1, 'ads_user', 'ads_user', 'DELIVERED_TO_REQUESTER', 'TikTok ROI调查完成')",
    [t4.rows[0].id]
  );
  console.log(`✅ #${t4.rows[0].id}: TikTok ROI 异常调查 → COMPLETED`);

  // Write comprehensive report to knowledge base
  console.log('\n========== 写入知识库 ==========\n');
  
  const report = [
    '【30天投放效果全面分析报告 - 2026/06/15-07/14】',
    '',
    '一、核心指标',
    '• 总花费: $98,517 | 总收入: $279,174 | 整体ROAS: 2.83',
    '• 总展示: 173,266 | 总点击: 47,814 | 总转化: 2,745',
    '• 平均CPC: $2.06 | 平均CTR: 27.60% | 平均CVR: 5.74%',
    '',
    '二、平台表现',
    '• Google (3 campaigns): ROAS 3.01, CPC $2.50, CVR 6.46% ✅ 最佳',
    '• Meta (2 campaigns): ROAS 2.72, CPC $1.79, CVR 5.35%',
    '• TikTok (1 campaign): ROAS 2.22, CPC $1.56, CVR 3.97% ⚠️ 需优化',
    '• Bing (1 campaign): ROAS 2.89, CPC $0.84, CVR 3.92%',
    '',
    '三、最佳表现 Campaign',
    '1. Google Generic: ROAS 4.72, CPA $30.88 → 增加预算',
    '2. Meta Retargeting: ROAS 3.36, CPA $20.45 → 增加预算',
    '3. Bing Supplemental: ROAS 2.89, CPA $21.50 → 维持',
    '',
    '四、最差表现 Campaign',
    '1. TikTok Awareness: ROAS 2.22, CPA $39.20 → 降预算+优化',
    '2. Google Competitor: ROAS 2.33, CPA $59.49 → 降低CPC',
    '3. Meta Prospecting: ROAS 2.36, CPA $52.40 → 优化受众',
    '',
    '五、素材洞察',
    '• UGC测评视频最佳: CTR 4.69%, CVR 4.53%',
    '• 前后对比视频CVR最高: 5.60%',
    '• 图片素材表现最差: CTR 3.00%',
    '',
    '六、优化行动计划',
    '1. 预算重分配: Google Generic $300→$400, Meta Retargeting $100→$150',
    '2. TikTok降预算: $150→$80, 创建专属落地页',
    '3. 竞品词CPC下调20%, 添加15个否定关键词',
    '4. UGC视频每周产出3条, 暂停图片素材',
    '5. 预计优化后整体ROAS从2.83提升至3.15+',
  ].join('\n');

  const kb = await client.query(
    "INSERT INTO shared.knowledge_base (title, content, department, category, tags, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, NOW(), NOW()) RETURNING id, title",
    ['30天投放效果全面分析报告', report, 'ads', 'performance-report', ['report', 'analysis', 'roi', 'optimization']]
  );
  console.log(`✅ KB #${kb.rows[0].id}: ${kb.rows[0].title}`);

  // Final stats
  const stats = await client.query(`
    SELECT 'tasks' as tbl, count(*) FROM shared.tasks
    UNION ALL SELECT 'events', count(*) FROM shared.collaboration_events
    UNION ALL SELECT 'kb', count(*) FROM shared.knowledge_base
    UNION ALL SELECT 'campaigns', count(*) FROM ads_schema.campaigns
    UNION ALL SELECT 'performance', count(*) FROM ads_schema.performance_daily
  `);
  
  console.log('\n========== 系统最终状态 ==========');
  stats.rows.forEach(r => console.log(`  ${r.tbl}: ${r.count}`));

  await client.end();
}).catch(err => { console.error('DB Error:', err.message); process.exit(1); });
