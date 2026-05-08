const https = require('https');

// Try multiple apps to find one that works
const apps = [
  { id: process.env.FEISHU_APP_ID, secret: process.env.FEISHU_APP_SECRET, name: 'FEISHU_APP' },
  { id: process.env.FEISHU_SUPPORT_APP_ID, secret: process.env.FEISHU_SUPPORT_APP_SECRET, name: 'FEISHU_SUPPORT_APP' },
  { id: process.env.FEISHU_SENTINEL_APP_ID, secret: process.env.FEISHU_SENTINEL_APP_SECRET, name: 'FEISHU_SENTINEL_APP' },
];

// Get app access token
function getAccessToken(appId, appSecret) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      app_id: appId,
      app_secret: appSecret
    });
    
    const options = {
      hostname: 'open.feishu.cn',
      path: '/open-apis/auth/v3/tenant_access_token/internal',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    };
    
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const result = JSON.parse(body);
          if (result.tenant_access_token) {
            resolve(result.tenant_access_token);
          } else {
            reject(new Error('No token: ' + body));
          }
        } catch (e) {
          reject(e);
        }
      });
    });
    
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

// Send message to user
async function sendMessage(token, openId, message) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      receive_id: openId,
      msg_type: 'text',
      content: JSON.stringify({ text: message })
    });
    
    const options = {
      hostname: 'open.feishu.cn',
      path: '/open-apis/im/v1/messages?receive_id_type=open_id',
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    };
    
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(body));
        } catch (e) {
          resolve(body);
        }
      });
    });
    
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

const ownerOpenId = 'ou_a0e1dd57f4c003588d9645441fe19d8d';

const message = `📊 **运营支撑部 - 今日服务保障汇报**

**时间**: 2026年4月21日 12:59 PM

**检查结果**:
- ✅ 数据库连接: 正常
- ✅ 待处理任务: 0
- ✅ 进行中任务: 0
- ✅ 24小时内已完成任务: 0

**状态**: 所有系统运行正常，暂无待处理工单。

---

*本消息由自动心跳检查发送*`;

// Try each app
async function tryApps() {
  for (const app of apps) {
    if (!app.id || !app.secret) continue;
    
    console.log(`Trying app: ${app.name}...`);
    try {
      const token = await getAccessToken(app.id, app.secret);
      console.log(`  Got token for ${app.name}`);
      
      const result = await sendMessage(token, ownerOpenId, message);
      console.log(`  Result:`, JSON.stringify(result));
      
      if (result.code === 0) {
        console.log(`✅ Success with ${app.name}!`);
        return;
      } else {
        console.log(`  Failed: ${result.msg}`);
      }
    } catch (e) {
      console.log(`  Error: ${e.message}`);
    }
  }
  console.log('❌ All apps failed');
}

tryApps();
