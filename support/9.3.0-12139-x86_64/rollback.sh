#!/usr/bin/env bash
set -euo pipefail

DEFAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT="${1:-${DEFAULT_ROOT}}"
REL="patch/9.3.0-12139/SurveillanceStation-x86_64-9.3.0-12139"
TARGET="${ROOT}/${REL}"
ARCHIVE="${ROOT}/.rollback/9.3.0-12139-x86_64"

if [[ ! -d "${TARGET}" ]]; then
  echo "ERROR missing payload: ${TARGET}" >&2
  exit 1
fi
if [[ -e "${ARCHIVE}" ]]; then
  echo "ERROR rollback archive already exists: ${ARCHIVE}" >&2
  exit 1
fi

mkdir -p "$(dirname "${ARCHIVE}")"
mv "${TARGET}" "${ARCHIVE}"
test ! -e "${TARGET}"
test -d "${ARCHIVE}"
echo "OK rollback: ${REL} -> .rollback/9.3.0-12139-x86_64"
