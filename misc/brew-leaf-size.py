#!/usr/bin/env python3
"""Report Homebrew disk usage per leaf formula.

A "leaf" formula is installed but depended on by nothing else (brew leaves).
For each leaf we print its own size plus its transitive runtime dependencies
(i.e. what it costs to keep that leaf installed), and separately how much disk
is duplicated because several leaves share the same dependency.

Run with no arguments:  python3 brew-leaf-size.py

Requires Linux Homebrew, Python 3.7+, and GNU findutils (Ubuntu base image).
"""

import json
import os
import statistics
import subprocess
import sys
from collections import defaultdict


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def run(cmd, env=None) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, env=env)


def human(n: float) -> str:
    """Format byte counts as human-readable sizes (1024-based)."""
    for unit in ("B", "KiB", "MiB", "GiB", "TiB", "PiB"):
        if n < 1024 or unit == "PiB":
            return f"{int(n)} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1024.0


def strip_noise(text: str) -> str:
    """brew may print bootstrap output before the JSON; skip to the first { or [."""
    starts = [i for i in (text.find("{"), text.find("[")) if i != -1]
    return text[min(starts):] if starts else text


def brew_info() -> dict:
    """Installed-formula JSON from brew (auto-update/analytics noise off)."""
    env = dict(os.environ, HOMEBREW_NO_AUTO_UPDATE="1", HOMEBREW_NO_ANALYTICS="1")
    for label, cmd in (
        ("brew info --json=v2 --installed", ["brew", "info", "--json=v2", "--installed"]),
        ("brew list --formula --json=v2", ["brew", "list", "--formula", "--json=v2"]),
    ):
        r = run(cmd, env=env)
        if r.returncode == 0:
            return json.loads(strip_noise(r.stdout))
        print(f"warning: {label} failed: {r.stderr.strip()}", file=sys.stderr)
    fail("could not obtain installed-formula data from brew")


def build_model(info: dict) -> tuple:
    """Return (names, deps, leaves) from the brew JSON.

    deps are the runtime ones (dependencies + recommended_dependencies);
    build/test/optional deps are not kept installed and are excluded.
    """
    formulae = {f["name"]: f for f in info.get("formulae", []) if f.get("name")}
    names = set(formulae)
    deps = {}
    for name, f in formulae.items():
        d = set(f.get("dependencies") or []) | set(f.get("recommended_dependencies") or [])
        deps[name] = sorted(d)
    depended_on = {d for deps_list in deps.values() for d in deps_list}
    leaves = sorted(names - depended_on)
    return names, deps, leaves


def measure_sizes(cellar: str, names: set) -> dict:
    """Sum of regular-file sizes under each formula's keg dirs (GNU find -printf %s)."""
    sizes = {}
    for name in names:
        keg = os.path.join(cellar, name)
        total = 0
        if os.path.isdir(keg):
            for version in os.listdir(keg):
                r = run(["find", os.path.join(keg, version), "-type", "f", "-printf", "%s\n"])
                if r.returncode == 0:
                    total += sum(int(t) for t in r.stdout.split() if t.isdigit())
        sizes[name] = total
    return sizes


def closures(leaves: list, deps: dict, names: set) -> dict:
    """Transitive runtime dependency set of every leaf (installed ones only)."""
    out = {}
    for leaf in leaves:
        seen, stack = set(), list(deps.get(leaf, ()))
        while stack:
            dep = stack.pop()
            if dep in names and dep not in seen:
                seen.add(dep)
                stack += deps.get(dep, ())
        out[leaf] = seen
    return out


def format_table(headers, rows, aligns) -> str:
    widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(cell))
    lines = ["  ".join(f"{c:{a}{w}}" for c, a, w in zip(r, aligns, widths)).rstrip()
             for r in [headers] + rows]
    lines.insert(1, "  ".join("-" * w for w in widths))
    return "\n".join(lines)


def main() -> int:
    info = brew_info()
    names, deps, leaves = build_model(info)
    if not leaves:
        print("no leaf formulae found; nothing to analyze", file=sys.stderr)
        return 0

    cellar = run(["brew", "--cellar"]).stdout.strip()
    sizes = measure_sizes(cellar, names)
    cl = closures(leaves, deps, names)

    # Per-leaf cost = own size + all transitive deps (each dep counted once per leaf).
    leaf_rows = []
    for leaf in leaves:
        dep_set = cl[leaf]
        leaf_rows.append({
            "name": leaf, "own": sizes[leaf], "deps": len(dep_set),
            "total": sizes[leaf] + sum(sizes[d] for d in dep_set),
        })
    leaf_rows.sort(key=lambda r: (-r["total"], r["name"]))

    # Shared dependencies: a dep used by k leaves duplicates (k-1) * its size.
    users = defaultdict(list)
    for leaf in leaves:
        for dep in cl[leaf]:
            users[dep].append(leaf)
    shared = []
    for dep, user_list in users.items():
        if len(user_list) > 1:
            shared.append({
                "name": dep, "size": sizes[dep], "leaves": sorted(user_list),
                "duplicated": (len(user_list) - 1) * sizes[dep],
            })
    shared.sort(key=lambda r: (-r["duplicated"], r["name"]))

    total_installed = sum(sizes.values())
    sum_leaf_totals = sum(r["total"] for r in leaf_rows)
    duplicated = sum(r["duplicated"] for r in shared)
    totals = [r["total"] for r in leaf_rows]

    print("Homebrew leaf-formula size analysis")
    print(f"  brew   : brew")
    print(f"  cellar : {cellar}")
    print(f"  size   : apparent file size (GNU find -printf %s)")
    print()
    print(f"Installed formulae : {len(names)}")
    print(f"Leaf formulae      : {len(leaves)}")
    print(f"Total installed    : {human(total_installed)}  (union of all formulae)")
    print(f"Sum of leaf totals : {human(sum_leaf_totals)}  (each leaf + its transitive deps)")
    print(f"Duplication        : {human(duplicated)}  ({duplicated / sum_leaf_totals * 100:.1f}% of leaf totals)")
    print()
    print("Leaf totals: "
          f"min {human(min(totals))} | median {human(statistics.median(totals))} | "
          f"mean {human(statistics.mean(totals))} | max {human(max(totals))}")
    print()

    rows = [[str(i), human(r["total"]), human(r["own"]), str(r["deps"]), r["name"]]
            for i, r in enumerate(leaf_rows, 1)]
    print(f"Per-leaf size (own size + transitive dependencies), all {len(leaf_rows)} leaves:")
    print(format_table(["#", "total", "own", "deps", "leaf"], rows, [">", ">", ">", ">", "<"]))
    print()

    rows = [[str(i), human(r["duplicated"]), human(r["size"]), str(len(r["leaves"])),
             r["name"], ", ".join(r["leaves"])]
            for i, r in enumerate(shared, 1)]
    print(f"Shared dependencies (used by >= 2 leaves), all {len(shared)}:")
    print(format_table(["#", "duplicated", "size", "leaves", "formula", "shared by"], rows,
                       [">", ">", ">", ">", "<", "<"]))
    print()
    print(f"Sanity check: sum of leaf totals - total installed = "
          f"{human(sum_leaf_totals - total_installed)} = total duplication above")
    return 0


if __name__ == "__main__":
    sys.exit(main())
