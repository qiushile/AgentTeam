---
name: github-workflow
description: "Complete GitHub workflow: repo management, issues, PR lifecycle, and code review via gh CLI or REST API."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [GitHub, PRs, Issues, Code-Review, Repositories, Git, CI/CD]
---

# GitHub Workflow Suite

Unified skill for all GitHub operations. Covers repository management, issue tracking, PR lifecycle, and code review. Each section shows the `gh` way first, then the `git` + `curl` fallback.

## Shared Prerequisites

- Authenticated with GitHub (see setup below)
- Inside a git repository with a GitHub remote (for most operations)

### Auth Detection (used by all sections)

```bash
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  AUTH="gh"
else
  AUTH="git"
  if [ -z "$GITHUB_TOKEN" ]; then
    if [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
      GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2 | tr -d '\n\r')
    elif grep -q "github.com" ~/.git-credentials 2>/dev/null; then
      GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials 2>/dev/null | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
    fi
  fi
fi

REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
```

---

## Section A: Repository Management

Clone/create/fork repos, manage settings, branch protection, secrets, releases, and GitHub Actions.

### Cloning
```bash
git clone https://github.com/owner/repo-name.git
git clone --depth 1 https://github.com/owner/repo-name.git  # shallow
gh repo clone owner/repo-name
```

### Creating Repos
```bash
gh repo create my-project --public --clone
# curl: POST https://api.github.com/user/repos with JSON body
```

### Forking
```bash
gh repo fork owner/repo --clone
git fetch upstream && git merge upstream/main  # keep fork in sync
```

### Releases
```bash
gh release create v1.0.0 --generate-notes
gh release list
# curl: POST https://api.github.com/repos/$OWNER/$REPO/releases
```

### Secrets
```bash
gh secret set API_KEY --body "value"
gh secret list
# curl requires encryption with repo's public key — prefer gh
```

### Actions Workflows
```bash
gh workflow list
gh run list --limit 10
gh run rerun <ID> --failed
gh workflow run ci.yml --ref main
# curl: GET/POST https://api.github.com/repos/$OWNER/$REPO/actions/...
```

### Branch Protection
```bash
# curl: PUT https://api.github.com/repos/$OWNER/$REPO/branches/main/protection
```

---

## Section B: Issues Management

Create, search, triage, label, assign, and manage GitHub issues.

### Viewing Issues
```bash
gh issue list
gh issue list --label "bug"
gh issue view 42
# curl: GET /repos/$OWNER/$REPO/issues
```

### Creating Issues
```bash
gh issue create --title "Bug title" --body "Description" --label "bug" --assignee "user"
# curl: POST /repos/$OWNER/$REPO/issues
```

### Managing Issues
```bash
gh issue edit 42 --add-label "priority:high"
gh issue edit 42 --add-assignee user
gh issue comment 42 --body "Comment text"
gh issue close 42
gh issue reopen 42
# curl: POST/DELETE/PATCH /repos/$OWNER/$REPO/issues/42/...
```

### Issue Triage Workflow
1. List untriaged: `gh issue list --label "needs-triage"`
2. Read and categorize each
3. Apply labels and priority
4. Assign if owner is clear
5. Comment with triage notes

---

## Section C: PR Lifecycle

Branch, commit, create PR, monitor CI, auto-fix failures, and merge.

### Branch Creation
```bash
git fetch origin
git checkout main && git pull origin main
git checkout -b feat/add-feature
```

### Creating PRs
```bash
gh pr create --title "feat: add feature" --body "Summary\n\nCloses #42"
# curl: POST /repos/$OWNER/$REPO/pulls
```

### Monitoring CI
```bash
gh pr checks --watch
# curl: GET /repos/$OWNER/$REPO/commits/$SHA/status
```

### Auto-Fixing CI Failures
1. Get failure details: `gh run view <ID> --log-failed`
2. Fix code with file tools
3. `git add . && git commit && git push`
4. Re-check CI (up to 3 attempts)

### Merging
```bash
gh pr merge --squash --delete-branch
gh pr merge --auto --squash --delete-branch  # auto-merge
# curl: PUT /repos/$OWNER/$REPO/pulls/N/merge
```

---

## Section D: Code Review

Review local changes (pre-push) or PRs on GitHub with inline comments.

### Pre-Push Review
```bash
git diff main...HEAD --stat    # scope
git diff main...HEAD           # full diff
# Check for: debug statements, secrets, merge conflicts, large files
```

### PR Review Workflow
1. Gather context: `gh pr view N`, `gh pr diff N --name-only`
2. Check out PR: `git fetch origin pull/N/head:pr-N && git checkout pr-N`
3. Read diff + full file context
4. Run tests/linters locally
5. Apply review checklist (see below)
6. Post review

### Review Checklist
- **Correctness**: Edge cases, error handling, does it work?
- **Security**: No hardcoded secrets, input validation, no injection
- **Code Quality**: Clear naming, DRY, focused functions
- **Testing**: New paths tested, happy + error cases
- **Performance**: No N+1 queries, appropriate caching
- **Documentation**: Public APIs documented, README updated

### Leaving Review Comments
```bash
gh pr comment N --body "Summary"
gh pr review N --approve --body "LGTM"
gh pr review N --request-changes --body "See inline comments"
# curl: POST /repos/$OWNER/$REPO/pulls/N/reviews with inline comments
```

### Review Output Format
```
## Code Review Summary
### 🔴 Critical — [blocking issues]
### ⚠️ Warnings — [should fix]
### 💡 Suggestions — [non-blocking]
### ✅ Looks Good — [positive findings]
```

---

## Pitfalls

1. **GitHub API returns PRs in /issues endpoint** — filter with `'pull_request' not in i`
2. **Secrets via curl require encryption** — prefer `gh secret set`
3. **Auto-merge requires repo settings** — may not be enabled
4. **Context degradation in large PRs** — review file by file, not just the diff
5. **CI auto-fix loop** — max 3 attempts, then ask the user
6. **Always use `git diff main...HEAD`** (triple dot) for PR-scoped diffs, not `git diff main HEAD`