# Vision 401 Error Debugging Session (2026-06-25)

## Symptom
User sent image via Feishu, agent attempted vision_analyze, got:
```
Error code: 401 - {'error': {'code': 'invalid_api_key', 'message': 'invalid access token or token expired'}}
```

User said "又遇到了" (encountered again), indicating recurring issue.

## Environment
- Local macOS (M2) running Hermes Agent
- Remote wh002 server also running Hermes Gateway
- Both using DashScope (阿里云百炼) as provider
- Main model: `alibaba-coding-plan/qwen3.7-plus`
- Provider: `aliyun-bailian` with standard `sk-*` key

## Debugging Steps Taken

### 1. Checked API Key Validity
```bash
# On wh002
curl -s "https://dashscope.aliyuncs.com/compatible-mode/v1/models" \
  -H "Authorization: Bearer ***
# Result: HTTP 200, returned full model list
# Conclusion: API key is valid
```

### 2. Tested Text Completion
```bash
curl -s "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions" \
  -H "Authorization: Bearer *** \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3.7-plus","messages":[{"role":"user","content":"hello"}]}'
# Result: Success, returned valid response
# Conclusion: Text API works fine
```

### 3. Checked Vision Configuration
```bash
grep -A 10 'auxiliary:' ~/.hermes/config.yaml | grep -A 5 'vision:'
# Result:
#   vision:
#     provider: auto    <-- PROBLEM
#     model: ''
#     base_url: ''
#     api_key: ''
```

### 4. Identified Root Cause
`provider: auto` cannot resolve DashScope provider because:
- No standard environment variable (OPENAI_API_KEY, ANTHROPIC_API_KEY, etc.)
- DashScope uses custom provider name `aliyun-bailian`
- Auto resolution falls back to unavailable default, causing 401

### 5. Applied Fix
```bash
hermes config set auxiliary.vision.provider aliyun-bailian
hermes config set auxiliary.vision.model qwen3.7-plus
```

### 6. Verified Fix
```bash
# Tested vision_analyze with local image
# Result: Success, returned detailed image analysis
```

## Key Learnings

1. **Auto provider resolution fails with DashScope**: The `auto` setting only works with standard providers (OpenAI, Anthropic, etc.) that have well-known env vars. Custom providers like DashScope need explicit configuration.

2. **Auxiliary tools inherit from main config ONLY if explicitly configured**: Setting `provider: aliyun-bailian` in the main `model:` section does NOT automatically apply to auxiliary tools.

3. **Vision model must support image input**: Not all models support vision. `qwen3.7-plus` does, `qwen3.7-max` does not.

4. **Image path issues are separate from API issues**: In this session, also discovered that local macOS image paths don't exist on remote wh002 server. But the 401 error was the primary blocker.

## Prevention

Always configure auxiliary tools explicitly when using custom providers:

```yaml
auxiliary:
  vision:
    provider: aliyun-bailian  # Explicit, not 'auto'
    model: qwen3.7-plus
  compression:
    provider: aliyun-bailian
    model: qwen3.7-plus
  # ... etc
```
