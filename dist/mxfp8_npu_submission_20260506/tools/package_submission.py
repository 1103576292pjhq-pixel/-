#!/usr/bin/env python3
"""Build the official MXFP8 NPU RTL handoff submission package."""

from __future__ import annotations

import argparse
import datetime as _dt
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

INCLUDE_FILES = (
    "README.md",
    "MAIN.md",
    "STATUS.md",
)

INCLUDE_DIRS = (
    "rtl",
    "tb",
    "tools",
    "sim",
    "vectors",
    "constraints",
    "synth",
)

INCLUDE_TREE_DIRS = (
    "docs/report",
    "docs/usage",
    "reports/evidence",
    "reports/precision",
    "reports/verification",
    "reports/synthesis",
)

INCLUDE_EXTRA_FILES = (
    "docs/admin/final_submission_manifest.md",
    "reports/README.md",
)

FORBIDDEN_DIR_NAMES = {
    ".git",
    ".omx",
    ".codexpotter",
    "work",
    "dist",
    "__pycache__",
    ".pytest_cache",
}

FORBIDDEN_SUFFIXES = {
    ".vvp",
    ".pyc",
    ".pyo",
    ".tmp",
    ".bak",
}

FORBIDDEN_EXACT_NAMES = {
    "potter-run.log",
}


def is_forbidden(path: Path) -> bool:
    parts = set(path.parts)
    if parts & FORBIDDEN_DIR_NAMES:
        return True
    if path.suffix.lower() in FORBIDDEN_SUFFIXES:
        return True
    if path.name in FORBIDDEN_EXACT_NAMES:
        return True
    if path.name.lower().startswith("potter-runner-"):
        return True
    return False


def copy_file(src: Path, dst: Path, copied: list[Path]) -> None:
    if is_forbidden(src.relative_to(ROOT)):
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    copied.append(dst)


def copy_tree(rel_dir: str, package_dir: Path, copied: list[Path], missing: list[str]) -> None:
    src_dir = ROOT / rel_dir
    if not src_dir.exists():
        missing.append(rel_dir)
        return
    for src in src_dir.rglob("*"):
        rel = src.relative_to(ROOT)
        if is_forbidden(rel):
            continue
        if src.is_file():
            copy_file(src, package_dir / rel, copied)


def write_package_manifest(package_dir: Path, copied: list[Path]) -> None:
    manifest = package_dir / "PACKAGE_CONTENTS.txt"
    rel_paths = sorted(path.relative_to(package_dir).as_posix() for path in copied)
    manifest.write_text("\n".join(rel_paths) + "\n", encoding="utf-8")


def assert_clean_package(package_dir: Path) -> None:
    offenders = []
    for path in package_dir.rglob("*"):
        rel = path.relative_to(package_dir)
        if is_forbidden(rel):
            offenders.append(rel.as_posix())
    if offenders:
        sample = "\n".join(offenders[:20])
        raise SystemExit(f"Forbidden file or directory copied into package:\n{sample}")


def build_package(date_tag: str, allow_missing: bool) -> Path:
    dist_dir = ROOT / "dist"
    package_dir = dist_dir / f"mxfp8_npu_submission_{date_tag}"

    if package_dir.exists():
        resolved = package_dir.resolve()
        expected_parent = dist_dir.resolve()
        if resolved.parent != expected_parent:
            raise SystemExit(f"Refusing to remove unexpected package path: {resolved}")
        shutil.rmtree(package_dir)

    package_dir.mkdir(parents=True, exist_ok=True)

    copied: list[Path] = []
    missing: list[str] = []

    for rel_file in INCLUDE_FILES:
        src = ROOT / rel_file
        if not src.exists():
            missing.append(rel_file)
            continue
        copy_file(src, package_dir / rel_file, copied)

    for rel_dir in INCLUDE_DIRS:
        copy_tree(rel_dir, package_dir, copied, missing)

    for rel_dir in INCLUDE_TREE_DIRS:
        copy_tree(rel_dir, package_dir, copied, missing)

    for rel_file in INCLUDE_EXTRA_FILES:
        src = ROOT / rel_file
        if not src.exists():
            missing.append(rel_file)
            continue
        copy_file(src, package_dir / rel_file, copied)

    required_final_files = (
        "sim/run_submission_regression.ps1",
        "tools/package_submission.py",
        "docs/admin/final_submission_manifest.md",
        "docs/report/submission_report.md",
        "docs/report/12_backend_handoff_checklist.md",
        "docs/usage/02_synthesis_environment_check.md",
        "synth/rtl_filelist.f",
        "reports/evidence/final_evidence_index_2026-05-06.md",
        "reports/evidence/boundary_case_matrix.md",
        "reports/synthesis/environment_check_2026-05-06.md",
    )
    for rel_file in required_final_files:
        if not (package_dir / rel_file).exists():
            missing.append(rel_file)

    if missing and not allow_missing:
        shutil.rmtree(package_dir)
        missing_list = "\n".join(f"- {item}" for item in sorted(set(missing)))
        raise SystemExit(f"Cannot build complete submission package; missing:\n{missing_list}")

    write_package_manifest(package_dir, copied)
    assert_clean_package(package_dir)
    return package_dir


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--date",
        default=_dt.datetime.now().strftime("%Y%m%d"),
        help="Date tag for dist/mxfp8_npu_submission_YYYYMMDD",
    )
    parser.add_argument(
        "--allow-missing",
        action="store_true",
        help="Build a draft even if final report files are not present yet.",
    )
    args = parser.parse_args()

    package_dir = build_package(args.date, args.allow_missing)
    print(f"Built {package_dir}")
    print(f"Contents index: {package_dir / 'PACKAGE_CONTENTS.txt'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
