**Caveats:**
1. `warp-agent-cli`/`muse-code`/`fx`/`devin`/`kiro`/`kimchi`/`replit-agent`/`amp`/`roo` does not support BYOK in a natural way
2. `codewhale` suffers weird TUI input issue and cannot respond in interactive mode
3. `antigravity-cli` may work if `configured with model mapping
4. `prime-agent`/`deepagents` cannot be fully cached for Docker build
5. `zmx` auth is unstable, requiring further improvements

### forgecode

- **Auth:** `KEY=<key>; zmx r tmp -d forge provider login deepseek && sleep 5 && zmx s tmp ${KEY}$'\r' && sleep 2 && zmx s tmp deepseek-v4-flash-vision-exp$'\r' && sleep 10 && zmx k tmp && forge config set reasoning-effort max`
- **Headless:** `forge -p "Hello"` — No bypass option?
- **Interactive:** `: Hello` — Interactive auth is auto triggered if not already authenticated; Use `:config-reasoning-effort` to set effort level; No permission control option?; Use `:model` to switch models

### tmuxai

- **Auth:** `KEY=<key>; printf "models:\n  primary:\n    provider: openrouter\n    model: deepseek-v4-flash-vision-exp\n    api_key: $KEY\n    base_url: https://api.deepseek.com" | put /root/.config/tmuxai/config.yaml`
- **Headless:** `echo 'Hello' > c.tmp; tmuxai --yolo -f c.tmp` — Highly unrecommended
- **Interactive:** `tmuxai` — Run a standalone auth first; No effort level option?; No permission control option?; Use `/model` to switch models
 
### codex

- **Auth:** `KEY=<key>; printf 'disable_response_storage = true\nmodel = "deepseek-v4-flash-vision-exp"\nmodel_provider = "deepseek"\npreferred_auth_method = "apikey"\nforced_login_method = "api"\nmodel_reasoning_effort = "max"\nmodel_catalog_json = "/root/.codex/models.json"\n\n[model_providers.deepseek]\nname = "deepseek"\nbase_url = "https://api.deepseek.com"\nwire_api = "responses"\nexperimental_bearer_token = "_KEY"' | put /root/.codex/config.toml && sed -i "s|_KEY|$KEY|" /root/.codex/config.toml`
- **Headless:** `codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox "Hello"`
- **Interactive:** `codex` — Run a standalone auth first; Set effort level with `Alt-,`/`Alt-.`; Use `/permissions` to change approval mode; Use `/model` to switch models

### claude

- **Auth:** `KEY=<key>; jq -n '{env:{ANTHROPIC_BASE_URL:"https://api.deepseek.com/anthropic",ANTHROPIC_AUTH_TOKEN:"'$KEY'",ANTHROPIC_MODEL:"deepseek-v4-flash-vision-exp[1m]",ANTHROPIC_DEFAULT_OPUS_MODEL:"deepseek-v4-flash-vision-exp[1m]",ANTHROPIC_DEFAULT_SONNET_MODEL:"deepseek-v4-flash-vision-exp[1m]",ANTHROPIC_DEFAULT_HAIKU_MODEL:"deepseek-v4-flash-vision-exp[1m]",CLAUDE_CODE_SUBAGENT_MODEL:"deepseek-v4-flash-vision-exp[1m]",CLAUDE_CODE_EFFORT_LEVEL:"max",CLAUDE_CODE_AUTO_COMPACT_WINDOW:"786432"}}' | put /root/.claude/settings.json`
- **Headless:** `IS_SANDBOX=1 claude --dangerously-skip-permissions -p "Hello"`
- **Interactive:** `claude` — Run a standalone auth first; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### opencode

- **Auth:** `KEY=<key>; zmx r tmp -d opencode providers login -p deepseek && sleep 5 && zmx s tmp ${KEY}$'\r' && sleep 10 && zmx k tmp`
- **Headless:** `opencode run --auto -m "deepseek/deepseek-v4-flash-vision-exp" --variant max "Hello"`
- **Interactive:** `opencode` — `/connect` to auth interactively; Use `/variants` to set effort level; No permission control option?; Use `/models` to switch models

### pi

- **Auth:** `KEY=<key>; jq -n '{deepseek:{type:"api_key",key:"'$KEY'"}}' | put /root/.pi/agent/auth.json`
- **Headless:** `pi --provider deepseek --model deepseek-v4-flash-vision-exp -p --no-session --thinking max -a "Hello"`
- **Interactive:** `pi` — `/login` to auth interactively; The effort level option resides in `/settings`; No permission control option?; Use `/model` to switch models

### omp

- **Auth:** `KEY=<key>; put /root/.omp/agent/.env "DEEPSEEK_API_KEY=$KEY"`
- **Headless:** `omp --provider deepseek --model deepseek-v4-flash-vision-exp -p --no-session --thinking max --auto-approve "Hello"`
- **Interactive:** `omp` — `/login` to auth interactively; The effort level and tool approval mode options reside in `/settings`; Use `/model` to switch models

### jcode

- **Auth:** `KEY=<key>; put /root/.config/jcode/deepseek.env "DEEPSEEK_API_KEY=$KEY"`
- **Headless:** `jcode run -p deepseek -m deepseek-v4-flash-vision-exp "Hello"` — Neither CLI effort nor bypass option?
- **Interactive:** `jcode` — `/login` to auth interactively; Use `/effort` to set effort level; Recommended to turn off `/telemetry`; No permission control option?; Use `/model` to switch models

### hermes

- **Auth:** `KEY=<key>; put /root/.hermes/.env "DEEPSEEK_API_KEY=$KEY"`
- **Headless:** `hermes chat --provider deepseek --model deepseek-v4-flash-vision-exp --reasoning max --yolo -q "Hello"`
- **Interactive:** `hermes` — `hermes model` to auth interactively; Use `/reasoning` to set effort level; Use `/yolo` to toggle approval bypass; Use `/model` to switch models

### crush

- **Auth:** `KEY=<key>; printf "provider add deepseek --api-key $KEY\nmodel add deepseek/deepseek-v4-flash-vision-exp --name deepseek-v4-flash-vision-exp --context-window 1000000 --default-max-tokens 384000 --can-reason true --supports-images true --reasoning-effort max\nmodel large deepseek/deepseek-v4-flash-vision-exp --think --reasoning-effort max" | put /root/.config/crush/crushrc`
- **Headless:** `crush run "Hello" -m deepseek-v4-flash-vision-exp` — No bypass option? 
- **Interactive:** `crush -y` — A unified `/` to search `reason` for effort level and `model` for auth; Tool prompt offers permission guard; `Ctrl-L` to switch models

### grok

- **Auth:** `KEY=<key>; printf "[models]\ndefault = 'deepseek-v4-flash-vision-exp'\ndefault_reasoning_effort = 'max'\n\n[model.deepseek-v4-flash-vision-exp]\nmodel = 'deepseek-v4-flash-vision-exp[1m]'\nbase_url = 'https://api.deepseek.com/anthropic/v1'\nname = 'DeepSeek V4 Flash Vision Exp'\napi_backend = 'messages'\napi_key = '$KEY'\ncontext_window = 1000000\nextra_headers = { 'anthropic-version' = '2023-06-01' }\n" | put /root/.grok/config.toml`
- **Headless:** `grok --always-approve -p "Hello"`
- **Interactive:** `grok` — Run a standalone auth first; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### reasonix

- **Auth:** `KEY=<key>; put /root/.reasonix/.env "DEEPSEEK_API_KEY=$KEY"`
- **Headless:** `reasonix run -p --permission-mode bypassPermissions --effort max --model deepseek-v4-flash-vision-exp "Hello"`
- **Interactive:** `reasonix` — `reasonix setup` to auth; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### droid

- **Auth:** `KEY=<key>; jq -n '{customModels:[{model:"deepseek-v4-flash-vision-exp",displayName:"DeepSeek V4 Flash Vision Exp",baseUrl:"https://api.deepseek.com",apiKey:"'$KEY'",provider:"openai",maxOutputTokens:384000}]}' | put /root/.factory/settings.json`
- **Headless:** `droid exec --skip-permissions-unsafe -r max -m "custom:DeepSeek-V4-Flash-Vision-Exp-0" "Hello"`
- **Interactive:** `droid` — Run a standalone auth first plus onboarding login; Use `/model` to switch models and set up effort level; `Ctrl-L` to cycle permission modes

### goose

- **Auth:** `KEY=<key>; jq -n '{name:"deepseek",engine:"anthropic",display_name:"DeepSeek",api_key_env:"DEEPSEEK_API_KEY",base_url:"https://api.deepseek.com/anthropic",models:[{name:"deepseek-v4-flash-vision-exp",context_limit:1000000}],supports_streaming:true,requires_auth:true}' | put /root/.config/goose/custom_providers/deepseek.json && printf 'active_provider: deepseek\nproviders:\n  deepseek:\n    enabled: true\n    model: deepseek-v4-flash-vision-exp\n    configured: true\nGOOSE_MODE: auto\nGOOSE_DISABLE_KEYRING: 1' | put /root/.config/goose/config.yaml && put /root/.config/goose/secrets.yaml "DEEPSEEK_API_KEY: $KEY"`
- **Headless:** `goose run --no-session -t "Hello"` — No effort level option?
- **Interactive:** `goose` — `goose configure` to auth interactively; No effort level option?; Use `/mode` to change approval mode; Use `/model` to switch models

### aider

- **Auth:** `KEY=<key>; printf "api-key:\n- deepseek=$KEY" | put /root/.aider.conf.yml`
- **Headless:** `aider --no-git --model deepseek/deepseek-v4-flash-vision-exp --reasoning-effort max --yes-always --no-check-model-accepts-settings --no-show-model-warnings -m "Hello"`
- **Interactive:** `aider` — Run a standalone auth first; Use `/reasoning-effort` to set effort level; No permission control option?; Use `/model` to switch models

### copilot

- **Auth:** `KEY=<key>; printf "COPILOT_PROVIDER_TYPE=anthropic\nCOPILOT_PROVIDER_BASE_URL=https://api.deepseek.com/anthropic\nCOPILOT_PROVIDER_API_KEY=$KEY\nCOPILOT_MODEL=deepseek-v4-flash-vision-exp" | put /root/.copilot/.env`
- **Headless:** `copilot --yolo --effort max -p "Hello"`
- **Interactive:** `copilot` — Run a standalone auth first; Use `/settings effortLevel` to set effort level; Use `/yolo` to toggle approval bypass; Use `/model` to switch models

### cline

- **Auth:** `KEY=<key>; cline auth -p deepseek -k $KEY -m deepseek-v4-flash-vision-exp`
- **Headless:** `echo -n "Hello" | cline --auto-approve true --thinking xhigh`
- **Interactive:** `cline` — Run a standalone auth first; Use `/model` to switch models and set up effort level; `Shift-Tab` to cycle permission modes

### kilo

- **Auth:** `KEY=<key>; zmx r tmp -d kilo auth login && sleep 5 && zmx s tmp deepseek$'\r' && sleep 2 && zmx s tmp ${KEY}$'\r' && sleep 10 && zmx k tmp`
- **Headless:** `kilo run -m deepseek/deepseek-v4-flash-vision-exp --auto true --variant max "Hello"`
- **Interactive:** `kilo` — `/connect` to auth interactively; `Ctrl-t` to cycle through effort levels; Use `/auth-approve` to toggle approval bypass; Use `/models` to switch models

### kimi

- **Auth:** `KEY=<key>; printf 'default_permission_mode = "yolo"\ndefault_model = "deepseek-v4-flash-vision-exp"\ntelemetry = false\n\n[providers.deepseek]\ntype = "openai_responses"\nbase_url = "https://api.deepseek.com"\napi_key = "'$KEY'"\n\n[models."deepseek-v4-flash-vision-exp"]\nprovider = "deepseek"\nmodel = "deepseek-v4-flash-vision-exp"\nmax_context_size = 1000000\ncapabilities = ["thinking", "image_in", "tool_use"]\n\n[thinking]\nenabled = true\neffort = "max"\n' | put /root/.kimi-code/config.toml`
- **Headless:** `kimi -p "Hello"`
- **Interactive:** `kimi` — `/provider` to auth interactively; Use `/effort` to set effort level; Use `/permission` to change approval mode; Use `/model` to switch models

### qwen

- **Auth:** `KEY=<key>; jq -n '{modelProviders:{anthropic:[{id:"deepseek-v4-flash-vision-exp[1m]",name:"DeepSeek V4 Flash Vision Exp",baseUrl:"https://api.deepseek.com/anthropic",envKey:"ANTHROPIC_API_KEY",generationConfig:{contextWindowSize:1000000,modalities:{image:true},reasoning:{effort:"max"}}}]},env:{ANTHROPIC_API_KEY:"'$KEY'"},security:{auth:{selectedType:"anthropic"}},model:{name:"deepseek-v4-flash-vision-exp[1m]"}}' | put /root/.qwen/settings.json`
- **Headless:** `qwen --approval-mode yolo -p "Hello"`
- **Interactive:** `qwen` — `/auth` to auth interactively; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### qoder

- **Auth:** Not recommended. Run an interactive auth first
- **Headless:** `qoder -m deepseek/deepseek-v4-flash-vision-pg --reasoning-effort max --dangerously-skip-permissions -p --no-session-persistence "Hello"`
- **Interactive:** `qoder` — Interactive auth is auto triggered if not already authenticated; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### prime

- **Auth:** `KEY=<key>; jq -n '{deepseek:{type:"api_key",key:"'$KEY'"}}' | put /root/.prime/agent/auth.json && jq -n '{defaultProvider:"deepseek",defaultModel:"deepseek-v4-flash-vision-exp",defaultThinkingLevel:"max",telemetry:{enabled:false}}' | put /root/.prime/agent/settings.json`
- **Headless:** `prime-agent --no-session -p "Hello"` — No bypass option?
- **Interactive:** `prime-agent` — `/login` to auth interactively; Use `/effort` to set effort level; No permission control option?; Use `/model` to switch models

### deepagents

- **Auth:** `KEY=<key>; put /root/.deepagents/.env "DEEPSEEK_API_KEY=$KEY" && printf '[models]\ndefault = "deepseek:deepseek-v4-flash-vision-exp"\n\n[models.providers.deepseek.params]\nreasoning_effort = "max"\n' | put /root/.deepagents/config.toml`
- **Headless:** `dcode -S all --yolo -n "Hello"`
- **Interactive:** `dcode` — `/auth` to auth interactively; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### openhands

- **Auth:** `KEY=<key>; jq -n '{llm:{model:"deepseek/deepseek-v4-flash-vision-exp",api_key:"'$KEY'",base_url:"https://api.deepseek.com"}}' | put /root/.openhands/agent_settings.json`
- **Headless:** `openhands --yolo --headless -t "Hello"` — No effort level option?
- **Interactive:** `openhands` — `/settings` for auth and model designation; No effort level option?; Use `/confirm` to change approval mode

### deepcode

- **Auth:** `KEY=<key>; jq -n '{env:{MODEL:"deepseek-v4-flash-vision-exp",BASE_URL:"https://api.deepseek.com",API_KEY:"'$KEY'"},thinkingEnabled:true,reasoningEffort:"max",telemetryEnabled:false}' | put /root/.deepcode/settings.json`
- **Headless:** `deepcode -x -p "Hello"` — No bypass option?
- **Interactive:** `deepcode` — Run a standalone auth first; No effort level option?; No permission control option?; Use `/model` to switch models
