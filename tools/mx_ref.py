from __future__ import annotations

import argparse
import json
import math
import random
import struct
from dataclasses import dataclass
from pathlib import Path

MX_BLOCK_K = 32
MX_ELEM_FIXED_FRAC = 9
MX_PROD_FIXED_FRAC = MX_ELEM_FIXED_FRAC * 2
FP32_QNAN_BITS = 0x7FC00000
E4M3_NAN_VALUES = tuple(
    enc for enc in range(256) if ((enc >> 3) & 0xF) == 0xF and (enc & 0x7) == 0x7
)
FINITE_E4M3_VALUES = tuple(enc for enc in range(256) if enc not in E4M3_NAN_VALUES)


def float32(value: float) -> float:
    try:
        return struct.unpack("<f", struct.pack("<f", float(value)))[0]
    except OverflowError:
        if value >= 0:
            return math.inf
        return -math.inf


def float_to_bits(value: float) -> int:
    fp32_value = float32(value)
    if math.isnan(fp32_value):
        return FP32_QNAN_BITS
    return struct.unpack("<I", struct.pack("<f", fp32_value))[0]


def bits_to_float(bits: int) -> float:
    return struct.unpack("<f", struct.pack("<I", bits & 0xFFFFFFFF))[0]


def pack_block_hex(elems: list[int]) -> str:
    packed = 0
    for idx, elem in enumerate(elems):
      packed |= (elem & 0xFF) << (idx * 8)
    width = MX_BLOCK_K * 2
    return f"{packed:0{width}x}"


def random_e4m3(rng: random.Random) -> int:
    return rng.randrange(0, 256)


def random_e8m0(rng: random.Random) -> int:
    return rng.randrange(0, 255)


def random_finite_e4m3(rng: random.Random) -> int:
    return FINITE_E4M3_VALUES[rng.randrange(0, len(FINITE_E4M3_VALUES))]


def random_finite_e8m0(
    rng: random.Random,
    min_exp: int = -8,
    max_exp: int = 8,
) -> int:
    lo = max(-126, min_exp)
    hi = min(127, max_exp)
    if lo > hi:
        raise ValueError(f"invalid exponent range: [{min_exp}, {max_exp}]")
    return 127 + rng.randrange(lo, hi + 1)


def relative_error(a_bits: int, b_bits: int) -> float:
    a = bits_to_float(a_bits)
    b = bits_to_float(b_bits)
    if math.isnan(a) and math.isnan(b):
        return 0.0
    if math.isnan(a) or math.isnan(b):
        return float("inf")
    denom = max(abs(a), 1e-30)
    return abs(a - b) / denom


def e4m3_is_zero(enc: int) -> bool:
    return (enc & 0x7F) == 0


def e4m3_is_nan(enc: int) -> bool:
    return ((enc >> 3) & 0xF) == 0xF and (enc & 0x7) == 0x7


def e4m3_to_fixed(enc: int) -> int:
    sign = -1 if (enc >> 7) & 1 else 1
    exp_field = (enc >> 3) & 0xF
    mant = enc & 0x7

    if e4m3_is_zero(enc) or e4m3_is_nan(enc):
        magnitude = 0
    elif exp_field == 0:
        magnitude = mant
    else:
        magnitude = ((1 << 3) | mant) << (exp_field - 1)
    return sign * magnitude


def e8m0_is_nan(enc: int) -> bool:
    return enc == 0xFF


def e8m0_unbiased_exp(enc: int) -> int:
    if e8m0_is_nan(enc):
        return 0
    return enc - 127


def e4m3_to_value(enc: int) -> float:
    if e4m3_is_nan(enc):
        return math.nan
    return math.ldexp(e4m3_to_fixed(enc), -MX_ELEM_FIXED_FRAC)


