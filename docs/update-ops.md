# 更新操作手册

## 概述

本项目的更新体系覆盖两个核心组件：
- **Hermes Agent** — 主机部署，git 管理，有本地 patch
- **OpenClaw** — Docker 容器部署，18 个实例

## 发布频率

| 组件 | 平均间隔 | 更新检查建议 |
|------|----------|-------------|
| Hermes Agent | 6.3 天 | 每周一 |
| OpenClaw 7.x | 10.5 天 | 每两周 |

## 自动检测

### Cron 配置

| Job | 频率 | 命令 |
|-----|------|------|
| update-check-hermes | 每周一 9:00 | `bash /opt/openclaw-team/monitor/update-check.sh hermes` |
| update-check-openclaw | 每两周一 9:00 | `bash /opt/openclaw-team/monitor/update-check.sh openclaw` |

### 手动检测

```bash
# 检查全部
bash /opt/openclaw-team/monitor/update-check.sh all

# 只检查 Hermes
bash /opt/openclaw-team/monitor/update-check.sh hermes

# 只检查 OpenClaw
bash /opt/openclaw-team/monitor/update-check.sh openclaw
```

## 执行更新

### Hermes Agent

```bash
# 正常更新（含验证）
bash /opt/openclaw-team/scripts/update-hermes.sh

# 跳过验证（快速更新）
bash /opt/openclaw-team/scripts/update-hermes.sh --skip-verify
```

**更新流程：**
1. 记录当前版本（用于回滚）
2. 检查并 stash 本地修改
3. `git pull origin main`
4. 运行 patch 兼容性检查
5. 重新应用本地 patch
6. 恢复 stash
7. 验证

### OpenClaw

```bash
# 预览（不执行）
bash /opt/openclaw-team/scripts/update-openclaw.sh --dry-run

# 更新全部容器
bash /opt/openclaw-team/scripts/update-openclaw.sh

# 只更新指定容器
bash /opt/openclaw-team/scripts/update-openclaw.sh --service openclaw-dev
```

**更新流程：**
1. 记录当前镜像版本
2. 查询 GitHub 最新稳定版
3. 检查新镜像是否存在
4. 更新 `docker-compose.yml` 镜像引用
5. 逐个停止 → 删除 → 重建容器
6. 等待健康检查
7. 汇总报告

## 回滚

### 查看可用回滚点

```bash
bash /opt/openclaw-team/scripts/rollback.sh
```

### 执行回滚

```bash
# 回滚 Hermes
bash /opt/openclaw-team/scripts/rollback.sh hermes 20260813_090000

# 回滚 OpenClaw
bash /opt/openclaw-team/scripts/rollback.sh openclaw 20260813_090000
```

## 本地 Patch 管理

### 查看 patch 状态

```bash
bash /opt/openclaw-team/monitor/patch-compatibility.sh
```

### 当前 patch 清单

| ID | 目标 | 状态 | 说明 |
|----|------|------|------|
| feishu-approval-card | hermes-agent | not_submitted | 飞书审批卡片显示命令预览 |

### 添加新 patch

1. 生成 patch 文件放入 `patches/<repo>/` 目录
2. 更新 `patches/inventory.json` 添加记录
3. 测试 patch 可干净应用

### 清理已合入的 patch

当 `patch-compatibility.sh` 显示某个 patch 状态为 `merged` 时：
1. 从 `patches/inventory.json` 中删除该条目
2. 删除对应的 `.patch` 文件
3. commit 变更

## 更新后验证

### Hermes Agent

```bash
# 版本确认
hermes --version

# 飞书连通性（发消息测试）
# 在飞书群中 @bot 发送测试消息

# 检查日志
journalctl -u hermes-agent --since "5 min ago"
```

### OpenClaw

```bash
# 容器健康状态
docker ps --filter "name=openclaw-" --format "table {{.Names}}\t{{.Status}}"

# 逐个检查日志
for c in $(docker ps --filter "name=openclaw-" --format "{{.Names}}"); do
    echo "=== $c ==="
    docker logs --tail 5 "$c" 2>&1
done
```

## 文件清单

```
/opt/openclaw-team/
├── monitor/
│   ├── update-check.sh              # 版本检测入口
│   ├── update-check-state.json      # 检测结果（gitignore）
│   └── patch-compatibility.sh       # patch 兼容性检查
├── scripts/
│   ├── update-hermes.sh             # Hermes 更新执行
│   ├── update-openclaw.sh           # OpenClaw 滚动更新
│   └── rollback.sh                  # 回滚脚本
├── patches/
│   ├── inventory.json               # patch 清单
│   ├── hermes/
│   │   └── feishu-approval-card.patch
│   └── README.md
└── docs/
    └── update-ops.md                # 本文件
```
