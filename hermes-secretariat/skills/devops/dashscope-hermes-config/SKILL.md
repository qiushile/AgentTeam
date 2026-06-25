---
name: dashscope-hermes-config
description: Configure Hermes Agent with Alibaba Cloud DashScope (阿里云百炼) as the LLM provider, including auxiliary tools (vision, compression, etc.)
tags: [dashscope, alibaba, provider, configuration, vision, auxiliary]
---

# DashScope Hermes Configuration

Configure Hermes Agent to use Alibaba Cloud DashScope (阿里云百炼) as the primary LLM provider, with proper setup for auxiliary tools.

## When to Use

- Setting up Hermes with DashScope/Alibaba Cloud models (qwen series)
- Auxiliary tools (vision, compression, etc.) failing with 401 or "invalid_api_key" errors
- Debugging provider resolution issues with DashScope endpoints

## Configuration Structure

### 1. Main Model Configuration

```yaml
model:
  default: qwen3.7-plus
  provider: alibaba-coding-plan  # or aliyun-bailian
  base_url: https://coding.dashscope.aliyuncs.com/v1
```

### 2. Provider Definition

```yaml
providers:
  aliyun-bailian:
    base_url: https://dashscope.aliyuncs.com/compatible-mode/v1
    api_key: sk-***
    model: qwen3.7-max
```

### 3. Critical: Auxiliary Tools Configuration

**⚠️ PITFALL**: `provider: auto` does NOT work with DashScope for auxiliary tools. You MUST explicitly configure each auxiliary tool.

```yaml
auxiliary:
  vision:
    provider: aliyun-bailian  # NOT 'auto'
    model: qwen3.7-plus       # Must be a vision-capable model
    base_url: ''              # Inherits from provider
    api_key: ''               # Inherits from provider
    timeout: 120
    download_timeout: 30
  
  compression:
    provider: aliyun-bailian
    model: qwen3.7-plus
    # ... other settings
  
  # Repeat for other auxiliary tools as needed
```

## Common Symptoms & Fixes

### Symptom 1: Vision Tool Returns 401 "invalid_api_key"

**Root cause**: `auxiliary.vision.provider` is set to `auto`, which cannot resolve the DashScope API key.

**Fix**:
```bash
hermes config set auxiliary.vision.provider aliyun-bailian
hermes config set auxiliary.vision.model qwen3.7-plus
```

**Verification**:
```bash
# Test vision tool with a local image
# Should succeed without 401 error
```

### Symptom 2: Auxiliary Tools Timeout or Fail Silently

**Root cause**: Provider resolution failing, tools falling back to unavailable default providers.

**Fix**: Explicitly set `provider` and `model` for each auxiliary tool in `~/.hermes/config.yaml`.

## Debugging Steps

1. **Verify API key works**:
   ```bash
   curl -s "https://dashscope.aliyuncs.com/compatible-mode/v1/models" \
     -H "Authorization: Bearer *** | head -20
   # Should return model list with HTTP 200
   ```

2. **Test text completion**:
   ```bash
   curl -s "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions" \
     -H "Authorization: Bearer *** \
     -H "Content-Type: application/json" \
     -d '{"model":"qwen3.7-plus","messages":[{"role":"user","content":"hi"}]}'
   # Should return valid response
   ```

3. **Check auxiliary config**:
   ```bash
   grep -A 10 'auxiliary:' ~/.hermes/config.yaml | grep -A 5 'vision:'
   # Should show explicit provider, not 'auto'
   ```

## DashScope Endpoints Reference

- **Coding endpoint**: `https://coding.dashscope.aliyuncs.com/v1` — requires `sk-sp-*` keys
- **Standard endpoint**: `https://dashscope.aliyuncs.com/compatible-mode/v1` — requires standard `sk-*` keys
- Keys are NOT interchangeable between endpoints

## Vision-Capable Models

Models that support vision (image input) on DashScope:
- `qwen3.7-plus` ✓
- `qwen-vl-max` ✓
- `qwen-vl-plus` ✓
- `qwen3.7-max` ✗ (text only)

Always verify model supports vision before configuring `auxiliary.vision.model`.
