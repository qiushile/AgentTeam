---
name: llm-fine-tuning
description: "LLM fine-tuning: Axolotl (YAML configs), TRL (RLHF/DPO/GRPO), and Unsloth (2-5x faster fine-tuning)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [LLM, fine-tuning, Axolotl, TRL, Unsloth, RLHF, DPO, GRPO]
---

# LLM Fine-Tuning Suite

Unified skill for fine-tuning large language models. Three frameworks: Axolotl (YAML-driven), TRL (RLHF/DPO/GRPO), and Unsloth (speed-optimized).

---

## Section A: Axolotl (YAML-Driven Fine-Tuning)

Expert guidance for fine-tuning LLMs with Axolotl. Uses YAML configuration files to define training runs.

**Best for**: Standard supervised fine-tuning (SFT) and instruction tuning with clean YAML configs.

**Typical workflow**:
1. Prepare dataset (JSON/Parquet with instruction/input/output format)
2. Write Axolotl YAML config (model, dataset, training params)
3. Run training: `accelerate launch -m axolotl.cli.train config.yaml`
4. Merge LoRA weights if applicable
5. Test fine-tuned model

---

## Section B: TRL — RLHF/DPO/GRPO Training

Fine-tune LLMs using reinforcement learning with the TRL library.

**Best for**: Alignment training (RLHF, DPO, GRPO, ORPO, KTO) after supervised fine-tuning.

**Methods**:
- **SFT**: Supervised Fine-Tuning
- **DPO**: Direct Preference Optimization (simpler than RLHF)
- **GRPO**: Group Relative Preference Optimization
- **ORPO**: Odds Ratio Preference Optimization
- **KTO**: Kahneman-Tversky Optimization
- **RLHF**: Full RL from Human Feedback (PPO-based)

**Workflow**: Start with SFT model → prepare preference data → run DPO/ORPO/KTO or PPO → evaluate.

---

## Section C: Unsloth (2-5x Faster Fine-Tuning)

Optimized fine-tuning: 2-5x faster, 60-80% less VRAM. Compatible with TRL and HuggingFace trainers.

**Best for**: Limited VRAM (70B on 24GB with QLoRA), fast iteration, training many variants.

---

## Shared Pitfalls

1. **Dataset quality matters most** — inspect before training
2. **Start small** — test with data subset first
3. **LoRA vs full FT** — LoRA is faster; full FT gives better results
4. **Always validate** — test on held-out examples
5. **Mixed precision** — use `bf16` or `fp16` for speed