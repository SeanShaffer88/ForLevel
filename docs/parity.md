# ForLevel behavior and verification matrix

Scope: selected mockup 04 and the agreed guidance-only addon. No competitor feature set is implied.

| Behavior | Automated verification | Client-only gate |
|---|---|---|
| Compact 320×325 black/red panel, five numbered rows, integrated white arrow/red ring | Explicit frame/font/texture mock APIs, geometry bounds, highlight and asset paths; approved SVG/PNG mockup | Native font metrics, clipping, UI scale, combat and game rendering |
| `/forlevel`, `/fl`, Back, Skip, Done, Undo, review/resume | Both aliases dispatch; actual button/slash handlers and reversible state tested | Hardware interactions in game |
| Accept, grouped/split objectives and confirmed turn-in advancement | Real engine with logged, ready, abandoned, turned-in, secret, nil and throwing quest states | Actual Forever event/API behavior |
| Character progress, position, visibility and manual history | Sanitizer and table round-trip; malformed/sparse/oversized entries and failed-guide Undo rejected | Real logout/reload persistence |
| Missing API recovery and navigation safety | Automatic recovery without reinitialization; vector factory, map/facing/member errors, invalid/secret coordinates and continent mismatch suppressed | Launch build compatibility and world coordinate accuracy |
| Learned map compatibility | Only accessible Zone metadata; interior parents bounded/cycle-checked; observed zone IDs override static IDs without replacing unrelated names | Localized zone naming and new-zone map metadata |
| Solo route filtering and chapter progression | 46 real guides; cycle-free chains; 90 profile superset; alternate accept paths, all 36 catch-up checkpoints, chapter handoff, explicit broken-link/cycle errors and terminal state | Actual solo feasibility, congestion, escorts/elites and new-zone coverage |
| Source navigation data | All 13,092 at/area/healer points examined; two explicit upstream invalid area points rejected and diagnosed; no coordinate clamping | Terrain/boats/flights/path obstruction |
| On-the-way and item-start guidance | Held compatible quests, unfinished objectives, deduplication, pending sorted drop hints and suppression after acceptance/turn-in | Actual quest-item/drop behavior |
| Fresh UI during state changes | Stale tooltip, rows and arrow cleared on step change, guide switch, API loss, completion and hide/show | Native hover/ownership behavior |
| Minimal purpose and provenance | No quest acceptance/reward, movement, messaging or telemetry calls; byte-preserved guide/static data and MIT notices | No claim of unattended automation |

All 28 main chapters remain source-marked drafts. The data is not an exhaustive or independently timed fastest 1–60 route. Class filtering is not class-specific route optimization. The selected route still lacks leveling quest coverage for some new zones, as documented in [research](research.md).

Local passing tests and GitHub CI do not establish the outstanding client-only gates. No new runtime dependency is required.
