const https = require('https');

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
async function sendMessage(appId, appSecret, openId, message) {
  const token = await getAccessToken(appId, appSecret);
  
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

const appId = process.env.FEISHU_SUPPORT_APP_ID || process.env.FEISHU_APP_ID;
const appSecret = process.env.FEISHU_SUPPORT_APP_SECRET || process.env.FEISHU_APP_SECRET;

// 邱世乐的 open_id
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

sendMessage(appId, appSecret, ownerOpenId, message)
  .then(result => {
    console.log('Message sent result:', JSON.stringify(result, null, 2));
    if (result.code === 0) {
      console.log('✅ Report sent successfully to 邱世乐');
    } else {
      console.log('❌ Failed to send report:', result.msg);
    }
  })
  .catch(err => console.error('Error:', err.message));
