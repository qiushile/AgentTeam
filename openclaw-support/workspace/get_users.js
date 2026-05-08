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

// Get user list
async function getUserList(appId, appSecret) {
  const token = await getAccessToken(appId, appSecret);
  
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'open.feishu.cn',
      path: '/open-apis/contact/v3/users?page_size=20',
      method: 'GET',
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json'
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
    req.end();
  });
}

const appId = process.env.FEISHU_SUPPORT_APP_ID || process.env.FEISHU_APP_ID;
const appSecret = process.env.FEISHU_SUPPORT_APP_SECRET || process.env.FEISHU_APP_SECRET;

getUserList(appId, appSecret)
  .then(result => console.log('User list:', JSON.stringify(result, null, 2)))
  .catch(err => console.error('Error:', err.message));
