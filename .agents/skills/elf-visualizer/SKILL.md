---
name: elf-visualizer
description: Analyze an ELF binary and generate a self-contained HTML visualization of its on-disk file layout and runtime memory layout, including byte-level grids showing real byte values.
---

# ELF Visualizer

Produce an interactive HTML page that shows an ELF binary's structure in two ways:

1. **File view** — a vertical stack (by file offset) plus a byte-by-byte grid where each cell is one byte showing its real hex value, color-coded by section.
2. **Memory view** — a vertical stack (by virtual address) plus a byte-by-byte grid showing what each address holds after load (file-backed bytes vs zero-fill vs unmapped), verified against `/proc/self/maps`.

## When to use
- The user asks to "visualize", "draw", "break down", or "show the structure of" an ELF executable, object file, or shared library.
- Teaching or debugging linkers/loaders, section vs segment mapping, NOBITS/BSS, RELRO, page alignment, or W^X.

## Supporting files (in this skill directory)
- `template.html` — data-driven visualization. Fill in three JS arrays (`SECTIONS`, `SEGMENTS`, `PROCESS`) plus a few scalars; annotations and both byte grids render automatically (descriptions are generated from section `type`/`flags`, not hard-coded prose).
- `extract_bytes.ps1` — generates `elf_bytes.js` (the exact binary bytes) from a binary on disk.
- `dump_elf.sh` — runs readelf/objdump/gdb inside the `ai-dev` container.

## Workflow

### 1. Obtain the binary
- If a source file exists (e.g. `write_example.zig`), build it inside the `ai-dev` container (see "Container notes").
- Otherwise locate the existing ELF file.

