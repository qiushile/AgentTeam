
#compdef openclaw

_openclaw_root_completion() {
  local -a commands
  local -a options
  
  _arguments -C \
    "(--version -V)"{--version,-V}"[output the version number]" \
    "--container[Run the CLI inside a running Podman/Docker container named <name> (default: env OPENCLAW_CONTAINER)]" \
    "--dev[Dev profile: isolate state under ~/.openclaw-dev, default gateway port 19001, and shift derived ports (browser/canvas)]" \
    "--profile[Use a named profile (isolates OPENCLAW_STATE_DIR/OPENCLAW_CONFIG_PATH under ~/.openclaw-<name>)]" \
    "--log-level[Global log level override for file + console (silent|fatal|error|warn|info|debug|trace)]" \
    "--no-color[Disable ANSI colors]" \
    "1: :_values 'command' 'completion[Generate shell completion script]' 'crestodian[Open the ring-zero setup and repair helper]' 'setup[Create baseline config/workspace files; use --wizard for full onboarding]' 'onboard[Guided setup for auth, models, Gateway, workspace, channels, and skills]' 'configure[Interactive configuration for credentials, channels, gateway, and agent defaults]' 'config[Non-interactive config helpers (get/set/patch/unset/file/schema/validate). Run without subcommand for guided setup.]' 'backup[Create and verify local backup archives for OpenClaw state]' 'migrate[Import state from another agent system]' 'doctor[Health checks + quick fixes for the gateway and channels]' 'dashboard[Open the Control UI with your current token]' 'reset[Reset local config/state (keeps the CLI installed)]' 'uninstall[Uninstall the gateway service + local data (CLI remains)]' 'message[Send, read, and manage messages and channel actions]' 'mcp[Manage OpenClaw MCP config and channel bridge]' 'transcripts[Inspect stored transcripts]' 'agent[Run an agent turn via the Gateway (use --local for embedded)]' 'agents[Manage isolated agents (workspaces + auth + routing)]' 'status[Show channel health and recent session recipients]' 'health[Fetch health from the running gateway]' 'sessions[List stored conversation sessions]' 'commitments[List and manage inferred follow-up commitments]' 'tasks[Inspect durable background tasks and TaskFlow state]' 'acp[Run an ACP bridge backed by the Gateway]' 'gateway[Run, inspect, and query the WebSocket Gateway]' 'daemon[Manage the Gateway service (launchd/systemd/schtasks)]' 'logs[Tail gateway file logs via RPC]' 'system[System tools (events, heartbeat, presence)]' 'models[Model discovery, scanning, and configuration]' 'infer[Run provider-backed inference commands through a stable CLI surface]' 'approvals[Manage exec approvals (gateway or node host)]' 'exec-policy[Show or synchronize requested exec policy with host approvals]' 'nodes[Manage gateway-owned nodes (pairing, status, invoke, and media)]' 'devices[Device pairing and auth tokens]' 'node[Run and manage the headless node host service]' 'sandbox[Manage sandbox containers (Docker-based agent isolation)]' 'tui[Open a terminal UI connected to the Gateway]' 'cron[Manage cron jobs (via Gateway)]' 'dns[DNS helpers for wide-area discovery (Tailscale + CoreDNS)]' 'docs[Search the live OpenClaw docs]' 'proxy[Run the OpenClaw debug proxy and inspect captured traffic]' 'hooks[Manage internal agent hooks]' 'webhooks[Webhook helpers and integrations]' 'qr[Generate a mobile pairing QR code and setup code]' 'clawbot[Legacy clawbot command aliases]' 'pairing[Secure DM pairing (approve inbound requests)]' 'plugins[Manage OpenClaw plugins and extensions]' 'channels[Manage connected chat channels and accounts]' 'directory[Lookup contact and group IDs (self, peers, groups) for supported chat channels]' 'security[Audit local config and state for common security foot-guns]' 'secrets[Secrets runtime controls]' 'skills[List and inspect available skills]' 'update[Update OpenClaw and inspect update channel status]' 'memory[Search, inspect, and reindex memory files]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (completion) _openclaw_completion ;;
        (crestodian) _openclaw_crestodian ;;
        (setup) _openclaw_setup ;;
        (onboard) _openclaw_onboard ;;
        (configure) _openclaw_configure ;;
        (config) _openclaw_config ;;
        (backup) _openclaw_backup ;;
        (migrate) _openclaw_migrate ;;
        (doctor) _openclaw_doctor ;;
        (dashboard) _openclaw_dashboard ;;
        (reset) _openclaw_reset ;;
        (uninstall) _openclaw_uninstall ;;
        (message) _openclaw_message ;;
        (mcp) _openclaw_mcp ;;
        (transcripts) _openclaw_transcripts ;;
        (agent) _openclaw_agent ;;
        (agents) _openclaw_agents ;;
        (status) _openclaw_status ;;
        (health) _openclaw_health ;;
        (sessions) _openclaw_sessions ;;
        (commitments) _openclaw_commitments ;;
        (tasks) _openclaw_tasks ;;
        (acp) _openclaw_acp ;;
        (gateway) _openclaw_gateway ;;
        (daemon) _openclaw_daemon ;;
        (logs) _openclaw_logs ;;
        (system) _openclaw_system ;;
        (models) _openclaw_models ;;
        (infer) _openclaw_infer ;;
        (approvals) _openclaw_approvals ;;
        (exec-policy) _openclaw_exec_policy ;;
        (nodes) _openclaw_nodes ;;
        (devices) _openclaw_devices ;;
        (node) _openclaw_node ;;
        (sandbox) _openclaw_sandbox ;;
        (tui) _openclaw_tui ;;
        (cron) _openclaw_cron ;;
        (dns) _openclaw_dns ;;
        (docs) _openclaw_docs ;;
        (proxy) _openclaw_proxy ;;
        (hooks) _openclaw_hooks ;;
        (webhooks) _openclaw_webhooks ;;
        (qr) _openclaw_qr ;;
        (clawbot) _openclaw_clawbot ;;
        (pairing) _openclaw_pairing ;;
        (plugins) _openclaw_plugins ;;
        (channels) _openclaw_channels ;;
        (directory) _openclaw_directory ;;
        (security) _openclaw_security ;;
        (secrets) _openclaw_secrets ;;
        (skills) _openclaw_skills ;;
        (update) _openclaw_update ;;
        (memory) _openclaw_memory ;;
      esac
      ;;
  esac
}


_openclaw_completion() {
  _arguments -C \
    "(--shell -s)"{--shell,-s}"[Shell to generate completion for (default: zsh)]" \
    "(--install -i)"{--install,-i}"[Install completion script to shell profile]" \
    "--write-state[Write completion scripts to $OPENCLAW_STATE_DIR/completions (no stdout)]" \
    "(--yes -y)"{--yes,-y}"[Skip confirmation (non-interactive)]"
}

_openclaw_crestodian() {
  _arguments -C \
    "(--message -m)"{--message,-m}"[Run one Crestodian request]" \
    "--yes[Approve persistent config writes for this request]" \
    "--json[Output startup overview as JSON]"
}

_openclaw_setup() {
  _arguments -C \
    "--workspace[Agent workspace directory (default: ~/.openclaw/workspace; stored as agents.defaults.workspace)]" \
    "--wizard[Run interactive onboarding]" \
    "--non-interactive[Run onboarding without prompts]" \
    "--accept-risk[Acknowledge that agents are powerful and full system access is risky (required for --non-interactive)]" \
    "--mode[Onboard mode: local|remote]" \
    "--import-from[Migration provider to run during onboarding]" \
    "--import-source[Source agent home for --import-from]" \
    "--import-secrets[Import supported secrets during onboarding migration]" \
    "--remote-url[Remote Gateway WebSocket URL]" \
    "--remote-token[Remote Gateway token (optional)]"
}

_openclaw_onboard() {
  _arguments -C \
    "--workspace[Agent workspace directory (default: ~/.openclaw/workspace)]" \
    "--reset[Reset config + credentials + sessions before running onboard (workspace only with --reset-scope full)]" \
    "--reset-scope[Reset scope: config|config+creds+sessions|full]" \
    "--non-interactive[Run without prompts]" \
    "--modern[Use the conversational setup/repair assistant]" \
    "--accept-risk[Acknowledge that agents are powerful and full system access is risky (required for --non-interactive)]" \
    "--flow[Onboard flow: quickstart|advanced|manual|import]" \
    "--mode[Onboard mode: local|remote]" \
    "--auth-choice[Auth: custom-api-key|skip|claude-cli|apiKey|anthropic-cli|setup-token|arceeai-api-key|byteplus-api-key|cerebras-api-key|openai-device-code|openai|chutes|chutes-api-key|cloudflare-ai-gateway-api-key|zai-cn|codex|qwen-api-key-cn|qwen-api-key|zai-coding-cn|zai-coding-global|copilot-proxy|deepinfra-api-key|deepseek-api-key|fireworks-api-key|google-gemini-cli|github-copilot|zai-global|gmi-api-key|gemini-api-key|google-vertex-api-key|groq-api-key|huggingface-api-key|kilocode-api-key|kimi-code-api-key|litellm-api-key|lmstudio|microsoft-foundry-apikey|microsoft-foundry-entra|minimax-cn-api|minimax-global-api|minimax-cn-oauth|minimax-global-oauth|mistral-api-key|moonshot-api-key|moonshot-api-key-cn|novita-api-key|nvidia-api-key|ollama|ollama-cloud|openai-api-key|opencode-go|opencode-zen|arceeai-openrouter|openrouter-api-key|qianfan-api-key|qwen-oauth|sglang|qwen-standard-api-key-cn|qwen-standard-api-key|stepfun-standard-api-key-cn|stepfun-standard-api-key-intl|stepfun-plan-api-key-cn|stepfun-plan-api-key-intl|synthetic-api-key|tokenhub-api-key|together-api-key|venice-api-key|ai-gateway-api-key|vllm|volcengine-api-key|xai-api-key|xai-device-code|xai-oauth|xiaomi-api-key|xiaomi-token-plan-cn|xiaomi-token-plan-ams|xiaomi-token-plan-sgp|zai-api-key]" \
    "--token-provider[Token provider id (non-interactive; used with --auth-choice token)]" \
    "--token[Token value (non-interactive; used with --auth-choice token)]" \
    "--token-profile-id[Auth profile id (non-interactive; default: <provider>:manual)]" \
    "--token-expires-in[Optional token expiry duration (e.g. 365d, 12h)]" \
    "--secret-input-mode[API key persistence mode: plaintext|ref (default: plaintext)]" \
    "--cloudflare-ai-gateway-account-id[Cloudflare Account ID]" \
    "--cloudflare-ai-gateway-gateway-id[Cloudflare AI Gateway ID]" \
    "--alibaba-model-studio-api-key[Alibaba Model Studio API key]" \
    "--anthropic-api-key[Anthropic API key]" \
    "--arceeai-api-key[Arcee AI API key]" \
    "--openrouter-api-key[OpenRouter API key for Arcee AI models]" \
    "--byteplus-api-key[BytePlus API key]" \
    "--cerebras-api-key[Cerebras API key]" \
    "--chutes-api-key[Chutes API key]" \
    "--cloudflare-ai-gateway-api-key[Cloudflare AI Gateway API key]" \
    "--comfy-api-key[Comfy Cloud API key]" \
    "--deepinfra-api-key[DeepInfra API key]" \
    "--deepseek-api-key[DeepSeek API key]" \
    "--fal-api-key[fal API key]" \
    "--fireworks-api-key[Fireworks API key]" \
    "--github-copilot-token[GitHub Copilot OAuth token]" \
    "--gmi-api-key[GMI Cloud API key]" \
    "--gemini-api-key[Gemini API key]" \
    "--huggingface-api-key[Hugging Face API key (HF token)]" \
    "--kilocode-api-key[Kilo Gateway API key]" \
    "--kimi-code-api-key[Kimi Code API key (subscription)]" \
    "--litellm-api-key[LiteLLM API key]" \
    "--lmstudio-api-key[LM Studio API key]" \
    "--minimax-api-key[MiniMax API key]" \
    "--mistral-api-key[Mistral API key]" \
    "--moonshot-api-key[Moonshot API key]" \
    "--novita-api-key[NovitaAI API key]" \
    "--nvidia-api-key[NVIDIA API key]" \
    "--ollama-cloud-api-key[Ollama Cloud API key]" \
    "--openai-api-key[OpenAI API Key]" \
    "--opencode-zen-api-key[OpenCode API key (Zen catalog)]" \
    "--opencode-go-api-key[OpenCode API key (Go catalog)]" \
    "--qianfan-api-key[QIANFAN API key]" \
    "--modelstudio-standard-api-key-cn[Qwen Cloud standard API key (China)]" \
    "--modelstudio-standard-api-key[Qwen Cloud standard API key (Global/Intl)]" \
    "--modelstudio-api-key-cn[Qwen Cloud Coding Plan API key (China)]" \
    "--modelstudio-api-key[Qwen Cloud Coding Plan API key (Global/Intl)]" \
    "--qwen-oauth-token[Qwen OAuth token]" \
    "--runway-api-key[Runway API key]" \
    "--stepfun-api-key[StepFun API key]" \
    "--synthetic-api-key[Synthetic API key]" \
    "--tokenhub-api-key[Tencent TokenHub API key]" \
    "--together-api-key[Together AI API key]" \
    "--venice-api-key[Venice API key]" \
    "--ai-gateway-api-key[Vercel AI Gateway API key]" \
    "--volcengine-api-key[Volcano Engine API key]" \
    "--vydra-api-key[Vydra API key]" \
    "--xai-api-key[xAI API key]" \
    "--xiaomi-api-key[Xiaomi MiMo pay-as-you-go API key]" \
    "--xiaomi-token-plan-api-key[Xiaomi MiMo Token Plan API key]" \
    "--zai-api-key[Z.AI API key]" \
    "--custom-base-url[Custom provider base URL]" \
    "--custom-api-key[Custom provider API key (optional)]" \
    "--custom-model-id[Custom provider model ID]" \
    "--custom-provider-id[Custom provider ID (optional; auto-derived by default)]" \
    "--custom-compatibility[Custom provider API compatibility: openai|openai-responses|anthropic (default: openai)]" \
    "--custom-image-input[Mark the custom provider model as image-capable]" \
    "--custom-text-input[Mark the custom provider model as text-only]" \
    "--gateway-port[Gateway port]" \
    "--gateway-bind[Gateway bind: loopback|tailnet|lan|auto|custom]" \
    "--gateway-auth[Gateway auth: token|password]" \
    "--gateway-token[Gateway token (token auth)]" \
    "--gateway-token-ref-env[Gateway token SecretRef env var name (token auth; e.g. OPENCLAW_GATEWAY_TOKEN)]" \
    "--gateway-password[Gateway password (password auth)]" \
    "--remote-url[Remote Gateway WebSocket URL]" \
    "--remote-token[Remote Gateway token (optional)]" \
    "--tailscale[Tailscale: off|serve|funnel]" \
    "--tailscale-reset-on-exit[Reset tailscale serve/funnel on exit]" \
    "--install-daemon[Install gateway service]" \
    "--no-install-daemon[Skip gateway service install]" \
    "--skip-daemon[Skip gateway service install]" \
    "--daemon-runtime[Daemon runtime: node|bun]" \
    "--skip-channels[Skip channel setup]" \
    "--skip-skills[Skip skills setup]" \
    "--skip-bootstrap[Skip creating default agent workspace files]" \
    "--skip-search[Skip search provider setup]" \
    "--skip-health[Skip health check]" \
    "--skip-ui[Skip Control UI/TUI prompts]" \
    "--suppress-gateway-token-output[Suppress token-bearing Gateway/UI output]" \
    "--skip-hooks[Skip hook setup]" \
    "--node-manager[Node manager for skills: npm|pnpm|bun]" \
    "--import-from[Migration provider to run during onboarding]" \
    "--import-source[Source agent home for --import-from]" \
    "--import-secrets[Import supported secrets during onboarding migration]" \
    "--json[Output JSON summary]"
}

_openclaw_configure() {
  _arguments -C \
    "--section[Configuration sections (repeatable). Options: workspace, model, web, gateway, daemon, channels, plugins, skills, health]"
}

_openclaw_config_get() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_config_set() {
  _arguments -C \
    "--strict-json[Strict JSON parsing (error instead of raw string fallback)]" \
    "--json[Legacy alias for --strict-json]" \
    "--dry-run[Validate changes without writing openclaw.json (checks run in builder/json/batch modes; exec SecretRefs are skipped unless --allow-exec is set)]" \
    "--allow-exec[Dry-run only: allow exec SecretRef resolvability checks (may execute provider commands)]" \
    "--merge[Merge object/map values instead of replacing the target path]" \
    "--replace[Allow full replacement of protected map/list paths such as agents.defaults.models]" \
    "--ref-provider[SecretRef builder: provider alias]" \
    "--ref-source[SecretRef builder: source (env|file|exec)]" \
    "--ref-id[SecretRef builder: ref id]" \
    "--provider-source[Provider builder: source (env|file|exec)]" \
    "--provider-allowlist[Provider builder (env): allowlist entry (repeatable)]" \
    "--provider-path[Provider builder (file): path]" \
    "--provider-mode[Provider builder (file): mode (singleValue|json)]" \
    "--provider-timeout-ms[Provider builder (file|exec): timeout ms]" \
    "--provider-max-bytes[Provider builder (file): max bytes]" \
    "--provider-command[Provider builder (exec): absolute command path]" \
    "--provider-arg[Provider builder (exec): command arg (repeatable)]" \
    "--provider-no-output-timeout-ms[Provider builder (exec): no-output timeout ms]" \
    "--provider-max-output-bytes[Provider builder (exec): max output bytes]" \
    "--provider-json-only[Provider builder (exec): require JSON output]" \
    "--provider-env[Provider builder (exec): env assignment (repeatable)]" \
    "--provider-pass-env[Provider builder (exec): pass host env var (repeatable)]" \
    "--provider-trusted-dir[Provider builder (exec): trusted directory (repeatable)]" \
    "--provider-allow-insecure-path[Provider builder (file|exec): bypass strict path permission checks]" \
    "--provider-allow-symlink-command[Provider builder (exec): allow command symlink path]" \
    "--batch-json[Batch mode: JSON array of set operations]" \
    "--batch-file[Batch mode: read JSON array of set operations from file]"
}

