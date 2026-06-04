#!/usr/bin/env node
import { spawn } from "node:child_process";

const env = { ...process.env, CODEX_HOME: "/Users/qiushile/.openclaw/agents/main/agent/acp-auth/codex-source" };
for (const key of []) {
  delete env[key];
}

const child = spawn("npx", ["@zed-industries/codex-acp@^0.11.1"], {
  stdio: "inherit",
  env,
});

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }
  process.exit(code ?? 1);
});

child.on("error", (error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
