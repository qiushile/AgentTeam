---
name: creative-software-control
description: "Control creative software programmatically: ComfyUI (AI image/video generation via REST/WebSocket API) and TouchDesigner (real-time visual programming via MCP)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [comfyui, touchdesigner, creative, automation, image-generation, video-generation, visual-programming, mcp]
    category: creative
---

# Creative Software Control

Programmatic control of creative software tools for image/video generation and real-time visual programming.

## When to Use

- **ComfyUI section**: When generating images/videos with AI models via ComfyUI workflows
- **TouchDesigner section**: When controlling TouchDesigner for real-time visuals, projections, or interactive installations

---

## 1. ComfyUI (AI Image/Video Generation)

### Architecture

ComfyUI uses a node-based workflow system for AI image and video generation. Control it via:
- **comfy-cli**: Official CLI for setup, lifecycle management, and dependency handling
- **REST API**: Direct HTTP endpoints for queue management and image retrieval
- **WebSocket API**: Real-time progress monitoring and execution control

### Setup & Lifecycle

```bash
# Install comfy-cli (recommended)
pip install comfy-cli

# Initialize ComfyUI
comfy install

# Start server
comfy launch

# Check status
comfy status
```

### Workflow Execution

#### REST API Pattern

1. **Queue a workflow**:
   ```bash
   curl -X POST http://127.0.0.1:8188/prompt \
     -H "Content-Type: application/json" \
     -d '{"prompt": {...}, "client_id": "..."}'
   ```

2. **Monitor progress**: Poll `/history` endpoint or use WebSocket

3. **Retrieve results**: Images saved to `output/` directory

#### WebSocket Pattern

Connect to `ws://127.0.0.1:8188/ws?clientId=...` for real-time updates:
- `execution_start`, `execution_success`, `execution_error`
- Progress percentages per node
- Live preview images

### Critical Rules

1. **Workflow JSON must be valid** — ComfyUI rejects malformed workflows silently
2. **Check dependencies before execution** — missing custom nodes cause failures
3. **Use client_id for tracking** — enables progress monitoring and result retrieval
4. **Handle async execution** — workflows run in background, poll for completion
5. **Validate output paths** — images land in `output/` with generated filenames

### Common Pitfalls

- **Missing custom nodes**: Workflow references nodes not installed → execution fails
  - Fix: `comfy node install <node-name>` or use the web UI
- **Model not found**: Checkpoint/LoRA path incorrect → silent failure
  - Fix: Verify model paths in `models/` directory
- **Memory errors**: Large resolutions or batch sizes exceed VRAM
  - Fix: Reduce resolution, batch size, or enable `--lowvram` flag
- **WebSocket timeouts**: Connection drops during long generations
  - Fix: Reconnect with same client_id to resume monitoring

### Scripts & Tools

- `hardware_check.py` — Verify GPU/CUDA setup
- `comfyui_setup.sh` — Automated installation
- `extract_schema.py` — Extract workflow schema from API
- `check_deps.py` — Validate custom node dependencies
- `auto_fix_deps.py` — Auto-install missing dependencies
- `run_workflow.py` — Execute workflow via REST API
- `run_batch.py` — Batch workflow execution
- `ws_monitor.py` — WebSocket progress monitor

---

## 2. TouchDesigner (Real-Time Visual Programming)

### Architecture

TouchDesigner is a node-based visual programming environment for real-time interactive content. Control it via:
- **twozero MCP server**: 36 native tools for operator manipulation, parameter control, and execution
- **Streamable HTTP transport**: MCP server at port 40404
- **Python scripting**: Direct access to TouchDesigner's Python API

### Setup

1. **Install twozero.tox** — drag into TouchDesigner project
2. **Enable MCP toggle** in twozero component parameters
3. **Start MCP server** — automated via `setup.sh` or manually

```bash
# Automated setup
./setup.sh

# Manual: Start MCP server
python twozero_mcp_server.py --port 40404
```

### MCP Tools (36 Native Tools)

#### Operator Discovery
- `td_get_operator_info` — Get operator details (type, parameters, children)
- `td_get_par_info` — Get parameter metadata (type, range, defaults)
- `td_get_hints` — Get context-aware suggestions for next steps
- `td_list_operators` — List operators by type or path

#### Parameter Control
- `td_set_par` — Set parameter value
- `td_get_par` — Get parameter value
- `td_pulse_par` — Pulse a parameter (trigger action)
- `td_set_multiple_pars` — Set multiple parameters atomically

