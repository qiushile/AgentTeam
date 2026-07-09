#!/usr/bin/env node
/**
 * dev-query.js - Reusable database query helper
 * Reads DB config from .dev-config.json
 * Usage: node dev-query.js "SELECT ..."
 */
const { Client } = require('/home/node/.openclaw/extensions/postgres-tool/node_modules/pg');
const fs = require('fs');
const path = require('path');

const configPath = path.join(__dirname, '..', '.dev-config.json');
const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));

const query = process.argv[2];
if (!query) {
  console.error('Usage: node dev-query.js "SELECT ..."');
  process.exit(1);
}

(async () => {
  const c = new Client({
    host: config.db_host,
    port: config.db_port,
    user: config.db_user,
    password: process.env[config.env_var_password],
    database: config.db_name,
    connectionTimeoutMillis: 3000,
  });

  try {
    await c.connect();
    const r = await c.query(query);
    console.log(JSON.stringify(r.rows, null, 2));
    await c.end();
  } catch (e) {
    console.error('Query failed:', e.message);
    process.exit(1);
  }
})();
