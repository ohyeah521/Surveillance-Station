# Surveillance Station 9.3.0-12139 x86_64 support

## Scope

- Upstream baseline: `b168413c9793f97883739d1c4031f596b0ccac18`
- Package: `SurveillanceStation-x86_64-9.3.0-12139`
- Variant: standard x86_64 NAS package; DVA and ARM payloads are not included.
- Runtime payload: `patch/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139`

`activated.sh` already resolves the package version and architecture into that exact directory, so no resolver change is required.

## Reproducible build

The original files remain under `official/9.3.0-12139/...`. The modified files are always regenerated from those originals with guarded, fixed-width edits:

```bash
python3 tools/build_binary_patch.py \
  --manifest support/9.3.0-12139-x86_64/patch-manifest.json
```

Every patch record asserts the original bytes before writing. A wrong build, offset, overlapping edit, size change, unexpected extra byte change, or checksum mismatch makes the command exit non-zero.

## Verification

```bash
support/9.3.0-12139-x86_64/verify.sh
```

This checks:

1. `activated.sh` shell syntax;
2. all nine files expected by its `PATCH_FILES` array;
3. baseline and modified SHA-256 values;
4. exact manifest-only byte differences;
5. unchanged file sizes and x86_64 ELF headers;
6. the baseline, modified, and human-readable diff support artifacts.

The compatibility work is statically verified. A real DSM run is still required to confirm package start, camera availability, recording, playback, and the license display on the target NAS.

## Patch design notes

- Six files contain fixed-width changes: `libssutils.so`, `sscmshostd`, `sscored`, `ssdaemonmonitord`, `ssroutined`, and `ssmessaged`.
- `libssffmpegutils.so`, `sscamerad`, and `ssexechelperd` are included unchanged because the direct successors of the 9.2.5 patched branches already follow the old patched destinations. Two separate 9.3.0 `sscamerad` 93600-second predicates—including newly introduced AVC1 handling—are intentionally left intact rather than treated as mechanical replacements for the deleted gates.
- In `sscamerad`, the old first gate's successor now jumps directly from VA `0x4B5735` to the old patched destination at VA `0x4B56B9`. The old second caller gate is absent after VA `0x4D4C82`; the later `IsAVC1`/`SetAVC1` predicate is new to 9.3.0 (those symbols do not exist in 9.2.5), so it is not rewritten by this compatibility patch.
- `BINARY_DIFF.tsv` is the human-readable offset table; `patch-manifest.json` is the machine-verifiable source of truth.

## Rollback

Repository payload rollback (moves the payload into a recoverable archive):

```bash
support/9.3.0-12139-x86_64/rollback.sh
```

Reapply the archived payload:

```bash
support/9.3.0-12139-x86_64/reapply.sh
```

On a NAS where `activated.sh` has already replaced package files, use its existing restore path:

```bash
./activated.sh -r
```

Until this branch is pushed or merged into the remote selected by `activated.sh`, use the offline workflow from this checkout. For an online test against a pushed fork/branch, set the script's existing `REPO` and `BRANCH` environment variables to that remote first.
