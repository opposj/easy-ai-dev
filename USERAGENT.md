### forgecode

- **Auth:** `KEY=<key>; zmx r tmp -d forge provider login deepseek && sleep 2 && zmx s tmp ${KEY}$'\r' && sleep 2 && zmx s tmp deepseek-v4-flash-vision-exp$'\r' && sleep 2 && zmx k tmp && forge config set reasoning-effort max`
- **Headless:** `forge -p "Hello"` — No bypass option?
- **Interactive:** `: Hello` — Interactive auth is auto triggered if not already authenticated; Use `:config-reasoning-effort` to set effort level

### tmuxai

- **Auth:** `KEY=<key>; printf "models:\n  primary:\n    provider: openrouter\n    model: deepseek-v4-flash-vision-exp\n    api_key: $KEY\n    base_url: https://api.deepseek.com" > /root/.config/tmuxai/config.yaml`
- **Headless:** `echo 'Hello' > c.tmp; tmuxai --yolo -f c.tmp` — Highly unrecommended
- **Interactive:** `tmuxai` — Run a standalone auth first; No effort level option?
 
### codex

- **Auth:** `KEY=<key>; printf 'disable_response_storage = true\nmodel = "deepseek-v4-flash-vision-exp"\nmodel_provider = "deepseek"\npreferred_auth_method = "apikey"\nforced_login_method = "api"\nmodel_reasoning_effort = "max"\nmodel_catalog_json = "/root/.codex/models.json"\n\n[model_providers.deepseek]\nname = "deepseek"\nbase_url = "https://api.deepseek.com"\nwire_api = "responses"\nexperimental_bearer_token = "_KEY"' > /root/.codex/config.toml && sed -i "s|_KEY|$KEY|" /root/.codex/config.toml`
- **Headless:** `codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox "Hello"`
- **Interactive:** `codex` — Run a standalone auth first; Set effort level with `Alt-,`/`Alt-.`

### claude-code

- **Auth:** `KEY=<key>; echo '{}' | jq '.env={ANTHROPIC_BASE_URL:"https://api.deepseek.com/anthropic", ANTHROPIC_AUTH_TOKEN:"'$KEY'", ANTHROPIC_MODEL:"deepseek-v4-flash-vision-exp[1m]", ANTHROPIC_DEFAULT_OPUS_MODEL:"deepseek-v4-flash-vision-exp[1m]", ANTHROPIC_DEFAULT_SONNET_MODEL:"deepseek-v4-flash-vision-exp[1m]", ANTHROPIC_DEFAULT_HAIKU_MODEL:"deepseek-v4-flash-vision-exp[1m]", CLAUDE_CODE_SUBAGENT_MODEL:"deepseek-v4-flash-vision-exp[1m]", CLAUDE_CODE_EFFORT_LEVEL:"max", CLAUDE_CODE_AUTO_COMPACT_WINDOW:"786432"}' > /root/.claude/settings.json`
- **Headless:** `IS_SANDBOX=1 claude --dangerously-skip-permissions -p "Hello"`
- **Interactive:** `claude` — Run a standalone auth first; Use `/effort` to set effort level

### opencode

- **Auth:** `KEY=<key>; zmx r tmp -d opencode providers login -p deepseek && sleep 5 && zmx s tmp ${KEY}$'\r' && sleep 5 && zmx k tmp`
- **Headless:** `opencode run --auto -m "deepseek/deepseek-v4-flash-vision-exp" --variant max "Hello"`
- **Interactive:** `opencode` — `/connect` to auth interactively; Use `/variants` to set effort level

### pi

- **Auth:** `KEY=<key>; echo '{}' | jq '.deepseek={type:"api_key", key:"'$KEY'"}' > /root/.pi/agent/auth.json`
- **Headless:** `pi --provider deepseek --model deepseek-v4-flash-vision-exp -p --no-session --thinking max -a "Hello"`
- **Interactive:** `pi` — `/login` to auth interactively; The effort level option resides in `/settings`

### omp

- **Auth:** `KEY=<key>; printf "DEEPSEEK_API_KEY=$KEY" > /root/.omp/agent/.env`
- **Headless:** `omp --provider deepseek --model deepseek-v4-flash-vision-exp -p --no-session --thinking max --auto-approve "Hello"`
- **Interactive:** `omp` — `/login` to auth interactively; The effort level option resides in `/settings`

### jcode

- **Auth:** `KEY=<key>; printf "DEEPSEEK_API_KEY=$KEY" > /root/.config/jcode/deepseek.env`
- **Headless:** `jcode run -p deepseek -m deepseek-v4-flash-vision-exp "Hello"` — Neither CLI effort nor bypass option?
- **Interactive:** `jcode` — `/login` to auth interactively; Use `/effort` to set effort level; Recommended to turn off `/telemetry`
