#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TOOL_PATH="$(realpath "${ROOT_PATH}/syno-archive")"

function synoArchive() {
  CACHE_DIR="/tmp/pat"

  echo "Getting syno archive"
  rm -rf "${TOOL_PATH}"
  mkdir -p "${TOOL_PATH}"
  rm -rf "${CACHE_DIR}"
  mkdir -p "${CACHE_DIR}"

  OLDPAT_URL="https://global.download.synology.com/download/DSM/release/7.0.1/42218/DSM_DS3622xs%2B_42218.pat"
  OLDPAT_FILE="DSM_DS3622xs+_42218.pat"
  STATUS=$(curl -# -w "%{http_code}" -kL "${OLDPAT_URL}" -o "${CACHE_DIR}/${OLDPAT_FILE}")
  if [ $? -ne 0 ] || [ ${STATUS} -ne 200 ]; then
    echo "[E] DSM_DS3622xs%2B_42218.pat download error!"
    rm -rf ${CACHE_DIR}
    exit 1
  fi

  mkdir -p "${CACHE_DIR}/ramdisk"
  tar -C "${CACHE_DIR}/ramdisk/" -xf "${CACHE_DIR}/${OLDPAT_FILE}" hda1.tgz 2>&1
  if [ $? -ne 0 ]; then
    echo "[E] extractor rd.gz error!"
    rm -rf ${CACHE_DIR}
    exit 1
  fi
  (cd "${CACHE_DIR}/ramdisk" && xz -dc <"hda1.tgz" | cpio -idm) >/dev/null 2>&1 || true

  solist=(
    "lib/libboost_filesystem.so.1.68.0 libboost_filesystem.so.1.68.0"
    "lib/libboost_system.so.1.68.0 libboost_system.so.1.68.0"
    "lib/libcrypto.so.1.1 libcrypto.so.1.1"
    "lib/libicudata.so.64.2 libicudata.so.64"
    "lib/libicui18n.so.64.2 libicui18n.so.64"
    "lib/libicuio.so.64.2 libicuio.so.64"
    "lib/libicuuc.so.64.2 libicuuc.so.64"
    "lib/libjson.so.1 libjson.so"
    "lib/libmsgpackc.so.2.0.0 libmsgpackc.so.2"
    "lib/libsodium.so libsodium.so"
    "lib/libsynocodesign.so.7 libsynocodesign.so.7"
    "lib/libsynocore.so.7 libsynocore.so.7"
    "lib/libsynocredentials.so.7 libsynocredentials.so.7"
    "lib/libsynocrypto.so.7 libsynocrypto.so.7"
    "syno/sbin/synoarchive synoarchive"
  )
  # Copy only necessary files
  for item in "${solist[@]}"; do
    IFS=' ' read -r S D <<<"${item}"
    cp -f "${CACHE_DIR}/ramdisk/usr/${S}" "${TOOL_PATH}/${D}"
  done

  rm -rf "${CACHE_DIR}" 2>/dev/null
}

function getOfficiallibs() {
  local VERSION="${1}"
  local SPK_URL="${2}"

  SS_NAME="$(basename "${SPK_URL}")"
  SS_PATH="$(basename "${SPK_URL}" .spk)"

  echo "Download ${SS_NAME}"
  curl -#kLO "${SPK_URL}"

  echo "extract ${SS_NAME}"
  mkdir -p "${ROOT_PATH}/extract"

  chmod -R +x "${TOOL_PATH}"
  LD_LIBRARY_PATH="${TOOL_PATH}" "${TOOL_PATH}/synoarchive" -vxf "${SS_NAME}" -C "${ROOT_PATH}/extract"

  if [ ! -f "${ROOT_PATH}/extract/package.tgz" ]; then
    echo "[E] ${SS_NAME} is not a valid package!"
    exit 1
  fi

  echo "extract ${ROOT_PATH}/extract/package.tgz"

  mkdir -p "${ROOT_PATH}/extract/package"
  (cd "${ROOT_PATH}/extract/package" && xz -dc <"${ROOT_PATH}/extract/package.tgz" | cpio -idm ${PATCH_LIST}) >/dev/null 2>&1 || true

  mkdir -p "${ROOT_PATH}/${VERSION}/${SS_PATH}"
  rm -rf "${ROOT_PATH}/${VERSION}/${SS_PATH}"
  mv -f "${ROOT_PATH}/extract/package" "${ROOT_PATH}/${VERSION}/${SS_PATH}"

  rm -rf "${ROOT_PATH}/extract"
  rm -f "${SS_NAME}"
}

[ ! -f "${TOOL_PATH}/synoarchive" ] && synoArchive

RE_VERSION="${RE_VERSION:-"9.2"}"
PATCH_LIST="${PATCH_LIST:-"bin/ssctl  lib/libssutils.so sbin/ssactruled sbin/sscmshostd sbin/sscored sbin/ssdaemonmonitord sbin/ssexechelperd sbin/ssroutined sbin/ssmessaged sbin/ssrtmpclientd webapi/Camera/src/SYNO.SurveillanceStation.Camera.so"}"  

SS_URL="https://archive.synology.com/download/Package/SurveillanceStation"
VER_LIST="$(curl -skL "${SS_URL}" | grep -oP '(?<=href="/download/Package/SurveillanceStation/)[^"]*' | awk -v ver="${RE_VERSION}" -F"-" '$1 >= ver')"

for V in ${VER_LIST}; do
  SPK_LSIT="$(curl -skL "${SS_URL}/${V}" | grep -oP '(?<=href=")http[^"]+\.spk')"
  for S in ${SPK_LSIT}; do
    getOfficiallibs "${V}" "${S}"
  done
done
