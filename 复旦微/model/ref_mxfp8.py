#!/usr/bin/env python3
from __future__ import annotations

import argparse
import math
import random
import struct
from pathlib import Path

K_BLOCK = 32
NUM_LLMT = 16


def f32(value: float) -> float:
    return struct.unpack(">f", struct.pack(">f", float(value)))[0]


def f32_hex(value: float) -> str:
    return f"{struct.unpack('>I', struct.pack('>f', f32(value)))[0]:08x}"


def hex_f32(value: str) -> float:
    return struct.unpack(">f", int(value, 16).to_bytes(4, "big"))[0]


def e4m3_value(byte: int) -> float:
    byte &= 0xff
    sign = -1.0 if byte & 0x80 else 1.0
    exp = (byte >> 3) & 0x0f
    frac = byte & 0x07
    if exp == 0x0f and frac == 0x07:
        return math.nan
    if exp == 0:
        if frac == 0:
            return -0.0 if sign < 0 else 0.0
        return sign * (frac / 8.0) * (2.0 ** -6)
    return sign * (1.0 + frac / 8.0) * (2.0 ** (exp - 7))


def e8m0_value(scale: int) -> float:
    scale &= 0xff
    if scale == 0xff:
        return math.nan
    return 2.0 ** (scale - 127)


def mxfp8_value(byte: int, scale: int) -> float:
    return e4m3_value(byte) * e8m0_value(scale)


def dot32(a_block: list[int], a_scale: int, b_block: list[int], b_scale: int) -> float:
    vals = [f32(mxfp8_value(a, a_scale) * mxfp8_value(b, b_scale)) for a, b in zip(a_block, b_block)]
    while len(vals) > 1:
        vals = [f32(vals[i] + vals[i + 1]) for i in range(0, len(vals), 2)]
    return vals[0]


def array16(a_block: list[int], a_scale: int, b_blocks: list[list[int]], b_scales: list[int]) -> list[float]:
    return [dot32(a_block, a_scale, b_blocks[lane], b_scales[lane]) for lane in range(NUM_LLMT)]


def pack_block(block: list[int]) -> str:
    return "".join(f"{x & 0xff:02x}" for x in reversed(block))


def pack_lanes(blocks: list[list[int]]) -> str:
    words = []
    for lane in range(NUM_LLMT):
        words.extend(blocks[lane])
    return "".join(f"{x & 0xff:02x}" for x in reversed(words))


def pack_scales(scales: list[int]) -> str:
    return "".join(f"{x & 0xff:02x}" for x in reversed(scales))


def boundary_case() -> tuple[list[int], int, list[list[int]], list[int]]:
    vals = [0x00, 0x01, 0x02, 0x07, 0x08, 0x10, 0x38, 0x3f, 0x77, 0x7e, 0x80, 0x81, 0x87, 0x88, 0xb8, 0xfe]
    a = (vals * 2)[:K_BLOCK]
    b_blocks = []
    for lane in range(NUM_LLMT):
        rot = lane % len(vals)
        b_blocks.append(((vals[rot:] + vals[:rot]) * 2)[:K_BLOCK])
    b_scales = [(127 + lane % 5 - 2) & 0xff for lane in range(NUM_LLMT)]
    return a, 127, b_blocks, b_scales


def random_case(rng: random.Random) -> tuple[list[int], int, list[list[int]], list[int]]:
    finite = [x for x in range(0x100) if (x & 0x7f) != 0x7f]
    a = [rng.choice(finite) for _ in range(K_BLOCK)]
    b_blocks = [[rng.choice(finite) for _ in range(K_BLOCK)] for _ in range(NUM_LLMT)]
    a_scale = rng.randint(124, 130)
    b_scales = [rng.randint(124, 130) for _ in range(NUM_LLMT)]
    return a, a_scale, b_blocks, b_scales


def write_array_vectors(path: Path, cases: int, seed: int) -> None:
    rng = random.Random(seed)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        f.write(f"{cases}\n")
        for idx in range(cases):
            if idx == 0:
                a, a_scale, b_blocks, b_scales = boundary_case()
            else:
                a, a_scale, b_blocks, b_scales = random_case(rng)
            expected = array16(a, a_scale, b_blocks, b_scales)
            f.write(f"{pack_block(a)} {a_scale:02x} {pack_lanes(b_blocks)} {pack_scales(b_scales)} ")
            f.write(" ".join(f32_hex(x) for x in expected))
            f.write("\n")


