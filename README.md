# NextReset@TokenPark

**Put your AI allowance on a calmer schedule.**

**v0.2.1** · macOS 14+ · MIT License

[Website](https://nextreset.tokenpark.org) · [Download v0.2.1](https://github.com/Anson2Dev/NextReset/releases/tag/v0.2.1) · [GitHub](https://github.com/Anson2Dev/NextReset)

By **Anson Ho** — [anson.im](https://anson.im) · [anson@bestapp.us](mailto:anson@bestapp.us)

## Install

Install with Homebrew:

```sh
brew install --cask Anson2Dev/tap/nextreset
```

Or download the Apple silicon ZIP from [Releases](https://github.com/Anson2Dev/NextReset/releases/tag/v0.2.1), unzip it, and move **NextReset@TokenPark.app** to Applications. The v0.2.1 release is Developer ID signed and notarized by Apple, with the notarization ticket attached. Sign in to your Codex CLI before launching. Intel users can build from source on their Mac.

Update with `brew upgrade --cask nextreset`. If you installed the app manually, move that copy aside before installing through Homebrew.

Open **Settings → About** for version, author, website, email, and GitHub links.

NextReset@TokenPark is a native macOS menu bar utility for Codex allowance, reset tickets, and daily usage planning. It reads your existing local Codex sign-in through the app-server protocol and displays exact ticket expiry times in your time zone.

This is an independent community project, not an OpenAI product. Usage is displayed as `% / day`: the percentage of one full quota used per day, not a percentage of the remaining balance or a token count. For example, 20% / day consumes 20% of a full quota each day. Plans with reset tickets can exceed 100% / day.

## What you get

- A compact menu bar quota ring with a headroom dot and optional percentage and ticket count.
- An integrated budget dashboard with a full reset countdown and upward usage forecast.
- Four plans: **0 tickets**, **1 ticket**, **2 tickets**, **3 tickets**.
- A **💰** recommendation marker, with its reasoning in Plan Details and optional automatic selection in Settings.
- Exact expiry times, a collapsed ticket summary, and separate Settings and ticket-detail pages.
- A 30-minute refresh interval, stale-on-open/wake refresh, and manual refresh.
- Optional local notifications before expiry and when your quota is used up.
- No model inference, conversation reading, telemetry, or automatic ticket redemption.

## Requirements

- macOS 14 or later.
- Xcode 15+ / Swift 5.9+ to build.
- A current Codex CLI installation, already signed in with an eligible ChatGPT account.
- An account/server version that exposes rate limits; ticket details depend on service availability.

## Build and run

```sh
swift test
./scripts/build-app.sh
open "dist/NextReset@TokenPark.app"
```

The script builds for the current Mac architecture and applies a local ad-hoc signature by default. Set `SIGNING_IDENTITY` for Developer ID signing with hardened runtime and a secure timestamp. The separate notarization workflow produces a verified, stapled release archive and matching Homebrew Cask; see [Release instructions](docs/RELEASING.md). The published v0.1 archive remains unnotarized. This repository does not ship or alter Codex itself.

Codex discovery checks a saved executable, `TOKENPARK_CODEX_PATH`, common app/Homebrew/PATH locations, and common fnm/nvm installations. You can select the executable in Settings. No developer-specific executable path is embedded.

## Reading the menu bar

Settings → Menu bar offers three display modes: **Progress** (the default, ring only), **Progress + number** (remaining percentage), and **Progress + number + bank tickets** (percentage and a compact ticket count). Changes apply immediately and persist across launches. An exclamation mark inside the ring indicates that data needs refreshing. Ticket urgency and pace remain available in the dashboard and menu bar tooltip.

| Symbol | Meaning |
| --- | --- |
| Quota ring | Remaining allowance |
| Ticket outline | Available bank tickets (in the third display mode) |
| Filled ticket | A planned ticket is ready after quota is used up |
| Circled exclamation | Read failed, cache is stale, or ticket inventory needs refreshing |

The menu bar ring contains one status dot: green when observed daily use is below 90% of the selected plan's daily budget, amber from 90% through 110%, and red above 110%. A gray dot means there is not enough valid usage history. Stale data, connection errors, and unconfirmed ticket expiry show an exclamation mark instead. The tooltip and accessibility label also describe headroom in words.

Color is not the only status signal.

## Dashboard and settings

Next Reset stays at the top of the dashboard with a seconds-level countdown and the local reset date. The countdown updates only the display; account reads remain on the 30-minute schedule. When the deadline passes, it shows Awaiting refresh rather than a negative time.

Settings contains Menu bar display, Follow recommended plan, Ticket reminders, and About. Advanced contains daily capacity, and Locate Codex fallback. Codex is discovered automatically; the manual program picker is only for installations that cannot be found.

## Daily budget

For one ticket:

```text
(remaining + 100) / days until natural reset
```

All remaining quota is spendable. Each selected ticket contributes another full 100%, so the total budget is `remaining + 100 × tickets`. Plans assume each refill is redeemed after the previous quota is used up; redeeming earlier may discard a remaining balance.

Only the selected plan's tickets are counted. An inventory of three does not automatically mean all three should be spent this cycle. Unavailable tabs are disabled. Selecting a tab turns off automatic selection; turn **Follow recommended plan** back on in Settings to follow recommendations.

## What 💰 means

**The recommendation is a transparent planning heuristic, not a global optimization guarantee.** All plans assume redemption does not move the natural reset date; this behavior has not been independently established. Refresh after redemption to use the actual server-returned date.

1. If you enter an expected daily capacity, use that; otherwise use sampled pace after at least six hours of observation.
2. Prefer the **fewest tickets** whose budget covers that expected daily demand and whose earliest-expiring tickets can be redeemed before their deadlines at that pace. Keep a one-hour deadline margin.
3. If none can cover demand, suggest the largest timely candidate and explain the limitation.
4. Without enough history, the initial suggestion is explicitly provisional: suggest one ticket if it expires before the following natural cycle and fits the current plan; otherwise preserve tickets.
5. Unknown inventory or missing exact expiry data does not receive a fabricated recommendation marker.

The four-plan comparison covers the current natural-reset window, not every possible long-term schedule. It does not forecast future gifted tickets or other quota pools. More tickets increase the available budget but may not increase the amount of useful work you can complete.

## Sampling and reminders

Recent pace is consumption per valid sampled time, annualized to a 24-hour day. It is **not** an official daily usage ledger. At least 30 minutes of valid samples are required. Account changes, reset changes, ticket-count changes, balance increases, and intervals longer than an hour are excluded. Percentage rounding can make short observations noisy.

Enable reminders in Settings and allow macOS notifications. Known deadlines are scheduled for 24h and 3h beforehand; already-passed notice times are not replayed. The quota exhaustion reminder is evaluated when quota is refreshed. Sleep, power-off, notification settings, and Focus modes can affect delivery. The app does not keep your Mac awake.

## Privacy

NextReset starts `codex app-server --listen stdio://`, initializes a session, and calls `account/rateLimits/read`. Codex handles authentication and may contact OpenAI. NextReset does not directly read, save, or upload login tokens.

Local snapshots and quota samples are stored in `~/Library/Application Support/TokenPark/`. The raw account identifier is removed from the saved snapshot; a hash scopes samples to the correct account. Ticket IDs and quota metadata remain local. Preferences use the app's own UserDefaults. No caches, credentials, or developer-specific paths belong in the source repository.

## Development

```text
Sources/TokenParkCore/       Models, budget math, recommendation policy
Sources/TokenPark/           App-server reader, state, SwiftUI panel, menu bar
Tests/TokenParkCoreTests/    Deterministic planning and parsing tests
scripts/build-app.sh        Local .app packaging; optional Developer ID signing
scripts/notarize-release.sh Verified release ZIP and Homebrew Cask generation
scripts/generate-icon.swift App icon and logo raster generation
assets/                    Approved SVG, PNG and ICNS artwork
website/                    Static official website
wrangler.jsonc              Cloudflare deployment and custom domain
docs/examples/ci.yml        Optional macOS test/build workflow
```

The app uses no third-party packages. See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidance. The optional GitHub Actions workflow is in `docs/examples/ci.yml`. To enable it, copy it to `.github/workflows/ci.yml` using credentials with the `workflow` permission. Local tests and release builds can run without GitHub Actions.

Protocol reference: [OpenAI app-server documentation](https://learn.chatgpt.com/docs/app-server).

## Website deployment

The official site is served by Cloudflare Workers at **https://nextreset.tokenpark.org**. The HTML and CSS are static, with a small local script for copying the Homebrew installation command. A small Worker serves bundled text assets with caching, security headers, and a 404 page. Wrangler bundles the files during deployment.

```sh
npm ci
npm run dev
npm run check:deploy
npm run deploy
```

Deployment requires access to the Cloudflare account that owns `tokenpark.org`. The custom domain is declared in `wrangler.jsonc`; Wrangler manages its DNS and TLS setup. See [Cloudflare Workers](https://developers.cloudflare.com/workers/).

The Swift package and local storage retain the internal `TokenPark` identifier for compatibility. All user-facing release branding is NextReset@TokenPark.

## Documentation

See [Documentation index](docs/README.md) for interface decisions, icon regeneration, signing and releases, website deployment, and the verified v0.2.1 release record.

## License

MIT. See [LICENSE](LICENSE).
