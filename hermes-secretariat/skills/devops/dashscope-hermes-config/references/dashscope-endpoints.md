# DashScope Endpoints and API Keys

## Two Separate Endpoints

Alibaba Cloud DashScope provides TWO distinct API endpoints with DIFFERENT key requirements:

### 1. Coding Endpoint (编程专用端点)
- **URL**: `https://coding.dashscope.aliyuncs.com/v1`
- **Key format**: `sk-sp-*` (special prefix)
- **Purpose**: Optimized for coding tasks, may have different rate limits
- **Provider name in Hermes**: `alibaba-coding-plan`, `alibaba_coding`, `dashscope-coding`
- **Environment variable**: `DASHSCOPE_API_KEY` or `ALIYUN_CODING_API_KEY`

### 2. Standard Endpoint (标准端点)
- **URL**: `https://dashscope.aliyuncs.com/compatible-mode/v1`
- **Key format**: `sk-*` (standard prefix)
- **Purpose**: General purpose, all models including vision
- **Provider name in Hermes**: `aliyun-bailian`, `dashscope-bailian`
- **Environment variable**: `ALIYUN_DASHSCOPE_API_KEY`

## Critical Rules

1. **Keys are NOT interchangeable**: A `sk-sp-*` key will NOT work on the standard endpoint, and a `sk-*` key will NOT work on the coding endpoint.

2. **Base URL must include full path**: 
   - ❌ Wrong: `https://dashscope.aliyuncs.com`
   - ✅ Correct: `https://dashscope.aliyuncs.com/compatible-mode/v1`

3. **Different models may be available**: Not all models are available on both endpoints. Check model availability on each endpoint.

## Configuration Example

```yaml
# Standard endpoint (recommended for most use cases)
providers:
  aliyun-bailian:
    base_url: https://dashscope.aliyuncs.com/compatible-mode/v1
    api_key: sk-***
    model: qwen3.7-max

# Coding endpoint (for coding-specific tasks)
# Note: alibaba-coding-plan is a built-in plugin, may need config override
model:
  default: qwen3.7-plus
  provider: alibaba-coding-plan
  base_url: https://coding.dashscope.aliyuncs.com/v1
```

## Troubleshooting

### Symptom: 401 "invalid_api_key" on one endpoint but not the other
**Cause**: Using the wrong key type for the endpoint
**Fix**: 
- For `coding.dashscope.aliyuncs.com`: use `sk-sp-*` key
- For `dashscope.aliyuncs.com/compatible-mode`: use `sk-*` key

### Symptom: Model not found
**Cause**: Model not available on the selected endpoint
**Fix**: Check model list on each endpoint:
```bash
curl -s "https://dashscope.aliyuncs.com/compatible-mode/v1/models" \
  -H "Authorization: Bearer *** | grep '"id"'
```

## Environment Variables

Common environment variable names (set in shell or systemd service):

```bash
# For standard endpoint
export ALIYUN_DASHSCOPE_API_KEY=***
export ALIYUN_DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1

# For coding endpoint
export ALIYUN_CODING_API_KEY=***
export ALIYUN_CODING_BASE_URL=https://coding.dashscope.aliyuncs.com/v1

# Generic (may be used by some tools)
export DASHSCOPE_API_KEY=***
```

## Model Capabilities

### Vision-Capable Models (支持图片输入)
- `qwen3.7-plus` ✓
- `qwen-vl-max` ✓
- `qwen-vl-plus` ✓
- `qwen3.5-vl-plus` ✓
- `qwen3.5-vl-flash` ✓

### Text-Only Models (仅文本)
- `qwen3.7-max` ✗
- `qwen3.6-plus` ✗
- `qwen-turbo` ✗
- `qwen-plus` ✗

**Note**: Always verify vision capability before using a model for `auxiliary.vision`.
