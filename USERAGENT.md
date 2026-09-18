**Caveats:**
1. `warp-agent-cli`/`muse-code`/`fx`/`devin`/`kiro`/`kimchi`/`replit-agent`/`amp`/`roo`/`traecode` does not support BYOK in a natural way
2. `codewhale` suffers weird TUI input issue and cannot respond in interactive mode
3. `antigravity-cli` may work if `configured with model mapping
4. `prime-agent`/`deepagents` cannot be fully cached for Docker build
5. `zmx` auth is unstable, requiring further improvements
6. `bub` is out of control given a simple "Hello"

### forgecode

- **Auth:** `KEY=<key>; MODEL=<model>; zmx r tmp -d forge provider login deepseek && sleep 5 && zmx s tmp $KEY$'\r' && sleep 2 && zmx s tmp $MODEL$'\r' && sleep 10 && zmx k tmp && forge config set reasoning-effort max`
- **Headless:** `forge -p "Hello"` — No bypass option?
- **Interactive:** `: Hello` — Interactive auth is auto triggered if not already authenticated; Use `:config-reasoning-effort` to set effort level; No permission control option?; Use `:model` to switch models

### tmuxai

- **Auth:** `KEY=<key>; MODEL=<model>; printf "models:\n  primary:\n    provider: openrouter\n    model: $MODEL\n    api_key: $KEY\n    base_url: https://api.deepseek.com" | put /root/.config/tmuxai/config.yaml`
- **Headless:** `echo 'Hello' > c.tmp; tmuxai --yolo -f c.tmp` — Highly unrecommended
- **Interactive:** `tmuxai` — Run a standalone auth first; No effort level option?; No permission control option?; Use `/model` to switch models
 
### codex

- **Auth:** `KEY=<key>; MODEL=<model>; printf "disable_response_storage = true\nmodel = '$MODEL'\nmodel_provider = 'deepseek'\npreferred_auth_method = 'apikey'\nforced_login_method = 'api'\nmodel_reasoning_effort = 'max'\nmodel_catalog_json = '/root/.codex/models.json'\n\n[model_providers.deepseek]\nname = 'deepseek'\nbase_url = 'https://api.deepseek.com'\nwire_api = 'responses'\nexperimental_bearer_token = '$KEY'" | put /root/.codex/config.toml`
- **Headless:** `codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox "Hello"`
- **Interactive:** `codex` — Run a standalone auth first; Set effort level with `Alt-,`/`Alt-.`; Use `/permissions` to change approval mode; Use `/model` to switch models

### claude

- **Auth:** `KEY=<key>; MODEL=<model>; jq -n '{env:{ANTHROPIC_BASE_URL:"https://api.deepseek.com/anthropic",ANTHROPIC_AUTH_TOKEN:"'$KEY'",ANTHROPIC_MODEL:"'$MODEL'[1m]",ANTHROPIC_DEFAULT_OPUS_MODEL:"'$MODEL'[1m]",ANTHROPIC_DEFAULT_SONNET_MODEL:"'$MODEL'[1m]",ANTHROPIC_DEFAULT_HAIKU_MODEL:"'$MODEL'[1m]",CLAUDE_CODE_SUBAGENT_MODEL:"'$MODEL'[1m]",CLAUDE_CODE_EFFORT_LEVEL:"max",CLAUDE_CODE_AUTO_COMPACT_WINDOW:"786432"}}' | put /root/.claude/settings.json`
- **Headless:** `IS_SANDBOX=1 claude --dangerously-skip-permissions -p "Hello"`
- **Interactive:** `claude` — Run a standalone auth first; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### opencode

- **Auth:** `KEY=<key>; zmx r tmp -d opencode providers login -p deepseek && sleep 5 && zmx s tmp $KEY$'\r' && sleep 10 && zmx k tmp`
- **Headless:** `MODEL=<model>; opencode run --auto -m "deepseek/$MODEL" --variant max "Hello"`
- **Interactive:** `opencode` — `/connect` to auth interactively; Use `/variants` to set effort level; No permission control option?; Use `/models` to switch models

### pi

- **Auth:** `KEY=<key>; jq -n '{deepseek:{type:"api_key",key:"'$KEY'"}}' | put /root/.pi/agent/auth.json`
- **Headless:** `MODEL=<model>; pi --provider deepseek --model $MODEL -p --no-session --thinking max -a "Hello"`
- **Interactive:** `pi` — `/login` to auth interactively; The effort level option resides in `/settings`; No permission control option?; Use `/model` to switch models

### omp

- **Auth:** `KEY=<key>; put /root/.omp/agent/.env "DEEPSEEK_API_KEY=$KEY"`
- **Headless:** `MODEL=<model>; omp --provider deepseek --model $MODEL -p --no-session --thinking max --auto-approve "Hello"`
- **Interactive:** `omp` — `/login` to auth interactively; The effort level and tool approval mode options reside in `/settings`; Use `/model` to switch models

### jcode

- **Auth:** `KEY=<key>; put /root/.config/jcode/deepseek.env "DEEPSEEK_API_KEY=$KEY"`
- **Headless:** `MODEL=<model>; jcode run -p deepseek -m $MODEL "Hello"` — Neither CLI effort nor bypass option?
- **Interactive:** `jcode` — `/login` to auth interactively; Use `/effort` to set effort level; Recommended to turn off `/telemetry`; No permission control option?; Use `/model` to switch models

### hermes

- **Auth:** `KEY=<key>; put /root/.hermes/.env "DEEPSEEK_API_KEY=$KEY"`
- **Headless:** `MODEL=<model>; hermes chat --provider deepseek --model $MODEL --reasoning max --yolo -q "Hello"`
- **Interactive:** `hermes` — `hermes model` to auth interactively; Use `/reasoning` to set effort level; Use `/yolo` to toggle approval bypass; Use `/model` to switch models

### crush

- **Auth:** `KEY=<key>; MODEL=<model>; printf "provider add deepseek --api-key $KEY\nmodel add deepseek/$MODEL --name $MODEL --context-window 1000000 --default-max-tokens 384000 --can-reason true --supports-images true --reasoning-effort max\nmodel large deepseek/$MODEL --think --reasoning-effort max" | put /root/.config/crush/crushrc`
- **Headless:** `MODEL=<model>; crush run "Hello" -m $MODEL` — No bypass option? 
- **Interactive:** `crush -y` — A unified `/` to search `reason` for effort level and `model` for auth; Tool prompt offers permission guard; `Ctrl-L` to switch models

### grok

- **Auth:** `KEY=<key>; MODEL=<model>; printf "[models]\ndefault = '$MODEL'\ndefault_reasoning_effort = 'max'\n\n[model.$MODEL]\nmodel = '$MODEL'[1m]\nbase_url = 'https://api.deepseek.com/anthropic/v1'\nname = 'DeepSeek'\napi_backend = 'messages'\napi_key = '$KEY'\ncontext_window = 1000000\nextra_headers = { 'anthropic-version' = '2023-06-01' }" | put /root/.grok/config.toml`
- **Headless:** `grok --always-approve -p "Hello"`
- **Interactive:** `grok` — Run a standalone auth first; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### reasonix

- **Auth:** `KEY=<key>; put /root/.reasonix/.env "DEEPSEEK_API_KEY=$KEY"`
- **Headless:** `MODEL=<model>; reasonix run -p --permission-mode bypassPermissions --effort max --model $MODEL "Hello"`
- **Interactive:** `reasonix` — `reasonix setup` to auth; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### droid

- **Auth:** `KEY=<key>; MODEL=<model>; jq -n '{customModels:[{model:"'$MODEL'",displayName:"DeepSeek",baseUrl:"https://api.deepseek.com",apiKey:"'$KEY'",provider:"openai",maxOutputTokens:384000}]}' | put /root/.factory/settings.json`
- **Headless:** `droid exec --skip-permissions-unsafe -r max -m "custom:DeepSeek-0" "Hello"`
- **Interactive:** `droid` — Run a standalone auth first plus onboarding login; Use `/model` to switch models and set effort level; `Ctrl-L` to cycle permission modes

### goose

- **Auth:** `KEY=<key>; MODEL=<model>; jq -n '{name:"deepseek",engine:"anthropic",display_name:"DeepSeek",api_key_env:"DEEPSEEK_API_KEY",base_url:"https://api.deepseek.com/anthropic",models:[{name:"'$MODEL'",context_limit:1000000}],supports_streaming:true,requires_auth:true}' | put /root/.config/goose/custom_providers/deepseek.json && printf "active_provider: deepseek\nproviders:\n  deepseek:\n    enabled: true\n    model: $MODEL\n    configured: true\nGOOSE_MODE: auto\nGOOSE_DISABLE_KEYRING: 1" | put /root/.config/goose/config.yaml && put /root/.config/goose/secrets.yaml "DEEPSEEK_API_KEY: $KEY"`
- **Headless:** `goose run --no-session -t "Hello"` — No effort level option?
- **Interactive:** `goose` — `goose configure` to auth interactively; No effort level option?; Use `/mode` to change approval mode; Use `/model` to switch models

### aider

- **Auth:** `KEY=<key>; printf "api-key:\n- deepseek=$KEY" | put /root/.aider.conf.yml`
- **Headless:** `MODEL=<model>; aider --no-git --model deepseek/$MODEL --reasoning-effort max --yes-always --no-check-model-accepts-settings --no-show-model-warnings -m "Hello"`
- **Interactive:** `aider` — Run a standalone auth first; Use `/reasoning-effort` to set effort level; No permission control option?; Use `/model` to switch models

### copilot

- **Auth:** `KEY=<key>; MODEL=<model>; printf "COPILOT_PROVIDER_TYPE=anthropic\nCOPILOT_PROVIDER_BASE_URL=https://api.deepseek.com/anthropic\nCOPILOT_PROVIDER_API_KEY=$KEY\nCOPILOT_MODEL=$MODEL" | put /root/.copilot/.env`
- **Headless:** `copilot --yolo --effort max -p "Hello"`
- **Interactive:** `copilot` — Run a standalone auth first; Use `/settings effortLevel` to set effort level; Use `/yolo` to toggle approval bypass; Use `/model` to switch models

### cline

- **Auth:** `KEY=<key>; MODEL=<model>; cline auth -p deepseek -k $KEY -m $MODEL`
- **Headless:** `echo -n "Hello" | cline --auto-approve true --thinking xhigh`
- **Interactive:** `cline` — Run a standalone auth first; Use `/model` to switch models and set effort level; `Shift-Tab` to cycle permission modes

### codebuddy

- **Auth:** `KEY=<key>; MODEL=<model>; jq -n '{model:"'$MODEL'",reasoningEffort:"max",permissions:{defaultMode:"bypassPermissions"},trustAll:true,env:{CODEBUDDY_API_KEY:"'$KEY'",CODEBUDDY_BASE_URL:"https://api.deepseek.com"}}' | put /root/.codebuddy/settings.json`
- **Headless:** `CODEBUDDY_IS_SANDBOX=1 codebuddy -y -p "Hello"`
- **Interactive:** `codebuddy` — Run a standalone auth first; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; No custom model switching?

### kilo

- **Auth:** `KEY=<key>; zmx r tmp -d kilo auth login && sleep 5 && zmx s tmp deepseek$'\r' && sleep 2 && zmx s tmp $KEY$'\r' && sleep 10 && zmx k tmp`
- **Headless:** `MODEL=<model>; kilo run -m deepseek/$MODEL --auto true --variant max "Hello"`
- **Interactive:** `kilo` — `/connect` to auth interactively; `Ctrl-T` to cycle through effort levels; Use `/auth-approve` to toggle approval bypass; Use `/models` to switch models

### kimi

- **Auth:** `KEY=<key>; MODEL=<model>; printf "default_permission_mode = 'yolo'\ndefault_model = '$MODEL'\ntelemetry = false\n\n[providers.deepseek]\ntype = 'openai_responses'\nbase_url = 'https://api.deepseek.com'\napi_key = '$KEY'\n\n[models.'$MODEL']\nprovider = 'deepseek'\nmodel = '$MODEL'\nmax_context_size = 1000000\ncapabilities = ['thinking', 'image_in', 'tool_use']\n\n[thinking]\nenabled = true\neffort = 'max'" | put /root/.kimi-code/config.toml`
- **Headless:** `kimi -p "Hello"`
- **Interactive:** `kimi` — `/provider` to auth interactively; Use `/effort` to set effort level; Use `/permission` to change approval mode; Use `/model` to switch models

### qwen

- **Auth:** `KEY=<key>; MODEL=<model>; jq -n '{modelProviders:{anthropic:[{id:"'$MODEL'[1m]",name:"DeepSeek",baseUrl:"https://api.deepseek.com/anthropic",envKey:"ANTHROPIC_API_KEY",generationConfig:{contextWindowSize:1000000,modalities:{image:true},reasoning:{effort:"max"}}}]},env:{ANTHROPIC_API_KEY:"'$KEY'"},security:{auth:{selectedType:"anthropic"}},model:{name:"'$MODEL'[1m]"}}' | put /root/.qwen/settings.json`
- **Headless:** `qwen --approval-mode yolo -p "Hello"`
- **Interactive:** `qwen` — `/auth` to auth interactively; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### mcode

- **Auth:** `KEY=<key>; MODEL=<model>; MCODE_PROVIDER_API_KEY=$KEY mcode provider add --name deepseek --base-url https://api.deepseek.com --api-format openai-responses --model $MODEL && mcode provider test deepseek && sed -i "s|^defaultModel:.*|defaultModel: custom_provider:deepseek/$MODEL|" /root/.minimax/config.yaml`
- **Headless:** `mcode exec --permission full "Hello"`; No effect level option?
- **Interactive:** `mcode` — `/model` to auth interactively and switch models; No effect level option?; `Alt-M` to cycle permission modes