_openclaw_config_patch() {
  _arguments -C \
    "--file[Read a JSON5 config patch object from file]" \
    "--stdin[Read a JSON5 config patch object from stdin]" \
    "--dry-run[Validate changes without writing openclaw.json (checks schema and SecretRef resolvability; exec SecretRefs are skipped unless --allow-exec is set)]" \
    "--allow-exec[Dry-run only: allow exec SecretRef resolvability checks (may execute provider commands)]" \
    "--json[Output dry-run result as JSON]" \
    "--replace-path[Replace the object or array at this dot/bracket path instead of recursively applying it (repeatable)]"
}

_openclaw_config_unset() {
  _arguments -C \
    "--dry-run[validate the removal without writing the config file]" \
    "--allow-exec[allow exec SecretRef providers during --dry-run]" \
    "--json[print dry-run result as JSON]"
}

_openclaw_config_file() {
  _arguments -C \
    
}

_openclaw_config_schema() {
  _arguments -C \
    
}

_openclaw_config_validate() {
  _arguments -C \
    "--json[Output validation result as JSON]"
}

_openclaw_config() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--section[Configuration sections for guided setup (repeatable). Use with no subcommand.]" \
    "1: :_values 'command' 'get[Get a config value by dot path]' 'set[Set config values by path (value mode, ref/provider builder mode, or batch JSON mode).
Examples:
openclaw config set gateway.port 19001 --strict-json
openclaw config set channels.discord.token --ref-provider default --ref-source env --ref-id DISCORD_BOT_TOKEN
openclaw config set secrets.providers.vault --provider-source file --provider-path /etc/openclaw/secrets.json --provider-mode json
openclaw config set --batch-file ./config-set.batch.json --dry-run]' 'patch[Patch config from a JSON5 object in one validated write.
Objects merge recursively, arrays/scalars replace, and null deletes a path.
Examples:
openclaw config patch --file ./openclaw.patch.json5 --dry-run
openclaw config patch --stdin]' 'unset[Remove a config value by dot path]' 'file[Print the active config file path]' 'schema[Print the JSON schema for openclaw.json]' 'validate[Validate the current config against the schema without starting the gateway]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (get) _openclaw_config_get ;;
        (set) _openclaw_config_set ;;
        (patch) _openclaw_config_patch ;;
        (unset) _openclaw_config_unset ;;
        (file) _openclaw_config_file ;;
        (schema) _openclaw_config_schema ;;
        (validate) _openclaw_config_validate ;;
      esac
      ;;
  esac
}

_openclaw_backup_create() {
  _arguments -C \
    "--output[Archive path or destination directory]" \
    "--json[Output JSON]" \
    "--dry-run[Print the backup plan without writing the archive]" \
    "--verify[Verify the archive after writing it]" \
    "--only-config[Back up only the active JSON config file]" \
    "--no-include-workspace[Exclude workspace directories from the backup]"
}

_openclaw_backup_verify() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_backup() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'create[Write a backup archive for config, credentials, sessions, and workspaces]' 'verify[Validate a backup archive and its embedded manifest]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (create) _openclaw_backup_create ;;
        (verify) _openclaw_backup_verify ;;
      esac
      ;;
  esac
}

_openclaw_migrate_list() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_migrate_plan() {
  _arguments -C \
    "--from[Source directory to migrate from]" \
    "--include-secrets[Import supported credentials and secrets]" \
    "--no-auth-credentials[Skip auth credential migration]" \
    "--overwrite[Overwrite conflicting target files after item-level backups]" \
    "--json[Output JSON]" \
    "--skill[Select one skill to migrate by name or item id; repeat for multiple skills]" \
    "--plugin[Select one Codex plugin to migrate by name or item id; repeat for multiple plugins]" \
    "--verify-plugin-apps[Codex only: verify source plugin app accessibility with app/list before planning native plugin activation]"
}

_openclaw_migrate_apply() {
  _arguments -C \
    "--from[Source directory to migrate from]" \
    "--include-secrets[Import supported credentials and secrets]" \
    "--no-auth-credentials[Skip auth credential migration]" \
    "--overwrite[Overwrite conflicting target files after item-level backups]" \
    "--json[Output JSON]" \
    "--skill[Select one skill to migrate by name or item id; repeat for multiple skills]" \
    "--plugin[Select one Codex plugin to migrate by name or item id; repeat for multiple plugins]" \
    "--verify-plugin-apps[Codex only: verify source plugin app accessibility with app/list before planning native plugin activation]" \
    "--yes[Apply without prompting]" \
    "--backup-output[Pre-migration backup archive path or directory]" \
    "--no-backup[Skip the pre-migration OpenClaw backup]" \
    "--force[Allow dangerous options such as --no-backup]"
}

_openclaw_migrate() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--from[Source directory to migrate from]" \
    "--include-secrets[Import supported credentials and secrets]" \
    "--no-auth-credentials[Skip auth credential migration]" \
    "--overwrite[Overwrite conflicting target files after item-level backups]" \
    "--dry-run[Preview only; do not apply changes]" \
    "--yes[Apply without prompting after preview]" \
    "--skill[Select one skill to migrate by name or item id; repeat for multiple skills]" \
    "--plugin[Select one Codex plugin to migrate by name or item id; repeat for multiple plugins]" \
    "--backup-output[Pre-migration backup archive path or directory]" \
    "--no-backup[Skip the pre-migration OpenClaw backup]" \
    "--force[Allow dangerous options such as --no-backup]" \
    "--json[Output JSON]" \
    "--verify-plugin-apps[Codex only: verify source plugin app accessibility with app/list before planning native plugin activation]" \
    "1: :_values 'command' 'list[List migration providers]' 'plan[Preview a migration without changing OpenClaw state]' 'apply[Apply a migration after a verified backup]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_migrate_list ;;
        (plan) _openclaw_migrate_plan ;;
        (apply) _openclaw_migrate_apply ;;
      esac
      ;;
  esac
}

_openclaw_doctor() {
  _arguments -C \
    "--no-workspace-suggestions[Disable workspace memory system suggestions]" \
    "--yes[Accept defaults without prompting]" \
    "--repair[Apply recommended repairs without prompting]" \
    "--fix[Apply recommended repairs (alias for --repair)]" \
    "--force[Apply aggressive repairs (overwrites custom service config)]" \
    "--non-interactive[Run without prompts (safe migrations only)]" \
    "--generate-gateway-token[Generate and configure a gateway token]" \
    "--allow-exec[Allow doctor to execute exec SecretRefs while verifying configured secrets]" \
    "--deep[Scan system services for extra gateway installs]" \
    "--lint[Run read-only health checks and report findings]" \
    "--post-upgrade[Emit plugin-compat findings only (machine-readable with --json)]" \
    "--json[With --lint or --post-upgrade: emit machine-readable JSON output]" \
    "--severity-min[With --lint: drop findings below this severity (info|warning|error)]" \
    "--skip[With --lint: skip a specific check id (repeatable)]" \
    "--only[With --lint: run only the specified check id (repeatable)]"
}

_openclaw_dashboard() {
  _arguments -C \
    "--no-open[Print URL but do not launch a browser]" \
    "--yes[Start/install the gateway without prompting when needed]"
}

_openclaw_reset() {
  _arguments -C \
    "--scope[config|config+creds+sessions|full (default: interactive prompt)]" \
    "--yes[Skip confirmation prompts]" \
    "--non-interactive[Disable prompts (requires --scope + --yes)]" \
    "--dry-run[Print actions without removing files]"
}

_openclaw_uninstall() {
  _arguments -C \
    "--service[Remove the gateway service]" \
    "--state[Remove state + config]" \
    "--workspace[Remove workspace dirs]" \
    "--app[Remove the macOS app]" \
    "--all[Remove service + state + workspace + app]" \
    "--yes[Skip confirmation prompts]" \
    "--non-interactive[Disable prompts (requires --yes)]" \
    "--dry-run[Print actions without removing files]"
}

_openclaw_message_send() {
  _arguments -C \
    "(--message -m)"{--message,-m}"[Message body (required unless --media is set)]" \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--media[Attach media (image/audio/video/document). Accepts local paths or URLs.]" \
    "--presentation[Shared presentation payload as JSON (text, context, dividers, buttons, selects)]" \
    "--delivery[Shared delivery preferences as JSON]" \
    "--pin[Request that the delivered message be pinned when supported]" \
    "--reply-to[Reply-to message id]" \
    "--thread-id[Thread id (Telegram forum thread)]" \
    "--gif-playback[Treat video media as GIF playback (WhatsApp only).]" \
    "--force-document[Send media as document to avoid channel compression (Telegram, WhatsApp). Applies to images, GIFs, and videos.]" \
    "--silent[Send message silently without notification (Telegram + Discord)]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]"
}

_openclaw_message_broadcast() {
  _arguments -C \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--targets[Recipient/channel targets (same format as --target); accepts ids or names when the directory is available.]" \
    "--message[Message to send]" \
    "--media[Media URL]"
}

_openclaw_message_poll() {
  _arguments -C \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--poll-question[Poll question]" \
    "--poll-option[Poll option (repeat 2-12 times)]" \
    "--poll-multi[Allow multiple selections]" \
    "--poll-duration-hours[Poll duration in hours (Discord)]" \
    "--poll-duration-seconds[Poll duration in seconds (Telegram; 5-600)]" \
    "--poll-anonymous[Send an anonymous poll (Telegram)]" \
    "--poll-public[Send a non-anonymous poll (Telegram)]" \
    "(--message -m)"{--message,-m}"[Optional message body]" \
    "--silent[Send poll silently without notification (Telegram + Discord where supported)]" \
    "--thread-id[Thread id (Telegram forum topic / Slack thread ts)]"
}

_openclaw_message_react() {
  _arguments -C \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--message-id[Message id]" \
    "--emoji[Emoji for reactions]" \
    "--remove[Remove reaction]" \
    "--participant[WhatsApp reaction participant]" \
    "--from-me[WhatsApp reaction fromMe]" \
    "--target-author[Signal reaction target author (uuid or phone)]" \
    "--target-author-uuid[Signal reaction target author uuid]"
}

_openclaw_message_reactions() {
  _arguments -C \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--message-id[Message id]" \
    "--limit[Result limit]"
}

_openclaw_message_read() {
  _arguments -C \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--limit[Result limit]" \
    "--message-id[Read a specific message id]" \
    "--before[Read/search before id]" \
    "--after[Read/search after id]" \
    "--around[Read around id]" \
    "--thread-id[Thread id (Slack thread timestamp)]" \
    "--include-thread[Include thread replies (Discord)]"
}

_openclaw_message_edit() {
  _arguments -C \
    "--message-id[Message id]" \
    "(--message -m)"{--message,-m}"[Message body]" \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--thread-id[Thread id (Telegram forum thread)]"
}

_openclaw_message_delete() {
  _arguments -C \
    "--message-id[Message id]" \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]"
}

_openclaw_message_pin() {
  _arguments -C \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--message-id[Message id]"
}

_openclaw_message_unpin() {
  _arguments -C \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--message-id[Message id (or pinned message resource id for MSTeams)]" \
    "--pinned-message-id[Pinned message resource id (MSTeams: from pin or list-pins, not the chat message id)]"
}

_openclaw_message_pins() {
  _arguments -C \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--limit[Result limit]"
}

_openclaw_message_permissions() {
  _arguments -C \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]"
}

_openclaw_message_search() {
  _arguments -C \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--guild-id[Guild id]" \
    "--query[Search query]" \
    "--channel-id[Channel id]" \
    "--channel-ids[Channel id (repeat)]" \
    "--author-id[Author id]" \
    "--author-ids[Author id (repeat)]" \
    "--limit[Result limit]"
}

_openclaw_message_thread_create() {
  _arguments -C \
    "--thread-name[Thread name]" \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--message-id[Message id (optional)]" \
    "(--message -m)"{--message,-m}"[Initial thread message text]" \
    "--auto-archive-min[Thread auto-archive minutes]"
}

_openclaw_message_thread_list() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--channel-id[Channel id]" \
    "--include-archived[Include archived threads]" \
    "--before[Read/search before id]" \
    "--limit[Result limit]"
}

_openclaw_message_thread_reply() {
  _arguments -C \
    "(--message -m)"{--message,-m}"[Message body]" \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--media[Attach media (image/audio/video/document). Accepts local paths or URLs.]" \
    "--reply-to[Reply-to message id]"
}

_openclaw_message_thread() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'create[Create a thread]' 'list[List threads]' 'reply[Reply in a thread]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (create) _openclaw_message_thread_create ;;
        (list) _openclaw_message_thread_list ;;
        (reply) _openclaw_message_thread_reply ;;
      esac
      ;;
  esac
}

_openclaw_message_emoji_list() {
  _arguments -C \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--guild-id[Guild id (Discord)]"
}

_openclaw_message_emoji_upload() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--emoji-name[Emoji name]" \
    "--media[Emoji media (path or URL)]" \
    "--role-ids[Role id (repeat)]"
}

_openclaw_message_emoji() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List emojis]' 'upload[Upload an emoji]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_message_emoji_list ;;
        (upload) _openclaw_message_emoji_upload ;;
      esac
      ;;
  esac
}

_openclaw_message_sticker_send() {
  _arguments -C \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--sticker-id[Sticker id (repeat)]" \
    "(--message -m)"{--message,-m}"[Optional message body]"
}

_openclaw_message_sticker_upload() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--sticker-name[Sticker name]" \
    "--sticker-desc[Sticker description]" \
    "--sticker-tags[Sticker tags]" \
    "--media[Sticker media (path or URL)]"
}

_openclaw_message_sticker() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'send[Send stickers]' 'upload[Upload a sticker]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (send) _openclaw_message_sticker_send ;;
        (upload) _openclaw_message_sticker_upload ;;
      esac
      ;;
  esac
}

_openclaw_message_role_info() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]"
}

_openclaw_message_role_add() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--user-id[User id]" \
    "--role-id[Role id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]"
}

_openclaw_message_role_remove() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--user-id[User id]" \
    "--role-id[Role id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]"
}

_openclaw_message_role() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'info[List roles]' 'add[Add role to a member]' 'remove[Remove role from a member]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (info) _openclaw_message_role_info ;;
        (add) _openclaw_message_role_add ;;
        (remove) _openclaw_message_role_remove ;;
      esac
      ;;
  esac
}

_openclaw_message_channel_info() {
  _arguments -C \
    "(--target -t)"{--target,-t}"[Recipient/channel: E.164 for WhatsApp/Signal, Telegram chat id/@username, Discord/Slack/Mattermost <channelId|user:ID|channel:ID>, or iMessage handle/chat_id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]"
}

_openclaw_message_channel_list() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]"
}

_openclaw_message_channel() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'info[Fetch channel info]' 'list[List channels]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (info) _openclaw_message_channel_info ;;
        (list) _openclaw_message_channel_list ;;
      esac
      ;;
  esac
}

_openclaw_message_member_info() {
  _arguments -C \
    "--user-id[User id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--guild-id[Guild id (Discord)]"
}

_openclaw_message_member() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'info[Fetch member info]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (info) _openclaw_message_member_info ;;
      esac
      ;;
  esac
}

_openclaw_message_voice_status() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--user-id[User id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]"
}

_openclaw_message_voice() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'status[Fetch voice status]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (status) _openclaw_message_voice_status ;;
      esac
      ;;
  esac
}

_openclaw_message_event_list() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]"
}

_openclaw_message_event_create() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--event-name[Event name]" \
    "--start-time[Event start time]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--end-time[Event end time]" \
    "--desc[Event description]" \
    "--channel-id[Channel id]" \
    "--location[Event location]" \
    "--event-type[Event type]" \
    "--image[Cover image URL or local file path]"
}

_openclaw_message_event() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List scheduled events]' 'create[Create a scheduled event]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_message_event_list ;;
        (create) _openclaw_message_event_create ;;
      esac
      ;;
  esac
}

_openclaw_message_timeout() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--user-id[User id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--duration-min[Timeout duration minutes]" \
    "--until[Timeout until]" \
    "--reason[Moderation reason]"
}

_openclaw_message_kick() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--user-id[User id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--reason[Moderation reason]"
}

_openclaw_message_ban() {
  _arguments -C \
    "--guild-id[Guild id]" \
    "--user-id[User id]" \
    "--channel[Channel: telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch]" \
    "--account[Channel account id (accountId)]" \
    "--json[Output result as JSON]" \
    "--dry-run[Print payload and skip sending]" \
    "--verbose[Verbose logging]" \
    "--reason[Moderation reason]" \
    "--delete-days[Ban delete message days]"
}

