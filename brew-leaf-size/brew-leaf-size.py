#!/usr/bin/env python3
"""Analyze Homebrew disk usage by leaf formula.

A "leaf" formula is an installed formula that no other installed formula
depends on (the same set as `brew leaves`).

For every leaf formula f this tool reports the total size cost of having it
installed:

    total(f) = size(f) + sum(size(d) for d in transitive_deps(f))

Dependencies shared by several leaves are reported separately as duplicated
storage: a dependency d used by k leaves contributes

    duplicated(d) = (k - 1) * size(d)

Dependencies are the runtime ones (`dependencies` + `recommended_dependencies`
from the installed-formula JSON, obtained via `brew info --json=v2 --installed`
with a fallback to `brew list --formula --json=v2`), i.e. what `brew install`
keeps installed; build/test/optional dependencies are excluded.

Sizes are measured with find(1) (-printf %s / %b) over the regular files of each
formula's keg directories under the Cellar. Requires Python 3.7+, Homebrew and
GNU coreutils/findutils (Linux).
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import shutil
import statistics
import subprocess
import sys
from collections import defaultdict
from datetime import datetime
from typing import Any, NoReturn

DEFAULT_TOP = 0  # 0 = show all rows


def fail(message: str) -> NoReturn:
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def run(cmd: list[str], env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, capture_output=True, text=True, env=env)


def human(n: float) -> str:
    """Format a byte count for humans (1024-based)."""
    if n < 1024:
        return f"{n} B"
    value = float(n)
    for unit in ("KiB", "MiB", "GiB", "TiB", "PiB", "EiB"):
        value /= 1024.0
        if value < 1024.0 or unit == "EiB":
            return f"{value:.1f} {unit}"
    return f"{value:.1f} EiB"  # unreachable: the loop always returns on "EiB"


def preview(text: str, limit: int = 300) -> str:
    return repr(text[:limit]) + ("..." if len(text) > limit else "")


def strip_noise(text: str) -> str:
    """brew may print bootstrap output (e.g. its first-run `gem install bundler`)
    to stdout before the JSON; skip everything before the first '{' or '['."""
    positions = [idx for idx in (text.find("{"), text.find("[")) if idx != -1]
    if not positions:
        return text
    return text[min(positions):]


def load_json(text: str) -> Any:
    return json.loads(strip_noise(text))


def report_failures(failures: list[tuple[str, str, str, str]]) -> str:
    lines = []
    for label, reason, stdout, stderr in failures:
        lines.append(f"\n  {label}: {reason}")
        if stdout.strip():
            lines.append(f"    stdout: {preview(stdout)}")
        if stderr.strip():
            lines.append(f"    stderr: {preview(stderr, limit=1000)}")
    return "".join(lines)


def get_brew_info(brew: str) -> dict[str, Any]:
    env = dict(os.environ)
    env["HOMEBREW_NO_AUTO_UPDATE"] = env.get("HOMEBREW_NO_AUTO_UPDATE", "1")
    env["HOMEBREW_NO_ANALYTICS"] = env.get("HOMEBREW_NO_ANALYTICS", "1")
    attempts = (
        ("brew info --json=v2 --installed", [brew, "info", "--json=v2", "--installed"]),
        ("brew list --formula --json=v2", [brew, "list", "--formula", "--json=v2"]),
    )
    failures: list[tuple[str, str, str, str]] = []
    for label, cmd in attempts:
        result = run(cmd, env=env)
        if result.returncode != 0:
            failures.append((label, f"exit code {result.returncode}", result.stdout, result.stderr))
            continue
        try:
            parsed = load_json(result.stdout)
        except json.JSONDecodeError as exc:
            failures.append((label, f"invalid JSON: {exc}", result.stdout, result.stderr))
            continue
        if not isinstance(parsed, dict):
            failures.append((label, "unexpected JSON (not an object)", result.stdout, result.stderr))
            continue
        return parsed
    fail("could not obtain installed-formula data from brew" + report_failures(failures))


def get_cellar(brew: str) -> str:
    result = run([brew, "--cellar"])
    if result.returncode != 0:
        fail("could not determine the Cellar with `brew --cellar`; pass --cellar DIR")
    return result.stdout.strip()


def build_model(info: dict[str, Any]) -> tuple[set[str], dict[str, list[str]], list[str], list[str]]:
    """Return (names, deps, leaves, uninstalled_deps)."""
    formulae = {f["name"]: f for f in info.get("formulae", []) if f.get("name")}
    names = set(formulae)
    deps: dict[str, list[str]] = {}
    for name, formula in formulae.items():
        dependency = set(formula.get("dependencies") or [])
        dependency.update(formula.get("recommended_dependencies") or [])
        deps[name] = sorted(dependency)
    depended_on: set[str] = set()
    for dependency in deps.values():
        depended_on.update(dependency)
    leaves = sorted(name for name in names if name not in depended_on)
    uninstalled = sorted(depended_on - names)
    return names, deps, leaves, uninstalled


def measure_bytes(path: str, blocks: bool) -> int | None:
    """Sum of regular-file sizes under path (GNU find).

    %s = apparent size in bytes; %b = 512-byte blocks allocated.
    """
    fmt = "%b" if blocks else "%s"
    result = run(["find", path, "-type", "f", "-printf", fmt + "\\n"])
    if result.returncode != 0:
        return None
    total = 0
    for token in result.stdout.split():
        try:
            total += int(token)
        except ValueError:
            return None
    return total * 512 if blocks else total


def measure_sizes(cellar: str, names: set[str], blocks: bool, verbose: bool) -> dict[str, int]:
    sizes: dict[str, int] = {}
    for name in names:
        keg = os.path.join(cellar, name)
        if not os.path.isdir(keg):
            if verbose:
                print(f"warning: no keg directory for `{name}` ({keg})", file=sys.stderr)
            sizes[name] = 0
            continue
        total = 0
        versions = 0
        for entry in sorted(os.listdir(keg)):
            path = os.path.join(keg, entry)
            if not os.path.isdir(path):
                continue
            versions += 1
            size = measure_bytes(path, blocks)
            if size is None:
                if verbose:
                    print(f"warning: could not measure size of {path}", file=sys.stderr)
                size = 0
            total += size
        if versions == 0 and verbose:
            print(f"warning: no version directories under {keg}", file=sys.stderr)
        sizes[name] = total
    return sizes


def compute_closures(
    leaves: list[str], deps: dict[str, list[str]], names: set[str]
) -> dict[str, set[str]]:
    """Transitive (runtime) dependency set of every leaf, installed ones only."""
    closures: dict[str, set[str]] = {}
    for leaf in leaves:
        seen: set[str] = set()
        stack = list(deps.get(leaf, ()))
        while stack:
            dep = stack.pop()
            if dep in seen or dep not in names:
                continue
            seen.add(dep)
            stack.extend(deps.get(dep, ()))
        closures[leaf] = seen
    return closures


def leaf_stats(
    leaves: list[str], sizes: dict[str, int], closures: dict[str, set[str]]
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for leaf in leaves:
        dep_set = closures[leaf]
        rows.append({
            "name": leaf,
            "own": sizes.get(leaf, 0),
            "deps": len(dep_set),
            "total": sizes.get(leaf, 0) + sum(sizes.get(d, 0) for d in dep_set),
        })
    rows.sort(key=lambda r: (-r["total"], r["name"]))
    return rows


def shared_stats(
    leaves: list[str], sizes: dict[str, int], closures: dict[str, set[str]]
) -> list[dict[str, Any]]:
    users: defaultdict[str, list[str]] = defaultdict(list)
    for leaf in leaves:
        for dep in closures[leaf]:
            users[dep].append(leaf)
    rows: list[dict[str, Any]] = []
    for dep, user_list in users.items():
        if len(user_list) < 2:
            continue
        size = sizes.get(dep, 0)
        rows.append({
            "name": dep,
            "size": size,
            "leaves": sorted(user_list),
            "leaf_count": len(user_list),
            "duplicated": (len(user_list) - 1) * size,
        })
    rows.sort(key=lambda r: (-r["duplicated"], r["name"]))
    return rows


def summarize(
    leaf_rows: list[dict[str, Any]],
    shared_rows: list[dict[str, Any]],
    sizes: dict[str, int],
    names: set[str],
    leaves: list[str],
) -> dict[str, Any]:
    total_installed = sum(sizes.values())
    sum_leaf_totals = sum(r["total"] for r in leaf_rows)
    duplicated = sum(r["duplicated"] for r in shared_rows)
    totals = [r["total"] for r in leaf_rows]
    return {
        "installed_formulae": len(names),
        "leaf_formulae": len(leaves),
        "total_installed_bytes": total_installed,
        "sum_leaf_totals_bytes": sum_leaf_totals,
        "duplicated_bytes": duplicated,
        "duplication_percent": (duplicated / sum_leaf_totals * 100.0) if sum_leaf_totals else 0.0,
        "leaf_total_min_bytes": min(totals) if totals else 0,
        "leaf_total_median_bytes": statistics.median(totals) if totals else 0,
        "leaf_total_mean_bytes": statistics.mean(totals) if totals else 0,
        "leaf_total_max_bytes": max(totals) if totals else 0,
    }


def distribution(leaf_rows: list[dict[str, Any]]) -> list[tuple[str, int]]:
    buckets = (
        (0, 10 * 1024 ** 2, "<10 MiB"),
        (10 * 1024 ** 2, 100 * 1024 ** 2, "10-100 MiB"),
        (100 * 1024 ** 2, 1024 ** 3, "100 MiB-1 GiB"),
        (1024 ** 3, 10 * 1024 ** 3, "1-10 GiB"),
        (10 * 1024 ** 3, None, ">=10 GiB"),
    )
    out: list[tuple[str, int]] = []
    for low, high, label in buckets:
        count = sum(
            1 for r in leaf_rows
            if low <= r["total"] < (high if high is not None else float("inf"))
        )
        if count:
            out.append((label, count))
    return out


def render_table(headers: list[str], rows: list[list[str]], aligns: list[str]) -> str:
    widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(cell))
    lines = [
        "  ".join(f"{h:{a}{w}}" for h, a, w in zip(headers, aligns, widths)).rstrip(),
        "  ".join("-" * w for w in widths),
    ]
    for row in rows:
        lines.append("  ".join(f"{c:{a}{w}}" for c, a, w in zip(row, aligns, widths)).rstrip())
    return "\n".join(lines)


def print_human(
    args: argparse.Namespace,
    cellar: str,
    leaf_rows: list[dict[str, Any]],
    shared_rows: list[dict[str, Any]],
    summary: dict[str, Any],
) -> None:
    s = summary
    print("Homebrew leaf-formula size analysis")
    print(f"  brew   : {args.brew}")
    print(f"  cellar : {cellar}")
    print(f"  size   : {'allocated disk blocks (find -printf %b)' if args.blocks else 'apparent file size (find -printf %s)'}")
    print(f"  data   : {args.data if args.data else 'live `brew info --json=v2 --installed`'}")
    print()
    print(f"Installed formulae : {s['installed_formulae']}")
    print(f"Leaf formulae      : {s['leaf_formulae']}")
    print(f"Total installed    : {human(s['total_installed_bytes'])}  (union of all formulae, no duplication)")
    print(f"Sum of leaf totals : {human(s['sum_leaf_totals_bytes'])}  (each leaf counted with its transitive dependencies)")
    print(f"Duplication        : {human(s['duplicated_bytes'])}  ({s['duplication_percent']:.1f}% of leaf totals)")
    print()
    parts = [
        f"min {human(s['leaf_total_min_bytes'])}",
        f"median {human(s['leaf_total_median_bytes'])}",
        f"mean {human(s['leaf_total_mean_bytes'])}",
        f"max {human(s['leaf_total_max_bytes'])}",
    ]
    print("Leaf totals: " + " | ".join(parts))
    dist = distribution(leaf_rows)
    print("Leaf total distribution: " + " | ".join(f"{label}: {count}" for label, count in dist))
    print()

    limit = args.top if args.top > 0 else len(leaf_rows)
    shown = min(limit, len(leaf_rows))
    if shown == len(leaf_rows):
        heading = f"Per-leaf size (own size + transitive dependencies), all {len(leaf_rows)} leaves:"
    else:
        heading = f"Per-leaf size (own size + transitive dependencies), top {shown} of {len(leaf_rows)} leaves:"
    print(heading)
    rows = [
        [str(i), human(r["total"]), human(r["own"]), str(r["deps"]), r["name"]]
        for i, r in enumerate(leaf_rows[:shown], 1)
    ]
    print(render_table(["#", "total", "own", "deps", "leaf"], rows, [">", ">", ">", ">", "<"]))
    print()

    if not shared_rows:
        print("No shared dependencies (every dependency is used by at most one leaf).")
        return
    limit = args.top if args.top > 0 else len(shared_rows)
    shown = min(limit, len(shared_rows))
    if shown == len(shared_rows):
        heading = f"Shared dependencies (used by >= 2 leaves), all {len(shared_rows)}:"
    else:
        heading = f"Shared dependencies (used by >= 2 leaves), top {shown} of {len(shared_rows)}:"
    print(heading)
    rows = [
        [str(i), human(r["duplicated"]), human(r["size"]), str(r["leaf_count"]),
         r["name"], ", ".join(r["leaves"])]
        for i, r in enumerate(shared_rows[:shown], 1)
    ]
    print(render_table(
        ["#", "duplicated", "size", "leaves", "formula", "shared by"],
        rows,
        [">", ">", ">", ">", "<", "<"],
    ))
    print()
    diff = human(summary["sum_leaf_totals_bytes"] - summary["total_installed_bytes"])
    print(f"Sanity check: sum of leaf totals - total installed = {diff} = total duplication above")


def report_json(
    args: argparse.Namespace,
    cellar: str,
    sizes: dict[str, int],
    leaf_rows: list[dict[str, Any]],
    shared_rows: list[dict[str, Any]],
    closures: dict[str, set[str]],
    summary: dict[str, Any],
) -> dict[str, Any]:
    return {
        "brew": args.brew,
        "cellar": cellar,
        "size_mode": "blocks" if args.blocks else "apparent",
        "data": args.data if args.data else "brew info --json=v2 --installed",
        "measured_at": datetime.now().isoformat(timespec="seconds"),
        "summary": summary,
        "sizes": {name: sizes[name] for name in sorted(sizes)},
        "leaves": [
            {
                "name": r["name"],
                "own_size": r["own"],
                "dep_count": r["deps"],
                "deps": sorted(closures[r["name"]]),
                "total_size": r["total"],
            }
            for r in leaf_rows
        ],
        "shared": [
            {
                "name": r["name"],
                "size": r["size"],
                "leaf_count": r["leaf_count"],
                "leaves": r["leaves"],
                "duplicated": r["duplicated"],
            }
            for r in shared_rows
        ],
    }


def write_csv(outdir: str, leaf_rows: list[dict[str, Any]], shared_rows: list[dict[str, Any]]) -> None:
    os.makedirs(outdir, exist_ok=True)
    with open(os.path.join(outdir, "leaves.csv"), "w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(["leaf", "own_size_bytes", "dep_count", "total_size_bytes"])
        for r in leaf_rows:
            writer.writerow([r["name"], r["own"], r["deps"], r["total"]])
    with open(os.path.join(outdir, "shared.csv"), "w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(["formula", "size_bytes", "leaf_count", "duplicated_bytes", "leaves"])
        for r in shared_rows:
            writer.writerow([r["name"], r["size"], r["leaf_count"], r["duplicated"], ";".join(r["leaves"])])


def main() -> int:
    parser = argparse.ArgumentParser(
        description=("Analyze Homebrew disk usage per leaf formula: total size per leaf "
                     + "(own size + transitive dependencies) and duplicated storage of "
                     + "shared dependencies."),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    _ = parser.add_argument("--brew", default="brew", help="path to the brew executable")
    _ = parser.add_argument("--cellar", default=None, metavar="DIR",
                            help="Cellar directory (default: output of `brew --cellar`)")
    _ = parser.add_argument("--data", default=None, metavar="FILE",
                            help="read saved `brew info --json=v2 --installed` output (or "
                            + "`brew list --formula --json=v2`) from FILE instead of invoking brew")
    _ = parser.add_argument("--blocks", action="store_true",
                            help="measure allocated disk blocks (find -printf) instead of apparent file size (find -printf")
    _ = parser.add_argument("--top", type=int, default=DEFAULT_TOP, metavar="N",
                            help="show at most N rows of each table (0 = all rows; default: all)")
    _ = parser.add_argument("--json", action="store_true",
                            help="print a machine-readable JSON report instead of tables")
    _ = parser.add_argument("--csv", default=None, metavar="DIR",
                            help="also write leaves.csv and shared.csv into DIR")
    _ = parser.add_argument("--verbose", "-v", action="store_true",
                            help="warn about missing keg directories and other oddities")
    args = parser.parse_args()

    have_brew = shutil.which(args.brew) is not None
    if not args.data and not have_brew:
        fail(f"cannot find `{args.brew}` on PATH; is Homebrew installed? "
             + "(for offline analysis pass --data FILE --cellar DIR)")

    if args.data:
        try:
            with open(args.data, encoding="utf-8") as fh:
                info: dict[str, Any] = load_json(fh.read())
        except OSError as exc:
            fail(f"cannot read --data file: {exc}")
        except json.JSONDecodeError as exc:
            fail(f"--data file is not valid JSON: {exc}")
    else:
        info = get_brew_info(args.brew)

    names, deps, leaves, uninstalled = build_model(info)
    if not names:
        fail("no formulae found; is the data from `brew info --json=v2 --installed`?")
    if not leaves:
        print("no leaf formulae found; nothing to analyze", file=sys.stderr)
        return 0

    if args.cellar:
        cellar = args.cellar
    else:
        cellar = get_cellar(args.brew)

    sizes = measure_sizes(cellar, names, args.blocks, args.verbose)
    closures = compute_closures(leaves, deps, names)
    leaf_rows = leaf_stats(leaves, sizes, closures)
    shared_rows = shared_stats(leaves, sizes, closures)
    summary = summarize(leaf_rows, shared_rows, sizes, names, leaves)

    if uninstalled:
        print(f"note: {len(uninstalled)} dependencies reference formulae that are not installed "
              + f"({', '.join(uninstalled)}); their size is excluded from leaf totals",
              file=sys.stderr)

    if args.json:
        print(json.dumps(report_json(args, cellar, sizes, leaf_rows, shared_rows, closures, summary), indent=2))
    else:
        print_human(args, cellar, leaf_rows, shared_rows, summary)

    if args.csv:
        write_csv(args.csv, leaf_rows, shared_rows)
        print(f"wrote {os.path.join(args.csv, 'leaves.csv')} and {os.path.join(args.csv, 'shared.csv')}",
              file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
