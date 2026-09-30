# Changelog

## v0.2.1 — 2026-10-01

- Integrated total budget, full reset countdown and ticket-plan selection in one dashboard.
- Added an upward quota forecast with a reset flag, running-person marker and collision-aware labels.
- Marked the recommended plan with 💰 and removed Auto/Manual and Use Best controls from the dashboard.
- Removed the buffer setting and deductions: each selected ticket adds a full 100% to the remaining quota.
- Simplified Settings, Advanced and ticket details, with a compact adaptive settings window.
- Added forecast edge-case tests and synthetic native UI previews for light/dark and boundary states.

## Website and documentation — 2026-09-30

- Centered Homebrew installation command with a Copy button and mobile layout.
- Updated website logo, v0.2 links and Apple notarization notice.
- Consolidated interface, release, deployment and verified v0.2 records; removed local intermediate artifacts.
- Website asset versions are cache keys and do not change the v0.2 app release.

## v0.2 — 2026-09-30

- Compact menu bar with three persistent display modes; progress-only is the default.
- Quota headroom dot based on observed pace versus daily budget, with unknown and stale states.
- New three-color ring app icon, logo, and About artwork.
- Developer ID signed and Apple-notarized Apple silicon release, with a stapled ticket and Homebrew Cask distribution.

## v0.1 — 2026-09-30

Initial public release of NextReset@TokenPark.

- Native macOS menu bar allowance display and live reset countdown.
- Daily budget comparison for zero to three reset tickets.
- Sampled usage pace, recommendation explanations, and optional ticket reminders.
- Settings → About with author Anson Ho, contact links, GitHub, and MIT licensing.
- Static official website at https://nextreset.tokenpark.org.

Requires macOS 14+ and a signed-in Codex CLI. The downloadable Apple silicon build is ad-hoc signed, not notarized. Ticket availability depends on the account and service.
