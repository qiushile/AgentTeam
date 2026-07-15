# Heartbeat Configuration

## 投放效果检查与任务扫描（工作日早上 9:30 触发）
schedule: "30 9 * * 1"
model: "fast"
task: |
  1. 调用 `get_my_tasks` 检查是否有分配给 `ads` 的新投放或素材任务。
  2. 报告当前主要渠道的 ROI 异常波动。
  3. 执行今日的投放素材审核。