def sanitize_json_value(value: float | int | None) -> float | int | str | None:
    if value is None:
        return None
    if isinstance(value, float):
        if math.isnan(value):
            return "nan"
        if math.isinf(value):
            return "inf" if value > 0 else "-inf"
    return value


def choose_e4m3(rng: random.Random, finite_only: bool) -> int:
    if finite_only:
        return random_finite_e4m3(rng)
    return random_e4m3(rng)


def choose_e8m0(
    rng: random.Random,
    finite_only: bool,
    scale_exp_min: int,
    scale_exp_max: int,
) -> int:
    if finite_only:
        return random_finite_e8m0(rng, scale_exp_min, scale_exp_max)
    return random_e8m0(rng)


def dot32_to_bits(a_elems: list[int], a_scale: int, b_elems: list[int], b_scale: int) -> int:
    if e8m0_is_nan(a_scale) or e8m0_is_nan(b_scale):
        return FP32_QNAN_BITS
    if any(e4m3_is_nan(v) for v in a_elems) or any(e4m3_is_nan(v) for v in b_elems):
        return FP32_QNAN_BITS

    dot_sum = 0
    for a_val, b_val in zip(a_elems, b_elems):
        dot_sum += e4m3_to_fixed(a_val) * e4m3_to_fixed(b_val)

    shift = e8m0_unbiased_exp(a_scale) + e8m0_unbiased_exp(b_scale) - MX_PROD_FIXED_FRAC
    dot_value = float32(dot_sum * (2.0 ** shift))
    return float_to_bits(dot_value)


def dot32_block_stats(a_elems: list[int], a_scale: int, b_elems: list[int], b_scale: int) -> tuple[int, float]:
    dot_bits = dot32_to_bits(a_elems, a_scale, b_elems, b_scale)
    if dot_bits == FP32_QNAN_BITS:
        return dot_bits, math.nan

    dot_sum = 0
    for a_val, b_val in zip(a_elems, b_elems):
        dot_sum += e4m3_to_fixed(a_val) * e4m3_to_fixed(b_val)

    shift = e8m0_unbiased_exp(a_scale) + e8m0_unbiased_exp(b_scale) - MX_PROD_FIXED_FRAC
    return dot_bits, math.ldexp(dot_sum, shift)


def acc_add_bits(acc_bits: int, dot_bits: int) -> int:
    if dot_bits == FP32_QNAN_BITS:
        return FP32_QNAN_BITS
    acc_value = bits_to_float(acc_bits)
    dot_value = bits_to_float(dot_bits)
    return float_to_bits(float32(acc_value + dot_value))


def matmul_reference(
    a_blocks: list[list[list[int]]],
    a_scales: list[list[int]],
    b_blocks: list[list[list[int]]],
    b_scales: list[list[int]],
) -> list[list[int]]:
    m = len(a_blocks)
    k_blocks = len(a_blocks[0]) if m else 0
    n = len(b_blocks)
    y_bits = [[0 for _ in range(n)] for _ in range(m)]

    for row in range(m):
        for col in range(n):
            acc = 0
            for kb in range(k_blocks):
                dot = dot32_to_bits(
                    a_blocks[row][kb],
                    a_scales[row][kb],
                    b_blocks[col][kb],
                    b_scales[col][kb],
                )
                acc = acc_add_bits(acc, dot)
            y_bits[row][col] = acc
    return y_bits


@dataclass
class Case:
    name: str
    a_elems: list[int]
    a_scale: int
    b_elems: list[int]
    b_scale: int
    expected_bits: int


def build_cases() -> list[Case]:
    ones = [0x38] * MX_BLOCK_K
    neg_ones = [0xB8] * MX_BLOCK_K
    zeros = [0x00] * MX_BLOCK_K
    subs = [0x01] * MX_BLOCK_K
    elem_nan = ones.copy()
    elem_nan[0] = 0x7F
    return [
        Case("zeros", zeros, 0x7F, zeros, 0x7F, 0x00000000),
        Case("ones", ones, 0x7F, ones, 0x7F, 0x42000000),
        Case("neg_ones", neg_ones, 0x7F, ones, 0x7F, 0xC2000000),
        Case("subnormals", subs, 0x7F, ones, 0x7F, 0x3D800000),
        Case("scale_nan", ones, 0xFF, ones, 0x7F, FP32_QNAN_BITS),
        Case("elem_nan", elem_nan, 0x7F, ones, 0x7F, FP32_QNAN_BITS),
    ]


