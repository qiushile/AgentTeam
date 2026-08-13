# 本地 Patch 管理

本目录维护所有本地独有的代码补丁，用于在 upstream 未合入时保持自定义功能。

## 目录结构

```
patches/
├── inventory.json          # patch 清单 + upstream 追踪状态
├── hermes/                 # Hermes Agent 相关 patch
│   └── feishu-approval-card.patch
└── README.md               # 本文件
```

## 工作流程

### 更新前检查

```bash
bash /opt/openclaw-team/monitor/patch-compatibility.sh
```

检查每个 patch 是否已被 upstream 合入：
- **merged** → 可安全删除本地 patch
- **not_submitted / rejected** → 更新后需重新应用
- **superseded** → upstream 用了不同方式，需评估是否还需要本地 patch

### 应用 patch

```bash
cd /opt/WorkStation/hermes-agent
git apply /opt/openclaw-team/patches/hermes/feishu-approval-card.patch
```

### 更新 inventory.json

每次 patch 状态变化时更新 `inventory.json`：
- `upstream_status`: not_submitted / pr_open / merged / rejected / superseded
- `applied`: 当前是否已应用到本地代码
- `last_verified`: 最后一次验证兼容性的日期

## 当前 Patch 清单

| ID | 目标 | 状态 | 说明 |
|----|------|------|------|
| feishu-approval-card | hermes-agent | not_submitted | 飞书审批卡片显示命令预览 |

## 原则

1. **尽量 upstream**：能提交 PR 就提交，减少本地维护负担
2. **定期清理**：每次大版本更新后检查 merged 状态的 patch，及时删除
3. **文档化**：每个 patch 必须在 inventory.json 中有完整记录
