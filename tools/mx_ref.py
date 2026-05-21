#!/usr/bin/env python3
import argparse
import json
import math
from pathlib import Path
import struct


FP32_QNAN = 0x7FC00000
FINITE_E4M3_TABLE = [
    0x00, 0x01, 0x02, 0x08, 0x10, 0x18, 0x20, 0x28,
    0x30, 0x34, 0x38, 0x3C, 0x40, 0x44, 0x48, 0x4C,
    0x80, 0x81, 0x88, 0x90, 0x98, 0xA0, 0xA8, 0xB0,
    0xB4, 0xB8, 0xBC, 0xC0, 0xC4, 0xC8, 0xCC,
]
FINITE_SCALE_TABLE = [0x7D, 0x7E, 0x7F, 0x80, 0x81]
PRECISION_PROFILES = {
    "baseline": {
        "elem_table": FINITE_E4M3_TABLE,
        "scale_table": FINITE_SCALE_TABLE,
        "description": "Existing finite sampled distribution with E8M0 scales 2^-2 through 2^2.",
    },
    "narrow-scale": {
        "elem_table": FINITE_E4M3_TABLE,
        "scale_table": [0x7E, 0x7F, 0x80],
        "description": "Finite sampled distribution with narrow E8M0 scale coverage from 2^-1 through 2^1.",
    },
    "wide-scale": {
        "elem_table": FINITE_E4M3_TABLE,
        "scale_table": [0x79, 0x7B, 0x7D, 0x7F, 0x81, 0x83, 0x85],
        "description": "Finite sampled distribution with wider E8M0 scale coverage from 2^-6 through 2^6.",
    },
}


def bits_to_float(bits: int) -> float:
    return struct.unpack(">f", bits.to_bytes(4, "big"))[0]


def float_to_bits(value: float) -> int:
    if math.isnan(value):
        return FP32_QNAN
    return int.from_bytes(struct.pack(">f", value), "big")


def f32(value: float) -> float:
    return bits_to_float(float_to_bits(value))


def e4m3_to_float(x: int) -> float:
    sign = -1.0 if (x & 0x80) else 1.0
    exp = (x >> 3) & 0xF
    mant = x & 0x7
    if exp == 0 and mant == 0:
        return math.copysign(0.0, sign)
    if exp == 0xF and mant == 0x7:
        return math.nan
    if exp == 0:
        return sign * mant * (2.0 ** -9)
    return sign * (8 + mant) * (2.0 ** (exp - 10))


def e8m0_to_float(x: int) -> float:
    if x == 0xFF:
        return math.nan
    return 2.0 ** (x - 127)


def dot32(a_elem: int, b_elem: int, a_scale: int = 0x7F, b_scale: int = 0x7F) -> int:
    av = e4m3_to_float(a_elem)
    bv = e4m3_to_float(b_elem)
    sa = e8m0_to_float(a_scale)
    sb = e8m0_to_float(b_scale)
    if any(math.isnan(v) for v in (av, bv, sa, sb)):
        return FP32_QNAN
    return float_to_bits(sum((av * sa) * (bv * sb) for _ in range(32)))


def f32_add_bits(a_bits: int, b_bits: int) -> int:
    a = bits_to_float(a_bits)
    b = bits_to_float(b_bits)
    if math.isnan(a) or math.isnan(b):
        return FP32_QNAN
    return float_to_bits(f32(a + b))


def pack_block(elems: list[int]) -> int:
    value = 0
    for idx, elem in enumerate(elems):
        value |= (elem & 0xFF) << (8 * idx)
    return value


def block_dot_bits(a_elems: list[int], a_scale: int, b_elems: list[int], b_scale: int) -> int:
    dot = block_dot_float(a_elems, a_scale, b_elems, b_scale)
    if math.isnan(dot):
        return FP32_QNAN
    return float_to_bits(dot)


def block_dot_float(a_elems: list[int], a_scale: int, b_elems: list[int], b_scale: int) -> float:
    sa = e8m0_to_float(a_scale)
    sb = e8m0_to_float(b_scale)
    if math.isnan(sa) or math.isnan(sb):
        return math.nan

    total = 0.0
    for a_elem, b_elem in zip(a_elems, b_elems):
        av = e4m3_to_float(a_elem)
        bv = e4m3_to_float(b_elem)
        if math.isnan(av) or math.isnan(bv):
            return math.nan
        total += (av * sa) * (bv * sb)
    return total


def mix32(x: int) -> int:
    x &= 0xFFFFFFFF
    x ^= x >> 16
    x = (x * 0x7FEB352D) & 0xFFFFFFFF
    x ^= x >> 15
    x = (x * 0x846CA68B) & 0xFFFFFFFF
    x ^= x >> 16
    return x & 0xFFFFFFFF


