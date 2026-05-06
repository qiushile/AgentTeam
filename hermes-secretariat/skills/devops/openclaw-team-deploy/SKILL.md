---
name: openclaw-team-deploy
description: Configure, deploy, and manage OpenClaw Team multi-agent deployment — model assignment, docker-compose config, remote deployment via SSH/Tailscale.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [openclaw, deployment, docker, model-config, devops]
    related_skills: [openclaw-troubleshooting]
---

# OpenClaw Team 部署配置

## 架构概览

- **源码目录（只读）**：`~/WorkStation/mine/claw/openclaw/`（本地），`/opt/openclaw/`（远程）
- **配置仓库（可改动）**：`~/WorkStation/mine/claw/ClawTeam/`（本地），`/opt/openclaw-team/`（远程）
- **本地 Secretariat**：`~/.openclaw/`，通过 LaunchAgent 管理
- **远程部署**：SSH `root@ubuntu24.tailcc8506.ts.net`（Tailscale）
- **远程 Sentinel**：systemd 服务 `openclaw.service`，EnvironmentFile=`/opt/openclaw-team/.env`
- **远程 Agents**：Docker Compose 管理，13+ 容器

## 模型分配模式

Team 使用两个主力模型：

| 模型 | 端点 | Agent（10个） |
|------|------|--------------|
| qwen3.6-plus | `coding.dashscope.aliyuncs.com/v1` | orchestrator, dev, ads, project, qa, spatial, game, finance, hr, supply-chain |
| GLM-5.1 (astron-code-latest) | `maas-coding-api.cn-huabei-1.xf-yun.com/v2` | pm, design, sales, marketing, support, expert, academic, legal |

### docker-compose.yml 配置模板

**qwen3.6-plus Agent：**
```yaml
environment:
  - OPENAI_API_KEY=${ALIYUN_API_KEY}
  - OPENAI_BASE_URL=${ALIYUN_BASE_URL}
  - OPENAI_MODEL=qwen3.6-plus
```

**GLM-5.1 Agent：**
```yaml
environment:
  - OPENAI_API_KEY=${IFLYTEK_API_KEY}
  - OPENAI_BASE_URL=${IFLYTEK_OPENAI_URL}
  - OPENAI_MODEL=${IFLYTEK_MODEL}
```

## .env 关键变量

```bash
# 阿里通义
ALIYUN_API_KEY=sk-sp-xxx
ALIYUN_BASE_URL=https://coding.dashscope.aliyuncs.com/v1

# 科大讯飞
IFLYTEK_API_KEY=app_id:api_secret
IFLYTEK_OPENAI_URL=https://maas-coding-api.cn-huabei-1.xf-yun.com/v2
IFLYTEK_ANTHROPIC_URL=https://maas-coding-api.cn-huabei-1.xf-yun.com/anthropic
IFLYTEK_MODEL=astron-code-latest

# 数据库
POSTGRES_PASSWORD=xxx
ORCHESTRATOR_DB_PASS=xxx
DEV_DB_PASS=xxx
# ... 各 Agent 独立 DB 密码
```

## 自动同步机制

ClawTeam 仓库已配置自动 Git 同步（`scripts/git-sync.sh`）：

- **本地**：LaunchAgent `com.clawteam.git-sync`，每 5 分钟运行一次
- **远端**：cron（`2-59/5 * * * *`），每 5 分钟运行一次
- 脚本自动判断：文件变更应 `git add` 提交还是加入 `.gitignore`
- 流程：更新 .gitignore → pull 远端 → 分类未跟踪文件 → commit & push

**同步日志**：
- 本地：`/tmp/git-sync-local.log`
- 远端：`/tmp/git-sync-remote.log`

手动触发同步：
```bash
# 本地
bash ~/WorkStation/mine/claw/ClawTeam/scripts/git-sync.sh local
# 远端
ssh root@ubuntu24.tailcc8506.ts.net "bash /opt/openclaw-team/scripts/git-sync.sh remote"
```

## 部署流程

### 标准部署

```bash
# 1. 本地编辑配置后提交
cd ~/WorkStation/mine/claw/ClawTeam
git add docker-compose.yml && git commit -m "feat(config): ..."
git add openclaw-secretariat/openclaw.json && git commit -m "feat(secretariat): ..."
git push

# 2. 远端自动同步（5分钟内生效），或手动触发
ssh root@ubuntu24.tailcc8506.ts.net "bash /opt/openclaw-team/scripts/git-sync.sh remote"

# 3. 如果 .env 有变更（.env 不在 git 中），单独 scp
scp .env root@ubuntu24.tailcc8506.ts.net:/opt/openclaw-team/.env

# 4. 重启受影响的容器（用 --no-deps 只重建变更的）
ssh root@ubuntu24.tailcc8506.ts.net "cd /opt/openclaw-team && docker compose up -d --no-deps openclaw-pm openclaw-design ..."
```

