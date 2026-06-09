# Post-Install Zsh Setup Reference

## Verified working on Ubuntu 24.04 (Alibaba Cloud ECS)

### Plugin installation methods

| Method | Works? | Notes |
|--------|--------|-------|
| `git clone` from GitHub | ❌ Often times out | Alibaba Cloud blocks/slow-routes GitHub |
| `git clone` from Gitee mirrors | ⚠️ May require auth | Many old mirrors are private now |
| `apt install zsh-*` | ✅ Reliable | Installs to `/usr/share/zsh-*/` |

### apt-installed plugin paths
- `zsh-autosuggestions`: `/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh`
- `zsh-syntax-highlighting`: `/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh`

### Prompt customization

**Key zsh prompt escapes:**
- `%m` — short hostname
- `%c` — trailing dir component
- `%~` — full path (abbreviated)
- `%(?:A:B)` — conditional (if exit code 0 then A else B)
- `$ret_status` — shows exit code if non-zero

**robbyrussell base prompt (after source $ZSH/oh-my-zsh.sh):**
Override PROMPT variable after sourcing oh-my-zsh to customize.

**Hostname + path format (verified working):**
```
PROMPT="${ret_status} %(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$fg_bold[cyan]%}%m%{$reset_color%} %{$fg[blue]%}%c%{$reset_color%} $(git_prompt_info)"
```
Renders as: `➜ qd001 ~/path` (hostname in cyan, path in blue)

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
