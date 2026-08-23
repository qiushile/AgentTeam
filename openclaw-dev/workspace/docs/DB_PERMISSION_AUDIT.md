# 数据库权限审计报告

> 审计日期: 2026-08-22  
> 审计者: 研发部高级研发专家 (dev_user)  
> 状态: 初稿完成

---

## 一、审计范围

| 项目 | 详情 |
|---|---|
| 数据库 | dev_db (PostgreSQL) |
| 审计对象 | dev_user 角色权限 |
| 审计时间 | 2026-08-22 |
| DB 主机 | 172.23.0.20:5432 |

## 二、用户清单

| 用户名 | 超级用户 | 创建DB | 创建角色 | 可登录 | 风险评估 |
|---|---|---|---|---|---|
| postgres | ✅ | ✅ | ✅ | ✅ | 正常 (系统管理员) |
| dev_user | ❌ | ❌ | ❌ | ✅ | **待审查** |

**结论**: ✅ 仅 2 个用户，无未授权用户。dev_user 无超级权限。

## 三、dev_user 权限详情

### 3.1 Schema 权限

| Schema | USAGE | CREATE | 评估 |
|---|---|---|---|
| public | ✅ | ❌ | ✅ 仅使用，符合最小权限 |
| shared | ✅ | ✅ | ⚠️ 有 CREATE 权限，可创建新表 |
| dev_schema | ✅ | ✅ | ✅ 研发专属 schema，合理 |

### 3.2 表级权限

dev_user 对以下 6 张表拥有 **ALL PRIVILEGES** (SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER):

| 表名 | Schema | 权限数量 | 评估 |
|---|---|---|---|
| tasks | shared | 7 | ⚠️ TRUNCATE/TRIGGER/REFERENCES 可能过多 |
| collaboration_events | shared | 7 | ⚠️ TRUNCATE/TRIGGER/REFERENCES 可能过多 |
| dev_tasks | dev_schema | 7 | ✅ 研发专属，合理 |
| dev_projects | dev_schema | 7 | ✅ 研发专属，合理 |
| dev_code_reviews | dev_schema | 7 | ✅ 研发专属，合理 |
| dev_deployments | dev_schema | 7 | ✅ 研发专属，合理 |

### 3.3 权限矩阵

```
用户      Schema/表              SELECT INSERT UPDATE DELETE TRUNCATE REFERENCES TRIGGER
────────  ─────────────────────  ────── ────── ────── ────── ──────── ────────── ───────
dev_user  shared.tasks             ✅      ✅      ✅      ✅       ✅         ✅          ✅
dev_user  shared.collaboration     ✅      ✅      ✅      ✅       ✅         ✅          ✅
dev_user  dev_schema.dev_tasks     ✅      ✅      ✅      ✅       ✅         ✅          ✅
dev_user  dev_schema.dev_projects  ✅      ✅      ✅      ✅       ✅         ✅          ✅
dev_user  dev_schema.dev_code_     ✅      ✅      ✅      ✅       ✅         ✅          ✅
dev_user  dev_schema.dev_deploy    ✅      ✅      ✅      ✅       ✅         ✅          ✅
```

## 四、安全发现

### 4.1 低风险项

| # | 发现 | 风险等级 | 建议 |
|---|---|---|---|
| F-01 | shared 表有 TRUNCATE 权限 | 低 | 日常操作不需要 TRUNCATE，可回收 |
| F-02 | shared 表有 TRIGGER 权限 | 低 | 日常操作不需要创建触发器，可回收 |
| F-03 | shared 表有 REFERENCES 权限 | 低 | 不影响功能，但可回收以最小化 |
| F-04 | shared schema 有 CREATE 权限 | 低 | 可在需要时临时授予，平时回收 |

### 4.2 无高风险项

- ✅ 无超级用户权限非管理员用户
- ✅ 无跨 schema 越权访问
- ✅ 无公开表 (public role) 敏感数据暴露
- ✅ 密码通过环境变量管理，未硬编码

## 五、加固建议

### 5.1 权限最小化方案

```sql
-- 回收 shared 表的非必要权限
REVOKE TRUNCATE, TRIGGER, REFERENCES ON shared.tasks FROM dev_user;
REVOKE TRUNCATE, TRIGGER, REFERENCES ON shared.collaboration_events FROM dev_user;

-- 保留 dev_schema 的 ALL PRIVILEGES（研发专属）
-- 保留 shared schema 的 CREATE（用于创建临时表等）

-- 最终权限矩阵
-- shared: SELECT, INSERT, UPDATE, DELETE
-- dev_schema: ALL PRIVILEGES
```

### 5.2 长期建议

| 建议 | 优先级 | 说明 |
|---|---|---|
| 定期权限审计 | P1 | 每季度执行一次权限审查 |
| 密码轮换 | P2 | 建议 90 天轮换一次 dev_user 密码 |
| 连接限制 | P2 | 限制 dev_user 最大连接数 |
| 审计日志 | P2 | 开启 PostgreSQL 审计日志 |

## 六、结论

| 指标 | 当前状态 | 目标 | 达标 |
|---|---|---|---|
| 超级用户数 | 1 (postgres) | ≤ 1 | ✅ |
| 未授权用户 | 0 | 0 | ✅ |
| dev_user 权限 | 6 表 ALL | 最小化 | ⚠️ 可优化 |
| 密码管理 | 环境变量 | 安全 | ✅ |

**总体评估**: ✅ 安全状态良好，无高风险项。建议按 5.1 方案回收 shared 表的部分权限。

---

> 最后更新: 2026-08-22  
> 下次审计: 2026-11-22
