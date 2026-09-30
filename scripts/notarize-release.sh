#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${SIGNING_IDENTITY:?Set SIGNING_IDENTITY to your Developer ID Application certificate}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to your notarytool Keychain profile name}"
if [[ "$(uname -m)" != arm64 ]]; then
  echo "This release script currently builds the Apple silicon distribution only." >&2
  exit 1
fi
# Confirm credentials before starting a new build. No passwords enter this script.
xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" --output-format json >/dev/null
swift test
mkdir -p dist
RELEASE_DIR="$(mktemp -d "$PWD/dist/release.XXXXXX")"
export APP_OUTPUT_DIR="$RELEASE_DIR"
./scripts/build-app.sh
APP="$RELEASE_DIR/NextReset@TokenPark.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
ARCH="$(lipo -archs "$APP/Contents/MacOS/TokenPark")"
[[ "$ARCH" == arm64 ]] || { echo "Unexpected release architecture: $ARCH" >&2; exit 1; }
SUBMISSION="$RELEASE_DIR/notary-submission.zip"
ditto -c -k --keepParent "$APP" "$SUBMISSION"
echo "Submitting to Apple; results will be saved in $RELEASE_DIR/notary-result.json"
xcrun notarytool submit "$SUBMISSION" --keychain-profile "$NOTARY_PROFILE" \
  --wait --timeout 30m --output-format json > "$RELEASE_DIR/notary-result.json"
STATUS="$(plutil -extract status raw -o - "$RELEASE_DIR/notary-result.json")"
if [[ "$STATUS" != Accepted ]]; then
  cat "$RELEASE_DIR/notary-result.json"
  echo "Notarization did not succeed. No release archive or Cask was generated." >&2
  exit 1
fi
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
codesign --verify --deep --strict "$APP"
spctl --assess --type execute --verbose=2 "$APP"
# Hash only the final archive, after attaching Apple's notarization ticket.
ARCHIVE="NextReset-v${VERSION}-macOS-arm64.zip"
ditto -c -k --keepParent "$APP" "$RELEASE_DIR/$ARCHIVE"
(cd "$RELEASE_DIR" && shasum -a 256 "$ARCHIVE" > SHA256SUMS.txt)
SHA="$(shasum -a 256 "$RELEASE_DIR/$ARCHIVE" | cut -d ' ' -f 1)"
mkdir -p "$RELEASE_DIR/Casks"
cat > "$RELEASE_DIR/Casks/nextreset.rb" <<CASK
cask "nextreset" do
  version "$VERSION"
  sha256 "$SHA"

  url "https://github.com/Anson2Dev/NextReset/releases/download/v#{version}/NextReset-v#{version}-macOS-arm64.zip"
  name "NextReset@TokenPark"
  desc "Codex quota and reset ticket menu bar utility"
  homepage "https://nextreset.tokenpark.org/"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "NextReset@TokenPark.app"

  caveats <<~EOS
    Install and sign in to Codex CLI before launching NextReset.
  EOS
end
CASK
printf '\nVerified release files and matching Cask: %s\n' "$RELEASE_DIR"
