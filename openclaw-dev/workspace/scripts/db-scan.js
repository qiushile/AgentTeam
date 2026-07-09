#!/usr/bin/env node
/**
 * db-scan.js - Scan Docker network for PostgreSQL
 * Reads target subnet from .dev-config.json or uses default 172.23.0.0/24
 * Usage: node db-scan.js [subnet]
 */
const net = require('net');
const fs = require('fs');
const path = require('path');

const configPath = path.join(__dirname, '..', '.dev-config.json');
let config = {};
try { config = JSON.parse(fs.readFileSync(configPath, 'utf-8')); } catch(e) {}

const subnet = process.argv[2] || (config.db_host ? config.db_host.split('.').slice(0,3).join('.') : '172.23.0');

console.log(`Scanning ${subnet}.1-254:5432...`);

const results = [];
const batchSize = 20;

async function scanHost(host) {
  return new Promise((resolve) => {
    const s = new net.Socket();
    s.setTimeout(300);
    s.on('connect', () => { results.push(host); s.destroy(); resolve(true); });
    s.on('error', () => resolve(false));
    s.on('timeout', () => { s.destroy(); resolve(false); });
    s.connect(5432, host);
  });
}

(async () => {
  const start = Date.now();
  for (let i = 1; i <= 254; i++) {
    if (i % batchSize === 1 || i === 1) {
      const batch = [];
      for (let j = 0; j < batchSize && i + j <= 254; j++) {
        batch.push(scanHost(`${subnet}.${i + j}`));
      }
      await Promise.all(batch);
      i += batchSize - 1;
    }
  }

  const elapsed = ((Date.now() - start) / 1000).toFixed(1);
  console.log(`\nScan complete in ${elapsed}s. Found ${results.length} PostgreSQL host(s):`);
  results.forEach(host => console.log(`  ${host}:5432`));

  // Update config if different host found and current not in results
  const currentHost = config.db_host || '';
  if (results.length > 0 && !results.includes(currentHost)) {
    console.log(`\n⚠ Current host ${currentHost} not found! Suggested: ${results[0]}`);
  }

  process.exit(0);
})();