### qoder

- **Auth:** Not recommended. Run an interactive auth first
- **Headless:** `MODEL=<model>; qoder -m deepseek/$MODEL --reasoning-effort max --dangerously-skip-permissions -p --no-session-persistence "Hello"`
- **Interactive:** `qoder` — Interactive auth is auto triggered if not already authenticated; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### prime

- **Auth:** `KEY=<key>; MODEL=<model>; jq -n '{deepseek:{type:"api_key",key:"'$KEY'"}}' | put /root/.prime/agent/auth.json && jq -n '{defaultProvider:"deepseek",defaultModel:"'$MODEL'",defaultThinkingLevel:"max",telemetry:{enabled:false}}' | put /root/.prime/agent/settings.json`
- **Headless:** `prime-agent --no-session -p "Hello"` — No bypass option?
- **Interactive:** `prime-agent` — `/login` to auth interactively; Use `/effort` to set effort level; No permission control option?; Use `/model` to switch models

### deepagents

- **Auth:** `KEY=<key>; MODEL=<model>; put /root/.deepagents/.env "DEEPSEEK_API_KEY=$KEY" && printf "[models]\ndefault = 'deepseek:$MODEL'\n\n[models.providers.deepseek.params]\nreasoning_effort = 'max'" | put /root/.deepagents/config.toml`
- **Headless:** `dcode -S all --yolo -n "Hello"`
- **Interactive:** `dcode` — `/auth` to auth interactively; Use `/effort` to set effort level; `Shift-Tab` to cycle permission modes; Use `/model` to switch models

