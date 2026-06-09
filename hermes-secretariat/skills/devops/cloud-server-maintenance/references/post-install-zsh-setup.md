# Post-Install Zsh Setup Reference

## Verified working on Ubuntu 24.04 (Alibaba Cloud ECS)

### Plugin installation methods

| Method | Works? | Notes |
|--------|--------|-------|
| `git clone` from GitHub | ❌ Often times out | Alibaba Cloud blocks/slow-routes GitHub |
| `git clone` from Gitee mirrors | ❌ Auth required now | No longer works without login |
| `apt install zsh-*` | ✅ Only reliable method | Installs to `/usr/share/zsh-*/` |

### apt-installed plugin paths
- `zsh-autosuggestions`: `/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh`
- `zsh-syntax-highlighting`: `/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh`

### Prompt customization

**Key zsh prompt escapes:**
- `%m` — short hostname
- `%c` — trailing dir component only (e.g., `log`)
- `%~` — full path with `~` abbreviation (e.g., `/var/log`, `~/WorkStation`)
- `%(?:A:B)` — conditional (if exit code 0 then A else B)
- `$ret_status` — shows exit code if non-zero

**robbyrussell base prompt (after source $ZSH/oh-my-zsh.sh):**
Override PROMPT variable after sourcing oh-my-zsh to customize.

**Hostname + full-path format (verified working):**
```
PROMPT='%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$fg_bold[cyan]%}%m %{$fg[blue]%}%~%{$reset_color%} $(git_prompt_info)'
```
Renders as: `➜ qd001 ~/path` or `➜ qd001 /var/log` (hostname cyan, full path blue). Use single quotes to prevent bash variable expansion when writing over SSH.

### Writing .zshrc over SSH
Bash heredocs with nested quotes fail silently over SSH. Use python3:
```bash
ssh user@host 'python3 << "PYEOF"
with open("/home/user/.zshrc", "w") as f:
    f.write("content here")
PYEOF'
```

### Default ECS user
- Ubuntu 24.04 on Alibaba Cloud: `ecs-user`
- NOT `root` (root login may be disabled in sshd_config)
- Default shell after install: `/bin/bash`
