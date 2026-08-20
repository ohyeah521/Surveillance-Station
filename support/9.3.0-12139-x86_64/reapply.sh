#!/usr/bin/env bash
set -euo pipefail

DEFAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT="${1:-${DEFAULT_ROOT}}"
REL="patch/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139"
TARGET="${ROOT}/${REL}"
ARCHIVE="${ROOT}/.rollback/9.3.0-12139-x86_64"

if [[ ! -d "${ARCHIVE}" ]]; then
  echo "ERROR missing rollback archive: ${ARCHIVE}" >&2
  exit 1
fi
if [[ -e "${TARGET}" ]]; then
  echo "ERROR payload already exists: ${TARGET}" >&2
  exit 1
fi

mkdir -p "$(dirname "${TARGET}")"
mv "${ARCHIVE}" "${TARGET}"
test -d "${TARGET}"
test ! -e "${ARCHIVE}"
echo "OK reapply: .rollback/9.3.0-12139-x86_64 -> ${REL}"
