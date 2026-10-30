# WoW Forever leveling guide comparison

Method: Exa returned 25 result slots across server identity, guide discovery, API and licensing/download searches; linked pages were then read directly. Result slots are not a unique-source count.

Research snapshot: October 29, 2026. This is a source comparison and a proposed route-selection method, not a validated fastest 1–60 route or completed addon.

| Guide | Published approach | Value for this addon | Evidence limits |
|---|---|---|---|
| [BoostedXP](https://boostedxp.com/) | Time-based simulated routes adjusted using player data; advertises 28 routes covering 1–60. | Strongest stated emphasis on speed; useful candidate for comparing travel, kill and quest costs. | Predictions and simulation counts are publisher claims, not independent timed proof of fastest leveling. Its [author listing](https://www.curseforge.com/wow/addons/boostedxp) identifies an MIT license, says routes are planned and checked to 30, and labels 30–60 drafts until playable. Dungeons are optional and class quests are supported. |
| [Wowdee](https://wowdee.com/features/leveling-guides) | Explicit race starts and faction chapter sequences through 60; groups nearby pickups and objectives; optional dungeons and escorts. | Clear sequential baseline and recovery controls. | Chapter levels are a plan; the publisher explicitly says extra XP may be needed. No guaranteed completion time. |
| [4Ever Leveling](https://www.curseforge.com/wow/addons/foreverleveling) | Classic routes adapted for Forever, saved progress, quest-state advancement and navigation. | Reference for confirmed advancement and class/race filtering. | New race routes remain in development. The project is All Rights Reserved; its route dataset is not licensed for copying. |
| [Forever Routes](https://foreverroutes.com/) | Player-authored zone, quest and dungeon plans with prerequisite and projected XP checks. | Useful comparison for prerequisite-aware planning and batching dungeon turn-ins with later town visits. | Custom planning does not establish fastest routing; the site describes Forever quest coverage up to level 30 so far. |
| [WoW Forever Guides](https://wowforeverguides.com/leveling) | Zone brackets with travel and XP references; separates beta 1–30 from planned 31–60. | Useful zone-level cross-check. | Not a quest-by-quest speed benchmark; includes a RestedXP affiliate relationship. |
| [LFCarry](https://lfcarry.com/guides/wow-forever-leveling) | Broad zone route and roughly 150-hour estimate, assuming one run of each dungeon. | Secondary context only. | Commercial boosting provider; no timed solo dataset and dungeon assumptions conflict with the selected solo route. |
| [Mmonster](https://mmonster.co/wow-forever/guides/leveling/1-60) | Race starting hubs and faction zone brackets, including provisional new-zone choices. | Cross-check new-zone candidates. | Recommends dungeons and provides no per-quest timing evidence; new-zone brackets require validation. |
| [LootWoW](https://www.lootwow.com/news/wow-forever-1-60-leveling-time-guide-how-long-does-each-level-range-take) | General leveling-time advice rather than an ordered quest route. | Low weight for route selection. | Time units do not clearly distinguish played from calendar time; no ordered quest dataset. Do not adopt its estimates as targets. |

## Selected target

Official Blizzard WoW: Classic Forever, launching November 4, 2026. Solo leveling only, with all races and classes as the default coverage target. Routing assumes normal XP without rested XP or other bonuses unless the player changes that assumption. The exact launch client build still requires verification.

## Proposed routing criterion

Minimize expected elapsed time to the next XP checkpoint, including travel, combat, drops, turn-ins, training, transport and expected deaths. Batch nearby tasks while preserving prerequisites and quest-log capacity. Exclude dungeon, raid and group-only detours from the selected solo route; the intended future verification gate is to retain only quests with verified solo prerequisites. The current alpha excludes explicit dungeon steps and dependent chains, but lacks reliable group/elite metadata. Validate quest IDs, NPC positions and XP against the exact client/server; do not assume Classic quest data is unchanged.

No reviewed source establishes an independently measured optimum for every class and starting race. Advertised 1–60 coverage must be distinguished from current Forever-specific verification, particularly above level 30. Blizzard's [beta announcement](https://news.blizzard.com/en-us/article/24304160/the-world-of-warcraft-forever-beta-now-live) describes initial level-20 testing with a later increase to 30.

## Remaining verification

Confirm launch client build and APIs, validate licensed route data and solo prerequisite closure, and test in game. All-race/class coverage and normal XP are working defaults. Blizzard's [Forever starter guide](https://news.blizzard.com/en-us/article/24315280/new-players-starter-guide-welcome-to-world-of-warcraft-forever) confirms Forever includes new starting content, making those distinctions material.

The mockup uses invented sample quest labels and distance. The comparison summarizes sources; the separate draft addon reuses MIT-licensed BoostedXP guide data with attribution. No in-game test or optimality claim is made.

## Downloaded source audit

BoostedXP 1.0.6 route files were inspected directly: 28 leveling chapters, all marked draft, plus 18 class side guides; 513 dungeon-tagged steps and 36 no-dungeon catch-up steps. The copied files retain their source flags. This direct evidence qualifies broader marketing claims of checked early routes. The package SHA-256 is `F956FAAA044646C1E65E1D495A35B0D7FB16D0B2FB9DE6805D137F90221A1088`. Its main routes are warrior-planned and lack quest coverage for some new zones; neither class filtering nor a solo-only subset proves optimal leveling.