_openclaw_message() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'send[Send a message]' 'broadcast[Broadcast a message to multiple targets]' 'poll[Send a poll]' 'react[Add or remove a reaction]' 'reactions[List reactions on a message]' 'read[Read recent messages]' 'edit[Edit a message]' 'delete[Delete a message]' 'pin[Pin a message]' 'unpin[Unpin a message]' 'pins[List pinned messages]' 'permissions[Fetch channel permissions]' 'search[Search Discord messages]' 'thread[Thread actions]' 'emoji[Emoji actions]' 'sticker[Sticker actions]' 'role[Role actions]' 'channel[Channel actions]' 'member[Member actions]' 'voice[Voice actions]' 'event[Event actions]' 'timeout[Timeout a member]' 'kick[Kick a member]' 'ban[Ban a member]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (send) _openclaw_message_send ;;
        (broadcast) _openclaw_message_broadcast ;;
        (poll) _openclaw_message_poll ;;
        (react) _openclaw_message_react ;;
        (reactions) _openclaw_message_reactions ;;
        (read) _openclaw_message_read ;;
        (edit) _openclaw_message_edit ;;
        (delete) _openclaw_message_delete ;;
        (pin) _openclaw_message_pin ;;
        (unpin) _openclaw_message_unpin ;;
        (pins) _openclaw_message_pins ;;
        (permissions) _openclaw_message_permissions ;;
        (search) _openclaw_message_search ;;
        (thread) _openclaw_message_thread ;;
        (emoji) _openclaw_message_emoji ;;
        (sticker) _openclaw_message_sticker ;;
        (role) _openclaw_message_role ;;
        (channel) _openclaw_message_channel ;;
        (member) _openclaw_message_member ;;
        (voice) _openclaw_message_voice ;;
        (event) _openclaw_message_event ;;
        (timeout) _openclaw_message_timeout ;;
        (kick) _openclaw_message_kick ;;
        (ban) _openclaw_message_ban ;;
      esac
      ;;
  esac
}

_openclaw_mcp_serve() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--token-file[Read gateway token from file]" \
    "--password[Gateway password (if required)]" \
    "--password-file[Read gateway password from file]" \
    "--claude-channel-mode[Claude channel notification mode: auto, on, or off]" \
    "(--verbose -v)"{--verbose,-v}"[Verbose logging to stderr]"
}

_openclaw_mcp_list() {
  _arguments -C \
    "--json[Print JSON]"
}

_openclaw_mcp_show() {
  _arguments -C \
    "--json[Print JSON]"
}

_openclaw_mcp_status() {
  _arguments -C \
    "(--verbose -v)"{--verbose,-v}"[Show transport, auth, timeout, and filter details]" \
    "--json[Print JSON]"
}

_openclaw_mcp_probe() {
  _arguments -C \
    "--json[Print JSON]"
}

_openclaw_mcp_doctor() {
  _arguments -C \
    "--probe[Also connect to each checked server]" \
    "--json[Print JSON]"
}

_openclaw_mcp_add() {
  _arguments -C \
    "--command[Stdio command to spawn]" \
    "--arg[Repeatable stdio argument]" \
    "--env[Repeatable stdio environment entry]" \
    "--cwd[Working directory for stdio server]" \
    "--url[HTTP MCP server URL]" \
    "--transport[HTTP transport: streamable-http or sse]" \
    "--header[Repeatable HTTP header]" \
    "--auth[HTTP auth mode: oauth]" \
    "--oauth-scope[OAuth scope]" \
    "--oauth-redirect-url[OAuth redirect URL]" \
    "--oauth-client-metadata-url[OAuth client metadata URL]" \
    "--include[Comma-separated MCP tool names or '\''*'\'' globs to expose]" \
    "--exclude[Comma-separated MCP tool names or '\''*'\'' globs to hide]" \
    "--timeout[Per-request timeout in seconds]" \
    "--connect-timeout[Connection timeout in seconds]" \
    "--parallel[Mark this server safe for concurrent tool calls]" \
    "--disabled[Save the server disabled]" \
    "--ssl-verify[Verify HTTPS certificates: true or false]" \
    "--client-cert[HTTP mutual TLS client certificate path]" \
    "--client-key[HTTP mutual TLS client key path]" \
    "--no-probe[Save without connecting first]"
}

_openclaw_mcp_set() {
  _arguments -C \
    
}

_openclaw_mcp_tools() {
  _arguments -C \
    "--include[Comma-separated MCP tool names or '\''*'\'' globs to expose]" \
    "--exclude[Comma-separated MCP tool names or '\''*'\'' globs to hide]" \
    "--clear[Clear this server'\''s MCP tool filter]"
}

_openclaw_mcp_configure() {
  _arguments -C \
    "--enable[Enable this saved server]" \
    "--disable[Disable this saved server]" \
    "--include[Comma-separated MCP tool names or '\''*'\'' globs to expose]" \
    "--exclude[Comma-separated MCP tool names or '\''*'\'' globs to hide]" \
    "--clear-tools[Clear this server'\''s MCP tool filter]" \
    "--timeout[Per-request timeout in seconds]" \
    "--connect-timeout[Connection timeout in seconds]" \
    "--clear-timeouts[Clear request and connection timeout overrides]" \
    "--parallel[Mark this server safe for concurrent tool calls]" \
    "--no-parallel[Clear the concurrent tool-call marker]" \
    "--auth[HTTP auth mode: oauth]" \
    "--clear-auth[Clear auth and OAuth metadata]" \
    "--oauth-scope[OAuth scope]" \
    "--oauth-redirect-url[OAuth redirect URL]" \
    "--oauth-client-metadata-url[OAuth client metadata URL]" \
    "--ssl-verify[Verify HTTPS certificates: true or false]" \
    "--client-cert[HTTP mutual TLS client certificate path]" \
    "--client-key[HTTP mutual TLS client key path]" \
    "--clear-tls[Clear TLS verification and mTLS overrides]" \
    "--probe[Probe the updated server before saving]"
}

_openclaw_mcp_login() {
  _arguments -C \
    "--code[Authorization code from the OAuth redirect]"
}

_openclaw_mcp_logout() {
  _arguments -C \
    
}

_openclaw_mcp_reload() {
  _arguments -C \
    
}

_openclaw_mcp_unset() {
  _arguments -C \
    
}

_openclaw_mcp() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'serve[Expose OpenClaw channels over MCP stdio]' 'list[List configured MCP servers]' 'show[Show one configured MCP server or the full MCP config]' 'status[Show configured MCP server transport status without connecting]' 'probe[Connect to configured MCP servers and list available capabilities]' 'doctor[Check configured MCP servers for static setup problems]' 'add[Add one MCP server from flags and probe it before saving]' 'set[Set one configured MCP server from a JSON object]' 'tools[Update per-server MCP tool include/exclude filters]' 'configure[Update MCP server operator controls without replacing the server]' 'login[Authorize an OAuth MCP server]' 'logout[Clear stored OAuth credentials for an MCP server]' 'reload[Dispose cached MCP runtimes so new config is used on the next turn]' 'unset[Remove one configured MCP server]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (serve) _openclaw_mcp_serve ;;
        (list) _openclaw_mcp_list ;;
        (show) _openclaw_mcp_show ;;
        (status) _openclaw_mcp_status ;;
        (probe) _openclaw_mcp_probe ;;
        (doctor) _openclaw_mcp_doctor ;;
        (add) _openclaw_mcp_add ;;
        (set) _openclaw_mcp_set ;;
        (tools) _openclaw_mcp_tools ;;
        (configure) _openclaw_mcp_configure ;;
        (login) _openclaw_mcp_login ;;
        (logout) _openclaw_mcp_logout ;;
        (reload) _openclaw_mcp_reload ;;
        (unset) _openclaw_mcp_unset ;;
      esac
      ;;
  esac
}

_openclaw_transcripts_list() {
  _arguments -C \
    "--json[Print JSON]"
}

_openclaw_transcripts_show() {
  _arguments -C \
    "--json[Print JSON]"
}

_openclaw_transcripts_path() {
  _arguments -C \
    "--dir[Print the session directory]" \
    "--metadata[Print metadata.json]" \
    "--transcript[Print transcript.jsonl]" \
    "--json[Print JSON]"
}

_openclaw_transcripts() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List stored transcript sessions]' 'show[Print a transcript summary markdown file]' 'path[Print a stored transcripts artifact path]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_transcripts_list ;;
        (show) _openclaw_transcripts_show ;;
        (path) _openclaw_transcripts_path ;;
      esac
      ;;
  esac
}

_openclaw_agent() {
  _arguments -C \
    "(--message -m)"{--message,-m}"[Message body for the agent]" \
    "(--to -t)"{--to,-t}"[Recipient number in E.164 used to derive the session key]" \
    "--session-key[Explicit session key (agent:<id>:<key>, or scoped to --agent)]" \
    "--session-id[Use an explicit session id]" \
    "--agent[Agent id (overrides routing bindings)]" \
    "--model[Model override for this run (provider/model or model id)]" \
    "--thinking[Thinking level: off | minimal | low | medium | high | xhigh | adaptive | max where supported]" \
    "--verbose[Persist agent verbose level for the session]" \
    "--channel[Delivery channel: last|telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch (omit to use the main session channel)]" \
    "--reply-to[Delivery target override (separate from session routing)]" \
    "--reply-channel[Delivery channel override (separate from routing)]" \
    "--reply-account[Delivery account id override]" \
    "--local[Run the embedded agent locally (requires model provider API keys in your shell)]" \
    "--deliver[Send the agent'\''s reply back to the selected channel]" \
    "--json[Output result as JSON]" \
    "--timeout[Override agent command timeout (seconds, default 600 or config value)]"
}

_openclaw_agents_list() {
  _arguments -C \
    "--json[Output JSON instead of text]" \
    "--bindings[Include routing bindings]"
}

_openclaw_agents_bindings() {
  _arguments -C \
    "--agent[Filter by agent id]" \
    "--json[Output JSON instead of text]"
}

_openclaw_agents_bind() {
  _arguments -C \
    "--agent[Agent id (defaults to current default agent)]" \
    "--bind[Binding to add (repeatable). If omitted, accountId is resolved by channel defaults/hooks.]" \
    "--json[Output JSON summary]"
}

_openclaw_agents_unbind() {
  _arguments -C \
    "--agent[Agent id (defaults to current default agent)]" \
    "--bind[Binding to remove (repeatable)]" \
    "--all[Remove all bindings for this agent]" \
    "--json[Output JSON summary]"
}

_openclaw_agents_add() {
  _arguments -C \
    "--workspace[Workspace directory for the new agent]" \
    "--model[Model id for this agent]" \
    "--agent-dir[Agent state directory for this agent]" \
    "--bind[Route channel binding (repeatable)]" \
    "--non-interactive[Disable prompts; requires --workspace]" \
    "--json[Output JSON summary]"
}

_openclaw_agents_set_identity() {
  _arguments -C \
    "--agent[Agent id to update]" \
    "--workspace[Workspace directory used to locate the agent + IDENTITY.md]" \
    "--identity-file[Explicit IDENTITY.md path to read]" \
    "--from-identity[Read values from IDENTITY.md]" \
    "--name[Identity name]" \
    "--theme[Identity theme]" \
    "--emoji[Identity emoji]" \
    "--avatar[Identity avatar (workspace path, http(s) URL, or data URI)]" \
    "--json[Output JSON summary]"
}

_openclaw_agents_delete() {
  _arguments -C \
    "--force[Skip confirmation]" \
    "--json[Output JSON summary]"
}

_openclaw_agents() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List configured agents]' 'bindings[List routing bindings]' 'bind[Add routing bindings for an agent]' 'unbind[Remove routing bindings for an agent]' 'add[Add a new isolated agent]' 'set-identity[Update an agent identity (name/theme/emoji/avatar)]' 'delete[Delete an agent and prune workspace/state]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_agents_list ;;
        (bindings) _openclaw_agents_bindings ;;
        (bind) _openclaw_agents_bind ;;
        (unbind) _openclaw_agents_unbind ;;
        (add) _openclaw_agents_add ;;
        (set-identity) _openclaw_agents_set_identity ;;
        (delete) _openclaw_agents_delete ;;
      esac
      ;;
  esac
}

_openclaw_status() {
  _arguments -C \
    "--json[Output JSON instead of text]" \
    "--all[Full diagnosis (read-only, pasteable)]" \
    "--usage[Show model provider usage/quota snapshots]" \
    "--deep[Probe channels (WhatsApp Web + Telegram + Discord + Slack + Signal)]" \
    "--timeout[Probe timeout in milliseconds]" \
    "--verbose[Verbose logging]" \
    "--debug[Alias for --verbose]"
}

_openclaw_health() {
  _arguments -C \
    "--json[Output JSON instead of text]" \
    "--timeout[Connection timeout in milliseconds]" \
    "--verbose[Verbose logging]" \
    "--debug[Alias for --verbose]"
}

_openclaw_sessions_list() {
  _arguments -C \
    "--json[Output as JSON]" \
    "--verbose[Verbose logging]" \
    "--store[Path to session store (default: resolved from config)]" \
    "--agent[Agent id to inspect (default: configured default agent)]" \
    "--all-agents[Aggregate sessions across all configured agents]" \
    "--active[Only show sessions updated within the past N minutes]" \
    "--limit[Max sessions to show (default: 100; use \"all\" for full output)]"
}

_openclaw_sessions_cleanup() {
  _arguments -C \
    "--store[Path to session store (default: resolved from config)]" \
    "--agent[Agent id to maintain (default: configured default agent)]" \
    "--all-agents[Run maintenance across all configured agents]" \
    "--dry-run[Preview maintenance actions without writing]" \
    "--enforce[Apply maintenance even when configured mode is warn]" \
    "--fix-missing[Remove store entries whose transcript files are missing (bypasses age/count retention)]" \
    "--fix-dm-scope[Retire stale direct-DM session rows that no longer match session.dmScope=main]" \
    "--active-key[Protect this session key from budget-eviction]" \
    "--json[Output JSON]"
}

_openclaw_sessions_tail() {
  _arguments -C \
    "--session-key[Session key to tail (default: active sessions or latest)]" \
    "--tail[Number of existing trajectory events to show]" \
    "--follow[Continue following for new trajectory events]" \
    "--store[Path to session store (default: resolved from config)]" \
    "--agent[Agent id to inspect (default: configured default agent)]" \
    "--all-agents[Aggregate sessions across all configured agents]"
}

_openclaw_sessions_export_trajectory() {
  _arguments -C \
    "--session-key[Session key to export]" \
    "--output[Output directory name inside .openclaw/trajectory-exports]" \
    "--workspace[Workspace root for the export (default: current directory)]" \
    "--store[Path to session store (default: resolved from session key)]" \
    "--agent[Agent id for resolving the default session store]" \
    "--request-json-base64[Base64url-encoded export request]" \
    "--json[Output JSON]"
}

_openclaw_sessions() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--json[Output as JSON]" \
    "--verbose[Verbose logging]" \
    "--store[Path to session store (default: resolved from config)]" \
    "--agent[Agent id to inspect (default: configured default agent)]" \
    "--all-agents[Aggregate sessions across all configured agents]" \
    "--active[Only show sessions updated within the past N minutes]" \
    "--limit[Max sessions to show (default: 100; use \"all\" for full output)]" \
    "1: :_values 'command' 'list[List stored conversation sessions]' 'cleanup[Run session-store maintenance now]' 'tail[Tail human-readable session trajectory progress]' 'export-trajectory[Export a redacted trajectory bundle for a stored session]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_sessions_list ;;
        (cleanup) _openclaw_sessions_cleanup ;;
        (tail) _openclaw_sessions_tail ;;
        (export-trajectory) _openclaw_sessions_export_trajectory ;;
      esac
      ;;
  esac
}

_openclaw_commitments_list() {
  _arguments -C \
    "--json[Output JSON instead of text]" \
    "--agent[Agent id to inspect]" \
    "--status[Filter by status (pending, sent, dismissed, snoozed, expired)]" \
    "--all[Show all statuses]"
}

_openclaw_commitments_dismiss() {
  _arguments -C \
    "--json[Output JSON instead of text]"
}

_openclaw_commitments() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--json[Output JSON instead of text]" \
    "--agent[Agent id to inspect]" \
    "--status[Filter by status (pending, sent, dismissed, snoozed, expired)]" \
    "--all[Show all statuses]" \
    "1: :_values 'command' 'list[List inferred follow-up commitments]' 'dismiss[Dismiss inferred follow-up commitments]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_commitments_list ;;
        (dismiss) _openclaw_commitments_dismiss ;;
      esac
      ;;
  esac
}

_openclaw_tasks_list() {
  _arguments -C \
    "--json[Output as JSON]" \
    "--runtime[Filter by kind (subagent, acp, cron, cli)]" \
    "--status[Filter by status (queued, running, succeeded, failed, timed_out, cancelled, lost)]"
}

_openclaw_tasks_audit() {
  _arguments -C \
    "--json[Output as JSON]" \
    "--severity[Filter by severity (warn, error)]" \
    "--code[Filter by finding code (stale_queued, stale_running, lost, delivery_failed, missing_cleanup, inconsistent_timestamps, restore_failed, stale_waiting, stale_blocked, cancel_stuck, missing_linked_tasks, blocked_task_missing)]" \
    "--limit[Limit displayed findings]"
}

_openclaw_tasks_maintenance() {
  _arguments -C \
    "--json[Output as JSON]" \
    "--apply[Apply reconciliation, cleanup stamping, and pruning]"
}

_openclaw_tasks_show() {
  _arguments -C \
    "--json[Output as JSON]"
}

_openclaw_tasks_notify() {
  _arguments -C \
    
}