def precision_profile_config(name: str) -> dict:
    if name not in PRECISION_PROFILES:
        valid = ", ".join(sorted(PRECISION_PROFILES))
        raise SystemExit(f"unknown precision profile '{name}'; valid profiles: {valid}")
    return PRECISION_PROFILES[name]


def elem_at(
    seed: int,
    role: int,
    major: int,
    kb: int,
    lane: int,
    randomize: bool,
    elem_table=None,
) -> int:
    if not randomize:
        return deterministic_elem(major * 97 + kb * 31 + lane * (3 if role else 1))
    idx = mix32(seed ^ (role * 0x9E3779B9) ^ (major * 0x85EBCA6B) ^ (kb * 0xC2B2AE35) ^ lane)
    table = elem_table if elem_table is not None else FINITE_E4M3_TABLE
    return table[idx % len(table)]


def scale_at(
    seed: int,
    role: int,
    major: int,
    kb: int,
    randomize: bool,
    scale_table=None,
) -> int:
    if not randomize:
        return deterministic_scale(major + (2 if role else 1) * kb)
    idx = mix32(seed ^ (role * 0x27D4EB2D) ^ (major * 0x165667B1) ^ (kb * 0xD3A2646C))
    table = scale_table if scale_table is not None else FINITE_SCALE_TABLE
    return table[idx % len(table)]


def deterministic_elem(index: int) -> int:
    table = [0x38, 0x40, 0x30, 0xB8, 0x01, 0x00, 0x34, 0xBC]
    return table[index % len(table)]


def deterministic_scale(index: int) -> int:
    table = [0x7F, 0x80, 0x7E]
    return table[index % len(table)]


