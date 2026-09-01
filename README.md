### Feature

*Why shall you choose easy-ai-dev?*

- Simple enough to fully control: A single Dockerfile to build with, bundled with clean startup `zsh` and `vim` configurations
- Versatile tech stack: Off-the-shelf support for a wide range of AI agents (currently 25 kinds) and languages (currently 23 tokens) in addition to handy modern TUI gadgets

### Start From Here

- **Build:** `docker build [--build-arg ...] -t ai-dev[:{tag}] .`
- **Run:** `docker run -it --rm --privileged ai-dev[:{tag}]`

### Build Arguments

Four build args control what goes into the image: `TIER` (cozy preset), `TUI` (interactive/headless tool set), `LANGS` (languages), and `AGENTS` (agents)

`TIER` seeds defaults for the other three; explicit args merge on top of the tier — `TUI` overrides, `LANGS`/`AGENTS` append — and every list is deduplicated before installation:

| TIER | TUI | LANGS | AGENTS |
| - | - | - | - |
| `full` (default) | 1 | all | all |
| `pro` | 1 | python tsc go rust sql lua clojure lisp zig r | forgecode codex opencode pi crush jcode cline kilo omp |
| `default` | 1 | python tsc go rust sql | forgecode codex opencode pi |
| `lite` | 0 | python tsc | forgecode |
| (empty) | 0 | — | — |

- `TUI={0|1}` — with `1`, the modern interactive tool set (tmux, zellij, bat, eza, starship, lazygit, fastfetch, fzf, zoxide, yazi, tlrc, …) is installed; with `0`, only the bare essentials
- `LANGS` — comma separated language tokens; see `LANGUAGE.md`. Vocabulary: `c cpp ruby fortran perl python js tsc go rust sql php lua elixir erlang zig swift r clojure java lisp dart ada`. `all` selects the full vocabulary
- `AGENTS` — comma separated agents; see `USERAGENT.md`. `all` selects all 25

*Examples:*

```sh
docker build -t ai-dev . # full: all
docker build --build-arg TIER=lite -t ai-dev:lite . # headless, minimal
docker build --build-arg TIER= -t ai-dev:bare . # headless, no languages/agents
docker build --build-arg TIER=default --build-arg LANGS=php,clojure -t ai-dev:jvm . # languages merged on top
docker build --build-arg TIER=default --build-arg AGENTS=codex,cline -t ai-dev:cn . # agents merged on top
docker build --build-arg TIER=lite --build-arg TUI=1 -t ai-dev:lite-tui . # explicit TUI overrides tier
```

*Notes:*

1. `perl`, `c`, `c++`, `ruby` and `fortran` are always available; BTW, `ruby` is Homebrew's launcher
2. `js`/`tsc` install a real `bun` + Node.js toolchain; I actually dislike `node`, however, it finally turns out that `bun` is not omnipotent everywhere
3. `java` installs `openjdk` only, while `clojure` brings `openjdk` along as its dependency; Similar thing happens to `elixir` who bundles `erlang`
4. Agents declare their language dependencies; If interested, read `scripts/resolve-tier.zsh`
5. For convenience, `deepseek-v4-flash-vision-exp` is assumed to be used for all agents
