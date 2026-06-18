DashScope API Key 端点兼容性：`sk-sp-*` 前缀的 Key 仅对 `coding.dashscope.aliyuncs.com/v1` 有效，用于 `dashscope.aliyuncs.com/compatible-mode/v1` 会返回 HTTP 401 "Incorrect API key provided"。两个端点不共用同一个 Key。OpenClaw 的 `.env` 中 `ALIYUN_BASE_URL` 和 `openclaw.json` 中 `models.providers.qwen.baseUrl` 必须保持一致。
§
openclaw-team 部署架构：
- 远端（ubuntu24）：ssh root@ubuntu24.tailcc8506.ts.net，源码/opt/openclaw/，配置/opt/openclaw-team/，sentinel用systemd管理，Agent为Docker容器
- 本地（macOS）：编辑源码 + 部署 openclaw-secretariat（~/.openclaw/）+ hermes-secretariat
- Node.js 路径：/www/server/nodejs/v24.14.0/bin/node
- 两边.env不同，均被.gitignore排除

Wh002服务器：运行Hermes Agent + Feishu Gateway，源码/opt/WorkStation/hermes-agent/，venv在同目录venv/。环境变量ALIYUN_CODING_API_KEY（sk-sp-*前缀，coding端点）和ALIYUN_DASHSCOPE_API_KEY（百炼端点）已配置。期望模型配置：Hermes默认coding-aliyun/qwen3.7-plus、fallback dashscope-bailian/qwen3.7-max；OpenCode默认dashscope-bailian/qwen3.7-max、fallback coding-aliyun/qwen3.7-plus。
§
Team 模型分配：qwen3.6-plus（DashScope coding端点）和 GLM-5.1（讯飞 coding端点）。
qwen3.6-plus: orchestrator/dev/ads/project/qa/spatial/game/finance/hr/supply-chain（10个Agent）
GLM-5.1 (astron-code-latest): pm/design/sales/marketing/support/expert/academic/legal（8个Agent）
讯飞端点: openai_url=`https://maas-coding-api.cn-huabei-1.xf-yun.com/v2`, anthropic_url=`https://maas-coding-api.cn-huabei-1.xf-yun.com/anthropic`, 上下文200k
本地 openclaw.json 已添加 iflytek provider，models 列表中有 iflytek/astron-code-latest
§
DOCX生成与MD编写强制规则：
1. MD源文件中禁止使用---横线
2. 所有DOCX正文和表格必须使用宋体(SimSun)，标题可用微软雅黑但必须黑色
3. 移除w:pBdr（横线）、w:keepNext、w:keepLines
4. 移除所有主题色（themeColor等），强制颜色为000000黑色
5. 移除斜体w:i/w:iCs、列表编号w:numPr、修订跟踪w:rsid*
6. 所有表格加黑色单线边框（sz=4, color=000000）
7. 默认语言设为zh-CN
8. MD进git追踪，docx放docx-output/目录被gitignore
§
Server qd001: 114.215.149.37, Ubuntu 24.04, 512MB, Tailscale Exit Node (100.123.102.18), SSH port 10022. SSH config uses `???` pattern for tailnet.
§
screencapture 截 Electron 窗口（Codex）：需先 `osascript -e 'tell application "Codex" to activate'` 激活并等2秒，再截。否则可能截到空白桌面。