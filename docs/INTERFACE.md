# Interface terminology and hierarchy

NextReset@TokenPark's main panel answers four questions in order:

1. **Next Reset** — a live countdown for the planning window; the date line names the window and time zone.
2. **Weekly remaining** — the remaining percentage of the weekly quota, when the service identifies a weekly window. Other windows use their own label.
3. **Daily Budget** — the recommended use per day for the selected ticket plan. **Current pace** uses the same `% / day` unit and represents sampled use, not today's accumulated consumption.
4. **Reset Tickets** — available count, **Next expiry**, and the buffer reminder. Expiry does not mean quota reset.

The four plan choices stay No ticket / 1 ticket / 2 tickets / 3 tickets. Best marks the recommendation; Auto or Manual names the selection mode. Manual selection exposes Use Best to restore automatic selection. Auto · Estimate identifies provisional recommendations.

Plan Details contains recommendation reasoning, measurement definitions, manual-selection behavior, and the assumption that ticket redemption leaves the planning reset unchanged. This assumption still requires confirmation; the interface does not make the strategy a guarantee.

Settings contains Auto-select Best, Ticket reminders, and About (version, MIT license, author, website, email, and GitHub). Advanced contains the buffer, daily capacity, and Locate Codex fallback.

Percentages always denote quota; `% / day` denotes usage pace. The dashboard does not use a percentage progress bar for pace attainment. The contextual suggestion may express a multiplier of the current pace.

Keep all interface text in English. Preserve the ivory/sage palette, system fonts, SF Symbols, compact popover, and separate detail pages.
