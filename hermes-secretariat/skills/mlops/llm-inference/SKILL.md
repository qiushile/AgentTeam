---
name: llm-inference
description: "LLM inference: llama.cpp (local GGUF), vLLM (high-throughput serving), Outlines (structured output), OBLITERATUS (refusal ablation)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [LLM, inference, serving, GGUF, vLLM, structured-output, GGUF]
---

# LLM Inference Suite

Unified skill for running and serving LLMs. Four tools: llama.cpp (local), vLLM (serving), Outlines (structured output), OBLITERATUS (refusal ablation).

---

## Section A: llama.cpp (Local GGUF Inference)

Run GGUF-quantized models locally. Best for offline inference, edge deployment, and model discovery via HuggingFace Hub.

**Key features**:
- GGUF format support (Q4_K_M, Q5_K_M, Q8_0, etc.)
- CPU and GPU (Metal, CUDA, Vulkan) inference
- Model discovery via HuggingFace Hub
- Server mode with OpenAI-compatible API

**Typical workflow**:
1. Discover model: `huggingface-cli download org/model --include "*.gguf"`
2. Run inference: `llama-cli -m model.gguf -p "prompt" -n 256`
3. Server mode: `llama-server -m model.gguf --host 0.0.0.0 --port 8080`

---

## Section B: vLLM (High-Throughput Serving)

High-throughput LLM serving with PagedAttention, continuous batching, and OpenAI-compatible API.

**Best for**: Production serving, high throughput, multi-model support, quantization (GPTQ, AWQ, FP8).

**Key features**:
- PagedAttention for efficient memory management
- Continuous batching for high throughput
- OpenAI-compatible API endpoint
- Support for GPTQ, AWQ, FP8 quantization
- Multi-GPU tensor parallelism

**Quick start**:
```bash
pip install vllm
python -m vllm.entrypoints.openai.api_server --model meta-llama/Llama-3-8B
curl http://localhost:8000/v1/chat/completions -d '{"model": "meta-llama/Llama-3-8B", "messages": [{"role": "user", "content": "Hello"}]}'
```

---

## Section C: Outlines (Structured Output)

Guarantee valid JSON/XML/code structure during LLM generation using regex-based constrained decoding.

**Best for**: When you need the LLM to output structured data (JSON, XML, specific code patterns) with 100% validity.

**Key features**:
- Regex-based constrained decoding
- Pydantic model support
- Grammar-based generation
- Works with multiple backends (llama.cpp, transformers, etc.)

**Typical use**: Force JSON output, generate valid code templates, extract structured data from text.

---

## Section D: OBLITERATUS (Refusal Ablation)

Abliterate LLM refusals using diff-in-means method. Removes "I cannot", "I'm sorry" patterns from model outputs.

**Best for**: When you need an uncensored model for red-teaming, security research, or removing overly cautious refusal patterns.

**Method**: diff-in-means — computes the difference between refusal and non-refusal activation patterns, then shifts activations during generation.

---

## Shared Pitfalls

1. **Model quantization trade-offs** — Q4 loses some quality; Q8 is near-lossless but 2x larger
2. **GPU memory** — check VRAM requirements before loading models
3. **Context length** — GGUF models may have different context limits than original
4. **API compatibility** — vLLM and llama-server both offer OpenAI-compatible APIs but with different feature support
5. **Structured output overhead** — Outlines adds latency; only use when output validity is critical