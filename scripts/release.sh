#!/usr/bin/env bash
# Build, sign, notarize, and package Hangar as a distributable DMG.
#
# Prereqs (one-time):
#   1. Xcode + Command Line Tools installed
#   2. Developer ID Application certificate in your login keychain
#   3. notarytool keychain profile set up:
#        xcrun notarytool store-credentials AC_PASSWORD \
#          --apple-id <your-apple-id> --team-id AR8U26HF34 --password <app-specific-password>
#
# Usage:
#   ./scripts/release.sh                 # full flow
#   ./scripts/release.sh --skip-notarize # signed only, no notarization
#
# Override defaults via env vars: SIGN_IDENTITY, KEYCHAIN_PROFILE, TEAM_ID

set -euo pipefail

# ---- Config -----------------------------------------------------------------
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Himanshu Kumar (AR8U26HF34)}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-AC_PASSWORD}"
TEAM_ID="${TEAM_ID:-AR8U26HF34}"
SCHEME="Hangar"
PROJECT="Hangar.xcodeproj"
PRODUCT_NAME="Hangar"

SKIP_NOTARIZE=0
for arg in "$@"; do
  case "$arg" in
    --skip-notarize) SKIP_NOTARIZE=1 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# ---- Paths ------------------------------------------------------------------
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BUILD_DIR="$ROOT/build"
DIST_DIR="$ROOT/dist"
APP_PATH="$BUILD_DIR/Build/Products/Release/$PRODUCT_NAME.app"

VERSION="$(awk -F'"' '/CFBundleShortVersionString/ {print $2; exit}' "$ROOT/Hangar/Info.plist" 2>/dev/null || true)"
if [[ -z "$VERSION" ]]; then
  VERSION="$(awk '/CFBundleShortVersionString:/ {gsub(/[" ]/,""); split($0,a,":"); print a[2]; exit}' "$ROOT/project.yml")"
fi
[[ -n "$VERSION" ]] || { echo "could not determine version" >&2; exit 1; }

DMG_PATH="$DIST_DIR/${PRODUCT_NAME}-${VERSION}.dmg"

step() { printf "\n\033[1;34m==> %s\033[0m\n" "$*"; }

# ---- Prereq checks ----------------------------------------------------------
step "Checking prerequisites"
command -v xcodebuild >/dev/null || { echo "xcodebuild missing" >&2; exit 1; }
command -v hdiutil    >/dev/null || { echo "hdiutil missing" >&2; exit 1; }
command -v codesign   >/dev/null || { echo "codesign missing" >&2; exit 1; }
if (( ! SKIP_NOTARIZE )); then
  command -v xcrun >/dev/null || { echo "xcrun missing" >&2; exit 1; }
fi
security find-identity -v -p codesigning | grep -q "$SIGN_IDENTITY" \
  || { echo "signing identity not found: $SIGN_IDENTITY" >&2; exit 1; }
echo "version: $VERSION"
echo "identity: $SIGN_IDENTITY"

# ---- Build ------------------------------------------------------------------
step "Building Release"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  clean build \
  | xcbeautify --quiet 2>/dev/null || \
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  clean build

[[ -d "$APP_PATH" ]] || { echo "build did not produce $APP_PATH" >&2; exit 1; }

step "Verifying app signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

# ---- Notarize the .app (so it can be stapled) ------------------------------
if (( ! SKIP_NOTARIZE )); then
  step "Notarizing .app"
  ZIP_PATH="$BUILD_DIR/${PRODUCT_NAME}-${VERSION}.zip"
  rm -f "$ZIP_PATH"
  /usr/bin/ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait
  rm -f "$ZIP_PATH"

  step "Stapling .app"
  xcrun stapler staple "$APP_PATH"
  xcrun stapler validate "$APP_PATH"
fi

# ---- Build DMG --------------------------------------------------------------
step "Building DMG"
mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"

STAGING="$(mktemp -d -t hangar-dmg)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
  -volname "$PRODUCT_NAME" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$DMG_PATH" >/dev/null

step "Signing DMG"
codesign --sign "$SIGN_IDENTITY" --timestamp "$DMG_PATH"
codesign -dv --verbose=2 "$DMG_PATH"

# ---- Notarize the DMG ------------------------------------------------------
if (( ! SKIP_NOTARIZE )); then
  step "Notarizing DMG"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait

  step "Stapling DMG"
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"

  step "Gatekeeper assessment"
  spctl -a -t open --context context:primary-signature -v "$DMG_PATH"
fi

# ---- Done -------------------------------------------------------------------
SIZE="$(du -h "$DMG_PATH" | awk '{print $1}')"
printf "\n\033[1;32m✓ Release ready: %s (%s)\033[0m\n" "$DMG_PATH" "$SIZE"