#### Execution & Control
- `td_execute_python` — Execute arbitrary Python in TouchDesigner context
- `td_run_op_method` — Call operator method (e.g., `cook()`, `destroy()`)
- `td_cook` — Force operator to recompute
- `td_pause_op` / `td_resume_op` — Pause/resume operator execution

#### Network & DAT Operations
- `td_send_dat` — Send data to DAT operator
- `td_get_dat` — Read DAT contents
- `td_clear_dat` — Clear DAT contents

#### CHOP Operations
- `td_get_chop_samples` — Read CHOP channel data
- `td_set_chop` — Write CHOP channel data

### Critical Rules

1. **NEVER guess parameter names** — always call `td_get_par_info` first
   - Parameter names are case-sensitive and operator-specific
   - Guessing leads to silent failures or wrong values

2. **If `tdAttributeError` fires, STOP** — call `td_get_operator_info` immediately
   - The operator path is wrong or the operator doesn't exist
   - Continuing will cause cascading errors

3. **NEVER hardcode absolute paths** — use relative paths or operator references
   - TouchDesigner projects move between machines
   - Absolute paths break portability

4. **Prefer native MCP tools over `td_execute_python`** — native tools are safer and faster
   - `td_execute_python` bypasses validation and can crash TouchDesigner
   - Use only when native tools don't cover your use case

5. **Call `td_get_hints` before building** — get context-aware suggestions
   - Avoids common mistakes and suggests best practices
   - Saves time by preventing trial-and-error

### Common Pitfalls

- **Wrong parameter type**: Setting string to numeric parameter → silent failure
  - Fix: Always check parameter type with `td_get_par_info`
- **Operator not cooked**: Reading stale data from operator
  - Fix: Call `td_cook` before reading, or check `cookFrame` timestamp
- **MCP server not running**: Connection refused on port 40404
  - Fix: Verify twozero component is enabled and MCP server is started
- **Python execution crashes TouchDesigner**: Unhandled exception in `td_execute_python`
  - Fix: Wrap code in try/except, test in TouchDesigner's textport first
- **Parameter range violations**: Setting value outside min/max → clamped silently
  - Fix: Check parameter range with `td_get_par_info` before setting

### Workflow Pattern

1. **Discover**: `td_get_hints` → understand what's possible
2. **Inspect**: `td_get_operator_info` → understand operator structure
3. **Validate**: `td_get_par_info` → understand parameter constraints
4. **Execute**: Use native MCP tools (or `td_execute_python` as last resort)
5. **Verify**: Read back values to confirm changes took effect

---

## Tool Selection Guide

| Use Case | Tool |
|----------|------|
| AI image generation (Stable Diffusion, SDXL, Flux) | **ComfyUI** |
| AI video generation (AnimateDiff, SVD) | **ComfyUI** |
| Complex AI workflows with custom nodes | **ComfyUI** |
| Real-time interactive visuals | **TouchDesigner** |
| Projection mapping / installations | **TouchDesigner** |
| Live performance visuals | **TouchDesigner** |
| Kinect / sensor input processing | **TouchDesigner** |
| Real-time audio-reactive visuals | **TouchDesigner** |

## Common Pitfalls Across Both Tools

1. **Not checking prerequisites** — missing dependencies cause silent failures
2. **Ignoring error messages** — both tools return structured errors, read them
3. **Hardcoding paths** — breaks portability between machines
4. **Skipping validation** — always verify changes took effect
5. **Not using discovery tools** — `td_get_hints` and ComfyUI's schema extraction prevent mistakes

## Verification Checklists

### After ComfyUI Workflow
- [ ] Workflow JSON is valid (no syntax errors)
- [ ] All custom nodes are installed
- [ ] All models/checkpoints exist in correct paths
- [ ] Execution completed without errors (check WebSocket or history)
- [ ] Output images/videos are in `output/` directory
- [ ] Results match expectations (visual inspection)

### After TouchDesigner Control
- [ ] Operator exists at specified path (`td_get_operator_info` succeeded)
- [ ] Parameter names are correct (`td_get_par_info` confirmed)
- [ ] Parameter values are within valid ranges
- [ ] Changes took effect (read back values to verify)
- [ ] No `tdAttributeError` or other exceptions
- [ ] TouchDesigner didn't crash (check process is still running)
