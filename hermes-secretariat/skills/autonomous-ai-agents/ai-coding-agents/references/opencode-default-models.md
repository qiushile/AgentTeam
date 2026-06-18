# OpenCode Default Model Selection

OpenCode's default model depends on which provider API key is configured. It checks providers in priority order and uses the first one found.

## Priority Order

| Priority | Provider | Env Var | Default Model |
|----------|----------|---------|---------------|
| 1 | GitHub Copilot | `COPILOT_GITHUB_TOKEN` | GPT-4o |
| 2 | Anthropic | `ANTHROPIC_API_KEY` | Claude 4 Sonnet |
| 3 | OpenAI | `OPENAI_API_KEY` | GPT-4.1 |
| 4 | Google Gemini | `GEMINI_API_KEY` | Gemini 2.5 |
| 5 | Groq | `GROQ_API_KEY` | Qwen QwQ |
| 6 | OpenRouter | `OPENROUTER_API_KEY` | Claude 3.7 Sonnet |
| 7 | xAI | `XAI_API_KEY` | Grok 3 Beta |
| 8 | AWS Bedrock | AWS credentials | (varies) |
| 9 | Azure OpenAI | `AZURE_OPENAI_ENDPOINT` | (varies) |

## Agent-Specific Defaults

OpenCode has 4 internal agents, each can have different defaults:

| Agent | Purpose | Typical Default |
|-------|---------|-----------------|
| `coder` | Main coding tasks | Full model (e.g., Claude 4 Sonnet) |
| `summarizer` | Context compression | Full model |
| `task` | Subtask decomposition | Smaller/cheaper model (e.g., GPT-4.1-mini) |
| `title` | Session title generation | Smallest model (80 token limit) |

## Source

Found in `internal/config/config.go` → `setProviderDefaults()` function. The code checks each provider's API key and sets defaults via `viper.SetDefault("agents.*.model", ...)`.

## Override

Use `--model provider/model` flag to force a specific model regardless of defaults:
```bash
opencode run --model anthropic/claude-sonnet-4 "task"
```

Or configure in `.opencode.json`:
```json
{
  "agents": {
    "coder": { "model": "anthropic/claude-sonnet-4" }
  }
}
```
