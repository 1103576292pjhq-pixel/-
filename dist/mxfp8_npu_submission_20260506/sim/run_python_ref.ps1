$ErrorActionPreference = "Stop"

$workdir = Split-Path -Parent $PSScriptRoot
python (Join-Path $workdir "tools\\mx_ref.py") --selftest
python (Join-Path $workdir "tools\\mx_ref.py") --emit-dot32-vectors 8 --seed 1234 --outdir (Join-Path $workdir "vectors\\dot32_smoke")