_openclaw_tasks_cancel() {
  _arguments -C \
    
}

_openclaw_tasks_flow_list() {
  _arguments -C \
    "--json[Output as JSON]" \
    "--status[Filter by status (queued, running, waiting, blocked, succeeded, failed, cancelled, lost)]"
}

_openclaw_tasks_flow_show() {
  _arguments -C \
    "--json[Output as JSON]"
}

_openclaw_tasks_flow_cancel() {
  _arguments -C \
    
}

_openclaw_tasks_flow() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List tracked TaskFlows]' 'show[Show one TaskFlow by flow id or owner key]' 'cancel[Cancel a running TaskFlow]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_tasks_flow_list ;;
        (show) _openclaw_tasks_flow_show ;;
        (cancel) _openclaw_tasks_flow_cancel ;;
      esac
      ;;
  esac
}

_openclaw_tasks() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--json[Output as JSON]" \
    "--runtime[Filter by kind (subagent, acp, cron, cli)]" \
    "--status[Filter by status (queued, running, succeeded, failed, timed_out, cancelled, lost)]" \
    "1: :_values 'command' 'list[List tracked background tasks]' 'audit[Show stale or broken background tasks and TaskFlows]' 'maintenance[Preview or apply tasks and TaskFlow maintenance]' 'show[Show one background task by task id, run id, or session key]' 'notify[Set task notify policy]' 'cancel[Cancel a running background task]' 'flow[Inspect durable TaskFlow state under tasks]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_tasks_list ;;
        (audit) _openclaw_tasks_audit ;;
        (maintenance) _openclaw_tasks_maintenance ;;
        (show) _openclaw_tasks_show ;;
        (notify) _openclaw_tasks_notify ;;
        (cancel) _openclaw_tasks_cancel ;;
        (flow) _openclaw_tasks_flow ;;
      esac
      ;;
  esac
}

_openclaw_acp_client() {
  _arguments -C \
    "--cwd[Working directory for the ACP session]" \
    "--server[ACP server command (default: openclaw)]" \
    "--server-args[Extra arguments for the ACP server]" \
    "--server-verbose[Enable verbose logging on the ACP server]" \
    "(--verbose -v)"{--verbose,-v}"[Verbose client logging]"
}

_openclaw_acp() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--token-file[Read gateway token from file]" \
    "--password[Gateway password (if required)]" \
    "--password-file[Read gateway password from file]" \
    "--session[Default session key (e.g. agent:main:main)]" \
    "--session-label[Default session label to resolve]" \
    "--require-existing[Fail if the session key/label does not exist]" \
    "--reset-session[Reset the session key before first use]" \
    "--no-prefix-cwd[Do not prefix prompts with the working directory]" \
    "--provenance[ACP provenance mode: off, meta, or meta+receipt]" \
    "(--verbose -v)"{--verbose,-v}"[Verbose logging to stderr]" \
    "1: :_values 'command' 'client[Run an interactive ACP client against the local ACP bridge]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (client) _openclaw_acp_client ;;
      esac
      ;;
  esac
}

_openclaw_gateway_run() {
  _arguments -C \
    "--port[Port for the gateway WebSocket]" \
    "--bind[Bind mode (\"loopback\"|\"lan\"|\"tailnet\"|\"auto\"|\"custom\"). Defaults to config gateway.bind (or loopback).]" \
    "--token[Shared token required in connect.params.auth.token (default: OPENCLAW_GATEWAY_TOKEN env if set)]" \
    "--auth[Gateway auth mode (\"none\"|\"token\"|\"password\"|\"trusted-proxy\")]" \
    "--password[Password for auth mode=password]" \
    "--password-file[Read gateway password from file]" \
    "--tailscale[Tailscale exposure mode (\"off\"|\"serve\"|\"funnel\")]" \
    "--tailscale-reset-on-exit[Reset Tailscale serve/funnel configuration on shutdown]" \
    "--allow-unconfigured[Allow gateway start without enforcing gateway.mode=local in config (does not repair config)]" \
    "--dev[Create a dev config + workspace if missing (no BOOTSTRAP.md)]" \
    "--reset[Reset dev config + credentials + sessions + workspace (requires --dev)]" \
    "--force[Kill any existing listener on the target port before starting]" \
    "--verbose[Verbose logging to stdout/stderr]" \
    "--cli-backend-logs[Only show CLI backend logs in the console (includes stdout/stderr)]" \
    "--claude-cli-logs[Deprecated alias for --cli-backend-logs]" \
    "--ws-log[WebSocket log style (\"auto\"|\"full\"|\"compact\")]" \
    "--compact[Alias for \"--ws-log compact\"]" \
    "--raw-stream[Log raw model stream events to jsonl]" \
    "--raw-stream-path[Raw stream jsonl path]"
}

_openclaw_gateway_status() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to config/remote/local)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--no-probe[Skip RPC probe]" \
    "--require-rpc[Exit non-zero when the RPC probe fails]" \
    "--deep[Scan system-level services]" \
    "--json[Output JSON]"
}

_openclaw_gateway_install() {
  _arguments -C \
    "--port[Gateway port]" \
    "--runtime[Daemon runtime (node|bun). Default: node]" \
    "--token[Gateway token (token auth)]" \
    "--wrapper[Executable wrapper for generated service ProgramArguments]" \
    "--force[Reinstall/overwrite if already installed]" \
    "--json[Output JSON]"
}

_openclaw_gateway_uninstall() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_gateway_start() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_gateway_stop() {
  _arguments -C \
    "--json[Output JSON]" \
    "--disable[Persistently suppress KeepAlive/RunAtLoad so the gateway does not respawn until next start (launchd only)]"
}

_openclaw_gateway_restart() {
  _arguments -C \
    "--force[Restart immediately without waiting for active gateway work]" \
    "--safe[Request an OpenClaw-aware restart after active work drains]" \
    "--skip-deferral[Bypass the safe-restart deferral gate; requires --safe]" \
    "--wait[Wait duration before forcing restart (ms, 10s, 5m; 0 waits indefinitely)]" \
    "--json[Output JSON]"
}

_openclaw_gateway_call() {
  _arguments -C \
    "--params[JSON object string for params]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]" \
    "--json[Output JSON]"
}

_openclaw_gateway_usage_cost() {
  _arguments -C \
    "--days[Number of days to include]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]" \
    "--json[Output JSON]"
}

_openclaw_gateway_health() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]" \
    "--json[Output JSON]"
}

_openclaw_gateway_stability() {
  _arguments -C \
    "--limit[Maximum number of recent events]" \
    "--type[Filter by diagnostic event type]" \
    "--since-seq[Only include events after this sequence]" \
    "--bundle[Read a persisted stability bundle instead of calling Gateway; pass \"latest\" for newest]" \
    "--export[Write a shareable support diagnostics export]" \
    "--output[Diagnostics export output .zip path]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]" \
    "--json[Output JSON]"
}

_openclaw_gateway_diagnostics_export() {
  _arguments -C \
    "--output[Output .zip path]" \
    "--log-lines[Maximum sanitized log lines to include]" \
    "--log-bytes[Maximum log bytes to inspect]" \
    "--url[Gateway WebSocket URL for health snapshot]" \
    "--token[Gateway token for health snapshot]" \
    "--password[Gateway password for health snapshot]" \
    "--timeout[Status/health snapshot timeout in ms]" \
    "--no-stability-bundle[Skip persisted stability bundle lookup]" \
    "--json[Output JSON]"
}

_openclaw_gateway_diagnostics() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'export[Write a shareable, payload-free diagnostics .zip]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (export) _openclaw_gateway_diagnostics_export ;;
      esac
      ;;
  esac
}

_openclaw_gateway_probe() {
  _arguments -C \
    "--url[Explicit Gateway WebSocket URL (still probes localhost)]" \
    "--ssh[SSH target for remote gateway tunnel (user@host or user@host:port)]" \
    "--ssh-identity[SSH identity file path]" \
    "--ssh-auto[Try to derive an SSH target from Bonjour discovery]" \
    "--token[Gateway token (applies to all probes)]" \
    "--password[Gateway password (applies to all probes)]" \
    "--timeout[Overall probe budget in ms]" \
    "--json[Output JSON]"
}

_openclaw_gateway_discover() {
  _arguments -C \
    "--timeout[Per-command timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_gateway() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--port[Port for the gateway WebSocket]" \
    "--bind[Bind mode (\"loopback\"|\"lan\"|\"tailnet\"|\"auto\"|\"custom\"). Defaults to config gateway.bind (or loopback).]" \
    "--token[Shared token required in connect.params.auth.token (default: OPENCLAW_GATEWAY_TOKEN env if set)]" \
    "--auth[Gateway auth mode (\"none\"|\"token\"|\"password\"|\"trusted-proxy\")]" \
    "--password[Password for auth mode=password]" \
    "--password-file[Read gateway password from file]" \
    "--tailscale[Tailscale exposure mode (\"off\"|\"serve\"|\"funnel\")]" \
    "--tailscale-reset-on-exit[Reset Tailscale serve/funnel configuration on shutdown]" \
    "--allow-unconfigured[Allow gateway start without enforcing gateway.mode=local in config (does not repair config)]" \
    "--dev[Create a dev config + workspace if missing (no BOOTSTRAP.md)]" \
    "--reset[Reset dev config + credentials + sessions + workspace (requires --dev)]" \
    "--force[Kill any existing listener on the target port before starting]" \
    "--verbose[Verbose logging to stdout/stderr]" \
    "--cli-backend-logs[Only show CLI backend logs in the console (includes stdout/stderr)]" \
    "--claude-cli-logs[Deprecated alias for --cli-backend-logs]" \
    "--ws-log[WebSocket log style (\"auto\"|\"full\"|\"compact\")]" \
    "--compact[Alias for \"--ws-log compact\"]" \
    "--raw-stream[Log raw model stream events to jsonl]" \
    "--raw-stream-path[Raw stream jsonl path]" \
    "1: :_values 'command' 'run[Run the WebSocket Gateway (foreground)]' 'status[Show gateway service status + probe connectivity/capability]' 'install[Install the Gateway service (launchd/systemd/schtasks)]' 'uninstall[Uninstall the Gateway service (launchd/systemd/schtasks)]' 'start[Start the Gateway service (launchd/systemd/schtasks)]' 'stop[Stop the Gateway service (launchd/systemd/schtasks)]' 'restart[Restart the Gateway service (launchd/systemd/schtasks)]' 'call[Call a Gateway method]' 'usage-cost[Fetch usage cost summary from session logs]' 'health[Fetch Gateway health]' 'stability[Fetch payload-free Gateway stability diagnostics]' 'diagnostics[Export local support diagnostics]' 'probe[Show gateway reachability, auth capability, and read-probe summary (local + remote)]' 'discover[Discover gateways via Bonjour (local + wide-area if configured)]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (run) _openclaw_gateway_run ;;
        (status) _openclaw_gateway_status ;;
        (install) _openclaw_gateway_install ;;
        (uninstall) _openclaw_gateway_uninstall ;;
        (start) _openclaw_gateway_start ;;
        (stop) _openclaw_gateway_stop ;;
        (restart) _openclaw_gateway_restart ;;
        (call) _openclaw_gateway_call ;;
        (usage-cost) _openclaw_gateway_usage_cost ;;
        (health) _openclaw_gateway_health ;;
        (stability) _openclaw_gateway_stability ;;
        (diagnostics) _openclaw_gateway_diagnostics ;;
        (probe) _openclaw_gateway_probe ;;
        (discover) _openclaw_gateway_discover ;;
      esac
      ;;
  esac
}

_openclaw_daemon_status() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to config/remote/local)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--no-probe[Skip RPC probe]" \
    "--require-rpc[Exit non-zero when the RPC probe fails]" \
    "--deep[Scan system-level services]" \
    "--json[Output JSON]"
}

_openclaw_daemon_install() {
  _arguments -C \
    "--port[Gateway port]" \
    "--runtime[Daemon runtime (node|bun). Default: node]" \
    "--token[Gateway token (token auth)]" \
    "--wrapper[Executable wrapper for generated service ProgramArguments]" \
    "--force[Reinstall/overwrite if already installed]" \
    "--json[Output JSON]"
}

_openclaw_daemon_uninstall() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_daemon_start() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_daemon_stop() {
  _arguments -C \
    "--json[Output JSON]" \
    "--disable[Persistently suppress KeepAlive/RunAtLoad so the gateway does not respawn until next start (launchd only)]"
}

_openclaw_daemon_restart() {
  _arguments -C \
    "--force[Restart immediately without waiting for active gateway work]" \
    "--safe[Request an OpenClaw-aware restart after active work drains]" \
    "--skip-deferral[Bypass the safe-restart deferral gate; requires --safe]" \
    "--wait[Wait duration before forcing restart (ms, 10s, 5m; 0 waits indefinitely)]" \
    "--json[Output JSON]"
}

_openclaw_daemon() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'status[Show service install status + probe connectivity/capability]' 'install[Install the Gateway service (launchd/systemd/schtasks)]' 'uninstall[Uninstall the Gateway service (launchd/systemd/schtasks)]' 'start[Start the Gateway service (launchd/systemd/schtasks)]' 'stop[Stop the Gateway service (launchd/systemd/schtasks)]' 'restart[Restart the Gateway service (launchd/systemd/schtasks)]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (status) _openclaw_daemon_status ;;
        (install) _openclaw_daemon_install ;;
        (uninstall) _openclaw_daemon_uninstall ;;
        (start) _openclaw_daemon_start ;;
        (stop) _openclaw_daemon_stop ;;
        (restart) _openclaw_daemon_restart ;;
      esac
      ;;
  esac
}

_openclaw_logs() {
  _arguments -C \
    "--limit[Max lines to return]" \
    "--max-bytes[Max bytes to read]" \
    "--follow[Follow log output]" \
    "--interval[Polling interval in ms]" \
    "--json[Emit JSON log lines]" \
    "--plain[Plain text output (no ANSI styling)]" \
    "--no-color[Disable ANSI colors]" \
    "--local-time[Display timestamps in local timezone (default)]" \
    "--utc[Display timestamps in UTC]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_system_event() {
  _arguments -C \
    "--text[System event text]" \
    "--mode[Wake mode (now|next-heartbeat)]" \
    "--session-key[Target a specific session for the event (defaults to the agent'\''s main session)]" \
    "--json[Output JSON]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_system_heartbeat_last() {
  _arguments -C \
    "--json[Output JSON]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_system_heartbeat_enable() {
  _arguments -C \
    "--json[Output JSON]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_system_heartbeat_disable() {
  _arguments -C \
    "--json[Output JSON]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_system_heartbeat() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'last[Show the last heartbeat event]' 'enable[Enable heartbeats]' 'disable[Disable heartbeats]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (last) _openclaw_system_heartbeat_last ;;
        (enable) _openclaw_system_heartbeat_enable ;;
        (disable) _openclaw_system_heartbeat_disable ;;
      esac
      ;;
  esac
}

_openclaw_system_presence() {
  _arguments -C \
    "--json[Output JSON]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_system() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'event[Enqueue a system event and optionally trigger a heartbeat]' 'heartbeat[Heartbeat controls]' 'presence[List system presence entries]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (event) _openclaw_system_event ;;
        (heartbeat) _openclaw_system_heartbeat ;;
        (presence) _openclaw_system_presence ;;
      esac
      ;;
  esac
}

_openclaw_models_list() {
  _arguments -C \
    "--all[Show full model catalog]" \
    "--local[Filter to local models]" \
    "--provider[Filter by provider id]" \
    "--json[Output JSON]" \
    "--plain[Plain line output]"
}

_openclaw_models_status() {
  _arguments -C \
    "--json[Output JSON]" \
    "--plain[Plain output]" \
    "--check[Exit non-zero if auth is expiring/expired (1=expired/missing, 2=expiring)]" \
    "--probe[Probe configured provider auth (live)]" \
    "--probe-provider[Only probe a single provider]" \
    "--probe-profile[Only probe specific auth profile ids (repeat or comma-separated)]" \
    "--probe-timeout[Per-probe timeout in ms]" \
    "--probe-concurrency[Concurrent probes]" \
    "--probe-max-tokens[Probe max tokens (best-effort)]" \
    "--agent[Agent id to inspect (overrides OPENCLAW_AGENT_DIR)]"
}

_openclaw_models_set() {
  _arguments -C \
    
}

_openclaw_models_set_image() {
  _arguments -C \
    
}

_openclaw_models_aliases_list() {
  _arguments -C \
    "--json[Output JSON]" \
    "--plain[Plain output]"
}

_openclaw_models_aliases_add() {
  _arguments -C \
    
}

_openclaw_models_aliases_remove() {
  _arguments -C \
    
}

_openclaw_models_aliases() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List model aliases]' 'add[Add or update a model alias]' 'remove[Remove a model alias]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_models_aliases_list ;;
        (add) _openclaw_models_aliases_add ;;
        (remove) _openclaw_models_aliases_remove ;;
      esac
      ;;
  esac
}

_openclaw_models_fallbacks_list() {
  _arguments -C \
    "--json[Output JSON]" \
    "--plain[Plain output]"
}

_openclaw_models_fallbacks_add() {
  _arguments -C \
    
}

_openclaw_models_fallbacks_remove() {
  _arguments -C \
    
}

_openclaw_models_fallbacks_clear() {
  _arguments -C \
    
}

_openclaw_models_fallbacks() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List fallback models]' 'add[Add a fallback model]' 'remove[Remove a fallback model]' 'clear[Clear all fallback models]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_models_fallbacks_list ;;
        (add) _openclaw_models_fallbacks_add ;;
        (remove) _openclaw_models_fallbacks_remove ;;
        (clear) _openclaw_models_fallbacks_clear ;;
      esac
      ;;
  esac
}