def run_selftest() -> None:
    if float_to_bits(math.nan) != FP32_QNAN_BITS:
        raise SystemExit("nan canonicalization mismatch")

    for case in build_cases():
        got = dot32_to_bits(case.a_elems, case.a_scale, case.b_elems, case.b_scale)
        if got != case.expected_bits:
            raise SystemExit(
                f"{case.name} mismatch: expected 0x{case.expected_bits:08x}, got 0x{got:08x}"
            )

    acc = 0
    case = build_cases()[1]
    acc = acc_add_bits(acc, dot32_to_bits(case.a_elems, case.a_scale, case.b_elems, case.b_scale))
    acc = acc_add_bits(acc, dot32_to_bits(case.a_elems, case.a_scale, case.b_elems, case.b_scale))
    if acc != 0x42800000:
        raise SystemExit(f"accumulate mismatch: expected 0x42800000, got 0x{acc:08x}")

    inf_minus_inf = acc_add_bits(float_to_bits(math.inf), float_to_bits(-math.inf))
    if inf_minus_inf != FP32_QNAN_BITS:
        raise SystemExit(
            f"inf-plus-neg-inf mismatch: expected 0x{FP32_QNAN_BITS:08x}, got 0x{inf_minus_inf:08x}"
        )

    a_blocks = [[[0x38] * MX_BLOCK_K, [0x38] * MX_BLOCK_K]]
    a_scales = [[0x7F, 0x7F]]
    b_blocks = [[[0x38] * MX_BLOCK_K, [0xB8] * MX_BLOCK_K]]
    b_scales = [[0x7F, 0x7F]]
    y_bits = matmul_reference(a_blocks, a_scales, b_blocks, b_scales)
    if y_bits[0][0] != 0x00000000:
        raise SystemExit(f"matmul mismatch: expected 0x00000000, got 0x{y_bits[0][0]:08x}")

    print("PASS: Python MX reference self-test completed.")


def run_random(count: int, seed: int) -> None:
    rng = random.Random(seed)
    acc = 0
    for idx in range(count):
        a_elems = [random_e4m3(rng) for _ in range(MX_BLOCK_K)]
        b_elems = [random_e4m3(rng) for _ in range(MX_BLOCK_K)]
        a_scale = random_e8m0(rng)
        b_scale = random_e8m0(rng)
        dot = dot32_to_bits(a_elems, a_scale, b_elems, b_scale)
        acc = acc_add_bits(acc, dot)
        print(
            f"{idx:04d} dot=0x{dot:08x} acc=0x{acc:08x} "
            f"a_scale=0x{a_scale:02x} b_scale=0x{b_scale:02x}"
        )


