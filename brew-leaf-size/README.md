# brew-leaf-size

Analyzes Homebrew disk usage **by leaf formula** on Linux with Homebrew
(Linuxbrew), e.g. inside the `ai-dev` container.

A **leaf formula** is an installed formula that no other installed formula
depends on — the same set as `brew leaves`.

## What it computes

For every leaf formula `f`:

```
total(f) = size(f) + sum(size(d) for d in transitive_deps(f))
```

i.e. what it would cost to have `f` installed on its own, including everything
it pulls in (own size plus each transitive dependency, counted once per leaf).

Dependencies shared by several leaves are reported separately as **duplicated
storage**: a dependency `d` used by `k` leaves contributes

```
duplicated(d) = (k - 1) * size(d)
```

Invariant (printed as a sanity check):

```
sum of leaf totals  -  total installed (union)  =  sum of duplicated(d)
```

Example: `f1` and `fn` both depend on `f1_d1`. `f1_d1` is then shared by 2
leaves, so its duplicated size is `(2 - 1) * size(f1_d1)`.

## Requirements

- Linux with Homebrew installed (`/home/linuxbrew/.linuxbrew` is typical)
- Python 3.7+ (Ubuntu base image ships it)
- GNU coreutils / findutils (preinstalled on Ubuntu)

No other dependencies — standard library only.

## Usage

```sh
python3 brew-leaf-size.py
```

On a machine where `brew` is not on `PATH`:

```sh
python3 brew-leaf-size.py --brew /home/linuxbrew/.linuxbrew/bin/brew
```

Inside the container:

```sh
docker run -it --rm --privileged \
  -v "$PWD/brew-leaf-size:/tools/brew-leaf-size" \
  ai-dev python3 /tools/brew-leaf-size/brew-leaf-size.py
```

### Options

| Option | Meaning |
| --- | --- |
| `--brew PATH` | brew executable (default: `brew` on PATH) |
| `--cellar DIR` | Cellar directory (default: output of `brew --cellar`) |
| `--data FILE` | Use saved `brew info --json=v2 --installed` output (or `brew list --formula --json=v2`) instead of invoking brew — offline mode; combine with `--cellar` |
| `--blocks` | Measure allocated disk blocks (`find -printf %b`, 512-byte units) instead of apparent file size (`find -printf %s`) |
| `--top N` | Show at most N rows per table (default: all rows) |
| `--json` | Print a machine-readable JSON report instead of tables |
| `--csv DIR` | Also write `leaves.csv` and `shared.csv` into DIR (always full data) |
| `-v` | Warn about missing keg directories and other oddities |

Offline analysis (JSON saved on the target machine, analyzed anywhere):

```sh
brew info --json=v2 --installed > brew-info.json
python3 brew-leaf-size.py --data brew-info.json \
  --cellar /home/linuxbrew/.linuxbrew/Cellar
```

For further statistical work:

```sh
python3 brew-leaf-size.py --json > report.json
python3 brew-leaf-size.py --csv ./csv --top 0
```

## Example output

Illustrative (from the fake test dataset):

```
Homebrew leaf-formula size analysis
  brew   : brew
  cellar : .../Cellar
  size   : apparent file size (find -printf %s)
  data   : live `brew info --json=v2 --installed`

Installed formulae : 7
Leaf formulae      : 4
Total installed    : 147 B  (union of all formulae, no duplication)
Sum of leaf totals : 164 B  (each leaf counted with its transitive dependencies)
Duplication        : 17 B   (10.4% of leaf totals)

Leaf totals: min 0 B | median 28.5 B | mean 41.0 B | max 107 B
Leaf total distribution: <10 MiB: 4

Per-leaf size (own size + transitive dependencies), all 4 leaves:
  #    total   own  deps  leaf
  1   107 B  100 B     1  f2
  2    37 B   20 B     3  fn
  3    20 B   10 B     2  f1
  4     0 B    0 B     0  empty

Shared dependencies (used by >= 2 leaves), all 3:
  #  duplicated  size  leaves  formula  shared by
  1        7 B   7 B       2  d1       f1, fn
  2        7 B   7 B       2  d3       fn, f2
  3        3 B   3 B       2  d2       f1, fn

Sanity check: sum of leaf totals - total installed = 17 B = total duplication above
```

## Semantics and caveats

- **Dependencies** are the runtime ones — `dependencies` + `recommended_dependencies`
  from the installed-formula JSON — i.e. what `brew install` keeps installed.
  The tool obtains that JSON via `brew info --json=v2 --installed` (fallback:
  `brew list --formula --json=v2`). Build/test/optional dependencies are
  excluded (they are not kept installed unless something else needs them).
  Note: brew may print bootstrap output to stdout before the JSON (e.g. its
  first-run `gem install bundler`); the tool skips anything before the JSON,
  both for live runs and `--data` files.
- **Sizes** are the sum of regular-file sizes in each formula's keg directories
  under the Cellar, measured with GNU `find -printf %s` per installed version
  (all versions summed; `--blocks` uses `%b`, allocated 512-byte blocks, to get
  real disk usage). Symlinks under `opt`, `bin`, etc. cost nothing and are not
  counted. Data written to `var`/`etc` by formulae at runtime is not counted.
- Only formulae are analyzed, not casks.
- A dependency that references a formula which is not installed is excluded
  from totals and reported on stderr.

## Tests

The test suite runs the analyzer against a fake brew dataset with
hand-computed expected values (including multi-version kegs, recommended
deps, an uninstalled dependency, and an empty formula):

```sh
bash test/run_tests.sh
```