_openclaw_models_image_fallbacks_list() {
  _arguments -C \
    "--json[Output JSON]" \
    "--plain[Plain output]"
}

_openclaw_models_image_fallbacks_add() {
  _arguments -C \
    
}

_openclaw_models_image_fallbacks_remove() {
  _arguments -C \
    
}

_openclaw_models_image_fallbacks_clear() {
  _arguments -C \
    
}

_openclaw_models_image_fallbacks() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List image fallback models]' 'add[Add an image fallback model]' 'remove[Remove an image fallback model]' 'clear[Clear all image fallback models]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_models_image_fallbacks_list ;;
        (add) _openclaw_models_image_fallbacks_add ;;
        (remove) _openclaw_models_image_fallbacks_remove ;;
        (clear) _openclaw_models_image_fallbacks_clear ;;
      esac
      ;;
  esac
}

_openclaw_models_scan() {
  _arguments -C \
    "--min-params[Minimum parameter size (billions)]" \
    "--max-age-days[Skip models older than N days]" \
    "--provider[Filter by provider prefix]" \
    "--max-candidates[Max fallback candidates]" \
    "--timeout[Per-probe timeout in ms]" \
    "--concurrency[Probe concurrency]" \
    "--no-probe[Skip live probes; list free candidates only]" \
    "--yes[Accept defaults without prompting]" \
    "--no-input[Disable prompts (use defaults)]" \
    "--set-default[Set agents.defaults.model to the first selection]" \
    "--set-image[Set agents.defaults.imageModel to the first image selection]" \
    "--json[Output JSON]"
}

_openclaw_models_auth_list() {
  _arguments -C \
    "--provider[Filter by provider id]" \
    "--agent[Agent id (default: configured default agent)]" \
    "--json[Output JSON]"
}

_openclaw_models_auth_add() {
  _arguments -C \
    
}

_openclaw_models_auth_login() {
  _arguments -C \
    "--provider[Provider id registered by a plugin]" \
    "--method[Provider auth method id]" \
    "--device-code[Use the provider device-code auth method]" \
    "--profile-id[Auth profile id override for single-profile login methods]" \
    "--set-default[Apply the provider'\''s default model recommendation]" \
    "--force[Remove existing profiles for the provider before logging in (use when a cached OAuth profile is stuck or you want to switch accounts)]"
}

_openclaw_models_auth_setup_token() {
  _arguments -C \
    "--provider[Provider id]" \
    "--yes[Skip confirmation]"
}

_openclaw_models_auth_paste_token() {
  _arguments -C \
    "--provider[Provider id (e.g. anthropic)]" \
    "--profile-id[Auth profile id (default: <provider>:manual)]" \
    "--expires-in[Optional expiry duration (e.g. 365d, 12h). Stored as absolute expiresAt.]"
}

_openclaw_models_auth_paste_api_key() {
  _arguments -C \
    "--provider[Provider id (e.g. openai)]" \
    "--profile-id[Auth profile id (default: <provider>:manual)]"
}

_openclaw_models_auth_login_github_copilot() {
  _arguments -C \
    "--yes[Overwrite existing profile without prompting]"
}

_openclaw_models_auth_order_get() {
  _arguments -C \
    "--provider[Provider id (e.g. anthropic)]" \
    "--agent[Agent id (default: configured default agent)]" \
    "--json[Output JSON]"
}

_openclaw_models_auth_order_set() {
  _arguments -C \
    "--provider[Provider id (e.g. anthropic)]" \
    "--agent[Agent id (default: configured default agent)]"
}

_openclaw_models_auth_order_clear() {
  _arguments -C \
    "--provider[Provider id (e.g. anthropic)]" \
    "--agent[Agent id (default: configured default agent)]"
}

_openclaw_models_auth_order() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'get[Show per-agent auth order override (from auth-state.json)]' 'set[Set per-agent auth order override (writes auth-state.json)]' 'clear[Clear per-agent auth order override (fall back to config/round-robin)]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (get) _openclaw_models_auth_order_get ;;
        (set) _openclaw_models_auth_order_set ;;
        (clear) _openclaw_models_auth_order_clear ;;
      esac
      ;;
  esac
}

_openclaw_models_auth() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--agent[Agent id for auth commands]" \
    "1: :_values 'command' 'list[List saved auth profiles]' 'add[Interactive auth helper (provider auth or paste token)]' 'login[Run a provider plugin auth flow (OAuth/API key)]' 'setup-token[Run a provider CLI to create/sync a token (TTY required)]' 'paste-token[Paste a token into auth-profiles.json and update config]' 'paste-api-key[Paste an API key into auth-profiles.json and update config]' 'login-github-copilot[Login to GitHub Copilot via GitHub device flow (TTY required)]' 'order[Manage per-agent auth profile order overrides]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_models_auth_list ;;
        (add) _openclaw_models_auth_add ;;
        (login) _openclaw_models_auth_login ;;
        (setup-token) _openclaw_models_auth_setup_token ;;
        (paste-token) _openclaw_models_auth_paste_token ;;
        (paste-api-key) _openclaw_models_auth_paste_api_key ;;
        (login-github-copilot) _openclaw_models_auth_login_github_copilot ;;
        (order) _openclaw_models_auth_order ;;
      esac
      ;;
  esac
}

_openclaw_models() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--status-json[Output JSON (alias for `models status --json`)]" \
    "--status-plain[Plain output (alias for `models status --plain`)]" \
    "--agent[Agent id to inspect (overrides OPENCLAW_AGENT_DIR)]" \
    "1: :_values 'command' 'list[List models (configured by default)]' 'status[Show configured model state]' 'set[Set the default model]' 'set-image[Set the image model]' 'aliases[Manage model aliases]' 'fallbacks[Manage model fallback list]' 'image-fallbacks[Manage image model fallback list]' 'scan[Scan OpenRouter free models for tools + images]' 'auth[Manage model auth profiles]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_models_list ;;
        (status) _openclaw_models_status ;;
        (set) _openclaw_models_set ;;
        (set-image) _openclaw_models_set_image ;;
        (aliases) _openclaw_models_aliases ;;
        (fallbacks) _openclaw_models_fallbacks ;;
        (image-fallbacks) _openclaw_models_image_fallbacks ;;
        (scan) _openclaw_models_scan ;;
        (auth) _openclaw_models_auth ;;
      esac
      ;;
  esac
}

_openclaw_infer_list() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_infer_inspect() {
  _arguments -C \
    "--name[Capability id]" \
    "--json[Output JSON]"
}

_openclaw_infer_model_run() {
  _arguments -C \
    "--prompt[Prompt text]" \
    "--file[Image file]" \
    "--model[Model override]" \
    "--thinking[Thinking level override]" \
    "--local[Force local execution]" \
    "--gateway[Force gateway execution]" \
    "--json[Output JSON]"
}

_openclaw_infer_model_list() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_infer_model_inspect() {
  _arguments -C \
    "--model[Model id]" \
    "--json[Output JSON]"
}

_openclaw_infer_model_providers() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_infer_model_auth_login() {
  _arguments -C \
    "--provider[Provider id]" \
    "--method[Provider auth method id]"
}

_openclaw_infer_model_auth_logout() {
  _arguments -C \
    "--provider[Provider id]" \
    "--agent[Agent id (default: configured default agent)]" \
    "--json[Output JSON]"
}

_openclaw_infer_model_auth_status() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_infer_model_auth() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'login[Run provider auth login]' 'logout[Remove saved auth profiles for one provider]' 'status[Show configured auth state]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (login) _openclaw_infer_model_auth_login ;;
        (logout) _openclaw_infer_model_auth_logout ;;
        (status) _openclaw_infer_model_auth_status ;;
      esac
      ;;
  esac
}

_openclaw_infer_model() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'run[Run a one-shot model turn]' 'list[List known models]' 'inspect[Inspect one model catalog entry]' 'providers[List model providers from the catalog]' 'auth[Provider auth helpers]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (run) _openclaw_infer_model_run ;;
        (list) _openclaw_infer_model_list ;;
        (inspect) _openclaw_infer_model_inspect ;;
        (providers) _openclaw_infer_model_providers ;;
        (auth) _openclaw_infer_model_auth ;;
      esac
      ;;
  esac
}

_openclaw_infer_image_generate() {
  _arguments -C \
    "--prompt[Prompt text]" \
    "--model[Model override]" \
    "--count[Number of images]" \
    "--size[Size hint like 1024x1024]" \
    "--aspect-ratio[Aspect ratio hint like 16:9]" \
    "--resolution[Resolution hint: 1K, 2K, or 4K]" \
    "--output-format[Output format hint: png, jpeg, or webp]" \
    "--background[Background hint: transparent, opaque, or auto]" \
    "--openai-background[OpenAI background hint: transparent, opaque, or auto]" \
    "--timeout-ms[Provider request timeout in milliseconds]" \
    "--output[Output path]" \
    "--json[Output JSON]"
}

_openclaw_infer_image_edit() {
  _arguments -C \
    "--file[Input file]" \
    "--prompt[Prompt text]" \
    "--model[Model override]" \
    "--size[Size hint like 1024x1024]" \
    "--aspect-ratio[Aspect ratio hint like 16:9]" \
    "--resolution[Resolution hint: 1K, 2K, or 4K]" \
    "--output-format[Output format hint: png, jpeg, or webp]" \
    "--background[Background hint: transparent, opaque, or auto]" \
    "--openai-background[OpenAI background hint: transparent, opaque, or auto]" \
    "--timeout-ms[Provider request timeout in milliseconds]" \
    "--output[Output path]" \
    "--json[Output JSON]"
}

_openclaw_infer_image_describe() {
  _arguments -C \
    "--file[Image file]" \
    "--prompt[Prompt hint]" \
    "--model[Model override]" \
    "--timeout-ms[Provider request timeout in milliseconds]" \
    "--json[Output JSON]"
}

_openclaw_infer_image_describe_many() {
  _arguments -C \
    "--file[Image file]" \
    "--prompt[Prompt hint]" \
    "--model[Model override]" \
    "--timeout-ms[Provider request timeout in milliseconds]" \
    "--json[Output JSON]"
}

_openclaw_infer_image_providers() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_infer_image() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'generate[Generate images]' 'edit[Edit images with one or more input files]' 'describe[Describe one image file]' 'describe-many[Describe multiple image files]' 'providers[List image generation providers]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (generate) _openclaw_infer_image_generate ;;
        (edit) _openclaw_infer_image_edit ;;
        (describe) _openclaw_infer_image_describe ;;
        (describe-many) _openclaw_infer_image_describe_many ;;
        (providers) _openclaw_infer_image_providers ;;
      esac
      ;;
  esac
}

_openclaw_infer_audio_transcribe() {
  _arguments -C \
    "--file[Audio file]" \
    "--language[Language hint]" \
    "--prompt[Prompt hint]" \
    "--model[Model override]" \
    "--json[Output JSON]"
}

_openclaw_infer_audio_providers() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_infer_audio() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'transcribe[Transcribe one audio file]' 'providers[List audio transcription providers]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (transcribe) _openclaw_infer_audio_transcribe ;;
        (providers) _openclaw_infer_audio_providers ;;
      esac
      ;;
  esac
}

_openclaw_infer_tts_convert() {
  _arguments -C \
    "--text[Input text]" \
    "--channel[Channel hint]" \
    "--voice[Voice hint]" \
    "--model[Model override]" \
    "--output[Output path]" \
    "--local[Force local execution]" \
    "--gateway[Force gateway execution]" \
    "--json[Output JSON]"
}

_openclaw_infer_tts_voices() {
  _arguments -C \
    "--provider[Speech provider id]" \
    "--json[Output JSON]"
}

_openclaw_infer_tts_providers() {
  _arguments -C \
    "--local[Force local execution]" \
    "--gateway[Force gateway execution]" \
    "--json[Output JSON]"
}

_openclaw_infer_tts_personas() {
  _arguments -C \
    "--local[Force local execution]" \
    "--gateway[Force gateway execution]" \
    "--json[Output JSON]"
}

_openclaw_infer_tts_status() {
  _arguments -C \
    "--gateway[Force gateway execution]" \
    "--json[Output JSON]"
}

_openclaw_infer_tts_enable() {
  _arguments -C \
    "--local[Force local execution]" \
    "--gateway[Force gateway execution]" \
    "--json[Output JSON]"
}

_openclaw_infer_tts_disable() {
  _arguments -C \
    "--local[Force local execution]" \
    "--gateway[Force gateway execution]" \
    "--json[Output JSON]"
}

_openclaw_infer_tts_set_provider() {
  _arguments -C \
    "--provider[Speech provider id]" \
    "--local[Force local execution]" \
    "--gateway[Force gateway execution]" \
    "--json[Output JSON]"
}

_openclaw_infer_tts_set_persona() {
  _arguments -C \
    "--persona[TTS persona id]" \
    "--off[Disable the active TTS persona]" \
    "--local[Force local execution]" \
    "--gateway[Force gateway execution]" \
    "--json[Output JSON]"
}

_openclaw_infer_tts() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'convert[Convert text to speech]' 'voices[List voices for a TTS provider]' 'providers[List speech providers]' 'personas[List TTS personas]' 'status[Show TTS status]' 'enable[Enable TTS]' 'disable[Disable TTS]' 'set-provider[Set the active TTS provider]' 'set-persona[Set the active TTS persona]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (convert) _openclaw_infer_tts_convert ;;
        (voices) _openclaw_infer_tts_voices ;;
        (providers) _openclaw_infer_tts_providers ;;
        (personas) _openclaw_infer_tts_personas ;;
        (status) _openclaw_infer_tts_status ;;
        (enable) _openclaw_infer_tts_enable ;;
        (disable) _openclaw_infer_tts_disable ;;
        (set-provider) _openclaw_infer_tts_set_provider ;;
        (set-persona) _openclaw_infer_tts_set_persona ;;
      esac
      ;;
  esac
}

_openclaw_infer_video_generate() {
  _arguments -C \
    "--prompt[Prompt text]" \
    "--model[Model override]" \
    "--size[Size hint like 1280x720]" \
    "--aspect-ratio[Aspect ratio hint like 16:9]" \
    "--resolution[Resolution hint: 360P, 480P, 540P, 720P, 768P, or 1080P]" \
    "--duration[Target duration in seconds]" \
    "--audio[Enable generated audio when supported]" \
    "--watermark[Request provider watermark when supported]" \
    "--timeout-ms[Provider request timeout in milliseconds]" \
    "--output[Output path]" \
    "--json[Output JSON]"
}

_openclaw_infer_video_describe() {
  _arguments -C \
    "--file[Video file]" \
    "--model[Model override]" \
    "--json[Output JSON]"
}

_openclaw_infer_video_providers() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_infer_video() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'generate[Generate video]' 'describe[Describe one video file]' 'providers[List video generation and description providers]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (generate) _openclaw_infer_video_generate ;;
        (describe) _openclaw_infer_video_describe ;;
        (providers) _openclaw_infer_video_providers ;;
      esac
      ;;
  esac
}

_openclaw_infer_web_search() {
  _arguments -C \
    "--query[Search query]" \
    "--provider[Provider id]" \
    "--limit[Result limit]" \
    "--json[Output JSON]"
}

_openclaw_infer_web_fetch() {
  _arguments -C \
    "--url[URL]" \
    "--provider[Provider id]" \
    "--format[Format hint]" \
    "--json[Output JSON]"
}

_openclaw_infer_web_providers() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_infer_web() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'search[Run web search]' 'fetch[Fetch one URL]' 'providers[List web providers]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (search) _openclaw_infer_web_search ;;
        (fetch) _openclaw_infer_web_fetch ;;
        (providers) _openclaw_infer_web_providers ;;
      esac
      ;;
  esac
}

_openclaw_infer_embedding_create() {
  _arguments -C \
    "--text[Input text]" \
    "--provider[Provider id]" \
    "--model[Model override]" \
    "--json[Output JSON]"
}

_openclaw_infer_embedding_providers() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_infer_embedding() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'create[Create embeddings]' 'providers[List embedding providers]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (create) _openclaw_infer_embedding_create ;;
        (providers) _openclaw_infer_embedding_providers ;;
      esac
      ;;
  esac
}

_openclaw_infer() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List canonical capability ids and supported transports]' 'inspect[Inspect one canonical capability id]' 'model[Text inference and model catalog commands]' 'image[Image generation and description]' 'audio[Audio transcription]' 'tts[Text to speech]' 'video[Video generation and description]' 'web[Web capabilities]' 'embedding[Embedding providers]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_infer_list ;;
        (inspect) _openclaw_infer_inspect ;;
        (model) _openclaw_infer_model ;;
        (image) _openclaw_infer_image ;;
        (audio) _openclaw_infer_audio ;;
        (tts) _openclaw_infer_tts ;;
        (video) _openclaw_infer_video ;;
        (web) _openclaw_infer_web ;;
        (embedding) _openclaw_infer_embedding ;;
      esac
      ;;
  esac
}

