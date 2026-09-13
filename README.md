### Feature

*Why shall you choose easy-ai-dev?*

- Simple enough to fully control: A single Dockerfile to build with, bundled with clean startup `zsh` and `vim` configurations
- Versatile tech stack: Off-the-shelf support for a wide range of AI agents and languages in addition to handy modern TUI gadgets

### Start From Here

- **Build:** `docker build [--build-arg ...] -t ai-dev[:{tag}] .`
- **Run:** `docker run -it --rm --privileged ai-dev[:{tag}]`

### Build Arguments

Four build args control what goes into the image: `TIER` (cozy preset), `TUI` (interactive/headless tool set), `LANGS` (languages), and `AGENTS` (agents)

`TIER` seeds defaults for the other three; Explicit args merge on top of the tier; `TUI` overrides, `LANGS`/`AGENTS` append, and every list is deduplicated before installation:

| TIER | TUI | LANGS | AGENTS |
| - | - | - | - |
| `full` (default) | 1 | all | all |
| `pro` | 1 | python tsc go rust sql lua clojure lisp zig r | forgecode codex opencode pi crush jcode cline kilo omp |
| `default` | 1 | python tsc go rust sql | forgecode codex opencode pi |
| `lite` | 0 | python tsc | forgecode |
| (empty) | 0 | — | — |

- `TUI={0|1}` — With `1`, the modern interactive tool set is installed; With `0`, only the bare essentials
- `LANGS` — Comma separated language tokens; See `LANGUAGE.md`
- `AGENTS` — Comma separated agents; See `USERAGENT.md`

*Examples*

```sh
docker build -t ai-dev -t ai-dev:full .
docker build --build-arg TIER=lite -t ai-dev:lite . 
docker build --build-arg TIER= -t ai-dev:bare . 
docker build --build-arg TIER=default --build-arg LANGS=lisp,zig -t ai-dev:custom-langs .
docker build --build-arg TIER=default --build-arg AGENTS=crush,cline -t ai-dev:custom-agents . 
docker build --build-arg TIER=lite --build-arg TUI=1 -t ai-dev:lite-tui .
```

*Notes*

1. `perl`, `c`, `c++`, `ruby` and `fortran` are always available; BTW, `ruby` is Homebrew's launcher
2. `js`/`tsc` install a real `bun` + Node.js toolchain; I actually dislike `node`, however, it finally turns out that `bun` is not omnipotent everywhere
3. `java` installs `openjdk` only, while `clojure`/`kotlin` brings `openjdk` along as its dependency; Similar thing happens to `elixir` who bundles `erlang`
4. Agents declare their language dependencies; If interested, read `scripts/resolve-tier.zsh`
5. For convenience, DeepSeek is assumed to be the provider for all agents
