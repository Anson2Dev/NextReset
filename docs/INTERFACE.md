# Interface terminology and hierarchy

NextReset@TokenPark's main panel combines budget and forecast in one surface:

1. **Budget until reset** — total spendable quota in the selected plan, beside a live days/hours/minutes/seconds countdown. The exact reset date and time zone sit below the countdown.
2. **Tickets to use** — 0 / 1 / 2 / 3 ticket choices each show their total spendable quota. Unavailable counts are disabled. 💰 appears before the recommended option’s ticket label, independently of selection. The main panel has no Auto/Manual menu, Use Best button, or separate recommendation row. Hover help and accessibility hints identify provisional recommendations. Follow recommended plan remains available in Settings.
3. **Remaining quota** — the selected pool is forecast from Now to Reset. Both lines rise toward the finish: the remaining-quota axis has the starting budget at the bottom and 0% at the top. A green line shows sampled current pace, a gray dashed line reaches 0% exactly at Reset, and a checkered flag marks that top-right intersection. A running-person symbol follows the observed line's endpoint, without a “You” label. Consumption stops at zero when the pool would run out early. Missing pace shows only the ideal line; stale/error states hide the forecast.
4. **Reset Tickets** — available count and **Next expiry**, without an explanatory line below. Expiry does not mean quota reset.

Each forecast is a planning pool including future manual ticket redemptions, not a simulation of the live balance jumping at redemption. Budget calculations use all remaining quota and add 100% per selected ticket: with 37% remaining, totals are 37%, 137%, 237%, and 337%. There is no buffer setting or deduction; legacy saved buffer preferences are no longer read.

The chart uses one Canvas coordinate system with fixed plot insets. Flag, runner, endpoints, axes, and labels cannot resize the plot. Endpoint annotations and runner positions avoid both curves and each other. The popover is 440 points wide, up to 680 points tall; shorter screens scroll the content while retaining header/footer. Light and dark appearances use semantic foreground colors.

Plan Details contains recommendation reasoning, measurement definitions, manual-selection behavior, and the assumption that ticket redemption leaves the planning reset unchanged. This assumption still requires confirmation; the interface does not make the strategy a guarantee.

Settings contains Menu bar display, Follow recommended plan, Ticket reminders, and About (version, MIT license, author, website, email, and GitHub). Advanced contains daily capacity, and Locate Codex fallback. Settings uses compact control rows without explanatory paragraphs; the zero-capacity convention is available as hover help and notification permission status remains visible.

Percentages always denote quota; `% / day` denotes usage pace. The dashboard does not use a percentage progress bar for pace attainment. The contextual suggestion compares current and ideal pace in % / day.

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

## Visual verification

Debug builds can render synthetic previews without reading the quota cache or persisting settings:

```sh
swift run TokenPark --render-preview dist/ui-preview
```

Fixtures cover normal, fast, balanced, nearly balanced, zero, missing and large usage, zero quota, short reset windows, dark appearance, stale data, and a short screen. Production builds exclude this rendering command.