### openhands

- **Auth:** `KEY=<key>; MODEL=<model>; jq -n '{llm:{model:"deepseek/'$MODEL'",api_key:"'$KEY'",base_url:"https://api.deepseek.com"}}' | put /root/.openhands/agent_settings.json`
- **Headless:** `openhands --yolo --headless -t "Hello"` — No effort level option?
- **Interactive:** `openhands` — `/settings` for auth and model designation; No effort level option?; Use `/confirm` to change approval mode

### deepcode

- **Auth:** `KEY=<key>; MODEL=<model>; jq -n '{env:{MODEL:"'$MODEL'",BASE_URL:"https://api.deepseek.com",API_KEY:"'$KEY'"},thinkingEnabled:true,reasoningEffort:"max",telemetryEnabled:false}' | put /root/.deepcode/settings.json`
- **Headless:** `deepcode -x -p "Hello"` — No bypass option?
- **Interactive:** `deepcode` — Run a standalone auth first; No effort level option?; No permission control option?; Use `/model` to switch models

### atomic

- **Auth:** `KEY=<key>; MODEL=<model>; jq -n '{llm:{activeTextProvider:"deepseek",activeEmbeddingProvider:"deepseek",providers:[{id:"deepseek",kind:"openai-compatible",baseUrl:"https://api.deepseek.com",defaultChatModel:"'$MODEL'",maxOutputTokens:384000,extraBody:{reasoning_effort:"max"},userModels:[{id:"'$MODEL'",kind:"chat",contextWindow:1000000,supportsVision:true}]}]},analytics:{enabled:false}}' | put /root/.atomic-agent/config.json && printf "OPENAI_COMPAT_API_KEY=$KEY\nATOMIC_AGENT_UPDATE_CHECK_ON_STARTUP=false" | put /root/.atomic-agent/.env`
- **Headless:** `echo "Hello" | atag run --no-approval` 
- **Interactive:** `atag` — Run a standalone auth first; No effort level option?; Use `/mode` to change approval mode; Use `/model` to switch models

