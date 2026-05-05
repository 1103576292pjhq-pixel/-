#!/usr/bin/env python3
"""Render small report-oriented waveform PNGs from archived VCD files."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import argparse
import re

import matplotlib.pyplot as plt


@dataclass(frozen=True)
class SignalSpec:
    name: str
    label: str
    kind: str


@dataclass(frozen=True)
class RenderJob:
    vcd: Path
    png: Path
    title: str
    top: str
    signals: tuple[SignalSpec, ...]


def parse_vcd(vcd_path: Path, top: str, signal_names: set[str]) -> tuple[dict[str, list[tuple[int, str]]], int]:
    id_to_name: dict[str, str] = {}
    scope: list[str] = []
    in_header = True
    now = 0
    max_time = 0
    values: dict[str, list[tuple[int, str]]] = {name: [] for name in signal_names}

    var_re = re.compile(r"^\$var\s+\S+\s+\d+\s+(\S+)\s+(\S+)")

    with vcd_path.open("r", encoding="utf-8", errors="replace") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue

            if in_header:
                if line.startswith("$scope"):
                    parts = line.split()
                    if len(parts) >= 3:
                        scope.append(parts[2])
                elif line.startswith("$upscope"):
                    if scope:
                        scope.pop()
                elif line.startswith("$var"):
                    match = var_re.match(line)
                    if match:
                        code, ref_name = match.groups()
                        if scope and scope[0] == top and len(scope) == 1 and ref_name in signal_names:
                            id_to_name.setdefault(code, ref_name)
                elif line.startswith("$enddefinitions"):
                    in_header = False
                continue

            if line.startswith("#"):
                now = int(line[1:])
                max_time = max(max_time, now)
                continue

            if line[0] in "01xXzZ":
                code = line[1:]
                name = id_to_name.get(code)
                if name is not None:
                    values[name].append((now, line[0].lower()))
                continue

            if line[0] in "bB":
                parts = line[1:].split()
                if len(parts) == 2:
                    bits, code = parts
                    name = id_to_name.get(code)
                    if name is not None:
                        values[name].append((now, bits.lower()))

    return values, max_time


def compact_hex(value: str) -> str:
    if not value or any(ch in value for ch in "xz"):
        return value
    width = len(value)
    intval = int(value, 2)
    hex_digits = max(1, (width + 3) // 4)
    if width > 64:
        mask = (1 << 32) - 1
        return f"lo32=0x{intval & mask:08x}"
    return f"0x{intval:0{hex_digits}x}"


def digital_value(value: str) -> int:
    return 1 if value == "1" else 0


def render_job(job: RenderJob) -> None:
    signal_names = {sig.name for sig in job.signals}
    values, max_time = parse_vcd(job.vcd, job.top, signal_names)
    if max_time <= 0:
        max_time = 1

    fig_height = 1.1 + 0.55 * len(job.signals)
    fig, ax = plt.subplots(figsize=(12, fig_height), dpi=160)
    ax.set_title(job.title, fontsize=12, loc="left")
    ax.set_xlabel("time (ns)")
    ax.set_yticks([])
    ax.set_xlim(0, max_time / 1000.0)
    ax.set_ylim(-0.4, len(job.signals) + 0.4)
    ax.grid(axis="x", linestyle=":", alpha=0.35)

    for lane, spec in enumerate(reversed(job.signals)):
        y_base = lane
        changes = values.get(spec.name, [])
        if not changes:
            ax.text(0, y_base + 0.15, f"{spec.label}: <no data>", fontsize=9)
            continue

        ax.text(-0.01 * (max_time / 1000.0), y_base + 0.15, spec.label, ha="right", va="center", fontsize=9)

        if spec.kind == "digital":
            times = [t / 1000.0 for t, _ in changes]
            vals = [y_base + 0.1 + 0.28 * digital_value(v) for _, v in changes]
            times.append(max_time / 1000.0)
            vals.append(vals[-1])
            ax.step(times, vals, where="post", linewidth=1.6)
            ax.hlines(y_base + 0.1, 0, max_time / 1000.0, linewidth=0.4, alpha=0.25)
        else:
            ax.hlines(y_base + 0.2, 0, max_time / 1000.0, linewidth=1.2)
            last = None
            text_count = 0
            for t, value in changes:
                if value == last:
                    continue
                last = value
                x = t / 1000.0
                ax.vlines(x, y_base + 0.05, y_base + 0.35, linewidth=0.8)
                if text_count < 8:
                    ax.text(x, y_base + 0.38, compact_hex(value), fontsize=8, rotation=20, va="bottom")
                    text_count += 1

    job.png.parent.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(job.png)
    plt.close(fig)


def build_jobs(root: Path) -> list[RenderJob]:
    wave_dir = root / "reports" / "evidence" / "waveforms"
    out_dir = root / "reports" / "evidence" / "waveform_screenshots"
    return [
        RenderJob(
            vcd=wave_dir / "tb_llmt_col_smoke_wave.vcd",
            png=out_dir / "tb_llmt_col_smoke.png",
            title="tb_llmt_col_smoke: clear + dot32 + FP32 accumulator",
            top="tb_llmt_col_smoke",
            signals=(
                SignalSpec("clk", "clk", "digital"),
                SignalSpec("valid_i", "valid_i", "digital"),
                SignalSpec("acc_clear_i", "acc_clear_i", "digital"),
                SignalSpec("valid_o", "valid_o", "digital"),
                SignalSpec("acc_o", "acc_o", "bus"),
            ),
        ),
        RenderJob(
            vcd=wave_dir / "tb_llmt_col_back_to_back_wave.vcd",
            png=out_dir / "tb_llmt_col_back_to_back.png",
            title="tb_llmt_col_back_to_back: continuous valid input",
            top="tb_llmt_col_back_to_back",
            signals=(
                SignalSpec("clk", "clk", "digital"),
                SignalSpec("valid_i", "valid_i", "digital"),
                SignalSpec("valid_o", "valid_o", "digital"),
                SignalSpec("acc_o", "acc_o", "bus"),
            ),
        ),
        RenderJob(
            vcd=wave_dir / "tb_mx_array_smoke_wave.vcd",
            png=out_dir / "tb_mx_array_smoke.png",
            title="tb_mx_array_smoke: 16-column array smoke",
            top="tb_mx_array_smoke",
            signals=(
                SignalSpec("clk", "clk", "digital"),
                SignalSpec("valid_i", "valid_i", "digital"),
                SignalSpec("acc_clear_i", "acc_clear_i[15:0]", "bus"),
                SignalSpec("valid_o", "valid_o[15:0]", "bus"),
                SignalSpec("ref_acc_o", "ref_acc_o", "bus"),
            ),
        ),
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="workspace root")
    args = parser.parse_args()

    root = args.root.resolve()
    for job in build_jobs(root):
        if not job.vcd.exists():
            raise SystemExit(f"missing VCD: {job.vcd}")
        render_job(job)
        print(f"Wrote {job.png}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
