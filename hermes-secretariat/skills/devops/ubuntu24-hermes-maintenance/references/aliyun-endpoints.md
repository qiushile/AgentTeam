# Aliyun LLM Endpoints Reference

## Two Distinct Endpoints

### coding-aliyun (Coding Plan)
- **Base URL**: `https://coding.dashscope.aliyuncs.com/v1`
- **Key prefix**: `sk-sp-*`
- **Env var**: `ALIYUN_CODING_API_KEY`
- **Models**: qwen3.7-plus, qwen3.6-plus
- **Context**: 1M tokens (coding plan)

### dashscope-bailian (Bailian)
- **Base URL**: `https://dashscope.aliyuncs.com/compatible-mode/v1`
- **Key prefix**: `sk-*` (regular, non-sp)
- **Env var**: `ALIYUN_DASHSCOPE_API_KEY`
- **Models**: qwen3.7-max, qwen-plus, etc.
- **Context**: varies by model

## Model Assignment (User-Specified)

| Tool | Default Model | Fallback Model |
|------|--------------|----------------|
| **Hermes Agent** | coding-aliyun/qwen3.7-plus | dashscope-bailian/qwen3.7-max |
| **OpenCode** | dashscope-bailian/qwen3.7-max | coding-aliyun/qwen3.7-plus |

## Key Rules

1. Keys are **NOT interchangeable** between endpoints
2. `sk-sp-*` keys ONLY work on `coding.dashscope.aliyuncs.com`
3. Regular `sk-*` keys ONLY work on `dashscope.aliyuncs.com/compatible-mode`
4. Both keys must be present in `.env` for full fallback support

## Quick Diagnostic

```bash
# Test coding endpoint
curl -s -w "\nHTTP:%{http_code}" \
  https://coding.dashscope.aliyuncs.com/v1/chat/completions \
  -H "Authorization: Bearer $ALIYUN_CODING_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3.7-plus","messages":[{"role":"user","content":"hi"}],"max_tokens":10}'

# Test bailian endpoint
curl -s -w "\nHTTP:%{http_code}" \
  https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions \
  -H "Authorization: Bearer $ALIYUN_DASHSCOPE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3.7-max","messages":[{"role":"user","content":"hi"}],"max_tokens":10}'
```

Expected: HTTP:200 with valid JSON response. HTTP:401 means wrong key for that endpoint.
