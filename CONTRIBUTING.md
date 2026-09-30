# Contributing to NextReset@TokenPark

Run `swift test` and `./scripts/build-app.sh` on macOS before submitting a change.

Keep quota math and recommendation logic in TokenParkCore, separate from UI and authentication. Add deterministic tests for changes to reset boundaries, expiry handling, sampling, and recommendation selection. Never convert a missing value into a zero balance or invent an expiry time.

Use English UI copy. Keep the default popover compact; use a separate page for details or settings. Check light/dark appearance, keyboard access, a short display, stale-data states, and account changes.

Do not attach authentication files, raw account responses, local caches, account IDs, or ticket IDs to issues. Use synthetic test fixtures. Public v0.2 binaries are Developer ID signed and notarized. Release signing is maintainer-controlled; do not commit signing material. Local builds remain ad-hoc signed by default. See [RELEASING.md](docs/RELEASING.md).

For website changes, use `npm ci` and `npm run check:deploy`, then check desktop and mobile layouts and any changed interaction. See [DEPLOYMENT.md](docs/DEPLOYMENT.md). Documentation-only edits need link and consistency checks rather than rebuilding the app.