_openclaw_approvals_get() {
  _arguments -C \
    "--node[Target node id/name/IP]" \
    "--gateway[Force gateway approvals]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_approvals_set() {
  _arguments -C \
    "--node[Target node id/name/IP]" \
    "--gateway[Force gateway approvals]" \
    "--file[Path to JSON file to upload]" \
    "--stdin[Read JSON from stdin]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_approvals_allowlist_add() {
  _arguments -C \
    "--node[Target node id/name/IP]" \
    "--gateway[Force gateway approvals]" \
    "--agent[Agent id (defaults to \"*\")]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_approvals_allowlist_remove() {
  _arguments -C \
    "--node[Target node id/name/IP]" \
    "--gateway[Force gateway approvals]" \
    "--agent[Agent id (defaults to \"*\")]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_approvals_allowlist() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'add[Add a glob pattern to an allowlist]' 'remove[Remove a glob pattern from an allowlist]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (add) _openclaw_approvals_allowlist_add ;;
        (remove) _openclaw_approvals_allowlist_remove ;;
      esac
      ;;
  esac
}

_openclaw_approvals() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'get[Fetch exec approvals snapshot]' 'set[Replace exec approvals with a JSON file]' 'allowlist[Edit the per-agent allowlist]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (get) _openclaw_approvals_get ;;
        (set) _openclaw_approvals_set ;;
        (allowlist) _openclaw_approvals_allowlist ;;
      esac
      ;;
  esac
}

_openclaw_exec_policy_show() {
  _arguments -C \
    "--json[Output as JSON]"
}

_openclaw_exec_policy_preset() {
  _arguments -C \
    "--json[Output as JSON]"
}

_openclaw_exec_policy_set() {
  _arguments -C \
    "--host[Exec host target: auto|sandbox|gateway|node]" \
    "--security[Exec security: deny|allowlist|full]" \
    "--ask[Exec ask mode: off|on-miss|always]" \
    "--ask-fallback[Host approvals fallback: deny|allowlist|full]" \
    "--json[Output as JSON]"
}

_openclaw_exec_policy() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'show[Show the local config policy, host approvals, and effective merge]' 'preset[Apply a synchronized preset: "yolo", "cautious", or "deny-all"]' 'set[Synchronize local config and host approvals using explicit values]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (show) _openclaw_exec_policy_show ;;
        (preset) _openclaw_exec_policy_preset ;;
        (set) _openclaw_exec_policy_set ;;
      esac
      ;;
  esac
}

_openclaw_nodes_status() {
  _arguments -C \
    "--connected[Only show connected nodes]" \
    "--last-connected[Only show nodes connected within duration (e.g. 24h)]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_describe() {
  _arguments -C \
    "--node[Node id, name, or IP]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_list() {
  _arguments -C \
    "--connected[Only show connected nodes]" \
    "--last-connected[Only show nodes connected within duration (e.g. 24h)]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_pending() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_approve() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_reject() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_remove() {
  _arguments -C \
    "--node[Node id, name, or IP]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_rename() {
  _arguments -C \
    "--node[Node id, name, or IP]" \
    "--name[New display name]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_invoke() {
  _arguments -C \
    "--node[Node id, name, or IP]" \
    "--command[Command (e.g. canvas.eval)]" \
    "--params[JSON object string for params]" \
    "--invoke-timeout[Node invoke timeout in ms (default 15000)]" \
    "--idempotency-key[Idempotency key (optional)]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_notify() {
  _arguments -C \
    "--node[Node id, name, or IP]" \
    "--title[Notification title]" \
    "--body[Notification body]" \
    "--sound[Notification sound]" \
    "--priority[Notification priority]" \
    "--delivery[Delivery mode]" \
    "--invoke-timeout[Node invoke timeout in ms (default 15000)]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_push() {
  _arguments -C \
    "--node[Node id, name, or IP]" \
    "--title[Push title]" \
    "--body[Push body]" \
    "--environment[Override APNs environment]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_camera_list() {
  _arguments -C \
    "--node[Node id, name, or IP]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_camera_snap() {
  _arguments -C \
    "--node[Node id, name, or IP]" \
    "--facing[Camera facing]" \
    "--device-id[Camera device id (from nodes camera list)]" \
    "--max-width[Max width in px (optional)]" \
    "--quality[JPEG quality (default 0.9)]" \
    "--delay-ms[Delay before capture in ms (macOS default 2000)]" \
    "--invoke-timeout[Node invoke timeout in ms (default 20000)]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_camera_clip() {
  _arguments -C \
    "--node[Node id, name, or IP]" \
    "--facing[Camera facing]" \
    "--device-id[Camera device id (from nodes camera list)]" \
    "--duration[Duration (default 3000ms; supports ms/s/m, e.g. 10s)]" \
    "--no-audio[Disable audio capture]" \
    "--invoke-timeout[Node invoke timeout in ms (default 90000)]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_camera() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List available cameras on a node]' 'snap[Capture a photo from a node camera (prints the saved path)]' 'clip[Capture a short video clip from a node camera (prints the saved path)]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_nodes_camera_list ;;
        (snap) _openclaw_nodes_camera_snap ;;
        (clip) _openclaw_nodes_camera_clip ;;
      esac
      ;;
  esac
}

_openclaw_nodes_screen_record() {
  _arguments -C \
    "--node[Node id, name, or IP]" \
    "--screen[Screen index (0 = primary)]" \
    "--duration[Clip duration (ms or 10s)]" \
    "--fps[Frames per second]" \
    "--no-audio[Disable microphone audio capture]" \
    "--out[Output path]" \
    "--invoke-timeout[Node invoke timeout in ms (default 120000)]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_screen() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'record[Capture a short screen recording from a node (prints the saved path)]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (record) _openclaw_nodes_screen_record ;;
      esac
      ;;
  esac
}

_openclaw_nodes_location_get() {
  _arguments -C \
    "--node[Node id, name, or IP]" \
    "--max-age[Use cached location newer than this (ms)]" \
    "--accuracy[Desired accuracy (default: balanced/precise depending on node setting)]" \
    "--location-timeout[Location fix timeout (ms)]" \
    "--invoke-timeout[Node invoke timeout in ms (default 20000)]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_nodes_location() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'get[Fetch the current location from a node]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (get) _openclaw_nodes_location_get ;;
      esac
      ;;
  esac
}

_openclaw_nodes() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'status[List known nodes with connection status and capabilities]' 'describe[Describe a node (capabilities + supported invoke commands)]' 'list[List pending and paired nodes]' 'pending[List pending pairing requests]' 'approve[Approve a pending pairing request]' 'reject[Reject a pending pairing request]' 'remove[Remove a paired node entry]' 'rename[Rename a paired node (display name override)]' 'invoke[Invoke a command on a paired node]' 'notify[Send a local notification on a node (mac only)]' 'push[Send an APNs test push to an iOS node]' 'camera[Capture camera media from a paired node]' 'screen[Capture screen recordings from a paired node]' 'location[Fetch location from a paired node]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (status) _openclaw_nodes_status ;;
        (describe) _openclaw_nodes_describe ;;
        (list) _openclaw_nodes_list ;;
        (pending) _openclaw_nodes_pending ;;
        (approve) _openclaw_nodes_approve ;;
        (reject) _openclaw_nodes_reject ;;
        (remove) _openclaw_nodes_remove ;;
        (rename) _openclaw_nodes_rename ;;
        (invoke) _openclaw_nodes_invoke ;;
        (notify) _openclaw_nodes_notify ;;
        (push) _openclaw_nodes_push ;;
        (camera) _openclaw_nodes_camera ;;
        (screen) _openclaw_nodes_screen ;;
        (location) _openclaw_nodes_location ;;
      esac
      ;;
  esac
}

_openclaw_devices_list() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_devices_remove() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_devices_clear() {
  _arguments -C \
    "--pending[Also reject all pending pairing requests]" \
    "--yes[Confirm destructive clear]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_devices_approve() {
  _arguments -C \
    "--latest[Show the most recent pending request to approve explicitly]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_devices_reject() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_devices_rotate() {
  _arguments -C \
    "--device[Device id]" \
    "--role[Role name]" \
    "--scope[Scopes to attach to the token (repeatable)]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_devices_revoke() {
  _arguments -C \
    "--device[Device id]" \
    "--role[Role name]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (password auth)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_devices() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List pending and paired devices]' 'remove[Remove a paired device entry]' 'clear[Clear paired devices from the gateway table]' 'approve[Approve a pending device pairing request]' 'reject[Reject a pending device pairing request]' 'rotate[Rotate a device token for a role]' 'revoke[Revoke a device token for a role]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_devices_list ;;
        (remove) _openclaw_devices_remove ;;
        (clear) _openclaw_devices_clear ;;
        (approve) _openclaw_devices_approve ;;
        (reject) _openclaw_devices_reject ;;
        (rotate) _openclaw_devices_rotate ;;
        (revoke) _openclaw_devices_revoke ;;
      esac
      ;;
  esac
}

_openclaw_node_run() {
  _arguments -C \
    "--host[Gateway host]" \
    "--port[Gateway port]" \
    "--tls[Use TLS for the gateway connection]" \
    "--tls-fingerprint[Expected TLS certificate fingerprint (sha256)]" \
    "--node-id[Override node id (clears pairing token)]" \
    "--display-name[Override node display name]"
}

_openclaw_node_status() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_node_install() {
  _arguments -C \
    "--host[Gateway host]" \
    "--port[Gateway port]" \
    "--tls[Use TLS for the gateway connection]" \
    "--tls-fingerprint[Expected TLS certificate fingerprint (sha256)]" \
    "--node-id[Override node id (clears pairing token)]" \
    "--display-name[Override node display name]" \
    "--runtime[Service runtime (node|bun). Default: node]" \
    "--force[Reinstall/overwrite if already installed]" \
    "--json[Output JSON]"
}

_openclaw_node_uninstall() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_node_stop() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_node_start() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_node_restart() {
  _arguments -C \
    "--json[Output JSON]"
}

_openclaw_node() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'run[Run the headless node host (foreground)]' 'status[Show node host status]' 'install[Install the node host service (launchd/systemd/schtasks)]' 'uninstall[Uninstall the node host service (launchd/systemd/schtasks)]' 'stop[Stop the node host service (launchd/systemd/schtasks)]' 'start[Start the node host service (launchd/systemd/schtasks)]' 'restart[Restart the node host service (launchd/systemd/schtasks)]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (run) _openclaw_node_run ;;
        (status) _openclaw_node_status ;;
        (install) _openclaw_node_install ;;
        (uninstall) _openclaw_node_uninstall ;;
        (stop) _openclaw_node_stop ;;
        (start) _openclaw_node_start ;;
        (restart) _openclaw_node_restart ;;
      esac
      ;;
  esac
}

_openclaw_sandbox_list() {
  _arguments -C \
    "--json[Output result as JSON]" \
    "--browser[List browser containers only]"
}

_openclaw_sandbox_recreate() {
  _arguments -C \
    "--all[Recreate all sandbox containers]" \
    "--session[Recreate container for specific session]" \
    "--agent[Recreate containers for specific agent]" \
    "--browser[Only recreate browser containers]" \
    "--force[Skip confirmation prompt]"
}

_openclaw_sandbox_explain() {
  _arguments -C \
    "--session[Session key to inspect (defaults to agent main)]" \
    "--agent[Agent id to inspect (defaults to derived agent)]" \
    "--json[Output result as JSON]"
}

_openclaw_sandbox() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List sandbox containers and their status]' 'recreate[Remove containers to force recreation with updated config]' 'explain[Explain effective sandbox/tool policy for a session/agent]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_sandbox_list ;;
        (recreate) _openclaw_sandbox_recreate ;;
        (explain) _openclaw_sandbox_explain ;;
      esac
      ;;
  esac
}

_openclaw_tui() {
  _arguments -C \
    "--local[Run against the local embedded agent runtime]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--password[Gateway password (if required)]" \
    "--session[Session key (default: \"main\", or \"global\" when scope is global)]" \
    "--deliver[Deliver assistant replies]" \
    "--thinking[Thinking level override]" \
    "--message[Send an initial message after connecting]" \
    "--timeout-ms[Agent timeout in ms (defaults to agents.defaults.timeoutSeconds)]" \
    "--history-limit[History entries to load]"
}

_openclaw_cron_status() {
  _arguments -C \
    "--json[Output JSON]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_cron_list() {
  _arguments -C \
    "--all[Include disabled jobs]" \
    "--agent[Filter by agent id]" \
    "--json[Output JSON]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_cron_add() {
  _arguments -C \
    "--name[Job name]" \
    "--description[Optional description]" \
    "--disabled[Create job disabled]" \
    "--delete-after-run[Delete one-shot job after it succeeds]" \
    "--keep-after-run[Keep one-shot job after it succeeds]" \
    "--agent[Agent id for this job]" \
    "--session[Session target (main|isolated)]" \
    "--session-key[Session key for job routing (e.g. agent:my-agent:my-session)]" \
    "--wake[Wake mode (now|next-heartbeat)]" \
    "--at[Run once at time (ISO with offset, or +duration). Use --tz for offset-less datetimes]" \
    "--every[Run every duration (e.g. 10m, 1h)]" \
    "--cron[Cron expression (5-field or 6-field with seconds)]" \
    "--tz[Timezone for cron expressions (IANA; cron default: Gateway host local timezone)]" \
    "--stagger[Cron stagger window (e.g. 30s, 5m)]" \
    "--exact[Disable cron staggering (set stagger to 0)]" \
    "--system-event[System event payload (main session)]" \
    "--message[Agent message payload]" \
    "--command[Command payload run as sh -lc <shell> on the Gateway]" \
    "--command-argv[Command payload argv as JSON array of strings]" \
    "--command-cwd[Working directory for command payloads]" \
    "--command-env[Environment override for command payloads (repeatable)]" \
    "--command-input[stdin for command payloads]" \
    "--thinking[Thinking level for agent jobs (off|minimal|low|medium|high|xhigh)]" \
    "--model[Model override for agent jobs (provider/model or alias)]" \
    "--timeout-seconds[Timeout seconds for agent or command jobs]" \
    "--no-output-timeout-seconds[No-output timeout seconds for command jobs]" \
    "--output-max-bytes[Maximum captured stdout/stderr bytes for command jobs]" \
    "--light-context[Use lightweight bootstrap context for agent jobs]" \
    "--tools[Tool allow-list (e.g. exec,read,write or exec read write)]" \
    "--announce[Fallback-deliver final text to a chat]" \
    "--deliver[Deprecated (use --announce). Fallback-delivers final text to a chat.]" \
    "--no-deliver[Disable runner fallback delivery]" \
    "--webhook[POST the finished payload to a webhook URL]" \
    "--channel[Delivery channel (last|<channel-id>)]" \
    "--to[Delivery destination (E.164, Telegram chatId, or Discord channel/user)]" \
    "--thread-id[Telegram forum topic thread id]" \
    "--account[Channel account id for delivery (multi-account setups)]" \
    "--best-effort-deliver[Do not fail the job if delivery fails]" \
    "--json[Output JSON]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_cron_rm() {
  _arguments -C \
    "--json[Output JSON]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_cron_enable() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_cron_disable() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_cron_get() {
  _arguments -C \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_cron_show() {
  _arguments -C \
    "--json[Output JSON]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_cron_runs() {
  _arguments -C \
    "--id[Job id]" \
    "--run-id[Filter by cron run id]" \
    "--limit[Max entries (default 50)]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_cron_run() {
  _arguments -C \
    "--due[Run only when due (default behavior in older versions)]" \
    "--wait[Wait for the queued run to finish]" \
    "--wait-timeout[Maximum time to wait for --wait]" \
    "--poll-interval[Polling interval for --wait]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_cron_edit() {
  _arguments -C \
    "--name[Set name]" \
    "--description[Set description]" \
    "--enable[Enable job]" \
    "--disable[Disable job]" \
    "--delete-after-run[Delete one-shot job after it succeeds]" \
    "--keep-after-run[Keep one-shot job after it succeeds]" \
    "--session[Session target (main|isolated)]" \
    "--agent[Set agent id]" \
    "--clear-agent[Unset agent and use default]" \
    "--session-key[Set session key for job routing]" \
    "--clear-session-key[Unset session key]" \
    "--wake[Wake mode (now|next-heartbeat)]" \
    "--at[Set one-shot time (ISO) or duration like 20m]" \
    "--every[Set interval duration like 10m]" \
    "--cron[Set cron expression]" \
    "--tz[Timezone for cron expressions (IANA; cron default: Gateway host local timezone)]" \
    "--stagger[Cron stagger window (e.g. 30s, 5m)]" \
    "--exact[Disable cron staggering (set stagger to 0)]" \
    "--system-event[Set systemEvent payload]" \
    "--message[Set agentTurn payload message]" \
    "--command[Set command payload run as sh -lc <shell> on the Gateway]" \
    "--command-argv[Set command payload argv as JSON array of strings]" \
    "--command-cwd[Set command payload working directory]" \
    "--command-env[Set command payload environment overrides (repeatable)]" \
    "--command-input[Set command payload stdin]" \
    "--thinking[Thinking level for agent jobs (off|minimal|low|medium|high|xhigh)]" \
    "--model[Model override for agent jobs]" \
    "--timeout-seconds[Timeout seconds for agent or command jobs]" \
    "--no-output-timeout-seconds[No-output timeout seconds for command jobs]" \
    "--output-max-bytes[Maximum captured stdout/stderr bytes for command jobs]" \
    "--light-context[Enable lightweight bootstrap context for agent jobs]" \
    "--no-light-context[Disable lightweight bootstrap context for agent jobs]" \
    "--tools[Tool allow-list (e.g. exec,read,write or exec read write)]" \
    "--clear-tools[Remove tool allow-list (use all tools)]" \
    "--announce[Fallback-deliver final text to a chat]" \
    "--deliver[Deprecated (use --announce). Fallback-delivers final text to a chat.]" \
    "--no-deliver[Disable runner fallback delivery]" \
    "--webhook[POST the finished payload to a webhook URL]" \
    "--channel[Delivery channel (last|<channel-id>)]" \
    "--to[Delivery destination (E.164, Telegram chatId, or Discord channel/user)]" \
    "--thread-id[Telegram forum topic thread id]" \
    "--account[Channel account id for delivery (multi-account setups)]" \
    "--best-effort-deliver[Do not fail job if delivery fails (also implies --announce when used alone)]" \
    "--no-best-effort-deliver[Fail job when delivery fails]" \
    "--failure-alert[Enable failure alerts for this job]" \
    "--no-failure-alert[Disable failure alerts for this job]" \
    "--failure-alert-after[Alert after N consecutive job errors]" \
    "--failure-alert-channel[Failure alert channel (last|<channel-id>)]" \
    "--failure-alert-to[Failure alert destination]" \
    "--failure-alert-cooldown[Minimum time between alerts (e.g. 1h, 30m)]" \
    "--failure-alert-include-skipped[Count consecutive skipped runs toward alerts]" \
    "--failure-alert-exclude-skipped[Alert only on execution errors]" \
    "--failure-alert-mode[Failure alert delivery mode (announce or webhook)]" \
    "--failure-alert-account-id[Account ID for failure alert channel (multi-account setups)]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_cron() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'status[Show cron scheduler status]' 'list[List cron jobs]' 'add[Add a cron job]' 'rm[Remove a cron job]' 'enable[Enable a cron job]' 'disable[Disable a cron job]' 'get[Get a cron job as JSON]' 'show[Show a cron job]' 'runs[Show cron run history (JSONL-backed)]' 'run[Run a cron job now (debug)]' 'edit[Edit a cron job (patch fields)]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (status) _openclaw_cron_status ;;
        (list) _openclaw_cron_list ;;
        (add) _openclaw_cron_add ;;
        (rm) _openclaw_cron_rm ;;
        (enable) _openclaw_cron_enable ;;
        (disable) _openclaw_cron_disable ;;
        (get) _openclaw_cron_get ;;
        (show) _openclaw_cron_show ;;
        (runs) _openclaw_cron_runs ;;
        (run) _openclaw_cron_run ;;
        (edit) _openclaw_cron_edit ;;
      esac
      ;;
  esac
}

_openclaw_dns_setup() {
  _arguments -C \
    "--domain[Wide-area discovery domain (e.g. openclaw.internal)]" \
    "--apply[Install/update CoreDNS config and (re)start the service (requires sudo)]"
}

_openclaw_dns() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'setup[Set up CoreDNS to serve your discovery domain for unicast DNS-SD (Wide-Area Bonjour)]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (setup) _openclaw_dns_setup ;;
      esac
      ;;
  esac
}

