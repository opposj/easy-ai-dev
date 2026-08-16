# Generates elf_bytes.js (window.ELF_HEX) from a binary on disk.
# This avoids pasting large hex blobs through edit/diff tools.
#
# Usage:
#   pwsh -File extract_bytes.ps1 -Binary .\write_example -Out .\elf_bytes.js
param(
    [string]$Binary = ".\write_example",
    [string]$Out = ".\elf_bytes.js"
)

$ErrorActionPreference = "Stop"

$path = (Resolve-Path $Binary).Path
$bytes = [System.IO.File]::ReadAllBytes($path)
$hex = ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""

$js = 'window.ELF_HEX = "' + $hex + '";' + [Environment]::NewLine
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $Out), $js, [System.Text.Encoding]::ASCII)

Write-Host "Wrote $Out : $($hex.Length) hex chars = $($bytes.Length) bytes"