def dot32_seq(a_values: list[int], b_values: list[int], a_scales: list[int], b_scales: list[int]) -> float:
    acc = f32(0.0)
    for a, b, sa, sb in zip(a_values, b_values, a_scales, b_scales):
        prod = f32(mxfp8_value(a, sa) * mxfp8_value(b, sb))
        acc = f32(acc + prod)
    return acc


def dot4096_array_order(a_values: list[int], b_values: list[int], a_scales: list[int], b_scales: list[int]) -> float:
    acc = f32(0.0)
    for base in range(0, len(a_values), K_BLOCK):
        block = dot32(
            a_values[base:base + K_BLOCK],
            a_scales[base],
            b_values[base:base + K_BLOCK],
            b_scales[base],
        )
        acc = f32(acc + block)
    return acc


def mac4096(seed: int, blocks: int = 128) -> None:
    rng = random.Random(seed)
    a_values: list[int] = []
    b_values: list[int] = []
    a_scales: list[int] = []
    b_scales: list[int] = []
    for _ in range(blocks):
        a, a_scale, b_blocks, b_scales_block = random_case(rng)
        a_values.extend(a)
        b_values.extend(b_blocks[0])
        a_scales.extend([a_scale] * K_BLOCK)
        b_scales.extend([b_scales_block[0]] * K_BLOCK)
    seq = dot32_seq(a_values, b_values, a_scales, b_scales)
    array_order = dot4096_array_order(a_values, b_values, a_scales, b_scales)
    abs_err = abs(array_order - seq)
    rel_err = abs_err / max(abs(seq), 1.0e-30)
    print(f"blocks={blocks} terms={blocks * K_BLOCK} seq_fp32={f32_hex(seq)} array_fp32={f32_hex(array_order)} abs_err={abs_err:.9e} rel_err={rel_err:.9e}")


def mac4096_stats(seed: int, cases: int, blocks: int = 128, out: Path | None = None) -> None:
    max_rel = -1.0
    max_abs = -1.0
    sum_rel = 0.0
    sum_sq_rel = 0.0
    worst = None
    lines = []
    for case in range(cases):
        case_seed = seed + case
        rng = random.Random(case_seed)
        a_values: list[int] = []
        b_values: list[int] = []
        a_scales: list[int] = []
        b_scales: list[int] = []
        for _ in range(blocks):
            a, a_scale, b_blocks, b_scales_block = random_case(rng)
            a_values.extend(a)
            b_values.extend(b_blocks[0])
            a_scales.extend([a_scale] * K_BLOCK)
            b_scales.extend([b_scales_block[0]] * K_BLOCK)
        seq = dot32_seq(a_values, b_values, a_scales, b_scales)
        array_order = dot4096_array_order(a_values, b_values, a_scales, b_scales)
        abs_err = abs(array_order - seq)
        rel_err = abs_err / max(abs(seq), 1.0e-30)
        sum_rel += rel_err
        sum_sq_rel += rel_err * rel_err
        if rel_err > max_rel:
            max_rel = rel_err
            max_abs = abs_err
            worst = (case, case_seed, f32_hex(seq), f32_hex(array_order), seq, array_order)
        lines.append(f"case={case} seed={case_seed} seq={f32_hex(seq)} array={f32_hex(array_order)} abs_err={abs_err:.9e} rel_err={rel_err:.9e}")

    mean_rel = sum_rel / cases
    rms_rel = math.sqrt(sum_sq_rel / cases)
    report = [
        "MXFP8 4096-point MAC relative error report",
        f"cases={cases}",
        f"terms_per_case={blocks * K_BLOCK}",
        f"base_seed={seed}",
        f"max_relative_error={max_rel:.9e}",
        f"mean_relative_error={mean_rel:.9e}",
        f"rms_relative_error={rms_rel:.9e}",
        f"max_absolute_error={max_abs:.9e}",
        f"worst_case={worst[0]} worst_seed={worst[1]} reference_seq_fp32={worst[2]} array_order_fp32={worst[3]}",
        "",
        "Per-case details:",
        *lines,
    ]
    text = "\n".join(report) + "\n"
    if out is not None:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding="utf-8")
    print(text, end="")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("cmd", choices=["vectors", "mac4096", "mac4096-stats"])
    parser.add_argument("--out", default="sim/array_vectors.hex")
    parser.add_argument("--cases", type=int, default=16)
    parser.add_argument("--seed", type=int, default=1)
    args = parser.parse_args()

    if args.cmd == "vectors":
        write_array_vectors(Path(args.out), args.cases, args.seed)
    elif args.cmd == "mac4096":
        mac4096(args.seed)
    elif args.cmd == "mac4096-stats":
        mac4096_stats(args.seed, args.cases, out=Path(args.out))


if __name__ == "__main__":
    main()
