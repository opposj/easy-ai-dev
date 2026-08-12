#!/usr/bin/env python3
"""Validate brew-leaf-size.py output on the fake dataset.

Expected values (hand-computed):

  sizes:  f1=10, fn=20, d1=7 (5+2 across two versions), d2=3, d3=7,
          f2=100, empty=0      -> union = 147
  leaves: f1, fn, f2, empty    (d1, d2, d3 are depended upon; "ghost" is
          listed as a dep of f1 but not installed and must be excluded)
  closures:
    f1 -> {d1, d2}             total = 10 + 7 + 3      = 20
    fn -> {d1, d2, d3}         total = 20 + 7 + 3 + 7  = 37
    f2 -> {d3} (recommended)   total = 100 + 7         = 107
    empty -> {}                total = 0
  sum of leaf totals = 164  ->  duplicated = 164 - 147 = 17
  shared: d1 (f1,fn) 7 | d2 (f1,fn) 3 | d3 (fn,f2) 7
"""
import json
import sys

d = json.load(sys.stdin)
s = d["summary"]

assert s["installed_formulae"] == 7, s
assert s["leaf_formulae"] == 4, s
assert s["total_installed_bytes"] == 147, s
assert s["sum_leaf_totals_bytes"] == 164, s
assert s["duplicated_bytes"] == 17, s
assert abs(s["duplication_percent"] - 17 / 164 * 100) < 1e-6, s
assert s["leaf_total_min_bytes"] == 0 and s["leaf_total_max_bytes"] == 107, s
assert abs(s["leaf_total_median_bytes"] - 28.5) < 1e-9, s
assert abs(s["leaf_total_mean_bytes"] - 41.0) < 1e-9, s

sizes = d["sizes"]
assert sizes["f1"] == 10 and sizes["fn"] == 20, sizes
assert sizes["d1"] == 7 and sizes["d2"] == 3 and sizes["d3"] == 7, sizes
assert sizes["f2"] == 100 and sizes["empty"] == 0, sizes

leaves = {r["name"]: r for r in d["leaves"]}
assert set(leaves) == {"f1", "fn", "f2", "empty"}, leaves
assert leaves["f1"]["total_size"] == 20 and leaves["f1"]["dep_count"] == 2, leaves["f1"]
assert set(leaves["f1"]["deps"]) == {"d1", "d2"}, leaves["f1"]  # "ghost" excluded
assert leaves["fn"]["total_size"] == 37 and leaves["fn"]["dep_count"] == 3, leaves["fn"]
assert set(leaves["fn"]["deps"]) == {"d1", "d2", "d3"}, leaves["fn"]
assert leaves["f2"]["total_size"] == 107 and leaves["f2"]["dep_count"] == 1, leaves["f2"]
assert set(leaves["f2"]["deps"]) == {"d3"}, leaves["f2"]  # recommended dep included
assert leaves["empty"]["total_size"] == 0 and leaves["empty"]["dep_count"] == 0, leaves["empty"]

shared = {r["name"]: r for r in d["shared"]}
assert set(shared) == {"d1", "d2", "d3"}, shared
assert shared["d1"]["duplicated"] == 7 and shared["d1"]["leaf_count"] == 2, shared["d1"]
assert set(shared["d1"]["leaves"]) == {"f1", "fn"}, shared["d1"]
assert shared["d2"]["duplicated"] == 3 and shared["d2"]["leaf_count"] == 2, shared["d2"]
assert set(shared["d2"]["leaves"]) == {"f1", "fn"}, shared["d2"]
assert shared["d3"]["duplicated"] == 7 and shared["d3"]["leaf_count"] == 2, shared["d3"]
assert set(shared["d3"]["leaves"]) == {"fn", "f2"}, shared["d3"]

print("ALL CHECKS PASSED")