### SCP 快速部署（适合 .env 变更或小改动）

```bash
scp .env docker-compose.yml root@ubuntu24.tailcc8506.ts.net:/opt/openclaw-team/
ssh root@ubuntu24.tailcc8506.ts.net "cd /opt/openclaw-team && docker compose up -d --no-deps <affected-containers>"
```

### 验证

```bash
# 检查容器状态（启动后需等 1-2 分钟 health check 才会变 healthy）
ssh root@ubuntu24.tailcc8506.ts.net "sleep 60 && docker ps --format 'table {{.Names}}\t{{.Status}}'"

# 如果容器在 Restarting 循环，立即查看日志排查
ssh root@ubuntu24.tailcc8506.ts.net "docker logs <container> --tail 30"

# 检查 Sentinel
ssh root@ubuntu24.tailcc8506.ts.net "systemctl status openclaw.service --no-pager"
```

## Sentinel 故障排查

### systemd 服务管理
```bash
# 查看状态
ssh root@ubuntu24.tailcc8506.ts.net "systemctl status openclaw.service --no-pager"

# 启动/停止/重启
ssh root@ubuntu24.tailcc8506.ts.net "systemctl start/stop/restart openclaw.service"

# 查看日志
ssh root@ubuntu24.tailcc8506.ts.net "journalctl -u openclaw.service --no-pager -n 50"
```

### .env 占位符陷阱 ⚠️
Sentinel 的 `.env` 可能被意外还原为占位符（`FEISHU_SENTINEL_APP_ID=cli_xxxx`），但**长期运行的进程不受影响**——只有系统重启或服务重启时才会暴露问题。

**症状**：
- 飞书 WebSocket 连接失败：`code: 1000040346, system busy`
- Bot 身份查询 400：`GET /open-apis/bot/v3/info` 返回 `Bad Request`
- 进程正常运行但无法响应消息

**排查**：
```bash
# 确认实际加载的 App ID
ssh root@ubuntu24.tailcc8506.ts.net "grep FEISHU_SENTINEL_APP_ID /opt/openclaw-team/.env"
# 如果返回 cli_xxxx，说明是占位符

# 从备份中查找历史真实值
ssh root@ubuntu24.tailcc8506.ts.net "for f in /opt/openclaw-team/backups/env/.env.backup.*; do echo \"\$(basename \$f)\"; grep FEISHU_SENTINEL \$f; done"
```

**修复**：
1. 从飞书开放平台获取正确的 App ID / App Secret
2. 编辑 `/opt/openclaw-team/.env` 填入真实值
3. `ssh root@ubuntu24.tailcc8506.ts.net "systemctl restart openclaw.service"`

### 飞书 WebSocket 常见错误
| 错误码 | 含义 | 可能原因 |
|--------|------|----------|
| `1000040346, system busy` | 飞书拒绝连接 | App ID/Secret 错误、应用被禁用、权限不足 |
| `Cannot read properties of undefined (reading 'PingInterval')` | 代码 bug | WebSocket 连接失败后的错误处理缺陷（伴随出现） |
| `bot identity background retry N/5 failed` | Bot 身份验证失败 | App ID/Secret 不匹配，或应用未发布 |

## ⚠️ 关键陷阱

### API Key 端点兼容性
- `sk-sp-*` 前缀的 Key **仅**对 `coding.dashscope.aliyuncs.com/v1` 有效
- 用于 `dashscope.aliyuncs.com/compatible-mode/v1` 会返回 HTTP 401
- 两个端点**不共用**同一个 Key
- `.env` 中 `ALIYUN_BASE_URL` 和 `openclaw.json` 中 `models.providers.qwen.baseUrl` 必须保持一致

### 多模型切换注意事项
- OpenClaw 的 `OPENAI_API_KEY` + `OPENAI_BASE_URL` + `OPENAI_MODEL` 三个变量必须**匹配**
- 常见错误：使用阿里 Key 指向讯飞端点，或反过来
- 切换模型时三个变量必须**同时改**，不能只改模型名

### SSH/Tailscale 连接不稳定
- 远程服务器通过 Tailscale 访问，连接可能超时
- 大文件传输（如完整 docker-compose.yml）可能因网络波动中断
- 解决方案：
  - 使用 `scp` 前先用 `ssh -o ConnectTimeout=5` 测试连通性
  - 超时后等待 30-60 秒重试
  - 优先使用 git pull 方式部署
  - `docker compose up` 会被 Hermes 误识别为长驻进程，需使用 `background=true` + `process(action='wait')`

