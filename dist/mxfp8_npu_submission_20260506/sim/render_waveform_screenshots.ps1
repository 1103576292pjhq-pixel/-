$ErrorActionPreference = "Stop"

$workdir = Split-Path -Parent $PSScriptRoot
python (Join-Path $workdir "tools\render_waveform_png.py") --root $workdir
