---
name: ml-evaluation
description: "ML evaluation: lm-eval-harness benchmarks (MMLU, GSM8K, etc.) and Weights & Biases experiment tracking."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [ML, evaluation, benchmarks, experiment-tracking, W&B, lm-eval]
---

# ML Evaluation Suite

Unified skill for evaluating and tracking ML experiments.

---

## Section A: lm-eval-harness (LLM Benchmarks)

Benchmark LLMs on standard tasks: MMLU, GSM8K, TruthfulQA, HellaSwag, ARC, Winogrande, etc.

**Best for**: Comparing model performance across standard benchmarks, evaluating fine-tuned models.

**Key benchmarks**:
- **MMLU**: Massive Multitask Language Understanding (57 subjects)
- **GSM8K**: Grade school math word problems
- **TruthfulQA**: Truthfulness in generation
- **HellaSwag**: Commonsense natural language inference
- **ARC**: AI2 Reasoning Challenge
- **Winogrande**: Adversarial pronoun disambiguation

**Typical workflow**:
```bash
pip install lm-eval
lm_eval --model hf --model_args pretrained=model_name --tasks mmlu,gsm8k --batch_size auto
```

---

## Section B: Weights & Biases (Experiment Tracking)

Log ML experiments, sweeps, model registry, and dashboards.

**Best for**: Tracking experiments across runs, hyperparameter sweeps, model versioning, team collaboration.

**Key features**:
- Experiment logging (metrics, hyperparams, artifacts)
- Hyperparameter sweeps (grid, random, bayesian)
- Model registry
- Dashboard creation
- Team collaboration

**Typical workflow**:
```python
import wandb
wandb.init(project="my-project", config={"lr": 0.01})
wandb.log({"loss": 0.5, "accuracy": 0.9})
wandb.finish()
```