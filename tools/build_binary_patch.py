#!/usr/bin/env python3
"""Build and verify byte-patch payloads from an explicit JSON manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def decode_hex(value: str, field: str) -> bytes:
    try:
        return bytes.fromhex(value)
    except ValueError as exc:
        raise ValueError(f"invalid hex in {field}: {value!r}") from exc


def load_manifest(path: Path) -> dict:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    required = {"version", "architecture", "baseline_root", "output_root", "files"}
    missing = sorted(required - manifest.keys())
    if missing:
        raise ValueError(f"manifest is missing fields: {', '.join(missing)}")
    return manifest


def apply_entries(source: bytes, entries: list[dict], relpath: str) -> bytes:
    output = bytearray(source)
    occupied: set[int] = set()

    for index, entry in enumerate(entries):
        offset = int(entry["offset"], 0)
        expected = decode_hex(entry["expected"], f"{relpath}[{index}].expected")
        replacement = decode_hex(entry["replacement"], f"{relpath}[{index}].replacement")
        if len(expected) != len(replacement):
            raise ValueError(
                f"{relpath}: size-changing patch at {offset:#x} "
                f"({len(expected)} != {len(replacement)})"
            )
        if offset < 0 or offset + len(expected) > len(source):
            raise ValueError(f"{relpath}: patch at {offset:#x} is outside the file")
        span = set(range(offset, offset + len(expected)))
        if occupied & span:
            raise ValueError(f"{relpath}: overlapping patch at {offset:#x}")
        occupied |= span
        actual = source[offset : offset + len(expected)]
        if actual != expected:
            raise ValueError(
                f"{relpath}: baseline mismatch at {offset:#x}: "
                f"expected {expected.hex()}, got {actual.hex()}"
            )
        output[offset : offset + len(replacement)] = replacement

    return bytes(output)


def expected_diff_positions(source: bytes, entries: list[dict]) -> set[int]:
    positions: set[int] = set()
    for entry in entries:
        offset = int(entry["offset"], 0)
        replacement = decode_hex(entry["replacement"], "replacement")
        positions.update(
            offset + index
            for index, value in enumerate(replacement)
            if source[offset + index] != value
        )
    return positions


def verify_file(source: bytes, target: bytes, spec: dict) -> None:
    relpath = spec["path"]
    if not source.startswith(b"\x7fELF"):
        raise ValueError(f"{relpath}: baseline is not an ELF file")
    if source[4:6] != b"\x02\x01" or int.from_bytes(source[18:20], "little") != 62:
        raise ValueError(f"{relpath}: baseline is not a little-endian x86_64 ELF")
    if target[0:20] != source[0:20]:
        raise ValueError(f"{relpath}: patched ELF header changed")
    if len(source) != len(target):
        raise ValueError(f"{relpath}: file size changed ({len(source)} -> {len(target)})")
    baseline_hash = sha256(source)
    if baseline_hash != spec["baseline_sha256"]:
        raise ValueError(
            f"{relpath}: baseline SHA-256 mismatch: "
            f"expected {spec['baseline_sha256']}, got {baseline_hash}"
        )

    expected_target = apply_entries(source, spec.get("patches", []), relpath)
    if target != expected_target:
        actual_diff = {i for i, pair in enumerate(zip(source, target)) if pair[0] != pair[1]}
        wanted_diff = expected_diff_positions(source, spec.get("patches", []))
        extra = sorted(actual_diff - wanted_diff)
        missing = sorted(wanted_diff - actual_diff)
        raise ValueError(
            f"{relpath}: target differs from manifest; "
            f"extra={[hex(i) for i in extra[:8]]}, "
            f"missing={[hex(i) for i in missing[:8]]}"
        )
    target_hash = sha256(target)
    expected_target_hash = spec.get("patched_sha256")
    if expected_target_hash and target_hash != expected_target_hash:
        raise ValueError(
            f"{relpath}: patched SHA-256 mismatch: "
            f"expected {expected_target_hash}, got {target_hash}"
        )


def run(manifest_path: Path, verify_only: bool) -> int:
    manifest = load_manifest(manifest_path)
    baseline_root = REPO_ROOT / manifest["baseline_root"]
    output_root = REPO_ROOT / manifest["output_root"]
    if not baseline_root.is_dir():
        raise ValueError(f"baseline directory does not exist: {baseline_root}")
    output_root.mkdir(parents=True, exist_ok=True)

    hash_lines: list[str] = []
    for spec in manifest["files"]:
        relpath = spec["path"]
        source_path = baseline_root / relpath
        target_path = output_root / relpath
        source = source_path.read_bytes()
        if sha256(source) != spec["baseline_sha256"]:
            raise ValueError(f"{relpath}: baseline SHA-256 does not match manifest")

        if not verify_only:
            target = apply_entries(source, spec.get("patches", []), relpath)
            target_path.parent.mkdir(parents=True, exist_ok=True)
            target_path.write_bytes(target)
            shutil.copymode(source_path, target_path)
        else:
            target = target_path.read_bytes()

        verify_file(source, target, spec)
        target_hash = sha256(target)
        hash_lines.append(f"{target_hash}  {relpath}")
        changed = sum(a != b for a, b in zip(source, target))
        print(f"OK {relpath}: size={len(target)} changed_bytes={changed} sha256={target_hash}")

    sums_path = output_root / "SHA256SUMS"
    expected_sums = "\n".join(hash_lines) + "\n"
    if verify_only:
        if sums_path.read_text(encoding="utf-8") != expected_sums:
            raise ValueError(f"checksum file does not match: {sums_path}")
    else:
        sums_path.write_text(expected_sums, encoding="utf-8")
    print(f"OK SHA256SUMS: {sums_path.relative_to(REPO_ROOT)}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    try:
        return run(args.manifest.resolve(), args.verify_only)
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
