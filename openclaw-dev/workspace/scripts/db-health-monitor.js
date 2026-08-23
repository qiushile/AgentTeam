#!/usr/bin/env node
/**
 * DB Health Monitor - 数据库健康检查与自动恢复脚本
 * 
 * 功能:
 * 1. 定期检查 PostgreSQL 连接可用性
 * 2. 连接失败时指数退避重试 (1s→2s→4s→8s→16s)
 * 3. 自动扫描子网寻找新 DB IP
 * 4. 自动更新 .dev-config.json
 * 5. 连续失败告警记录
 * 
 * 使用: node db-health-monitor.js [--daemon] [--interval=30]
 * 
 * 验收标准:
 * - IP 漂移后 5 分钟内自动恢复
 * - 连续 3 次失败记录告警
 * - 月度可用性 ≥ 99.9%
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ==================== 配置 ====================

const CONFIG_PATH = path.resolve(__dirname, '..', '.dev-config.json');
const LOG_PATH = path.resolve(__dirname, '..', 'logs', 'db-health.log');
const ALERT_PATH = path.resolve(__dirname, '..', 'logs', 'db-alerts.log');
const MAX_RETRIES = 5;
const RETRY_BASE_MS = 1000; // 指数退避基数
const SUBNET_PREFIX = '172.23.0';
const CONSECUTIVE_FAIL_THRESHOLD = 3;

// ==================== 日志 ====================

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function log(message, level = 'INFO') {
  const timestamp = new Date().toISOString();
  const line = `[${timestamp}] [${level}] ${message}`;
  console.log(line);
  ensureDir(path.dirname(LOG_PATH));
  fs.appendFileSync(LOG_PATH, line + '\n');
}

function logAlert(message) {
  ensureDir(path.dirname(ALERT_PATH));
  fs.appendFileSync(ALERT_PATH, `[${new Date().toISOString()}] ALERT: ${message}\n`);
}

// ==================== 配置读写 ====================

function loadConfig() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  } catch (e) {
    log(`Failed to load config: ${e.message}`, 'ERROR');
    return null;
  }
}

function saveConfig(config) {
  config.last_updated = new Date().toISOString().split('T')[0];
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2) + '\n');
  log(`Config updated: db_host=${config.db_host}`);
}

// ==================== 连接测试 ====================

async function testConnection(host, port, db, user, password) {
  const client = new Client({ host, port, database: db, user, password });
  try {
    await client.connect();
    await client.query('SELECT 1');
    return true;
  } catch (e) {
    return false;
  } finally {
    try { await client.end(); } catch {}
  }
}

// ==================== 指数退避重试 ====================

async function connectWithRetry(host, port, db, user, password) {
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    if (await testConnection(host, port, db, user, password)) return true;
    
    if (attempt < MAX_RETRIES) {
      const delay = RETRY_BASE_MS * Math.pow(2, attempt);
      log(`Connection failed (attempt ${attempt + 1}/${MAX_RETRIES + 1}), retrying in ${delay}ms...`, 'WARN');
      await new Promise(r => setTimeout(r, delay));
    }
  }
  return false;
}

// ==================== IP 扫描 ====================

async function scanSubnet(prefix, excludeIp) {
  log(`Scanning subnet ${prefix}.1-254 for PostgreSQL (excluding ${excludeIp})...`);
  const found = [];
  
  const promises = [];
  for (let i = 1; i <= 254; i++) {
    const ip = `${prefix}.${i}`;
    if (ip === excludeIp) continue;
    
    promises.push(
      new Promise((resolve) => {
        const timeout = setTimeout(() => resolve(null), 1000);
        try {
          const { exec } = require('child_process');
          exec(`timeout 1 bash -c "echo >/dev/tcp/${ip}/5432" 2>/dev/null`, (err) => {
            clearTimeout(timeout);
            if (!err) {
              found.push(ip);
              resolve(ip);
            } else {
              resolve(null);
            }
          });
        } catch {
          clearTimeout(timeout);
          resolve(null);
        }
      })
    );
  }
  
  await Promise.allSettled(promises);
  return found;
}

// ==================== 主健康检查 ====================

let consecutiveFails = 0;
let totalChecks = 0;
let successfulChecks = 0;

async function healthCheck() {
  const config = loadConfig();
  if (!config) {
    log('Cannot load config, aborting', 'ERROR');
    return false;
  }

  totalChecks++;
  const { db_host: host, db_port: port, db_name: db, db_user: user, env_var_password } = config;
  const password = process.env[env_var_password] || '';

  log(`Checking connection to ${host}:${port}/${db}...`);

  const connected = await connectWithRetry(host, port, db, user, password);

  if (connected) {
    consecutiveFails = 0;
    successfulChecks++;
    log(`✅ Connection successful (${successfulChecks}/${totalChecks}, ${(successfulChecks/totalChecks*100).toFixed(1)}% uptime)`);
    return true;
  }

  consecutiveFails++;
  log(`❌ Connection failed to ${host}:${port} (consecutive: ${consecutiveFails})`, 'ERROR');

  // 扫描子网寻找新 IP
  if (consecutiveFails >= 1) {
    log('Initiating subnet scan to find new DB host...', 'WARN');
    const foundIPs = await scanSubnet(SUBNET_PREFIX, host);
    
    if (foundIPs.length > 0) {
      const newHost = foundIPs[0];
      log(`Found PostgreSQL at ${newHost}, verifying...`);
      
      if (await testConnection(newHost, port, db, user, password)) {
        log(`✅ Verified new DB host: ${newHost}`);
        config.db_host = newHost;
        saveConfig(config);
        consecutiveFails = 0;
        logAlert(`DB host changed: ${host} → ${newHost}`);
        return true;
      }
    } else {
      log(`❌ No PostgreSQL hosts found in subnet ${SUBNET_PREFIX}.0/24`, 'ERROR');
    }
  }

  // 连续失败告警
  if (consecutiveFails >= CONSECUTIVE_FAIL_THRESHOLD) {
    const msg = `DB connection failed ${consecutiveFails} consecutive times. Last host: ${host}:${port}`;
    log(msg, 'ALERT');
    logAlert(msg);
  }

  return false;
}

// ==================== 守护模式 ====================

function runDaemon(intervalMin = 30) {
  log(`Starting DB health monitor in daemon mode (interval: ${intervalMin}min)`);
  healthCheck().then(() => {
    setInterval(() => {
      healthCheck().catch(e => log(`Unhandled error: ${e.message}`, 'ERROR'));
    }, intervalMin * 60 * 1000);
  });
}

// ==================== CLI ====================

function main() {
  const args = process.argv.slice(2);
  const isDaemon = args.includes('--daemon');
  const intervalArg = args.find(a => a.startsWith('--interval='));
  const intervalMin = intervalArg ? parseInt(intervalArg.split('=')[1]) : 30;

  if (isDaemon) {
    runDaemon(intervalMin);
  } else {
    healthCheck().then(ok => process.exit(ok ? 0 : 1))
      .catch(e => { log(`Fatal: ${e.message}`, 'ERROR'); process.exit(2); });
  }
}

main();
