# Verification record — 9.3.0-12139 x86_64

- Date: 2026-08-21 (Asia/Shanghai)
- Baseline commit: `b168413c9793f97883739d1c4031f596b0ccac18`
- Input: `official/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139`
- Output: `patch/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139`

## 1. Baseline behavior: requested payload is absent

Command:

```bash
set +e
git cat-file -e 'b168413c9793f97883739d1c4031f596b0ccac18:patch/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139' 2>&1
rc=$?
echo "EXIT_STATUS=$rc"
exit 0
```

Literal output and exit status:

```text
fatal: path 'patch/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139' exists on disk, but not in 'b168413c9793f97883739d1c4031f596b0ccac18'
EXIT_STATUS=128
```

This is the directory whose absence makes `activated.sh` take its HTTP-404 unsupported-version branch.

## 2. Modified behavior: resolver payload and exact hashes are present

Command:

```bash
support/9.3.0-12139-x86_64/verify.sh
rc=$?
echo "EXIT_STATUS=$rc"
exit "$rc"
```

Literal output and exit status:

```text
OK lib/libssutils.so: size=6463749 changed_bytes=63 sha256=1a1da8e6b161474e7693553f774e23df9542a98cd00929c8b789c77f6a1231e5
OK lib/libssffmpegutils.so: size=487984 changed_bytes=0 sha256=4dab20d159402d6b66696ac16cd4748d76f66c1a30ec7d7345c2347a2761fe66
OK sbin/sscmshostd: size=409715 changed_bytes=6 sha256=5bf9d50ce939e75446e6b652d9c6b42c97e65d03f9ab5cfc57261a0c1686d5d8
OK sbin/sscamerad: size=1209267 changed_bytes=0 sha256=073cf6f19e977202aadf333767c03e527d9ccd162f5aa7a8899925fe0149d588
OK sbin/sscored: size=46033 changed_bytes=7 sha256=b8985f191a32776be1d3443d783fe431165b654e68f00a17a3a5037623b9b316
OK sbin/ssdaemonmonitord: size=95643 changed_bytes=1 sha256=04748b34b631476715f45c971e6ef1994cbea0dd51f4efa94122a5007863029c
OK sbin/ssexechelperd: size=132563 changed_bytes=0 sha256=5909312180fce8ee604f1135acd3e447f260a6e7f572340a7a217730b5cd2ab4
OK sbin/ssroutined: size=215643 changed_bytes=11 sha256=8578d6c559977d9a1205b649a94128dd2ff3b3a5d38c36e7097b649b1657caf3
OK sbin/ssmessaged: size=309659 changed_bytes=3 sha256=a0c34be56bf864a79bdbd413d20790ff905d9f588307060e8959a67331fd72c2
OK SHA256SUMS: patch/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139/SHA256SUMS
OK activated.sh resolver payload: 9.3.0-12139 x86_64 (9 files)
OK support artifacts: BASELINE_SHA256SUMS MODIFIED_SHA256SUMS BINARY_DIFF.tsv
OK support verification complete
EXIT_STATUS=0
```

The verifier also asserts that only manifest-listed bytes differ, all files keep their baseline size, every payload file is an x86_64 ELF, and the three support listings match the manifest.

## 3. Literal modified bytes

Command:

```bash
python3 - <<'PY'
import json
from pathlib import Path
m=json.loads(Path('support/9.3.0-12139-x86_64/patch-manifest.json').read_text())
root=Path(m['output_root'])
for f in m['files']:
    data=(root/f['path']).read_bytes()
    for p in f.get('patches',[]):
        offset=int(p['offset'],0)
        size=len(bytes.fromhex(p['replacement']))
        print(f"OK {f['path']}@{offset:#x}={data[offset:offset+size].hex()}")
PY
printf 'EXIT_STATUS=%s\n' "$?"
```

Literal output and exit status:

```text
OK lib/libssutils.so@0x26eb70=31c0c3
OK lib/libssutils.so@0x27034f=7d
OK lib/libssutils.so@0x270452=7d
OK lib/libssutils.so@0x27053e=31c0909090
OK lib/libssutils.so@0x2739f3=7d
OK lib/libssutils.so@0x589db8=73796e6f6c6f67792e
OK lib/libssutils.so@0x589dc2=6f6d000000000000000000000000
OK lib/libssutils.so@0x589e08=3139322e3136382e3235302e3235300000000000000000000000000000
OK sbin/sscmshostd@0x225e0=31c0c3
OK sbin/sscmshostd@0x23540=31c0c3
OK sbin/sscored@0x4e14=e957ffffff90
OK sbin/sscored@0x6390=31c0c3
OK sbin/ssdaemonmonitord@0x7816=00
OK sbin/ssroutined@0x18af2=909090909090
OK sbin/ssroutined@0x1936b=e988f7ffff90
OK sbin/ssmessaged@0x11c80=31c0c3
EXIT_STATUS=0
```

## 4. Rollback and reapply

Input fixture: a byte-for-byte copy of the modified payload at `/tmp/ss12139-rollback.t18zZn`.

Commands:

```bash
support/9.3.0-12139-x86_64/rollback.sh /tmp/ss12139-rollback.t18zZn
support/9.3.0-12139-x86_64/reapply.sh /tmp/ss12139-rollback.t18zZn
diff -qr \
  patch/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139 \
  /tmp/ss12139-rollback.t18zZn/patch/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139
echo 'OK rollback/reapply byte-identical'
printf 'EXIT_STATUS=%s\n' "$?"
```

Literal output and exit status:

```text
OK rollback: patch/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139 -> .rollback/9.3.0-12139-x86_64
OK reapply: .rollback/9.3.0-12139-x86_64 -> patch/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139
OK rollback/reapply byte-identical
EXIT_STATUS=0
```

## Runtime boundary

The record above is deterministic static verification. It does not claim a completed DSM deployment. Live closure requires the target NAS to show package start success, nine replaced-file hashes, camera availability, an actual recording/playback check, and the expected license display; `./activated.sh -r` is the package-file rollback path.
