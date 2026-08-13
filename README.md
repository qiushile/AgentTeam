# ClawTeam: 企业级联邦式多 Agent 协作架构

[![OpenClaw Version](https://img.shields.io/badge/OpenClaw-v2026.3.7+-blue.svg)](https://github.com/openclaw/openclaw)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

ClawTeam 是一个为软件开发公司打造的 **“联邦式全生命周期 AI 数字团队”** 落地模板。本项目基于 [OpenClaw](https://github.com/openclaw/openclaw) 框架，专为**高性能无 GPU 服务器**（如高核高内存的 Ubuntu）以及**云端聚合算力**（如阿里云百炼 Coding Plan）场景进行了深度优化。

## 核心特性架构

*   **联邦式中枢调度 (Orchestrator-Led):** 采用统一协调中枢接收前端（企业微信/钉钉）请求，通过意图识别和向量匹配，精准将任务路由给后端的专业 Agent（产品、研发、测试等）。
*   **Docker 物理级隔离与沙箱:** 所有的专业 Agent 作为独立的 Docker 容器运行，针对涉及代码执行的高危 Agent（如 Developer Helper、Auto-Tester）默认采用 `sandbox` / `sandbox-browser` 隔离镜像，保障宿主机安全。
*   **PostgreSQL 统一知识底座:** 放弃分散的本地文件记忆，所有 Agent 接入搭载 `pgvector` 扩展的统一 PostgreSQL 数据库。
*   **RLS 行级安全与 Schema 隔离:** 在数据库层为不同 Agent 分配专属 Schema（如 `pm_schema`, `dev_schema`）保护私有知识，并通过 行级安全策略 (RLS) 实现细粒度的共享表（如 `shared.tasks`）读写协同。
*   **大模型算力池化 (Coding Plan 优化):** 所有 Agent 共享统一的阿里云 Dashscope API Key，但在各自的 `openclaw.json` 中配置最匹配岗位的模型（如研发配置 `qwen2.5-coder` / `glm-5`，中枢配置 `qwen-max`），并强制启用 Fallback 防限流降级链。

## 团队成员 (Agent Roster)

本团队模板预置了以下核心角色，可按需启动：
1.  **Orchestrator (协调中枢)**: 对接企微/钉钉，进行意图识别与任务分发。
2.  **Product Manager (产品经理)**: 竞品分析、需求定义，将草稿写入共享数据库。
3.  **Developer Helper (开发助手)**: 挂载代码库，基于需求生成代码、审查安全漏洞。
4.  **QA Agent (测试与质量保障)**: 自动编写用例、维护缺陷库。
5.  **DevOps (运维与日志分析)**: 服务器巡检、线上日志分析异常诊断。

## 目录结构

```text
ClawTeam/
├── .env                              # 全局环境变量配置（需手动创建并注入密钥）
├── docker-compose.yml                # 容器集群编排，统筹启动所有 Agent
├── init.sql                          # PostgreSQL 初始化脚本（Schema、角色与 RLS 策略）
│
├── openclaw-orchestrator/           # 协调中枢工作区
│   ├── openclaw.json                 # 全局网关、模型与权限配置
│   ├── SOUL.md                       # 中枢路由分发规则
│   └── AGENTS.md
│
├── openclaw-pm/                     # 产品部门工作区
│   ├── HEARTBEAT.md                  # 定时任务（如早间竞品简报）
│   └── ...
│
├── openclaw-dev/                    # 研发部门工作区
│   └── ...
│
└── ... (其他角色工作区)
```

## 快速部署指南

**环境前置要求：** Docker, Docker Compose, 搭载高内存的无 GPU 服务器 (如 Ubuntu)。

### 1. 克隆项目与预备配置
```bash
git clone https://github.com/qiushile/ClawTeam.git
cd ClawTeam

# 根据模板创建环境变量文件
cp .env.example .env
```
编辑 `.env` 文件，填入你的 `ALIYUN_API_KEY` / `ALIYUN_BASE_URL`（阿里云百炼）、数据库密码以及用于跨容器内网调用的 `SECRET_GATEWAY_TOKEN`。

对于 Sentinel / MoltGuard 场景，仓库内配置已支持直接使用 `ALIYUN_*` 变量，无需再额外准备 `OPENAI_*` 别名。

### 2. 启动底层服务与 Agent 联邦
一键拉起包括 PostgreSQL 底座在内的所有核心服务：
```bash
docker-compose up -d
```

### 3. 验证运行状态
检查数据库初始化与向量扩展加载情况：
```bash
docker logs openclaw-postgres
```
检查 Orchestrator 中枢是否成功启动并监听指定端口（默认 18789）：
```bash
docker logs -f openclaw-orchestrator
```

## 通信与安全声明

*   **Zero Public Ports:** 后端专业 Agent（Dev, PM 等）容器**绝对不要**映射端口到宿主机公网，所有通信均通过 Docker 内部网桥或 PostgreSQL `LISTEN/NOTIFY` 异步机制完成。
*   **Gateway Token:** 本项目已针对 OpenClaw v2026.3.7+ 的安全要求，在所有 `openclaw.json` 中强制启用了 `gateway.auth.mode: "token"` 认证，杜绝无鉴权越权访问。

## 灰度落地建议

针对企业实际落地，建议**不要一次性启动所有容器**。推荐优先启动 `Orchestrator` 与 `DevOps (Log Analyzer)` 进行灰度测试，因为日志分析对生产环境的干扰最小且提效最明显。待运转稳定后，再逐步拉起 `PM` 与 `Dev` 完成核心业务流闭环。

## 更新体系

本项目内置了完整的版本更新管理体系，覆盖 Hermes Agent 和 OpenClaw 两个核心组件。

### 快速命令

```bash
# 检测更新
bash monitor/update-check.sh all

# 更新 Hermes Agent
bash scripts/update-hermes.sh

# 更新 OpenClaw 容器
bash scripts/update-openclaw.sh

# 回滚
bash scripts/rollback.sh <component> <timestamp>

# 检查 patch 兼容性
bash monitor/patch-compatibility.sh
```

### 自动检测

通过 Hermes cron job 定期检测：
- **Hermes Agent**: 每周一 9:00
- **OpenClaw**: 每两周一 9:00

### 本地 Patch 管理

`patches/` 目录维护所有本地独有的代码补丁，`patches/inventory.json` 追踪 upstream 合入状态。

详见 [docs/update-ops.md](docs/update-ops.md)

## 参与贡献
欢迎提交 PR 改进团队工作流或添加新的专业 Agent 配置模板！
```