### 文件分类规则
- `.env`、运行时目录（`.openclaw/`）、日志（`*.log`）、密钥（`*.key`/`*.pem`）、缓存（`__pycache__/`、`.venv/`）等自动进入 `.gitignore`
- 配置文件、文档、脚本等代码文件自动 `git add` 并提交
- 新增的忽略模式会自动追加到 `.gitignore`
- 同步脚本本身维护在仓库中（`scripts/git-sync.sh`），两边共用

### 嵌套 Git 仓库清理
- `workspace-main/` 目录可能包含嵌套的 `.git`（早期 Agent 初始化遗留）
- 这会导致 `git status` 显示 `?? workspace-main/` 且无法纳入团队 git 管理
- 检测方法：`find /opt/openclaw-team -maxdepth 3 -name ".git" -type d`
- 清理方法：
  ```bash
  # 只删除嵌套 .git 目录，保留文件由 Team 统一管理
  rm -rf /opt/openclaw-team/openclaw-design/workspace-main/.git
  rm -rf /opt/openclaw-team/openclaw-support/workspace-main/.git
  ```
- `.gitignore` 应只忽略 `workspace-main/.openclaw/`（运行时目录），**不要**忽略整个 `workspace-main/`
- 然后 `git add -f workspace-main/` 纳入团队管理

### Git 同步操作规范
- **先分析再操作**：遇到分歧或冲突时，先用 `git status --short`、`git diff --name-status`、`git diff` 查看具体变更，不要盲目 stash/reset
- **禁止随意使用 `git reset --hard`**：会永久丢失未提交的本地修改。如必须对齐远端，先 `git stash push --include-untracked` 保存
- **保持线性 commit log**：同步时使用 `git pull --rebase`，避免 merge commit
- **Rebase 冲突处理**：
  - 仅限 `scripts/git-sync.sh` 或 `.gitignore` 的 auto-sync 冲突 → `git rebase --skip`（跳过重复提交）
  - 真实业务文件冲突 → 中止 rebase，分析后手动解决
- **长命令拆分**：SSH/Tailscale 不稳定时，把 `reset + clean + pull` 等长命令拆成独立步骤，每步单独超时控制
- **Tailscale 连接检测**：先 `tailscale status` 确认可达性，超时用 `ConnectTimeout=10` + `ServerAliveInterval=5`

### Git 提交拆分
- 手动部署时，建议将变更拆分为多个独立 commit，按功能模块分离
- 自动同步时脚本生成统一 commit message（`sync(dirs): timestamp`）

### Docker env_file 变量不展开陷阱 ⚠️
- Docker 的 `env_file` **不会展开** `${VAR}` 变量引用
- 错误示例：`.env` 中写 `ALIYUN_COMPAT_KEY=${ALIYUN_API_KEY}` → 容器收到的是字面字符串 `${ALIYUN_API_KEY}`，不是实际 Key
- 正确做法：`.env` 中每个变量必须写**完整真实值**，不能互相引用
- 如果之前写的是引用，需要用 `sed` 替换为真实值后重启容器

### 健康检查延迟
- 容器启动后 `health: starting` 状态会持续 1-2 分钟
- 这是正常的，health check 按间隔轮询，不需要干预
- 如果 3 分钟后仍是 `health: starting` 或 `unhealthy`，查看日志排查

## 本地 Secretariat 配置

编辑 `~/.openclaw/openclaw.json` 添加新模型 provider：

```json
{
  "models": {
    "providers": {
      "iflytek": {
        "baseUrl": "${IFLYTEK_OPENAI_URL}",
        "api": "openai-completions",
        "models": [{
          "id": "astron-code-latest",
          "name": "GLM-5.1",
          "reasoning": true,
          "input": ["text", "image"],
          "contextWindow": 200000,
          "maxTokens": 65536,
          "api": "openai-completions"
        }]
      }
    }
  },
  "auth": {
    "profiles": {
      "iflytek:default": {
        "provider": "iflytek",
        "mode": "api_key"
      }
    }
  }
}
```

重启生效：`launchctl stop ai.openclaw.gateway && launchctl start ai.openclaw.gateway`

## 端口映射

| Agent | Gateway 端口 | Web 端口 |
|-------|:-----------:|:-------:|
| orchestrator | 18001 | 13001 |
| dev | 18002 | 13002 |
| pm | 18003 | 13003 |
| design | 18004 | 13004 |
| ads | 18005 | 13005 |
| sales | 18006 | 13006 |
| marketing | 18007 | 13007 |
| project | 18008 | 13008 |
| qa | 18009 | 13009 |
| support | 18010 | 13010 |
| spatial | 18011 | 13011 |
| expert | 18012 | 13012 |
| game | 18013 | 13013 |
| secretariat（本地） | 18789 | — |
