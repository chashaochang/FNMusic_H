#!/usr/bin/env bash

set -euo pipefail

release_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
release_project_root="$(cd "$release_script_dir/.." && pwd)"
release_app_config="$release_project_root/AppScope/app.json5"
release_build_profile="$release_project_root/build-profile.json5"

release_version_name="$(sed -nE 's/^[[:space:]]*"versionName"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$release_app_config" | head -n 1)"
if [[ -z "$release_version_name" ]]; then
  echo "无法从 AppScope/app.json5 读取 versionName" >&2
  exit 1
fi

release_deveco_root="${FNMUSIC_DEVECO_STUDIO_PATH:-${DEVECO_STUDIO_PATH:-}}"
if [[ -z "$release_deveco_root" ]]; then
  for release_candidate in \
    "/Applications/DevEco-Studio 3.app/Contents" \
    "/Applications/DevEco-Studio.app/Contents"; do
    if [[ -x "$release_candidate/tools/node/bin/node" && \
      -f "$release_candidate/tools/hvigor/bin/hvigorw.js" ]]; then
      release_deveco_root="$release_candidate"
      break
    fi
  done
fi

if [[ -z "$release_deveco_root" ]]; then
  echo "未找到 DevEco Studio，请设置 DEVECO_STUDIO_PATH" >&2
  exit 1
fi

release_node="$release_deveco_root/tools/node/bin/node"
release_hvigor="$release_deveco_root/tools/hvigor/bin/hvigorw.js"
release_sdk_home="${FNMUSIC_DEVECO_SDK_HOME:-$release_deveco_root/sdk}"
release_requested_build_mode="${FNMUSIC_BUILD_MODE:-release}"
release_effective_build_mode="$release_requested_build_mode"
release_temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/fnmusic-unsigned.XXXXXX")"
release_profile_backup="$release_temp_dir/build-profile.local.json5"
release_unsigned_profile="$release_temp_dir/build-profile.unsigned.json5"

if [[ "$release_requested_build_mode" != "debug" && "$release_requested_build_mode" != "release" ]]; then
  echo "FNMUSIC_BUILD_MODE 仅支持 debug 或 release" >&2
  exit 1
fi

cp "$release_build_profile" "$release_profile_backup"

restore_release_profile() {
  cp "$release_profile_backup" "$release_build_profile"
  rm -rf "$release_temp_dir"
}
trap restore_release_profile EXIT INT TERM

if ! git -C "$release_project_root" show :build-profile.json5 > "$release_unsigned_profile"; then
  echo "无法读取仓库中的未签名构建配置" >&2
  exit 1
fi

if grep -q '"signingConfig"[[:space:]]*:' "$release_unsigned_profile"; then
  echo "仓库 build-profile.json5 仍绑定签名配置，已中止未签名构建" >&2
  exit 1
fi

if grep -q '"signingConfig"[[:space:]]*:' "$release_build_profile"; then
  printf '检测到本机签名配置，将构建 %s 模式并仅导出 unsigned 产物。\n' \
    "$release_effective_build_mode"
else
  if [[ "$release_effective_build_mode" == "release" ]]; then
    release_effective_build_mode="debug"
    echo "未检测到本机签名配置，API 26 Beta 工具链自动回退到 debug 未签名构建。"
  fi
  cp "$release_unsigned_profile" "$release_build_profile"
fi

(
  cd "$release_project_root"
  DEVECO_SDK_HOME="$release_sdk_home" "$release_node" "$release_hvigor" \
    --mode module \
    -p product=default \
    -p module=entry@default \
    -p buildMode="$release_effective_build_mode" \
    assembleHap \
    --analyze=normal \
    --parallel \
    --incremental \
    --no-daemon
)

release_source_hap="$release_project_root/entry/build/default/outputs/default/entry-default-unsigned.hap"
if [[ ! -f "$release_source_hap" ]]; then
  echo "构建完成，但未找到未签名 HAP：$release_source_hap" >&2
  exit 1
fi

release_output_dir="$release_project_root/dist"
release_output_hap="$release_output_dir/FNMusic_H-$release_version_name-unsigned.hap"
release_checksum_file="$release_output_hap.sha256"
mkdir -p "$release_output_dir"
cp "$release_source_hap" "$release_output_hap"

release_checksum="$(shasum -a 256 "$release_output_hap" | awk '{print $1}')"
printf '%s  %s\n' "$release_checksum" "$(basename "$release_output_hap")" > "$release_checksum_file"

printf '未签名 HAP：%s\n' "$release_output_hap"
printf 'SHA-256：%s\n' "$release_checksum"
