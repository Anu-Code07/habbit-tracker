#!/usr/bin/env bash
# Pulse release build helper
# Usage:
#   ./scripts/release_build.sh              # APK (default)
#   ./scripts/release_build.sh apk
#   ./scripts/release_build.sh aab
#   ./scripts/release_build.sh ipa
#   ./scripts/release_build.sh apk --install 00162357C001079
#   ./scripts/release_build.sh apk --install A059 --launch

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Pulse release build helper

Usage:
  ./scripts/release_build.sh [apk|aab|ipa] [--install DEVICE] [--launch]

Examples:
  ./scripts/release_build.sh
  ./scripts/release_build.sh apk
  ./scripts/release_build.sh aab
  ./scripts/release_build.sh ipa
  ./scripts/release_build.sh apk --install A059
  ./scripts/release_build.sh apk --install 00162357C001079 --launch

Notes:
  Android builds pass --no-tree-shake-icons (runtime habit IconData).
  --install accepts adb serial or model name from `adb devices -l`.
EOF
  exit 0
fi

TARGET="${1:-apk}"
shift || true

INSTALL_ID=""
LAUNCH=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      INSTALL_ID="${2:-}"
      if [[ -z "$INSTALL_ID" ]]; then
        echo "error: --install requires a device id or model (e.g. A059)" >&2
        exit 1
      fi
      shift 2
      ;;
    --launch)
      LAUNCH=1
      shift
      ;;
    *)
      echo "error: unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

VERSION_LINE="$(grep '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
VERSION_NAME="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"
APP_ID="com.pulse.pulse"

# Habit icons use runtime IconData(codePoint) — tree-shake must stay off.
NO_SHAKE=(--no-tree-shake-icons)

resolve_device() {
  local query="$1"
  if adb devices | awk 'NR>1 && $2=="device" {print $1}' | grep -qx "$query"; then
    echo "$query"
    return
  fi
  # Match model name from `adb devices -l` (e.g. A059)
  local id
  id="$(adb devices -l | awk -v m="model:$query" '
    $2 == "device" {
      for (i = 3; i <= NF; i++) if ($i == m) { print $1; exit }
    }')"
  if [[ -n "$id" ]]; then
    echo "$id"
    return
  fi
  echo "error: device not found: $query" >&2
  adb devices -l >&2
  exit 1
}

echo "==> Pulse release build"
echo "    version: $VERSION_NAME+$BUILD_NUMBER"
echo "    target:  $TARGET"
echo

case "$TARGET" in
  apk)
    flutter build apk --release "${NO_SHAKE[@]}"
    ARTIFACT="build/app/outputs/flutter-apk/app-release.apk"
    ;;
  aab|appbundle|bundle)
    flutter build appbundle --release "${NO_SHAKE[@]}"
    ARTIFACT="build/app/outputs/bundle/release/app-release.aab"
    ;;
  ipa|ios)
    flutter build ipa --release
    ARTIFACT="build/ios/ipa"
    ;;
  *)
    echo "error: target must be apk | aab | ipa" >&2
    exit 1
    ;;
esac

echo
echo "==> Built: $ARTIFACT"
if [[ -f "$ARTIFACT" ]]; then
  ls -lh "$ARTIFACT"
elif [[ -d "$ARTIFACT" ]]; then
  ls -lh "$ARTIFACT"
fi

if [[ -n "$INSTALL_ID" ]]; then
  if [[ "$TARGET" != "apk" ]]; then
    echo "error: --install only works with apk" >&2
    exit 1
  fi
  DEVICE="$(resolve_device "$INSTALL_ID")"
  echo
  echo "==> Installing on $DEVICE"
  adb -s "$DEVICE" install -r "$ARTIFACT"
  if [[ "$LAUNCH" -eq 1 ]]; then
    echo "==> Launching $APP_ID"
    adb -s "$DEVICE" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null
  fi
fi

echo
echo "Done."
