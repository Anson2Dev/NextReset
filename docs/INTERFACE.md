# Interface terminology and hierarchy

NextReset@TokenPark's main panel answers four questions in order:

1. **Next Reset** — a live countdown for the planning window; the date line names the window and time zone.
2. **Weekly remaining** — the remaining percentage of the weekly quota, when the service identifies a weekly window. Other windows use their own label.
3. **Daily Budget** — the recommended use per day for the selected ticket plan. **Current pace** uses the same `% / day` unit and represents sampled use, not today's accumulated consumption.
4. **Reset Tickets** — available count, **Next expiry**, and the buffer reminder. Expiry does not mean quota reset.

The four plan choices stay No ticket / 1 ticket / 2 tickets / 3 tickets. Best marks the recommendation; Auto or Manual names the selection mode. Manual selection exposes Use Best to restore automatic selection. Auto · Estimate identifies provisional recommendations.

Plan Details contains recommendation reasoning, measurement definitions, manual-selection behavior, and the assumption that ticket redemption leaves the planning reset unchanged. This assumption still requires confirmation; the interface does not make the strategy a guarantee.

Settings contains Menu bar display, Auto-select Best, Ticket reminders, and About (version, MIT license, author, website, email, and GitHub). Advanced contains the buffer, daily capacity, and Locate Codex fallback.

Percentages always denote quota; `% / day` denotes usage pace. The dashboard does not use a percentage progress bar for pace attainment. The contextual suggestion may express a multiplier of the current pace.

Keep all interface text in English. Preserve the ivory/sage palette, system fonts, SF Symbols, compact popover, and separate detail pages.

## Menu bar

Settings offers exactly three modes, persisted in `menuBarDisplay`:

| Mode | Content |
| --- | --- |
| Progress (default) | 17-point remaining-quota ring and center status dot |
| Progress + number | Ring and remaining percentage |
| Progress + number + bank tickets | Ring, percentage, ticket symbol and available count |

No pace arrows or ticket words are appended to the title. The tooltip and accessibility label retain remaining quota, ticket count, headroom, and status details.

The dot compares observed daily usage with the selected plan's daily budget: below 90% is green, 90–110% inclusive is amber, and above 110% is red. Missing/invalid data is unknown (gray); stale/error/expired-ticket states replace the dot with an exclamation mark. With zero budget, positive usage is tight and zero usage is balanced. Ticket urgency is described separately and does not determine the dot color.

## Approved identity

The fixed logo is a three-quarter charcoal ring, a gray remainder, and three vertical dots: green, amber, red from top to bottom. The menu bar uses only one changing dot. The app icon has an ivory rounded-square background; the standalone logo PNG is transparent.

- `assets/nextreset-logo.svg`: editable vector mark.
- `scripts/generate-icon.swift`: native renderer for PNGs and macOS icon sizes. It draws geometry directly; it does not read the SVG. Keep both in sync.
- `assets/AppIcon.icns`: packaged app icon, explicitly loaded from the bundle in About to avoid stale macOS icon-cache artwork.
- `assets/nextreset-logo.png`: standalone logo, also included in the app bundle.
- `assets/app-icon-preview.png`: small preview for documentation/review.
- `NextResetMark` in `Dashboard.swift`: native foreground colors for light/dark app headers.
- `website/index.html`: inline vector mark using the site's foreground color.

Regenerate after changing the artwork:

```sh
swift scripts/generate-icon.swift assets
iconutil -c icns assets/AppIcon.iconset -o assets/AppIcon.icns
./scripts/build-app.sh
```

`assets/AppIcon.iconset/` is ignored intermediate output. Existing signed/notarized releases must not be edited; new artwork requires a new app release.

## Website installation entry

The Homebrew command is centered across the top of the hero. A native Copy button writes the exact single-line command, shows Copied briefly, and announces success. If clipboard access fails, the script selects the command and explains manual copying. The button stays hidden when JavaScript is unavailable. On narrow screens the command wraps visually and the button moves below it; copied text retains a single line.
