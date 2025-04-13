#!/usr/bin/env bash
#
# Copyright (C) 2025 ohyeah521 <https://github.com/ohyeah521>
#
# This is free software, licensed under the GPLv3 License.
# See /LICENSE for more information.
#

install() {
  _process_file() {
    local file="${1}" url="${2}" mode="${3}"
    echo "Patch ${file}"
    [ ! -f "${file}_backup" ] && cp -pf "${file}" "${file}_backup"
    curl -skL "$url" -o "${file}"
    chown SurveillanceStation:SurveillanceStation "${file}"
    chmod "${mode}" "${file}"
  }

  REPO="${REPO:-"ohyeah521/Surveillance-Station"}"
  BRANCH="${BRANCH:-"main"}"

  STATUS="$(curl -s -m 10 -connect-timeout 10 -w "%{http_code}" "https://github.com/${REPO}/tree/${BRANCH}/${VERSION}/${ARCH}${SUFFIX}" -o /dev/null 2>/dev/null)"
  STATUS="${STATUS: -3}"
  case "${STATUS}" in
  "200") ;;
  "403")
    echo "Error: ${STATUS}, Access forbidden to the package on GitHub."
    exit 1
    ;;
  "404")
    echo "Error: ${STATUS}, Current version not found patch on GitHub."
    exit 1
    ;;
  *)
    echo "Error: ${STATUS}, Failed to download package from GitHub."
    exit 1
    ;;
  esac

  /usr/syno/bin/synopkg stop SurveillanceStation >/dev/null 2>&1
  sleep 5

  # 屏蔽认证服务器
  if grep -q "synosurveillance.synology.com" /etc/hosts; then
    echo "Already blocked license server: synosurveillance.synology.com."
  else
    echo "Add block license server: synosurveillance.synology.com"
    echo "0.0.0.0 synosurveillance.synology.com" | sudo tee -a /etc/hosts
  fi

  # 处理 patch 文件
  SS_PATH="/var/packages/SurveillanceStation/target"
  URL_FIX="https://github.com/${REPO}/raw/${BRANCH}/${VERSION}/${ARCH}${SUFFIX}"
  _process_file "${SS_PATH}/lib/libssutils.so" "${URL_FIX}/libssutils.so" 0644
  _process_file "${SS_PATH}/sbin/sscmshostd" "${URL_FIX}/sscmshostd" 0755
  _process_file "${SS_PATH}/sbin/sscored" "${URL_FIX}/sscored" 0755
  _process_file "${SS_PATH}/sbin/ssdaemonmonitord" "${URL_FIX}/ssdaemonmonitord" 0755
  _process_file "${SS_PATH}/sbin/ssexechelperd" "${URL_FIX}/ssexechelperd" 0755
  _process_file "${SS_PATH}/sbin/ssroutined" "${URL_FIX}/ssroutined" 0755
  _process_file "${SS_PATH}/sbin/ssmessaged" "${URL_FIX}/ssmessaged" 0755
  # _process_file "${SS_PATH}/sbin/ssrtmpclientd" "${URL_FIX}/ssrtmpclientd" 0755

  sleep 5
  /usr/syno/bin/synopkg start SurveillanceStation >/dev/null 2>&1
}

uninstall() {
  _process_file() {
    local file="${1}" suffix="${2}" mode="${3}"

    # 检查备份文件是否存在
    if [ -e "${file}${suffix}" ]; then
      echo "Restore ${file}"
      mv -f "${file}${suffix}" "${file}"
      chown SurveillanceStation:SurveillanceStation "${file}"
      chmod "${mode}" "${file}"
    else
      echo "Error: Backup files does not exist"
    fi
  }

  /usr/syno/bin/synopkg stop SurveillanceStation >/dev/null 2>&1
  sleep 5

  # 处理 patch 文件
  SS_PATH="/var/packages/SurveillanceStation/target"
  _process_file "${SS_PATH}/lib/libssutils.so" _backup 0644
  _process_file "${SS_PATH}/sbin/sscmshostd" _backup 0755
  _process_file "${SS_PATH}/sbin/sscored" _backup 0755
  _process_file "${SS_PATH}/sbin/ssdaemonmonitord" _backup 0755
  _process_file "${SS_PATH}/sbin/ssexechelperd" _backup 0755
  _process_file "${SS_PATH}/sbin/ssroutined" _backup 0755
  _process_file "${SS_PATH}/sbin/ssmessaged" _backup 0755
  # _process_file "${SS_PATH}/sbin/ssrtmpclientd" _backup 0755

  # 解除屏蔽认证服务器
  if grep -q "synosurveillance.synology.com" /etc/hosts; then
    echo "Unblocking license server: synosurveillance.synology.com"
    sudo sed -i '/synosurveillance.synology.com/d' /etc/hosts
  else
    echo "License server not blocked: synosurveillance.synology.com."
  fi

  sleep 5
  /usr/syno/bin/synopkg start SurveillanceStation >/dev/null 2>&1
}

if [ ! "${USER}" = "root" ]; then
  echo "Please run as root"
  exit 9
fi

if [ ! -x "/usr/syno/bin/synopkg" ]; then
  echo "Please run in Synology system"
  exit 1
fi

VERSION="$(/usr/syno/bin/synopkg version SurveillanceStation 2>/dev/null)"

if [ -z "${VERSION}" ]; then
  # TODO: install ?
  # /usr/syno/bin/synopkg chkupgradepkg 2>/dev/null
  # /usr/syno/bin/synopkg install_from_server SurveillanceStation

  echo "Please install Surveillance Station first"
  exit 1
fi

ARCH="$(synogetkeyvalue /var/packages/SurveillanceStation/INFO arch)"
SUFFIX=""
case "$(synogetkeyvalue /var/packages/SurveillanceStation/INFO model)" in
"synology_denverton_dva3219") SUFFIX="_dva_3219" ;;
"synology_denverton_dva3221") SUFFIX="_dva_3221" ;;
"synology_geminilake_dva1622") SUFFIX="_openvino" ;;
*) ;;
esac

echo "Found SurveillanceStation-${ARCH}-${VERSION}${SUFFIX}"

case "${1}" in
-r | --uninstall)
  uninstall
  ;;
*)
  install
  ;;
esac
