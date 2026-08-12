#!/usr/bin/env bash
# Tests for brew-leaf-size.py using a fake `brew info` file and a fake Cellar.
# Run on Linux (or WSL):  bash test/run_tests.sh
set -euo pipefail
cd "$(dirname "$0")/.."

CELLAR="$PWD/test/fake_cellar"
rm -rf "$CELLAR"
mkdir -p \
  "$CELLAR/f1/1.0" \
  "$CELLAR/fn/1.0" \
  "$CELLAR/d1/1.0" "$CELLAR/d1/1.1" \
  "$CELLAR/d2/1.0" \
  "$CELLAR/d3/1.0" \
  "$CELLAR/f2/1.0"

head -c 10 /dev/zero > "$CELLAR/f1/1.0/a"
head -c 20 /dev/zero > "$CELLAR/fn/1.0/x"
head -c 5  /dev/zero > "$CELLAR/d1/1.0/b"
head -c 2  /dev/zero > "$CELLAR/d1/1.1/c"
head -c 3  /dev/zero > "$CELLAR/d2/1.0/d"
head -c 7  /dev/zero > "$CELLAR/d3/1.0/e"
head -c 100 /dev/zero > "$CELLAR/f2/1.0/f"

DATA="$PWD/test/fake_data/brew_info.json"

echo "== apparent-size analysis (json mode) =="
python3 brew-leaf-size.py --data "$DATA" --cellar "$CELLAR" --json \
  > /tmp/brew_leaf_out.json 2> /tmp/brew_leaf_err.log
python3 test/check.py < /tmp/brew_leaf_out.json
grep -q "ghost" /tmp/brew_leaf_err.log && echo "PASS: uninstalled dependency noted on stderr"

echo "== human tables =="
python3 brew-leaf-size.py --data "$DATA" --cellar "$CELLAR" --top 0 | tee /tmp/brew_leaf_human.txt
grep -q "Shared dependencies" /tmp/brew_leaf_human.txt
grep -q "Sanity check" /tmp/brew_leaf_human.txt

echo "== blocks mode smoke test =="
python3 brew-leaf-size.py --data "$DATA" --cellar "$CELLAR" --blocks --json > /tmp/brew_leaf_blocks.json
python3 -c 'import json; d = json.load(open("/tmp/brew_leaf_blocks.json")); assert d["summary"]["total_installed_bytes"] > 0; print("PASS: blocks mode produced a positive total")'

echo "== csv mode =="
rm -rf /tmp/brew_leaf_csv
python3 brew-leaf-size.py --data "$DATA" --cellar "$CELLAR" --csv /tmp/brew_leaf_csv --top 0 > /dev/null
test -s /tmp/brew_leaf_csv/leaves.csv && test -s /tmp/brew_leaf_csv/shared.csv && echo "PASS: csv files written"

echo "ALL TESTS PASSED"
