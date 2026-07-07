# 代码质量规范文档

## 1. 代码审查 Checklist

### 1.1 通用检查项
- [ ] **功能正确性**: 代码是否实现了需求？边界条件是否处理？
- [ ] **安全性**: 是否存在 SQL 注入、XSS、CSRF 风险？
- [ ] **性能**: 是否有 N+1 查询？是否使用了合适的索引？
- [ ] **可维护性**: 代码结构是否清晰？命名是否有意义？
- [ ] **测试覆盖**: 单元测试/集成测试是否覆盖核心逻辑？
- [ ] **文档**: API 变更是否更新了文档？

### 1.2 前端检查项
- [ ] 组件是否遵循单一职责原则？
- [ ] 是否有内存泄漏风险（未清理的定时器、事件监听）？
- [ ] 响应式设计是否适配移动端？
- [ ] 无障碍访问 (a11y) 是否达标？

### 1.3 后端检查项
- [ ] API 是否有版本控制？
- [ ] 错误处理是否完善（不暴露内部错误信息）？
- [ ] 数据库事务是否正确管理？
- [ ] 日志是否包含足够的上下文信息？

### 1.4 数据库检查项
- [ ] 是否有合适的索引支持查询？
- [ ] 是否避免了全表扫描？
- [ ] 字段类型是否合理（不过度使用 TEXT/VARCHAR）？
- [ ] 是否有外键约束保证数据完整性？

## 2. ESLint/Prettier 统一配置

### 2.1 ESLint 配置 (`.eslintrc.json`)
```json
{
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
  "rules": {
    "no-console": ["warn", { "allow": ["warn", "error"] }],
    "no-unused-vars": "error",
    "eqeqeq": ["error", "always"],
    "curly": ["error", "all"]
  }
}
```

### 2.2 Prettier 配置 (`.prettierrc`)
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "all",
  "printWidth": 100
}
```

### 2.3 Husky + lint-staged 配置
```json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged"
    }
  },
  "lint-staged": {
    "*.{js,ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

## 3. SonarQube 集成方案

### 3.1 质量门禁 (Quality Gate)
| 指标 | 阈值 | 级别 |
|------|------|------|
| 代码覆盖率 | >= 80% | ERROR |
| 重复代码率 | <= 3% | ERROR |
| 严重漏洞 | 0 | ERROR |
| 主要代码异味 | <= 5 | WARNING |

### 3.2 CI 集成
```yaml
# GitHub Actions 示例
- name: SonarQube Scan
  uses: sonarsource/sonarqube-scan-action@v2
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

## 4. 自动化安全扫描

### 4.1 SAST 工具链
| 工具 | 用途 | 触发时机 |
|------|------|---------|
| ESLint Security Plugin | JS/TS 安全规则 | 每次 commit |
| npm audit / yarn audit | 依赖漏洞扫描 | 每次 PR |
| Bandit | Python 安全扫描 | 每次 PR |
| Trivy | 容器镜像扫描 | 每次构建 |

### 4.2 Dependabot 配置
```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
```

## 5. 分支策略 (GitFlow)

### 5.1 分支命名规范
| 分支类型 | 命名格式 | 示例 |
|---------|---------|------|
| 功能分支 | `feature/描述` | `feature/user-auth` |
| 修复分支 | `fix/描述` | `fix/login-timeout` |
| 发布分支 | `release/版本` | `release/v1.2.0` |
| 热修复分支 | `hotfix/描述` | `hotfix/security-patch` |

### 5.2 合并规则
- `feature/*` → `develop`：至少 1 人 code review + CI 通过
- `develop` → `main`：发布时创建 release 分支，QA 验证后合并
- `main` 分支：仅接受 release 和 hotfix 合并

---

> 创建时间: 2026-07-08
> 创建者: 研发部高级研发专家
> 状态: 待评审