_openclaw_docs() {
  _arguments -C \
    
}

_openclaw_proxy_start() {
  _arguments -C \
    "--host[Bind host]" \
    "--port[Bind port]"
}

_openclaw_proxy_run() {
  _arguments -C \
    "--host[Bind host]" \
    "--port[Bind port]"
}

_openclaw_proxy_validate() {
  _arguments -C \
    "--json[Print machine-readable JSON]" \
    "--proxy-url[Proxy URL to validate instead of config/env]" \
    "--proxy-ca-file[CA bundle file for verifying an HTTPS proxy endpoint]" \
    "--allowed-url[Destination expected to succeed through the proxy]" \
    "--denied-url[Destination expected to be blocked by the proxy]" \
    "--apns-reachable[Also verify sandbox APNs HTTP/2 is reachable through the proxy]" \
    "--apns-authority[APNs authority to probe with --apns-reachable]" \
    "--timeout-ms[Per-request timeout in milliseconds]"
}

_openclaw_proxy_coverage() {
  _arguments -C \
    
}

_openclaw_proxy_sessions() {
  _arguments -C \
    "--limit[Maximum sessions to show]"
}

_openclaw_proxy_query() {
  _arguments -C \
    "--preset[Query preset: double-sends, retry-storms, cache-busting, ws-duplicate-frames, missing-ack, error-bursts]" \
    "--session[Restrict to a capture session id]"
}

_openclaw_proxy_blob() {
  _arguments -C \
    "--id[Blob id]"
}

_openclaw_proxy_purge() {
  _arguments -C \
    
}

_openclaw_proxy() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'start[Start the local explicit debug proxy]' 'run[Run a child command with OpenClaw debug proxy capture enabled]' 'validate[Validate the operator-managed network proxy]' 'coverage[Report current debug proxy transport coverage and remaining gaps]' 'sessions[List recent capture sessions]' 'query[Run a built-in query preset against captured traffic]' 'blob[Read a captured payload blob by id]' 'purge[Delete all captured traffic metadata and blobs]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (start) _openclaw_proxy_start ;;
        (run) _openclaw_proxy_run ;;
        (validate) _openclaw_proxy_validate ;;
        (coverage) _openclaw_proxy_coverage ;;
        (sessions) _openclaw_proxy_sessions ;;
        (query) _openclaw_proxy_query ;;
        (blob) _openclaw_proxy_blob ;;
        (purge) _openclaw_proxy_purge ;;
      esac
      ;;
  esac
}

_openclaw_hooks_list() {
  _arguments -C \
    "--eligible[Show only eligible hooks]" \
    "--json[Output as JSON]" \
    "(--verbose -v)"{--verbose,-v}"[Show more details including missing requirements]"
}

_openclaw_hooks_info() {
  _arguments -C \
    "--json[Output as JSON]"
}

_openclaw_hooks_check() {
  _arguments -C \
    "--json[Output as JSON]"
}

_openclaw_hooks_enable() {
  _arguments -C \
    
}

_openclaw_hooks_disable() {
  _arguments -C \
    
}

_openclaw_hooks_relay() {
  _arguments -C \
    "--provider[Native harness provider]" \
    "--relay-id[Native hook relay id]" \
    "--generation[Native hook relay registration generation]" \
    "--event[Native hook event]" \
    "--pre-tool-use-unavailable[PreToolUse fallback mode when the originating relay is unavailable]" \
    "--timeout[Gateway timeout in ms]"
}

_openclaw_hooks_install() {
  _arguments -C \
    "(--link -l)"{--link,-l}"[Link a local path instead of copying]" \
    "--pin[Record npm installs as exact resolved <name>@<version>]"
}

_openclaw_hooks_update() {
  _arguments -C \
    "--all[Update all tracked hooks]" \
    "--dry-run[Show what would change without writing]"
}

_openclaw_hooks() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List all hooks]' 'info[Show detailed information about a hook]' 'check[Check hooks eligibility status]' 'enable[Enable a hook]' 'disable[Disable a hook]' 'relay[Internal native harness hook relay]' 'install[Deprecated: install a hook pack via `openclaw plugins install`]' 'update[Deprecated: update hook packs via `openclaw plugins update`]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_hooks_list ;;
        (info) _openclaw_hooks_info ;;
        (check) _openclaw_hooks_check ;;
        (enable) _openclaw_hooks_enable ;;
        (disable) _openclaw_hooks_disable ;;
        (relay) _openclaw_hooks_relay ;;
        (install) _openclaw_hooks_install ;;
        (update) _openclaw_hooks_update ;;
      esac
      ;;
  esac
}

_openclaw_webhooks_gmail_setup() {
  _arguments -C \
    "--account[Gmail account to watch]" \
    "--project[GCP project id (OAuth client owner)]" \
    "--topic[Pub/Sub topic name]" \
    "--subscription[Pub/Sub subscription name]" \
    "--label[Gmail label to watch]" \
    "--hook-url[OpenClaw hook URL]" \
    "--hook-token[OpenClaw hook token]" \
    "--push-token[Push token for gog watch serve]" \
    "--bind[gog watch serve bind host]" \
    "--port[gog watch serve port]" \
    "--path[gog watch serve path]" \
    "--include-body[Include email body snippets]" \
    "--max-bytes[Max bytes for body snippets]" \
    "--renew-minutes[Renew watch every N minutes]" \
    "--tailscale[Expose push endpoint via tailscale (funnel|serve|off)]" \
    "--tailscale-path[Path for tailscale serve/funnel]" \
    "--tailscale-target[Tailscale serve/funnel target (port, host:port, or URL)]" \
    "--push-endpoint[Explicit Pub/Sub push endpoint]" \
    "--json[Output JSON summary]"
}

_openclaw_webhooks_gmail_run() {
  _arguments -C \
    "--account[Gmail account to watch]" \
    "--topic[Pub/Sub topic path (projects/.../topics/..)]" \
    "--subscription[Pub/Sub subscription name]" \
    "--label[Gmail label to watch]" \
    "--hook-url[OpenClaw hook URL]" \
    "--hook-token[OpenClaw hook token]" \
    "--push-token[Push token for gog watch serve]" \
    "--bind[gog watch serve bind host]" \
    "--port[gog watch serve port]" \
    "--path[gog watch serve path]" \
    "--include-body[Include email body snippets]" \
    "--max-bytes[Max bytes for body snippets]" \
    "--renew-minutes[Renew watch every N minutes]" \
    "--tailscale[Expose push endpoint via tailscale (funnel|serve|off)]" \
    "--tailscale-path[Path for tailscale serve/funnel]" \
    "--tailscale-target[Tailscale serve/funnel target (port, host:port, or URL)]"
}

_openclaw_webhooks_gmail() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'setup[Configure Gmail watch + Pub/Sub + OpenClaw hooks]' 'run[Run gog watch serve + auto-renew loop]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (setup) _openclaw_webhooks_gmail_setup ;;
        (run) _openclaw_webhooks_gmail_run ;;
      esac
      ;;
  esac
}

_openclaw_webhooks() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'gmail[Gmail Pub/Sub hooks (via gogcli)]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (gmail) _openclaw_webhooks_gmail ;;
      esac
      ;;
  esac
}

_openclaw_qr() {
  _arguments -C \
    "--remote[Use gateway.remote.url and gateway.remote token/password (ignores device-pair publicUrl)]" \
    "--url[Override gateway URL used in the setup payload]" \
    "--public-url[Override gateway public URL used in the setup payload]" \
    "--token[Override gateway token for setup payload]" \
    "--password[Override gateway password for setup payload]" \
    "--setup-code-only[Print only the setup code]" \
    "--no-ascii[Skip ASCII QR rendering]" \
    "--json[Output JSON]"
}

_openclaw_clawbot_qr() {
  _arguments -C \
    "--remote[Use gateway.remote.url and gateway.remote token/password (ignores device-pair publicUrl)]" \
    "--url[Override gateway URL used in the setup payload]" \
    "--public-url[Override gateway public URL used in the setup payload]" \
    "--token[Override gateway token for setup payload]" \
    "--password[Override gateway password for setup payload]" \
    "--setup-code-only[Print only the setup code]" \
    "--no-ascii[Skip ASCII QR rendering]" \
    "--json[Output JSON]"
}

_openclaw_clawbot() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'qr[Generate a mobile pairing QR code and setup code]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (qr) _openclaw_clawbot_qr ;;
      esac
      ;;
  esac
}

_openclaw_pairing_list() {
  _arguments -C \
    "--channel[Channel ()]" \
    "--account[Account id (for multi-account channels)]" \
    "--json[Print JSON]"
}

_openclaw_pairing_approve() {
  _arguments -C \
    "--channel[Channel ()]" \
    "--account[Account id (for multi-account channels)]" \
    "--notify[Notify the requester on the same channel]"
}

_openclaw_pairing() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List pending pairing requests]' 'approve[Approve a pairing code and allow that sender]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_pairing_list ;;
        (approve) _openclaw_pairing_approve ;;
      esac
      ;;
  esac
}

_openclaw_plugins_list() {
  _arguments -C \
    "--json[Print JSON]" \
    "--enabled[Only show enabled plugins]" \
    "--verbose[Show detailed entries]"
}

_openclaw_plugins_search() {
  _arguments -C \
    "--limit[Max results]" \
    "--json[Print JSON]"
}

_openclaw_plugins_inspect() {
  _arguments -C \
    "--all[Inspect all plugins]" \
    "--runtime[Load plugin runtime for hooks/tools/diagnostics]" \
    "--json[Print JSON]"
}

_openclaw_plugins_enable() {
  _arguments -C \
    
}

_openclaw_plugins_disable() {
  _arguments -C \
    
}

_openclaw_plugins_uninstall() {
  _arguments -C \
    "--keep-files[Keep installed files on disk]" \
    "--keep-config[Deprecated alias for --keep-files]" \
    "--force[Skip confirmation prompt]" \
    "--dry-run[Show what would be removed without making changes]"
}

_openclaw_plugins_install() {
  _arguments -C \
    "(--link -l)"{--link,-l}"[Link a local path instead of copying]" \
    "--force[Overwrite an existing installed plugin or hook pack]" \
    "--pin[Record npm installs as exact resolved <name>@<version>]" \
    "--dangerously-force-unsafe-install[Deprecated no-op; install policy and plugin hooks may still block]" \
    "--marketplace[Install a Claude marketplace plugin from a local repo/path or git/GitHub source]"
}

_openclaw_plugins_update() {
  _arguments -C \
    "--all[Update all tracked plugins and hook packs]" \
    "--dry-run[Show what would change without writing]" \
    "--dangerously-force-unsafe-install[Deprecated no-op; install policy and plugin hooks may still block]"
}

_openclaw_plugins_registry() {
  _arguments -C \
    "--json[Print JSON]" \
    "--refresh[Rebuild the persisted registry from current plugin manifests]"
}

_openclaw_plugins_doctor() {
  _arguments -C \
    
}

_openclaw_plugins_build() {
  _arguments -C \
    "--root[Plugin package root]" \
    "--entry[Plugin entry module relative to --root]" \
    "--check[Fail if generated metadata is out of date]"
}

_openclaw_plugins_validate() {
  _arguments -C \
    "--root[Plugin package root]" \
    "--entry[Plugin entry module relative to --root]"
}

_openclaw_plugins_init() {
  _arguments -C \
    "--directory[Output directory]" \
    "--name[Display name]" \
    "--force[Overwrite an existing output directory]"
}

_openclaw_plugins_marketplace_list() {
  _arguments -C \
    "--json[Print JSON]"
}

_openclaw_plugins_marketplace() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List plugins published by a marketplace source]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_plugins_marketplace_list ;;
      esac
      ;;
  esac
}

_openclaw_plugins() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List discovered plugins]' 'search[Search ClawHub plugin packages]' 'inspect[Inspect plugin details]' 'enable[Enable a plugin in config]' 'disable[Disable a plugin in config]' 'uninstall[Uninstall a plugin]' 'install[Install a plugin or hook pack (path, archive, npm spec, git repo, clawhub:package, or marketplace entry)]' 'update[Update installed plugins and tracked hook packs]' 'registry[Inspect or rebuild the persisted plugin registry]' 'doctor[Report plugin load issues]' 'build[Generate simple tool plugin metadata]' 'validate[Validate simple tool plugin metadata]' 'init[Create a simple tool plugin project]' 'marketplace[Inspect Claude-compatible plugin marketplaces]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_plugins_list ;;
        (search) _openclaw_plugins_search ;;
        (inspect) _openclaw_plugins_inspect ;;
        (enable) _openclaw_plugins_enable ;;
        (disable) _openclaw_plugins_disable ;;
        (uninstall) _openclaw_plugins_uninstall ;;
        (install) _openclaw_plugins_install ;;
        (update) _openclaw_plugins_update ;;
        (registry) _openclaw_plugins_registry ;;
        (doctor) _openclaw_plugins_doctor ;;
        (build) _openclaw_plugins_build ;;
        (validate) _openclaw_plugins_validate ;;
        (init) _openclaw_plugins_init ;;
        (marketplace) _openclaw_plugins_marketplace ;;
      esac
      ;;
  esac
}

_openclaw_channels_list() {
  _arguments -C \
    "--all[Include bundled and installable catalog channels]" \
    "--json[Output JSON]"
}

_openclaw_channels_status() {
  _arguments -C \
    "--channel[Only show one channel (all|telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch)]" \
    "--probe[Probe channel credentials]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_channels_capabilities() {
  _arguments -C \
    "--channel[Channel (all|telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch)]" \
    "--account[Account id (only with --channel)]" \
    "--target[Channel target for permission audit (Discord channel:<id>)]" \
    "--timeout[Timeout in ms]" \
    "--json[Output JSON]"
}

_openclaw_channels_resolve() {
  _arguments -C \
    "--channel[Channel (telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch)]" \
    "--account[Account id (accountId)]" \
    "--kind[Target kind (auto|user|group)]" \
    "--json[Output JSON]"
}

_openclaw_channels_logs() {
  _arguments -C \
    "--channel[Channel (all|telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch)]" \
    "--lines[Number of lines (default: 200)]" \
    "--json[Output JSON]"
}

_openclaw_channels_add() {
  _arguments -C \
    "--channel[Channel (telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch)]" \
    "--account[Account id (default when omitted)]" \
    "--name[Display name for this account]" \
    "--token[Channel token or credential payload]" \
    "--token-file[Read channel token or credential payload from file]" \
    "--secret[Channel shared secret]" \
    "--secret-file[Read channel shared secret from file]" \
    "--bot-token[Bot token]" \
    "--app-token[App token]" \
    "--password[Channel password or login secret]" \
    "--cli-path[Channel CLI path]" \
    "--url[Channel setup URL]" \
    "--base-url[Channel base URL]" \
    "--http-url[Channel HTTP service URL]" \
    "--auth-dir[Channel auth directory override]" \
    "--use-env[Use env-backed credentials when supported]" \
    "--db-path[iMessage database path]" \
    "--service[iMessage service (imessage|sms|auto)]" \
    "--region[iMessage region (for SMS)]" \
    "--signal-number[Signal account number (E.164)]" \
    "--http-host[Signal HTTP daemon host]" \
    "--http-port[Signal HTTP daemon port]"
}