def emit_dot32_vectors(count: int, seed: int, outdir: Path) -> None:
    rng = random.Random(seed)
    outdir.mkdir(parents=True, exist_ok=True)

    a_blocks_hex: list[str] = []
    a_scales_hex: list[str] = []
    b_blocks_hex: list[str] = []
    b_scales_hex: list[str] = []
    expected_dot_hex: list[str] = []
    expected_acc_hex: list[str] = []
    meta: list[dict[str, object]] = []

    acc = 0
    for idx in range(count):
        a_elems = [random_e4m3(rng) for _ in range(MX_BLOCK_K)]
        b_elems = [random_e4m3(rng) for _ in range(MX_BLOCK_K)]
        a_scale = random_e8m0(rng)
        b_scale = random_e8m0(rng)
        dot_bits = dot32_to_bits(a_elems, a_scale, b_elems, b_scale)
        acc = acc_add_bits(acc, dot_bits)

        a_blocks_hex.append(pack_block_hex(a_elems))
        a_scales_hex.append(f"{a_scale:02x}")
        b_blocks_hex.append(pack_block_hex(b_elems))
        b_scales_hex.append(f"{b_scale:02x}")
        expected_dot_hex.append(f"{dot_bits:08x}")
        expected_acc_hex.append(f"{acc:08x}")
        meta.append(
            {
                "index": idx,
                "a_scale": f"0x{a_scale:02x}",
                "b_scale": f"0x{b_scale:02x}",
                "dot_bits": f"0x{dot_bits:08x}",
                "acc_bits": f"0x{acc:08x}",
            }
        )

    (outdir / "a_blocks.hex").write_text("\n".join(a_blocks_hex) + "\n", encoding="utf-8")
    (outdir / "a_scales.hex").write_text("\n".join(a_scales_hex) + "\n", encoding="utf-8")
    (outdir / "b_blocks.hex").write_text("\n".join(b_blocks_hex) + "\n", encoding="utf-8")
    (outdir / "b_scales.hex").write_text("\n".join(b_scales_hex) + "\n", encoding="utf-8")
    (outdir / "expected_dot.hex").write_text("\n".join(expected_dot_hex) + "\n", encoding="utf-8")
    (outdir / "expected_acc.hex").write_text("\n".join(expected_acc_hex) + "\n", encoding="utf-8")
    (outdir / "manifest.json").write_text(
        json.dumps(
            {
                "kind": "dot32_vectors",
                "count": count,
                "seed": seed,
                "block_k": MX_BLOCK_K,
                "packing": "element0_in_lsb_byte",
                "cases": meta,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"PASS: emitted dot32 vectors to {outdir}")


def emit_matmul_dataset(
    m: int,
    n: int,
    k: int,
    seed: int,
    outdir: Path,
    finite_only: bool = False,
    scale_exp_min: int = -8,
    scale_exp_max: int = 8,
) -> None:
    if k % MX_BLOCK_K != 0:
        raise SystemExit(f"k must be a multiple of {MX_BLOCK_K}, got {k}")

    rng = random.Random(seed)
    outdir.mkdir(parents=True, exist_ok=True)
    k_blocks = k // MX_BLOCK_K

    a_blocks: list[list[list[int]]] = []
    a_scales: list[list[int]] = []
    b_blocks: list[list[list[int]]] = []
    b_scales: list[list[int]] = []

    for row in range(m):
        row_blocks: list[list[int]] = []
        row_scales: list[int] = []
        for kb in range(k_blocks):
            row_blocks.append([choose_e4m3(rng, finite_only) for _ in range(MX_BLOCK_K)])
            row_scales.append(choose_e8m0(rng, finite_only, scale_exp_min, scale_exp_max))
        a_blocks.append(row_blocks)
        a_scales.append(row_scales)

    for col in range(n):
        col_blocks: list[list[int]] = []
        col_scales: list[int] = []
        for kb in range(k_blocks):
            col_blocks.append([choose_e4m3(rng, finite_only) for _ in range(MX_BLOCK_K)])
            col_scales.append(choose_e8m0(rng, finite_only, scale_exp_min, scale_exp_max))
        b_blocks.append(col_blocks)
        b_scales.append(col_scales)

    y_bits = matmul_reference(a_blocks, a_scales, b_blocks, b_scales)

    a_block_lines: list[str] = []
    a_scale_lines: list[str] = []
    b_block_lines: list[str] = []
    b_scale_lines: list[str] = []
    y_lines: list[str] = []
    y_values: list[float] = []

    for row in range(m):
        for kb in range(k_blocks):
            a_block_lines.append(pack_block_hex(a_blocks[row][kb]))
            a_scale_lines.append(f"{a_scales[row][kb]:02x}")

    for col in range(n):
        for kb in range(k_blocks):
            b_block_lines.append(pack_block_hex(b_blocks[col][kb]))
            b_scale_lines.append(f"{b_scales[col][kb]:02x}")

    for row in range(m):
        for col in range(n):
            bits = y_bits[row][col]
            y_lines.append(f"{bits:08x}")
            y_values.append(bits_to_float(bits))

    max_abs = max((abs(v) for v in y_values if not math.isnan(v)), default=0.0)
    nan_count = sum(math.isnan(v) for v in y_values)
    inf_count = sum(math.isinf(v) for v in y_values)
    finite_count = sum(math.isfinite(v) for v in y_values)

    (outdir / "a_blocks.hex").write_text("\n".join(a_block_lines) + "\n", encoding="utf-8")
    (outdir / "a_scales.hex").write_text("\n".join(a_scale_lines) + "\n", encoding="utf-8")
    (outdir / "b_blocks.hex").write_text("\n".join(b_block_lines) + "\n", encoding="utf-8")
    (outdir / "b_scales.hex").write_text("\n".join(b_scale_lines) + "\n", encoding="utf-8")
    (outdir / "expected_y.hex").write_text("\n".join(y_lines) + "\n", encoding="utf-8")
    (outdir / "manifest.json").write_text(
        json.dumps(
            {
                "kind": "matmul_dataset",
                "m": m,
                "n": n,
                "k": k,
                "k_blocks": k_blocks,
                "seed": seed,
                "finite_only": finite_only,
                "scale_exp_min": scale_exp_min if finite_only else None,
                "scale_exp_max": scale_exp_max if finite_only else None,
                "packing": "element0_in_lsb_byte",
                "y_stats": {
                    "max_abs": sanitize_json_value(max_abs),
                    "nan_count": nan_count,
                    "inf_count": inf_count,
                    "finite_count": finite_count,
                    "checksum_xor": f"0x{checksum_hex(y_lines):08x}",
                },
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"PASS: emitted matmul dataset to {outdir}")


def generate_row_or_col_blocks(
    outer_idx: int,
    k_blocks: int,
    seed: int,
    axis_tag: int,
    finite_only: bool,
    scale_exp_min: int,
    scale_exp_max: int,
) -> tuple[list[list[int]], list[int]]:
    rng = random.Random((seed << 20) ^ (axis_tag << 12) ^ outer_idx)
    blocks: list[list[int]] = []
    scales: list[int] = []
    for _ in range(k_blocks):
        blocks.append([choose_e4m3(rng, finite_only) for _ in range(MX_BLOCK_K)])
        scales.append(choose_e8m0(rng, finite_only, scale_exp_min, scale_exp_max))
    return blocks, scales


def build_sample_points(m: int, n: int, samples: int, seed: int) -> list[tuple[int, int]]:
    total = m * n
    sample_count = max(1, min(samples, total))
    if sample_count >= total:
        return [(row, col) for row in range(m) for col in range(n)]

    points: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()

    def add_point(row: int, col: int) -> None:
        point = (row, col)
        if point not in seen and 0 <= row < m and 0 <= col < n:
            seen.add(point)
            points.append(point)

    add_point(0, 0)
    add_point(0, n - 1)
    add_point(m - 1, 0)
    add_point(m - 1, n - 1)
    add_point(m // 2, n // 2)

    rng = random.Random((seed << 8) ^ 0x5A17)
    while len(points) < sample_count:
        add_point(rng.randrange(0, m), rng.randrange(0, n))
    return points


def report_matmul_stats(
    m: int,
    n: int,
    k: int,
    seed: int,
    samples: int,
    finite_only: bool,
    scale_exp_min: int,
    scale_exp_max: int,
    summary_out: Path | None = None,
) -> dict[str, object]:
    if k % MX_BLOCK_K != 0:
        raise SystemExit(f"k must be a multiple of {MX_BLOCK_K}, got {k}")

    k_blocks = k // MX_BLOCK_K
    sample_points = build_sample_points(m, n, samples, seed)
    row_cache: dict[int, tuple[list[list[int]], list[int]]] = {}
    col_cache: dict[int, tuple[list[list[int]], list[int]]] = {}

    project_checksum = 0
    finite_count = 0
    inf_count = 0
    nan_count = 0
    abs_err_sum = 0.0
    rel_err_sum = 0.0
    max_abs_err = -1.0
    max_rel_err = -1.0
    max_project_abs = 0.0
    worst_abs_case: dict[str, object] | None = None
    worst_rel_case: dict[str, object] | None = None

    for row_idx, col_idx in sample_points:
        if row_idx not in row_cache:
            row_cache[row_idx] = generate_row_or_col_blocks(
                row_idx,
                k_blocks,
                seed,
                axis_tag=0xA,
                finite_only=finite_only,
                scale_exp_min=scale_exp_min,
                scale_exp_max=scale_exp_max,
            )
        if col_idx not in col_cache:
            col_cache[col_idx] = generate_row_or_col_blocks(
                col_idx,
                k_blocks,
                seed,
                axis_tag=0xB,
                finite_only=finite_only,
                scale_exp_min=scale_exp_min,
                scale_exp_max=scale_exp_max,
            )

        row_blocks, row_scales = row_cache[row_idx]
        col_blocks, col_scales = col_cache[col_idx]

        project_acc = 0
        ideal_acc = 0.0
        for kb in range(k_blocks):
            dot_bits, ideal_dot = dot32_block_stats(
                row_blocks[kb],
                row_scales[kb],
                col_blocks[kb],
                col_scales[kb],
            )
            project_acc = acc_add_bits(project_acc, dot_bits)
            if math.isnan(ideal_dot):
                ideal_acc = math.nan
                break
            ideal_acc += ideal_dot

        project_value = bits_to_float(project_acc)
        project_checksum ^= project_acc

        if math.isnan(project_value) or math.isnan(ideal_acc):
            nan_count += 1
            continue
        if math.isinf(project_value) or math.isinf(ideal_acc):
            inf_count += 1
        else:
            finite_count += 1
            max_project_abs = max(max_project_abs, abs(project_value))

        abs_err = abs(project_value - ideal_acc)
        rel_err = abs_err / max(abs(ideal_acc), 1e-30)
        abs_err_sum += abs_err
        rel_err_sum += rel_err

        if abs_err > max_abs_err:
            max_abs_err = abs_err
            worst_abs_case = {
                "row": row_idx,
                "col": col_idx,
                "project_bits": f"0x{project_acc:08x}",
                "project_value": sanitize_json_value(project_value),
                "ideal_value": sanitize_json_value(ideal_acc),
                "abs_error": sanitize_json_value(abs_err),
                "rel_error": sanitize_json_value(rel_err),
            }
        if rel_err > max_rel_err:
            max_rel_err = rel_err
            worst_rel_case = {
                "row": row_idx,
                "col": col_idx,
                "project_bits": f"0x{project_acc:08x}",
                "project_value": sanitize_json_value(project_value),
                "ideal_value": sanitize_json_value(ideal_acc),
                "abs_error": sanitize_json_value(abs_err),
                "rel_error": sanitize_json_value(rel_err),
            }

    measured_count = finite_count + inf_count
    summary = {
        "kind": "matmul_sampled_stats",
        "m": m,
        "n": n,
        "k": k,
        "k_blocks": k_blocks,
        "seed": seed,
        "samples": len(sample_points),
        "sample_ratio": len(sample_points) / (m * n),
        "finite_only": finite_only,
        "scale_exp_min": scale_exp_min if finite_only else None,
        "scale_exp_max": scale_exp_max if finite_only else None,
        "project_checksum_xor": f"0x{project_checksum:08x}",
        "finite_count": finite_count,
        "inf_count": inf_count,
        "nan_count": nan_count,
        "max_project_abs": sanitize_json_value(max_project_abs),
        "mean_abs_error": sanitize_json_value(abs_err_sum / max(measured_count, 1)),
        "mean_rel_error": sanitize_json_value(rel_err_sum / max(measured_count, 1)),
        "max_abs_error": sanitize_json_value(max_abs_err if max_abs_err >= 0 else None),
        "max_rel_error": sanitize_json_value(max_rel_err if max_rel_err >= 0 else None),
        "worst_abs_case": worst_abs_case,
        "worst_rel_case": worst_rel_case,
        "unique_rows": len(row_cache),
        "unique_cols": len(col_cache),
    }

    summary_text = json.dumps(summary, indent=2, ensure_ascii=False) + "\n"
    if summary_out is not None:
        summary_out.parent.mkdir(parents=True, exist_ok=True)
        summary_out.write_text(summary_text, encoding="utf-8")
    print(summary_text, end="")
    return summary


def checksum_hex(lines: list[str]) -> int:
    checksum = 0
    for line in lines:
        checksum ^= int(line, 16)
    return checksum


def main() -> None:
    parser = argparse.ArgumentParser(description="MXFP8 reference helpers")
    parser.add_argument("--selftest", action="store_true", help="run deterministic checks")
    parser.add_argument("--random", type=int, default=0, help="emit N random dot32 cases")
    parser.add_argument("--seed", type=int, default=1234, help="seed for random mode")
    parser.add_argument("--emit-dot32-vectors", type=int, default=0, help="emit N dot32 vectors")
    parser.add_argument("--emit-matmul-dataset", action="store_true", help="emit a block-structured matmul dataset")
    parser.add_argument("--report-matmul-stats", action="store_true", help="sample matrix outputs and report error stats")
    parser.add_argument("--outdir", type=Path, default=Path("vectors/ref_out"), help="output directory")
    parser.add_argument("--summary-out", type=Path, default=None, help="optional JSON summary file")
    parser.add_argument("--m", type=int, default=8, help="matmul rows")
    parser.add_argument("--n", type=int, default=8, help="matmul cols")
    parser.add_argument("--k", type=int, default=64, help="matmul reduction size, multiple of 32")
    parser.add_argument("--samples", type=int, default=1024, help="sample count for matrix stats")
    parser.add_argument("--finite-only", action="store_true", help="avoid NaN payloads and clamp scales")
    parser.add_argument("--scale-exp-min", type=int, default=-8, help="minimum E8M0 exponent for finite-only modes")
    parser.add_argument("--scale-exp-max", type=int, default=8, help="maximum E8M0 exponent for finite-only modes")
    args = parser.parse_args()

    if args.selftest or (
        args.random == 0
        and args.emit_dot32_vectors == 0
        and not args.emit_matmul_dataset
        and not args.report_matmul_stats
    ):
        run_selftest()
    if args.random:
        run_random(args.random, args.seed)
    if args.emit_dot32_vectors:
        emit_dot32_vectors(args.emit_dot32_vectors, args.seed, args.outdir)
    if args.emit_matmul_dataset:
        emit_matmul_dataset(
            args.m,
            args.n,
            args.k,
            args.seed,
            args.outdir,
            finite_only=args.finite_only,
            scale_exp_min=args.scale_exp_min,
            scale_exp_max=args.scale_exp_max,
        )
    if args.report_matmul_stats:
        report_matmul_stats(
            args.m,
            args.n,
            args.k,
            args.seed,
            args.samples,
            finite_only=args.finite_only,
            scale_exp_min=args.scale_exp_min,
            scale_exp_max=args.scale_exp_max,
            summary_out=args.summary_out,
        )


if __name__ == "__main__":
    main()
