# Signed macOS releases and Homebrew

NextReset is distributed outside the Mac App Store using Developer ID Application signing and Apple notarization. The release currently targets Apple silicon and macOS 14 or later. No additional entitlements are needed: Codex runs as a separate installed process, not an embedded framework.

## One-time local setup

Install a Developer ID Application certificate with its private key in your login keychain. Confirm availability with `security find-identity -v -p codesigning`.

Store notarization credentials interactively in your own Terminal (substitute your team ID):

```sh
xcrun notarytool store-credentials "nextreset-notary" --team-id YOUR_TEAM_ID
```

Enter the Apple ID and its app-specific password when prompted. Do not commit passwords, private keys, or credential exports. The saved profile is local; only its name is supplied to the script.

## Build, notarize and package

Keep `AppInfo.version`, `CFBundleShortVersionString`, `CFBundleVersion`, and CHANGELOG in sync. Commit the reviewed release source before tagging it.

```sh
SIGNING_IDENTITY="Developer ID Application: Your Name (YOUR_TEAM_ID)" \
NOTARY_PROFILE="nextreset-notary" \
./scripts/notarize-release.sh
```

The script validates credentials, runs tests, creates a separate release directory, signs with hardened runtime and a secure timestamp, submits a ZIP to Apple, and requires status `Accepted`. It staples and validates the ticket, checks Gatekeeper, then creates the final distribution ZIP, SHA256SUMS.txt and matching `Casks/nextreset.rb`. Submission logs and intermediate archives stay in the ignored `dist/release.*` directory. Upload only the final versioned ZIP and SHA256SUMS.txt.

If Apple's processing exceeds the timeout, retain the output and submission ID; use `xcrun notarytool info ID --keychain-profile nextreset-notary` or `log ID` to inspect it. Do not publish an unaccepted submission. Staple and repackage after acceptance, or rerun the script for a fresh submission.

The ordinary `./scripts/build-app.sh` remains ad-hoc signed for development unless `SIGNING_IDENTITY` is set. It does not notarize. Never mistake a development build for the verified release archive.

## Publish

1. Publish a GitHub Release in `Anson2Dev/NextReset` whose tag matches the app version, attaching the verified versioned ZIP and SHA256SUMS.txt. Never overwrite an existing release archive with different contents.
2. Put the generated `Casks/nextreset.rb` in the public `Anson2Dev/homebrew-tap` repository. Its checksum must match the published ZIP, not the submission ZIP.
3. Run Homebrew Cask style/audit checks and an install/launch/uninstall check on a Mac. Preserve existing app installations and user settings during testing. Only then publish the tap change.
4. Update the website and README download links and signing statements after verifying the public release. The initial v0.1 archive remains ad-hoc signed and unnotarized.

Installation after the tap is published:

```sh
brew install --cask Anson2Dev/tap/nextreset
brew upgrade --cask nextreset
```

The Cask does not force-install or modify Codex. It also does not remove user data on uninstall.