_openclaw_channels_remove() {
  _arguments -C \
    "--channel[Channel (telegram|whatsapp|discord|irc|googlechat|slack|signal|imessage|feishu|nostr|msteams|mattermost|nextcloud-talk|matrix|line|zalo|clickclack|zalouser|sms|synology-chat|tlon|qa-channel|qqbot|twitch)]" \
    "--account[Account id (default when omitted)]" \
    "--delete[Delete config entries (no prompt)]"
}

_openclaw_channels_login() {
  _arguments -C \
    "--channel[Channel alias (auto when only one is configured)]" \
    "--account[Account id (accountId)]" \
    "--verbose[Verbose connection logs]"
}

_openclaw_channels_logout() {
  _arguments -C \
    "--channel[Channel alias (auto when only one is configured)]" \
    "--account[Account id (accountId)]"
}

_openclaw_channels() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List chat channels (configured by default; pass --all for installable catalog)]' 'status[Show gateway channel status (use status --deep for local)]' 'capabilities[Show provider capabilities (intents/scopes + supported features)]' 'resolve[Resolve channel/user names to IDs]' 'logs[Show recent channel logs from the gateway log file]' 'add[Add or update a channel account]' 'remove[Disable or delete a channel account]' 'login[Link a channel account (if supported)]' 'logout[Log out of a channel session (if supported)]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_channels_list ;;
        (status) _openclaw_channels_status ;;
        (capabilities) _openclaw_channels_capabilities ;;
        (resolve) _openclaw_channels_resolve ;;
        (logs) _openclaw_channels_logs ;;
        (add) _openclaw_channels_add ;;
        (remove) _openclaw_channels_remove ;;
        (login) _openclaw_channels_login ;;
        (logout) _openclaw_channels_logout ;;
      esac
      ;;
  esac
}

_openclaw_directory_self() {
  _arguments -C \
    "--channel[Channel (auto when only one is configured)]" \
    "--account[Account id (accountId)]" \
    "--json[Output JSON]"
}

_openclaw_directory_peers_list() {
  _arguments -C \
    "--channel[Channel (auto when only one is configured)]" \
    "--account[Account id (accountId)]" \
    "--json[Output JSON]" \
    "--query[Optional search query]" \
    "--limit[Limit results]"
}

_openclaw_directory_peers() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List peers]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_directory_peers_list ;;
      esac
      ;;
  esac
}

_openclaw_directory_groups_list() {
  _arguments -C \
    "--channel[Channel (auto when only one is configured)]" \
    "--account[Account id (accountId)]" \
    "--json[Output JSON]" \
    "--query[Optional search query]" \
    "--limit[Limit results]"
}

_openclaw_directory_groups_members() {
  _arguments -C \
    "--group-id[Group id]" \
    "--channel[Channel (auto when only one is configured)]" \
    "--account[Account id (accountId)]" \
    "--json[Output JSON]" \
    "--limit[Limit results]"
}

_openclaw_directory_groups() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'list[List groups]' 'members[List group members]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_directory_groups_list ;;
        (members) _openclaw_directory_groups_members ;;
      esac
      ;;
  esac
}

_openclaw_directory() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'self[Show the current account user]' 'peers[Peer directory (contacts/users)]' 'groups[Group directory]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (self) _openclaw_directory_self ;;
        (peers) _openclaw_directory_peers ;;
        (groups) _openclaw_directory_groups ;;
      esac
      ;;
  esac
}

_openclaw_security_audit() {
  _arguments -C \
    "--deep[Attempt live Gateway probes and plugin-owned collector checks]" \
    "--auth[Runtime gateway auth mode (\"none\"|\"token\"|\"password\"|\"trusted-proxy\")]" \
    "--token[Use explicit gateway token for deep probe auth]" \
    "--password[Use explicit gateway password for deep probe auth]" \
    "--fix[Apply safe fixes (tighten defaults + chmod state/config)]" \
    "--json[Print JSON]"
}

_openclaw_security() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'audit[Audit config + local state for common security foot-guns]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (audit) _openclaw_security_audit ;;
      esac
      ;;
  esac
}

_openclaw_secrets_reload() {
  _arguments -C \
    "--json[Output JSON]" \
    "--url[Gateway WebSocket URL (defaults to gateway.remote.url when configured)]" \
    "--token[Gateway token (if required)]" \
    "--timeout[Timeout in ms]" \
    "--expect-final[Wait for final response (agent)]"
}

_openclaw_secrets_audit() {
  _arguments -C \
    "--check[Exit non-zero when findings are present]" \
    "--allow-exec[Allow exec SecretRef resolution during audit (may execute provider commands)]" \
    "--json[Output JSON]"
}

_openclaw_secrets_configure() {
  _arguments -C \
    "--apply[Apply changes immediately after preflight]" \
    "--yes[Skip apply confirmation prompt]" \
    "--providers-only[Configure secrets.providers only, skip credential mapping]" \
    "--skip-provider-setup[Skip provider setup and only map credential fields to existing providers]" \
    "--agent[Agent id for auth-profiles targets (default: configured default agent)]" \
    "--allow-exec[Allow exec SecretRef preflight checks (may execute provider commands)]" \
    "--plan-out[Write generated plan JSON to a file]" \
    "--json[Output JSON]"
}

_openclaw_secrets_apply() {
  _arguments -C \
    "--from[Path to plan JSON]" \
    "--dry-run[Validate/preflight only]" \
    "--allow-exec[Allow exec SecretRef checks (may execute provider commands)]" \
    "--json[Output JSON]"
}

_openclaw_secrets() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'reload[Re-resolve secret references and atomically swap runtime snapshot]' 'audit[Audit plaintext secrets, unresolved refs, and precedence drift]' 'configure[Interactive secrets helper (provider setup + SecretRef mapping + preflight)]' 'apply[Apply a previously generated secrets plan]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (reload) _openclaw_secrets_reload ;;
        (audit) _openclaw_secrets_audit ;;
        (configure) _openclaw_secrets_configure ;;
        (apply) _openclaw_secrets_apply ;;
      esac
      ;;
  esac
}

_openclaw_skills_search() {
  _arguments -C \
    "--limit[Max results]" \
    "--json[Output as JSON]"
}

_openclaw_skills_install() {
  _arguments -C \
    "--version[Install a specific version]" \
    "--force[Overwrite an existing workspace skill]" \
    "--force-install[Install a pending GitHub-backed skill before ClawHub scan completes]" \
    "--global[Install into the shared managed skills directory]" \
    "--agent[Target agent workspace (defaults to cwd-inferred, then default agent)]" \
    "--as[Install a git/local skill under this slug]"
}

_openclaw_skills_update() {
  _arguments -C \
    "--all[Update all tracked ClawHub skills]" \
    "--force-install[Install a pending GitHub-backed skill before ClawHub scan completes]" \
    "--global[Update skills in the shared managed skills directory]" \
    "--agent[Target agent workspace (defaults to cwd-inferred, then default agent)]"
}

_openclaw_skills_verify() {
  _arguments -C \
    "--version[Verify a specific version]" \
    "--tag[Verify a dist tag]" \
    "--card[Print the generated Skill Card Markdown]" \
    "--global[Resolve installed skill metadata from the shared managed skills directory]" \
    "--agent[Target agent workspace (defaults to cwd-inferred, then default agent)]"
}

_openclaw_skills_workshop_list() {
  _arguments -C \
    "--json[Output as JSON]"
}

_openclaw_skills_workshop_inspect() {
  _arguments -C \
    "--json[Output as JSON]"
}

_openclaw_skills_workshop_propose_create() {
  _arguments -C \
    "--name[Skill name]" \
    "--description[Skill description]" \
    "--proposal[Path to PROPOSAL.md draft content]" \
    "--proposal-dir[Path to proposal directory with PROPOSAL.md and UTF-8 text support files]" \
    "--goal[Proposal or improvement goal]" \
    "--evidence[Evidence or notes for the proposal]" \
    "--json[Output as JSON]"
}

_openclaw_skills_workshop_propose_update() {
  _arguments -C \
    "--proposal[Path to PROPOSAL.md draft content]" \
    "--proposal-dir[Path to proposal directory with PROPOSAL.md and UTF-8 text support files]" \
    "--description[Concise proposal description]" \
    "--goal[Proposal or improvement goal]" \
    "--evidence[Evidence or notes for the proposal]" \
    "--json[Output as JSON]"
}

_openclaw_skills_workshop_revise() {
  _arguments -C \
    "--proposal[Path to revised PROPOSAL.md draft content]" \
    "--proposal-dir[Path to revised proposal directory with PROPOSAL.md and UTF-8 text support files]" \
    "--description[Replacement proposal description]" \
    "--goal[Replacement research or improvement goal]" \
    "--evidence[Replacement evidence or notes for the proposal]" \
    "--json[Output as JSON]"
}

_openclaw_skills_workshop_apply() {
  _arguments -C \
    "--json[Output as JSON]"
}

_openclaw_skills_workshop_reject() {
  _arguments -C \
    "--reason[Reason for rejection]" \
    "--json[Output as JSON]"
}

_openclaw_skills_workshop_quarantine() {
  _arguments -C \
    "--reason[Reason for quarantine]" \
    "--json[Output as JSON]"
}

_openclaw_skills_workshop() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--agent[Target agent workspace (defaults to cwd-inferred, then default agent)]" \
    "1: :_values 'command' 'list[List pending and completed skill proposals]' 'inspect[Inspect a skill proposal]' 'propose-create[Create a pending proposal for a new workspace skill]' 'propose-update[Create a pending proposal for an existing workspace skill]' 'revise[Revise a pending skill proposal]' 'apply[Apply a pending skill proposal]' 'reject[Reject a pending skill proposal]' 'quarantine[Quarantine a skill proposal]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (list) _openclaw_skills_workshop_list ;;
        (inspect) _openclaw_skills_workshop_inspect ;;
        (propose-create) _openclaw_skills_workshop_propose_create ;;
        (propose-update) _openclaw_skills_workshop_propose_update ;;
        (revise) _openclaw_skills_workshop_revise ;;
        (apply) _openclaw_skills_workshop_apply ;;
        (reject) _openclaw_skills_workshop_reject ;;
        (quarantine) _openclaw_skills_workshop_quarantine ;;
      esac
      ;;
  esac
}

_openclaw_skills_list() {
  _arguments -C \
    "--json[Output as JSON]" \
    "--eligible[Show only eligible (ready to use) skills]" \
    "(--verbose -v)"{--verbose,-v}"[Show more details including missing requirements]" \
    "--agent[Target agent workspace (defaults to cwd-inferred, then default agent)]"
}

_openclaw_skills_info() {
  _arguments -C \
    "--json[Output as JSON]" \
    "--agent[Target agent workspace (defaults to cwd-inferred, then default agent)]"
}

_openclaw_skills_check() {
  _arguments -C \
    "--agent[Target agent workspace (defaults to cwd-inferred, then default agent)]" \
    "--json[Output as JSON]"
}

_openclaw_skills() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--agent[Target agent workspace (defaults to cwd-inferred, then default agent)]" \
    "1: :_values 'command' 'search[Search ClawHub skills]' 'install[Install a skill from ClawHub, git, or a local directory]' 'update[Update ClawHub-installed skills in the active or shared managed directory]' 'verify[Verify a ClawHub skill with ClawHub]' 'workshop[Manage pending skill proposals]' 'list[List all available skills]' 'info[Show detailed information about a skill]' 'check[Check which skills are ready, visible, or missing requirements]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (search) _openclaw_skills_search ;;
        (install) _openclaw_skills_install ;;
        (update) _openclaw_skills_update ;;
        (verify) _openclaw_skills_verify ;;
        (workshop) _openclaw_skills_workshop ;;
        (list) _openclaw_skills_list ;;
        (info) _openclaw_skills_info ;;
        (check) _openclaw_skills_check ;;
      esac
      ;;
  esac
}

_openclaw_update_finalize() {
  _arguments -C \
    "--json[Output result as JSON]" \
    "--channel[Persist update channel for finalization]" \
    "--timeout[Timeout for update finalization steps in seconds (default: 1800)]" \
    "--yes[Skip confirmation prompts (non-interactive)]" \
    "--no-restart[Accepted for update command parity; finalization never restarts]"
}

_openclaw_update_wizard() {
  _arguments -C \
    "--timeout[Timeout for each update step in seconds (default: 1800)]"
}

_openclaw_update_status() {
  _arguments -C \
    "--json[Output result as JSON]" \
    "--timeout[Timeout for update checks in seconds (default: 3)]"
}

_openclaw_update() {
  local -a commands
  local -a options
  
  _arguments -C \
    "--json[Output result as JSON]" \
    "--no-restart[Skip restarting the gateway service after a successful update]" \
    "--dry-run[Preview update actions without making changes]" \
    "--channel[Persist update channel (git + npm)]" \
    "--tag[Override the package target for this update (dist-tag, version, or package spec)]" \
    "--timeout[Timeout for each update step in seconds (default: 1800)]" \
    "--yes[Skip confirmation prompts (non-interactive)]" \
    "1: :_values 'command' 'finalize[Run OpenClaw update finalization after an external core runtime change]' 'wizard[Interactive update wizard]' 'status[Show update channel and version status]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (finalize) _openclaw_update_finalize ;;
        (wizard) _openclaw_update_wizard ;;
        (status) _openclaw_update_status ;;
      esac
      ;;
  esac
}

_openclaw_memory_status() {
  _arguments -C \
    "--agent[Agent id (default: default agent)]" \
    "--json[Print JSON]" \
    "--deep[Probe embedding provider availability]" \
    "--index[Reindex if dirty (implies --deep)]" \
    "--fix[Repair stale recall locks and normalize promotion metadata]" \
    "--verbose[Verbose logging]"
}

_openclaw_memory_index() {
  _arguments -C \
    "--agent[Agent id (default: default agent)]" \
    "--force[Force full reindex]" \
    "--verbose[Verbose logging]"
}

_openclaw_memory_search() {
  _arguments -C \
    "--query[Search query (alternative to positional argument)]" \
    "--agent[Agent id (default: default agent)]" \
    "--max-results[Max results]" \
    "--min-score[Minimum score]" \
    "--json[Print JSON]"
}

_openclaw_memory_promote() {
  _arguments -C \
    "--agent[Agent id (default: default agent)]" \
    "--limit[Max candidates]" \
    "--min-score[Minimum weighted score (default: 0.75)]" \
    "--min-recall-count[Minimum recall count (default: 3)]" \
    "--min-unique-queries[Minimum distinct query count (default: 2)]" \
    "--apply[Append selected candidates to MEMORY.md]" \
    "--include-promoted[Include already promoted candidates]" \
    "--json[Print JSON]"
}

_openclaw_memory_promote_explain() {
  _arguments -C \
    "--agent[Agent id (default: default agent)]" \
    "--include-promoted[Include already promoted candidates]" \
    "--json[Print JSON]"
}

_openclaw_memory_rem_harness() {
  _arguments -C \
    "--agent[Agent id (default: default agent)]" \
    "--path[Seed the harness from historical daily memory file(s)]" \
    "--grounded[Also render a grounded day-level REM preview]" \
    "--include-promoted[Include already promoted deep candidates]" \
    "--json[Print JSON]"
}

_openclaw_memory_rem_backfill() {
  _arguments -C \
    "--agent[Agent id (default: default agent)]" \
    "--path[Historical daily memory file(s) or directory]" \
    "--rollback[Remove previously written grounded REM backfill entries]" \
    "--stage-short-term[Also seed grounded durable candidates into the short-term promotion store]" \
    "--rollback-short-term[Remove previously seeded grounded short-term candidates]" \
    "--json[Print JSON]"
}

_openclaw_memory() {
  local -a commands
  local -a options
  
  _arguments -C \
     \
    "1: :_values 'command' 'status[Show memory search index status]' 'index[Reindex memory files]' 'search[Search memory files]' 'promote[Rank short-term recalls and optionally append top entries to MEMORY.md]' 'promote-explain[Explain a specific promotion candidate and its score breakdown]' 'rem-harness[Preview REM reflections, candidate truths, and deep promotions without writing]' 'rem-backfill[Write grounded historical REM summaries into DREAMS.md for UI review]'" \
    "*::arg:->args"

  case $state in
    (args)
      case $line[1] in
        (status) _openclaw_memory_status ;;
        (index) _openclaw_memory_index ;;
        (search) _openclaw_memory_search ;;
        (promote) _openclaw_memory_promote ;;
        (promote-explain) _openclaw_memory_promote_explain ;;
        (rem-harness) _openclaw_memory_rem_harness ;;
        (rem-backfill) _openclaw_memory_rem_backfill ;;
      esac
      ;;
  esac
}


_openclaw_register_completion() {
  if (( ! $+functions[compdef] )); then
    return 0
  fi

  compdef _openclaw_root_completion openclaw
  precmd_functions=(${precmd_functions:#_openclaw_register_completion})
  unfunction _openclaw_register_completion 2>/dev/null
}

_openclaw_register_completion
if (( ! $+functions[compdef] )); then
  typeset -ga precmd_functions
  if [[ -z "${precmd_functions[(r)_openclaw_register_completion]}" ]]; then
    precmd_functions+=(_openclaw_register_completion)
  fi
fi
