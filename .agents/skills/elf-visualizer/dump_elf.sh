#!/home/linuxbrew/.linuxbrew/bin/zsh
# In-container ELF inspection. Run inside the ai-dev container, e.g.:
#   docker run --rm -v "$(pwd):/workspace" ai-dev:latest /home/linuxbrew/.linuxbrew/bin/zsh \
#     -c "sed -i 's/\r$//' /workspace/dump_elf.sh && /home/linuxbrew/.linuxbrew/bin/zsh /workspace/dump_elf.sh /workspace/write_example"
BIN="${1:-/workspace/write_example}"

echo "=== ELF header ==="
readelf -h "$BIN"

echo
echo "=== Program headers (wide) ==="
readelf -lW "$BIN"

echo
echo "=== Section headers (wide) ==="
readelf -SW "$BIN"

echo
echo "=== .rodata bytes ==="
readelf -x .rodata "$BIN" 2>/dev/null || true

echo
echo "=== disassembly around syscalls ==="
objdump -d "$BIN" 2>/dev/null | rg -B2 -A4 'syscall' || true

echo
echo "=== authoritative runtime memory map (gdb) ==="
gdb -batch -ex 'starti' -ex 'info proc mappings' -ex 'quit' "$BIN" 2>/dev/null || true
