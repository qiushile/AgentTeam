# OpenClaw 完全知识手册

> **版本**: 2026.5.7 | **许可证**: MIT | **源码**: https://github.com/openclaw/openclaw | **文档**: https://docs.openclaw.ai

---

## 目录

1. [OpenClaw 是什么？](#1-openclaw-是什么)
2. [核心架构](#2-核心架构)
3. [AI 模型配置](#3-ai-模型配置)
4. [Agent 系统](#4-agent-系统)
5. [消息通道](#5-消息通道)
6. [技能系统](#6-技能系统)
7. [插件系统](#7-插件系统)
8. [记忆系统](#8-记忆系统)
9. [工具系统](#9-工具系统)
10. [会话管理](#10-会话管理)
11. [自动化能力](#11-自动化能力)
12. [安全体系](#12-安全体系)
13. [配置管理](#13-配置管理)
14. [部署架构](#14-部署架构)
15. [常见问题](#15-常见问题)

---

## 1. OpenClaw 是什么？

**OpenClaw** 是一个**自托管、开源的 AI 代理网关（AI Agent Gateway）**——将大语言模型（LLM）变成能跨平台通信、使用工具、自主执行任务的智能代理。

### 核心特点

| 特点 | 说明 |
|------|------|
| **自托管** | 运行在你的服务器上，数据完全私有 |
| **多平台** | 一个 Gateway 同时服务 12+ 聊天平台 |
| **Agent 原生** | 不只是聊天，能读文件、执行命令、调 API |
| **开源** | MIT 许可，社区驱动 |
| **文件化配置** | 透明、可版本控制、可定制 |

### 与 ChatGPT/Claude 的区别

| 能力 | ChatGPT/Claude | OpenClaw |
|------|---------------|----------|
| 跨平台消息 | ❌ | ✅ 12+ 平台同时 |
| 持久记忆 | ❌（新对话就忘） | ✅ 文件系统永久存储 |
| 工具调用 | ⚠️ 有限 | ✅ 完整工具链 |
| 读文件 | ❌ | ✅ 直接读写 |
| 执行命令 | ❌ | ✅ Shell/API |
| 数据归属 | 对方服务器 | **你的服务器** |
| 开源 | ❌ | ✅ MIT |

### 项目背景

- 源自 WhatsApp 网关项目 **Warelay**
- 演变为 **Clawd** → **Molty** → **OpenClaw**（2026年1月30日更名）
- 名字含义：**OPEN + CLAW = 开源，对所有人开放**
- 完全免费，无商业版/付费版/企业版

---

## 2. 核心架构

```
┌─────────────────────────────────────────────────────────┐
│                    OpenClaw Gateway                      │
│                    (单进程守护进程)                       │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │ Channels │  │  Agents  │  │  Skills  │  │ Plugins │ │
│  │  (通道)   │←→│  (代理)   │←→│  (技能)   │←→│ (插件)  │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘ │
│       │             │            │              │      │
│  ┌────▼─────┐  ┌────▼────┐  ┌───▼──────┐  ┌───▼─────┐ │
│  │ Messages │  │ Memory  │  │  Tools   │  │ Models  │ │
│  │ (消息流)  │  │ (记忆)  │  │ (工具)    │  │(模型提供商)│ │
│  └──────────┘  └─────────┘  └──────────┘  └─────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │           WebSocket API (端口 18789)               │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │           配置系统 (openclaw.json)                  │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 技术栈

| 层级 | 技术 |
|------|------|
| **语言** | TypeScript |
| **运行时** | Node.js（必需），Bun（可选） |
| **数据库** | node:sqlite（会话），LanceDB（可选，向量记忆） |
| **通信协议** | WebSocket（JSON 帧），HTTP（Canvas/A2UI） |
| **AI 接口** | OpenAI 兼容 API |
| **配置格式** | JSON5（支持注释和尾逗号） |
| **进程管理** | systemd / LaunchAgent / Scheduled Task |

---

## 3. AI 模型配置

### 已配置模型（4 提供商 × 6 模型）

| 提供商 | 模型 | 上下文窗口 | 推理 | 多模态 |
|--------|------|-----------|------|--------|
| **阿里云** | qwen3.6-plus | **1M tokens** | ✅ | ✅ 文本+图像 |
| 阿里云 | qwen3-coder-plus | **1M tokens** | ❌ | 仅文本 |
| **智谱** | glm-5 | 202K tokens | ✅ | 仅文本 |
| 智谱 | glm-4.7 | 202K tokens | ✅ | 仅文本 |
| **Kimi** | kimi-k2.5 | 262K tokens | ✅ | ✅ 文本+图像 |
| **MiniMax** | MiniMax-M2.5 | 196K tokens | ✅ | 仅文本 |

**主模型**：`aliyun/qwen3.6-plus`

### 添加新模型

OpenClaw 兼容**任何 OpenAI API 格式**的模型提供商：

```json5
{
  models: {
    providers: {
      openai: {
        baseUrl: "https://api.openai.com",
        apiKey: "${OPENAI_API_KEY}",
        api: "openai-completions",
        models: [{
          id: "gpt-4o",
          name: "GPT-4o",
          input: ["text", "image"],
          reasoning: true,
          contextWindow: 128000,
          maxTokens: 16384
        }]
      }
    }
  }
}
```

---

## 4. Agent 系统

**Agent（代理）** = 有性格、记忆、技能、能自主行动的 AI 角色。

### Agent 文件结构

```
~/.openclaw/agents/<agentId>/
├── SOUL.md          ← 性格和行为风格
├── MEMORY.md        ← 核心记忆索引
├── USER.md          ← 用户信息
├── AGENTS.md        ← 工作规范
├── IDENTITY.md      ← 身份标识
├── TOOLS.md         ← 本地工具备注
├── HEARTBEAT.md     ← 定期检查任务
├── workspace/       ← 工作数据（CSV、报告等）
├── memory/          ← 每日日志
└── sessions/        ← 会话记录
```

### 当前配置的 3 个 Agent

| Agent ID | 工作空间 | 角色 |
|----------|---------|------|
| `supply-chain-inventory-forecaster` | `~/.openclaw/workspace-supply-chain-inventory-forecaster` | 库存预测专家（默认） |
| `supply-chain-route-optimizer` | `~/.openclaw/workspace-supply-chain-route-optimizer` | 路线优化专家 |
| `supply-chain-vendor-evaluator` | `~/.openclaw/workspace-supply-chain-vendor-evaluator` | 供应商评估专家 |

### Agent Loop（执行流程）

```
1. 接收消息（Gateway RPC: agent）
2. 解析会话（sessionKey/sessionId）
3. 加载工作空间文件（SOUL.md、MEMORY.md 等）
4. 加载技能快照
5. 组装系统提示（Base Prompt + Skills + Context）
6. 调用 LLM 推理
7. 流式输出 assistant/tool deltas
8. 执行工具调用
9. 持久化会话记录
10. 发送回复
```

---

## 5. 消息通道

### 已支持平台（12+）

| 通道 | 类型 | 说明 |
|------|------|------|
| 飞书 (Feishu) | 企业办公 | ✅ 已配置（当前禁用） |
| 钉钉 (DingTalk) | 企业办公 | 中国企业常用 |
| 企业微信 (WeCom) | 企业办公 | 微信企业版 |
| 微信 (WeChat) | 社交 | 中国用户最常用 |
| Telegram | 社交 | 国际通讯，配置简单 |
| Discord | 社区 | 社区/团队协作 |
| WhatsApp | 社交 | 国际通讯（via Baileys） |
| Signal | 社交 | 隐私通讯 |
| Slack | 企业办公 | 海外团队常用 |
| iMessage | 社交 | Apple 生态 |
| Microsoft Teams | 企业办公 | 微软企业办公 |
| WebChat | Web UI | 内置网页聊天 |

### 添加通道

```bash
# 启用飞书
openclaw config set channels.feishu.enabled true
openclaw config set channels.feishu.appId "你的AppID"
openclaw config set channels.feishu.appSecret "你的AppSecret"

# 添加 Telegram
openclaw config set channels.telegram.enabled true
openclaw config set channels.telegram.token "你的Bot Token"
```

### Agent 绑定

```bash
openclaw config set bindings --json '[
  {"agentId":"supply-chain-inventory-forecaster","match":{"channel":"feishu"}}
]'
```

---

## 6. 技能系统

**Skills（技能）** = 可复用的功能模块，教 Agent 如何完成特定任务。

### 已安装技能（58 个，18 个已激活）

| 技能 | 功能 | 触发场景 |
|------|------|---------|
| ☔ **weather** | 天气查询与预报 | 问天气、温度、下雨 |
| 🔍 **clawhub** | 技能商店搜索/安装 | 找新技能 |
| 📊 **diagram-maker** | SVG/HTML/Excalidraw 图表 | 流程图、架构图 |
| 📝 **feishu-doc** | 飞书文档读写 | 飞书文档操作 |
| 📁 **feishu-drive** | 飞书云盘管理 | 文件管理 |
| 🔐 **feishu-perm** | 飞书权限/分享 | 权限设置 |
| 📚 **feishu-wiki** | 飞书知识库导航 | 知识库操作 |
| 🩺 **healthcheck** | 系统安全审计 | 安全检查 |
| 🎭 **meme-maker** | 表情包生成 | 生成 meme |
| 📱 **node-connect** | 设备配对诊断 | 连接问题 |
| 🐛 **node-inspect-debugger** | Node.js 调试 | 断点调试 |
| 📓 **notion** | Notion 页面/搜索 | Notion 操作 |
| 🎙️ **openai-whisper-api** | 语音转文字 | 音频转录 |
| 🐍 **python-debugpy** | Python 调试 | 远程调试 |
| ✏️ **skill-creator** | 创建/编辑技能 | 制作 SKILL.md |
| 🧪 **spike** | 快速原型验证 | 可行性测试 |
| 🔄 **taskflow** | 多步骤任务编排 | 复杂任务流 |
| 📬 **taskflow-inbox-triage** | 收件箱分类 | 消息分类 |

### 技能文件结构

```
skills/<name>/
├── SKILL.md          ← 技能说明（必须）
├── assets/           ← 可选资源文件
└── scripts/          ← 可选脚本
```

### 安装新技能

```bash
# 搜索 ClawHub
openclaw skills search <关键词>

# 安装技能
openclaw skills install <技能名>
```

---

## 7. 插件系统

**Plugins（插件）** = 为 Gateway 提供底层能力的扩展模块。

### 已启用插件（5 个）

| 插件 | 功能 |
|------|------|
| **postgres-tool** | PostgreSQL 数据库查询 |
| **task-notifier** | 任务通知推送 |
| **feishu** | 飞书通道集成 |
| **minimax** | MiniMax 模型支持 |
| **kimi** | Kimi 模型支持 |

**允许但未启用**：`memory-lancedb`（语义记忆向量数据库）

### 插件 vs 技能

| | **插件** | **技能** |
|--|---------|---------|
| **层次** | 基础设施层 | 能力层 |
| **作用对象** | Gateway | Agent |
| **加载时机** | Gateway 启动时 | Agent 需要时 |
| **类比** | 公司 IT 系统 | 员工专业培训 |

---

## 8. 记忆系统

### 三层架构

```
┌─────────────────────────────────────────┐
│     短期记忆 (Session Context)           │
│  当前对话历史，会话结束即消失             │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│     长期记忆 (Memory Files)              │
│  MEMORY.md + memory/YYYY-MM-DD.md       │
│  永久存储在文件系统中                    │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│   语义记忆 (Vector Embeddings)           │
│  LanceDB 向量数据库                      │
│  支持自然语言搜索历史                    │
└─────────────────────────────────────────┘
```

### 记忆层级对比

| 层级 | 存储 | 生命周期 | 用途 |
|------|------|---------|------|
| **短期** | Gateway 内存 | 会话期间 | 当前对话上下文 |
| **长期** | 文件系统 | 永久 | 核心索引 + 每日日志 |
| **语义** | LanceDB | 永久 | 自然语言搜索 |

### 启动时自动加载

```
SOUL.md（性格）→ USER.md（用户）→ 今天/昨天日志 → MEMORY.md（核心索引）
```

---

## 9. 工具系统

### 当前授权

```json
{
  "tools": {
    "allow": ["group:fs", "group:runtime", "read", "write", "edit"],
    "deny": ["file_delete"]
  }
}
```

| 工具组 | 能力 |
|--------|------|
| group:fs | 文件系统操作（读、写、编辑、查找） |
| group:runtime | 运行时操作（执行命令、环境变量） |
| read | 读取文件内容 |
| write | 创建/覆盖文件 |
| edit | 精确文本编辑 |
| ~~file_delete~~ | ~~删除文件~~（已禁止） |

---

## 10. 会话管理

### 会话重置模式

| 模式 | 触发条件 | 配置 |
|------|---------|------|
| **每日重置** | 每天凌晨 4 点 | `{ mode: "daily", atHour: 4 }` |
| **空闲重置** | 空闲 N 分钟后 | `{ mode: "idle", idleMinutes: 120 }` |
| **手动重置** | 用户输入 `/new` 或 `/reset` | — |

### DM 会话隔离

```json5
{ session: { dmScope: "per-channel-peer" } }  // 推荐
```

| 模式 | 范围 |
|------|------|
| `main`（默认） | 所有 DM 共享一个会话 |
| `per-channel-peer` | 每个频道+发送者独立会话 ✅ |
| `per-peer` | 每个发送者跨频道共享 |

### 会话存储

```
~/.openclaw/agents/<agentId>/sessions/
├── sessions.json              ← 会话元数据
└── <sessionId>.jsonl          ← 对话转录
```

---

## 11. 自动化能力

### Heartbeat（心跳）

- **默认间隔**：30 分钟
- **功能**：定时检查 Agent 状态、数据更新、告警触发
- **配置**：`openclaw config set agents.defaults.heartbeat.every "30m"`

### Cron（定时任务）

- 每次运行新建会话
- 适合定时报告生成

### Taskflow（任务流）

- 多步骤任务编排
- 支持子任务和等待

### Hooks（钩子）

- 事件驱动脚本
- `agent:bootstrap`、命令钩子等

---

## 12. 安全体系

### 三层防御

```
1️⃣ 身份优先（谁可以和机器人说话）
    ↓
2️⃣ 范围控制（机器人能在哪里行动）
    ↓
3️⃣ 模型兜底（假设模型可被操纵，限制爆炸半径）
```

### DM 访问策略

| 策略 | 行为 |
|------|------|
| `pairing`（默认） | 未知发送者需配对码 |
| `allowlist` | 白名单外直接拒绝 |
| `open` | 任何人可 DM（需显式配置） |
| `disabled` | 完全忽略 DM |

### 安全审计

```bash
openclaw security audit          # 检查安全问题
openclaw security audit --deep   # 深度检查
openclaw security audit --fix    # 自动修复
```

### 提示注入防护

- 工具策略（允许/禁止操作）
- 执行审批（敏感命令需确认）
- 沙箱隔离（限制文件系统访问）
- 通道白名单（谁可以触发）
- 选择抗注入能力强的模型

---

## 13. 配置管理

### 核心文件

`~/.openclaw/openclaw.json`（JSON5 格式，支持注释）

### 四种编辑方式

| 方式 | 命令 | 适合场景 |
|------|------|---------|
| **交互式向导** | `openclaw configure` | 新手、全面配置 |
| **CLI 单行** | `openclaw config set <path> <value>` | 快速改单个字段 |
| **Control UI** | 浏览器 `http://127.0.0.1:18789` | 可视化编辑 |
| **直接编辑** | 编辑文件 | 批量修改 |

### 热重载

配置修改后**自动生效**，无需手动重启。

### 常用命令

```bash
# 查看配置
openclaw config get agents.defaults.model.primary

# 修改配置
openclaw config set agents.defaults.model.primary "zhipu/glm-5"

# 删除配置
openclaw config unset channels.feishu.appId

# 查看 schema
openclaw config schema
```

---

## 14. 部署架构

### 支持平台

| 类型 | 平台 |
|------|------|
| **桌面/服务器** | Linux、macOS、Windows |
| **移动端（Node）** | iOS、Android |
| **VPS 托管** | Fly.io、Hetzner、GCP、Azure、exe.dev |

### 进程管理

- Linux → systemd 用户服务
- macOS → LaunchAgent
- Windows → Scheduled Task

### 远程访问

```bash
# SSH 隧道
ssh -N -L 18789:127.0.0.1:18789 user@gateway-host

# 或通过 Tailscale/VPN
```

### 快速开始

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon
openclaw gateway status
```

---

## 15. 常见问题

### Q: OpenClaw 是免费的吗？
**A**: 完全免费，MIT 开源许可。无商业版/付费版。你只需承担服务器和模型 API 的运行成本。

### Q: 支持哪些 AI 模型？
**A**: 任何兼容 OpenAI API 格式的模型都可以接入。当前配置了阿里云、智谱、Kimi、MiniMax 共 6 个模型。

### Q: 数据存在哪里？
**A**: 全部在你自己的服务器上。配置、记忆、会话、技能都是本地文件。

### Q: 如何添加新的消息通道？
**A**: 在目标平台创建应用获取 Token，然后通过 `openclaw config set channels.<平台>.enabled true` 添加。

### Q: Agent 能记住之前的对话吗？
**A**: 能。短期记忆保存在会话中，长期记忆保存在文件系统中，语义记忆可通过 LanceDB 实现自然语言搜索。

### Q: 如何保护安全？
**A**: Token 认证 + DM 配对/白名单 + 工具权限 + 沙箱隔离 + 文件权限管控。运行 `openclaw security audit` 一键检查。

### Q: 心跳可以调快吗？
**A**: 可以，但不推荐低于 5 分钟。30 秒间隔会产生每天 2,880 次 LLM 调用，浪费资源。

### Q: 如何备份配置？
**A**: 配置都是文件，直接备份 `~/.openclaw/` 目录即可。

### Q: 开源 vs 商业版？
**A**: 只有一个版本——完全开源。没有付费功能、没有企业版、没有功能限制。

---

*文档生成时间：2026-09-02 | 基于 OpenClaw v2026.5.7*