### 2. Extract structure (authoritative data)
Run `dump_elf.sh` in the container and capture:
- `readelf -h` → entry point, phdr/shdr counts.
- `readelf -lW` → program headers (LOAD segments, perms, file/mem sizes, align) → drives `SEGMENTS` (page-aligned ranges + permissions).
- `readelf -SW` → section headers (name, address, offset, size, flags) → drives `SECTIONS` (each section's file range and virtual address).
- `readelf -x .rodata` / `objdump -s` → data bytes for annotations.
- `objdump -d | rg syscall` → key instructions for annotations.
- `gdb -batch -ex 'starti' -ex 'info proc mappings'` → **authoritative** runtime memory map. Do NOT rely only on header math — page rounding and gaps (e.g. the RELRO→.bss hole) are easy to miss.

### 3. Extract exact bytes (on the host, PowerShell)
```
pwsh -File .agents/skills/elf-visualizer/extract_bytes.ps1 -Binary .\write_example -Out .\elf_bytes.js
```
This writes `window.ELF_HEX = "..."` (2 hex chars per byte). Never paste the hex through an edit/diff tool — large inline hex can trip diff/transport limits. Generating the file from the binary on disk avoids this entirely.

### 4. Fill the template
Copy `template.html` into the working directory next to `elf_bytes.js`, then edit the three data arrays near the top of its `<script>`:
- `SECTIONS` — one entry per section (or file region such as the headers): `{ name, from, to, addr, size, color, type, flags }`. `from`/`to` are inclusive file offsets; for NOBITS sections set both to `null` and give `size` instead. `addr` is the section's virtual address (`0`/`null` means it is not loaded — e.g. `.comment`, `.shstrtab`, and the section-header table). `type` is the ELF section type (`PROGBITS`, `NOBITS`, `STRTAB`, ...) or `"header"`; `flags` is the flags string (`AX`, `A`, `W`, `MS`, ...). File-backed entries MUST tile the whole file — `0x0000` through `filesize − 1` — with no gaps or overlap; any uncovered bytes are auto-labeled "Padding".
- `SEGMENTS` — one entry per LOAD segment, page-aligned: `{ perm, vaddr, memsz }` from `readelf -lW`. Used only to classify memory as file-backed / zero-fill / unmapped and to attach permissions.
- `PROCESS` — process-level regions beyond the program image: the TLS template (`.tbss`), the GOT, the call stack, and the kernel `[vvar]`/`[vdso]` mappings. One entry each: `{ name, vaddr, size, perm, color, desc }` (`size: 0` for an empty region like an unused `.got`; an optional `note` overrides the computed address label, e.g. a TLS template that is declared but not mapped). These render as an extra stack under the memory view, with a gap marker between the low program-adjacent addresses and the high stack/kernel addresses. Get stack/vDSO/vvar addresses from `gdb -ex 'info proc mappings'` (and `p/x $fs_base` to check whether a TLS block exists) — they are ASLR-randomized and change every run, so record them per run rather than guessing.

Also set the scalars `BINARY_NAME`, `FILESIZE`, `ENTRY`, `MEM_BASE`, `MEM_SIZE` (bytes of address space to render), and optional `META`. Everything else (vertical stacks, annotations, legends, both byte grids, and the loaded/NOBITS summary note) renders automatically.

### 5. Verify and open
- Open the HTML in a browser. Spot-check the byte grid against `readelf` offsets (ELF magic `7f 45 4c 46`, section boundaries, `.text` entry).
- Cross-check the memory view against the gdb `/proc/self/maps` output (perm bits and the unmapped gap).
- Confirm the file-view segments are contiguous and non-overlapping: the first `from` is `0x0000`, each `from` equals the previous `to + 1`, and the last `to` equals `filesize − 1` (e.g. `0x1337` for 4920 bytes). This catches mislabeled ranges and unexplained gaps.

## Container notes (`ai-dev`)
- The image entrypoint is a zsh wrapper (`exec "$@"`), so pass the interpreter explicitly:
  ```
  docker run --rm -v "${PWD}:/workspace" ai-dev:latest /home/linuxbrew/.linuxbrew/bin/zsh <script>
  ```
- **Always mount the working dir** (`-v "${PWD}:/workspace"`) so binaries and artifacts survive container shutdown. This was a real data-loss failure mode.
- zig output name uses `--name`, not `-o`; strip symbols with `-fstrip`:
  ```
  zig build-exe -O ReleaseSmall -fstrip --name write_example write_example.zig
  ```
- Write multi-line inspection commands to a `.sh` file in the mounted dir, strip CRLF with `sed -i 's/\r$//'`, then execute by path. Avoid complex inline `-c "..."` — PowerShell→zsh→docker quoting mangles it.

## Pitfalls (from retrospective)
1. **Ephemeral container data loss** → always mount a volume.
2. **Quoting mangle** → use script files, not inline `-c`.
3. **CRLF in scripts** → `sed -i 's/\r$//'` before running.
4. **Giant hex in diffs** → generate `elf_bytes.js` from the binary; never paste hex inline.
5. **Fixed annotation heights overlap** → let annotations size naturally and scroll the column.
6. **Header-only memory math** → confirm with gdb `info proc mappings`.
7. **Gaps and mislabeled ranges in the file view** → the file layout must tile the entire file byte-for-byte; a region that "looks" like padding can actually be the tail of the program-header table (e.g. `9 × 56B` spans `0x0040–0x0237`, not `0x0040–0x01F7`). Derive every range from `e_phoff`/`e_phentsize`/`e_phnum` and `e_shoff`/`e_shentsize`/`e_shnum`, not eyeballed boundaries, and give every leftover zero byte an explicit `Align pad` label.
8. **Hard-coded explanatory prose** → keep the template free of per-binary comments. Generate descriptions from `type`/`flags`/name (the built-in `NAME_DESC`/`TYPE_DESC` dictionaries) and derive the file→memory mapping from `addr`/`from`, so the same template works for any binary layout.

## Examples
- "Visualize this compiled binary's structure."
- "Show me the memory layout of write_example after it loads."
- "Draw a byte-by-byte breakdown of this ELF file."