def emit_matmul_dataset(
    out_dir: Path,
    m: int,
    n: int,
    k_blocks: int,
    inject_nonfinite: bool,
    randomize: bool,
    seed: int,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    a_blocks: list[list[int]] = []
    b_blocks: list[list[int]] = []
    a_scales: list[int] = []
    b_scales: list[int] = []

    for row in range(m):
        for kb in range(k_blocks):
            a_blocks.append([elem_at(seed, 0, row, kb, lane, randomize) for lane in range(32)])
            a_scales.append(scale_at(seed, 0, row, kb, randomize))

    for col in range(n):
        for kb in range(k_blocks):
            b_blocks.append([elem_at(seed, 1, col, kb, lane, randomize) for lane in range(32)])
            b_scales.append(scale_at(seed, 1, col, kb, randomize))

    if inject_nonfinite:
        if m > 1:
            a_scales[1 * k_blocks] = 0xFF
        if n > 2:
            b_blocks[2 * k_blocks][0] = 0x7F

    expected: list[int] = []
    for row in range(m):
        for col in range(n):
            acc = 0x00000000
            for kb in range(k_blocks):
                dot = block_dot_bits(
                    a_blocks[row * k_blocks + kb],
                    a_scales[row * k_blocks + kb],
                    b_blocks[col * k_blocks + kb],
                    b_scales[col * k_blocks + kb],
                )
                acc = dot if kb == 0 else f32_add_bits(acc, dot)
            expected.append(acc)

    (out_dir / "a_blocks.hex").write_text(
        "".join(f"{pack_block(block):064x}\n" for block in a_blocks), encoding="ascii"
    )
    (out_dir / "b_blocks.hex").write_text(
        "".join(f"{pack_block(block):064x}\n" for block in b_blocks), encoding="ascii"
    )
    (out_dir / "a_scales.hex").write_text(
        "".join(f"{scale:02x}\n" for scale in a_scales), encoding="ascii"
    )
    (out_dir / "b_scales.hex").write_text(
        "".join(f"{scale:02x}\n" for scale in b_scales), encoding="ascii"
    )
    (out_dir / "expected_y.hex").write_text(
        "".join(f"{value:08x}\n" for value in expected), encoding="ascii"
    )
    manifest = {
        "kind": "matmul_dataset",
        "m": m,
        "n": n,
        "k": k_blocks * 32,
        "k_blocks": k_blocks,
        "seed": seed,
        "randomize": randomize,
        "inject_nonfinite": inject_nonfinite,
        "layout": "a rows are row-major by row,k_block; b rows are col-major by col,k_block; expected_y is row-major",
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="ascii")


def sampled_matmul_stats(m: int, n: int, k: int, samples: int, seed: int, precision_profile: str) -> dict:
    if k % 32 != 0:
        raise SystemExit("k must be a multiple of 32")

    profile = precision_profile_config(precision_profile)
    elem_table = profile["elem_table"]
    scale_table = profile["scale_table"]
    k_blocks = k // 32
    rel_errors: list[float] = []
    abs_errors: list[float] = []
    worst = {
        "row": 0,
        "col": 0,
        "projected_bits": "0x00000000",
        "ideal": 0.0,
        "abs_error": 0.0,
        "rel_error": 0.0,
    }

    for sample_idx in range(samples):
        row = mix32(seed ^ (sample_idx * 0xA511E9B3)) % m
        col = mix32(seed ^ (sample_idx * 0x63D83595) ^ 0x12345678) % n
        projected = 0x00000000
        ideal = 0.0

        for kb in range(k_blocks):
            a_block = [elem_at(seed, 0, row, kb, lane, True, elem_table) for lane in range(32)]
            b_block = [elem_at(seed, 1, col, kb, lane, True, elem_table) for lane in range(32)]
            a_scale = scale_at(seed, 0, row, kb, True, scale_table)
            b_scale = scale_at(seed, 1, col, kb, True, scale_table)
            dot_float = block_dot_float(a_block, a_scale, b_block, b_scale)
            dot_bits = float_to_bits(dot_float)
            projected = dot_bits if kb == 0 else f32_add_bits(projected, dot_bits)
            ideal += dot_float

        projected_float = bits_to_float(projected)
        abs_error = abs(projected_float - ideal)
        rel_error = abs_error / max(abs(ideal), 1.0e-30)
        abs_errors.append(abs_error)
        rel_errors.append(rel_error)
        if rel_error > worst["rel_error"]:
            worst = {
                "row": row,
                "col": col,
                "projected_bits": f"0x{projected:08x}",
                "projected": projected_float,
                "ideal": ideal,
                "abs_error": abs_error,
                "rel_error": rel_error,
            }

    return {
        "kind": "sampled_matmul_stats",
        "m": m,
        "n": n,
        "k": k,
        "k_blocks": k_blocks,
        "precision_profile": precision_profile,
        "profile": {
            "name": precision_profile,
            "description": profile["description"],
            "elem_count": len(elem_table),
            "scale_codes": [f"0x{scale:02x}" for scale in scale_table],
        },
        "samples": samples,
        "seed": seed,
        "mean_abs_error": sum(abs_errors) / len(abs_errors),
        "mean_rel_error": sum(rel_errors) / len(rel_errors),
        "max_abs_error": max(abs_errors),
        "max_rel_error": max(rel_errors),
        "worst": worst,
        "note": "projected path rounds each dot and FP32 accumulation; ideal path accumulates Python double values",
    }


def selftest() -> None:
    checks = [
        ("one", e4m3_to_float(0x38), 1.0),
        ("two", e4m3_to_float(0x40), 2.0),
        ("min_subnormal", e4m3_to_float(0x01), 2.0 ** -9),
        ("scale_one", e8m0_to_float(0x7F), 1.0),
    ]
    for name, got, exp in checks:
        if got != exp:
            raise SystemExit(f"FAIL {name}: got {got} expected {exp}")

    dot_checks = [
        ("dot_ones", dot32(0x38, 0x38), 0x42000000),
        ("dot_twos", dot32(0x38, 0x40), 0x42800000),
        ("dot_subnormal", dot32(0x01, 0x38), 0x3D800000),
        ("dot_nan", dot32(0x7F, 0x38), FP32_QNAN),
    ]
    for name, got, exp in dot_checks:
        if got != exp:
            raise SystemExit(f"FAIL {name}: got 0x{got:08x} expected 0x{exp:08x}")

    print("PASS mx_ref selftest")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--selftest", action="store_true")
    parser.add_argument("--emit-matmul-dataset", action="store_true")
    parser.add_argument("--out-dir", type=Path, default=Path("vectors/matmul_3x20x64_smoke"))
    parser.add_argument("--m", type=int, default=3)
    parser.add_argument("--n", type=int, default=20)
    parser.add_argument("--k-blocks", type=int, default=2)
    parser.add_argument("--inject-nonfinite", action="store_true")
    parser.add_argument("--random", action="store_true")
    parser.add_argument("--seed", type=int, default=20260508)
    parser.add_argument("--report-matmul-stats", action="store_true")
    parser.add_argument("--k", type=int, default=4096)
    parser.add_argument("--samples", type=int, default=256)
    parser.add_argument("--precision-profile", choices=sorted(PRECISION_PROFILES), default="baseline")
    args = parser.parse_args()
    if args.selftest:
        selftest()
    elif args.emit_matmul_dataset:
        emit_matmul_dataset(
            args.out_dir,
            args.m,
            args.n,
            args.k_blocks,
            args.inject_nonfinite,
            args.random,
            args.seed,
        )
        print(f"PASS wrote dataset {args.out_dir}")
    elif args.report_matmul_stats:
        stats = sampled_matmul_stats(args.m, args.n, args.k, args.samples, args.seed, args.precision_profile)
        args.out_dir.parent.mkdir(parents=True, exist_ok=True)
        args.out_dir.write_text(json.dumps(stats, indent=2), encoding="ascii")
        print(f"PASS wrote stats {args.out_dir}")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