### letta

- **Auth:** `KEY=<key>; letta backend local && letta --backend local connect deepseek --api-key $KEY`
- **Headless:** `MODEL=<model>; letta --ephemeral -p "Hello" --model deepseek/$MODEL` — Neither CLI effort nor bypass option?
- **Interactive:** `letta` — `/connect` to auth interactively; Use `/model` to switch models and set effort level; `Shift+Tab` to cycle permission modes

### zerostack

- **Auth:** `KEY=<key>; MODEL=<model>; printf "provider: deepseek\nmodel: $MODEL\nmax_tokens: 384000\ncontext_window: 1000000\nshow_reasoning: true\nextra_body:\n  reasoning_effort: max\napi_keys:\n  deepseek: $KEY\ncustom_providers:\n  deepseek:\n    provider_type: openai\n    base_url: https://api.deepseek.com" | put /root/.config/zerostack/config.yaml`
- **Headless:** `zerostack --dangerously-skip-permissions -p "Hello"` — No effort level option?
- **Interactive:** `zerostack` — Run a standalone auth first; Use `/thinking` to set effort level; Use `/mode` to change approval mode; Use `/model` to switch models

### mimo

- **Auth:** `KEY=<key>; MODEL=<model>; jq -n '{model:"deepseek/'$MODEL'",provider:{deepseek:{name:"DeepSeek",npm:"@ai-sdk/openai-compatible",models:{"'$MODEL'":{name:"'$MODEL'",reasoning:true,interleaved:{field:"reasoning_content"},options:{reasoningEffort:"max"},limit:{context:1000000,output:384000}}},options:{baseURL:"https://api.deepseek.com",apiKey:"'$KEY'"}}}}' | put /root/.config/mimocode/mimocode.json`
- **Headless:** `mimo run --variant max --dangerously-skip-permissions "Hello"`
- **Interactive:** `mimo` — `/connect` to auth interactively; `Ctrl-T` to cycle through effort levels; Use `/skip-permissions` to toggle approval bypass; Use `/models` to switch models
