#!/usr/bin/env bash
# Discover how the official Bachata S4 APK ships its arm64 emulator binary,
# and try to swap in a rebuilt one.
#
# Usage: scripts/repack.sh <official.apk> <new-shadps4-arm64> <out.apk>
#
# Stage 1 (always): dump the layout so the next iteration has facts.
# Stage 2 (best effort): replace the binary, strip old signature, re-sign.
set -euo pipefail

apk=${1:?usage: repack.sh <apk> <new-binary> <out.apk>}
newbin=${2:?}
out=${3:?}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
report="$work/layout.txt"

{
  echo "== apk: $apk ($(stat -c%s "$apk") bytes)"
  echo "== entries matching runtime / native payloads"
  unzip -l "$apk" | grep -Ei 'shadps4|runtime|rootfs|\.tar|\.zst|\.so$|assets/' | head -300
  echo
  echo "== full entry count"
  unzip -l "$apk" | tail -1
} >"$report"
cat "$report"

# Locate candidate containers that may hold bin/shadps4-arm64.
mapfile -t candidates < <(unzip -Z1 "$apk" | grep -Ei '(runtime|rootfs|debian).*(\.tar|\.zst|\.gz|\.xz|\.zip)$|\.tar\.zst$' || true)
printf '\n== candidate payload containers: %s\n' "${#candidates[@]}"
printf '   %s\n' "${candidates[@]:-<none>}"

if [ "${#candidates[@]}" -eq 0 ]; then
  echo "RESULT: no runtime payload container found; needs manual inspection (see layout above)"
  exit 2
fi

echo "RESULT: containers found, automatic swap not attempted in this revision"
exit 2
