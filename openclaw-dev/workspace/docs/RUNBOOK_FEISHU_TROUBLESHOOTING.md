# 飞书连接排查 Runbook

> 创建日期: 2026-08-24  
> 维护者: 研发部高级研发专家 (dev_user)  
> 触发条件: 飞书消息发送失败、tenant_access_token 错误、应用配置异常

---

## 一、故障诊断流程

### Step 1: 确认错误类型

| 错误信息 | 原因 | 处理流程 |
|---|---|---|
| `tenant_access_token code: 10003, msg: invalid param` | App ID/Secret 无效 | 转 Step 2 |
| `app_access_token expired` | Token 过期（自动刷新） | 等待自动刷新 |
| `chat not found` | chatId 无效 | 转 Step 3 |
| `user not found` | openId 无效 | 转 Step 4 |
| `permission denied` | 应用权限不足 | 转 Step 5 |

### Step 2: App ID/Secret 无效 (当前阻塞项)

**当前状态**: `FEISHU_APP_ID=cli_xxxx`, `FEISHU_APP_SECRET=***` (占位值)

```bash
# 2.1 检查当前配置
env | grep FEISHU_APP_ID
env | grep FEISHU_APP_SECRET

# 2.2 更新为有效凭证（需创始人提供）
export FEISHU_APP_ID='cli_aXXXXXXXXXXXXXXX'
export FEISHU_APP_SECRET='your_app_secret_here'

# 2.3 重启 Gateway 使配置生效
openclaw gateway restart

# 2.4 验证
# 发送测试消息到创始人飞书
```

**所需权限**（飞书开放平台）:
- `im:message` — 发送消息
- `contact:user.base:readonly` — 读取用户信息

### Step 3: chatId 无效

```bash
# 3.1 从飞书 URL 获取 chatId
# 飞书群聊 URL 格式: https://xxx.feishu.cn/group/chatId

# 3.2 使用 feishu_chat tool 获取群成员
# action: members, chatId: <from URL>

# 3.3 验证 chatId 格式
# 群聊: oc_xxxxxxxxxx
# 私聊: 使用 user:open_id 格式
```

### Step 4: openId 无效

```bash
# 4.1 从飞书事件 payload 获取 open_id
# 事件回调中包含 sender.open_id

# 4.2 使用 feishu_chat member_info 验证
# action: member_info, member_id: <open_id>

# 4.3 创始人的 open_id: ou_cce9fa7cfa2ef7779ae0cc7f0313f57d
```

### Step 5: 应用权限不足

**在飞书开放平台检查**:
1. 进入应用详情 → 权限管理
2. 确保已开通以下权限:
   - `im:message` (发送消息)
   - `im:message:send_as_bot` (以应用身份发送)
   - `contact:user.base:readonly` (读取用户基本信息)
3. 发布新版本使权限生效

---

## 二、多应用配置

当前环境中存在多个飞书应用:

| 应用 | App ID 前缀 | 用途 | 状态 |
|---|---|---|---|
| FEISHU_PM | cli_xxxx | 项目管理 | 占位值 |
| FEISHU_SECRETARIAT | cli_a95123f2c1f8dcc3 | 秘书处 | ✅ 有效 |
| FEISHU_EXPERT | cli_xxxx | 专家系统 | 占位值 |
| FEISHU_DEV | cli_xxxx | 研发部 | 占位值 |
| FEISHU_APP | cli_xxxx | 默认应用 | 占位值 |

**使用 FEISHU_SECRETARIAT 应用测试**:
```bash
# 临时使用 Secretariat 应用凭证
export FEISHU_APP_ID=$FEISHU_SECRETARIAT_APP_ID
export FEISHU_APP_SECRET=$FEISHU_SECRETARIAT_APP_SECRET
openclaw gateway restart
```

---

## 三、验证命令

```bash
# 测试 tenant_access_token 获取
curl -X POST https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal \
  -H "Content-Type: application/json" \
  -d '{
    "app_id": "'"$FEISHU_APP_ID"'",
    "app_secret": "'"$FEISHU_APP_SECRET"'"
  }'

# 预期响应 (成功):
# {"code":0,"msg":"success","tenant_access_token":"t-xxxx","expire":7200}

# 预期响应 (失败):
# {"code":10003,"msg":"invalid param"}
```

---

## 四、预防措施

1. **凭证有效性检查**: 启动时验证 token 获取
2. **Token 自动刷新**: Gateway 自动处理过期刷新
3. **权限审计**: 定期审查应用权限
4. **备份凭证**: 多个应用凭证互为备份

---

> 最后更新: 2026-08-24  
> 下次审查: 2026-09-24
