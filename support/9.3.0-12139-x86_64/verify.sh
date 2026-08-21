#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="${ROOT}/support/9.3.0-12139-x86_64/patch-manifest.json"

bash -n "${ROOT}/activated.sh"
python3 "${ROOT}/tools/build_binary_patch.py" --manifest "${MANIFEST}" --verify-only

python3 - "${ROOT}" "${MANIFEST}" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
manifest = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
script = (root / "activated.sh").read_text(encoding="utf-8")
match = re.search(r"PATCH_FILES=\(\n(?P<body>.*?)\n\)", script, flags=re.DOTALL)
if not match:
    raise SystemExit("PATCH_FILES array not found in activated.sh")
script_files = re.findall(r'"([^"]+)"', match.group("body"))
manifest_files = [entry["path"] for entry in manifest["files"]]
if script_files != manifest_files:
    raise SystemExit(
        "activated.sh/manifest mismatch:\n"
        f"  activated.sh={script_files}\n"
        f"  manifest={manifest_files}"
    )

payload = root / manifest["output_root"]
for relpath in script_files:
    path = payload / relpath
    if not path.is_file():
        raise SystemExit(f"missing payload file: {path}")

support = root / "support/9.3.0-12139-x86_64"
baseline_sums = "".join(
    f"{entry['baseline_sha256']}  {entry['path']}\n" for entry in manifest["files"]
)
modified_sums = "".join(
    f"{entry['patched_sha256']}  {entry['path']}\n" for entry in manifest["files"]
)
diff_lines = ["file\toffset\texpected\treplacement\tnote"]
for entry in manifest["files"]:
    for patch in entry.get("patches", []):
        diff_lines.append(
            "\t".join(
                [
                    entry["path"],
                    patch["offset"],
                    patch["expected"],
                    patch["replacement"],
                    patch["note"],
                ]
            )
        )
binary_diff = "\n".join(diff_lines) + "\n"
for name, expected in (
    ("BASELINE_SHA256SUMS", baseline_sums),
    ("MODIFIED_SHA256SUMS", modified_sums),
    ("BINARY_DIFF.tsv", binary_diff),
):
    actual = (support / name).read_text(encoding="utf-8")
    if actual != expected:
        raise SystemExit(f"support artifact does not match manifest: {support / name}")
print(f"OK activated.sh resolver payload: {manifest['version']} {manifest['architecture']} ({len(script_files)} files)")
print("OK support artifacts: BASELINE_SHA256SUMS MODIFIED_SHA256SUMS BINARY_DIFF.tsv")
PY

echo "OK support verification complete"
