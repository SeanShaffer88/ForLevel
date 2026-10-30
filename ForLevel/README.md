# ForLevel — draft alpha

A small 320×325 charcoal/red quest list, following selected mockup 04, with its own white direction arrow in a red ring for official Blizzard WoW: Forever, Interface 16001. Guidance only: it does not accept quests, choose rewards, move, fight, send addon messages, or upload data. No runtime libraries are required.

## Install for testing

Extract the ZIP so that `ForLevel/ForLevel.toc` sits directly inside the selected Forever client's `Interface/AddOns` folder. Choose the Forever client in Battle.net; do not install into Retail or an unrelated Classic version. Enable the addon, then type `/forlevel` (or `/fl`). If the launch interface number changes, verify compatibility before changing the TOC. This is an alpha testing artifact; launch-client and in-game tests remain outstanding.

## Use

Drag the window to move it. Follow Accept, Do and Turn in steps in sequence. The arrow remains inside the list window and hides when bearing data is unavailable or you arrive. It is a straight-line bearing, not obstacle-aware pathfinding: use written boat, flight and zone instructions. Different continents, inaccessible/secret positions and unknown maps show no direction. Quest completion advances only from confirmed state; abandoned quests are never treated as turned in.

Back reviews an earlier step. `/forlevel resume` returns to automatic progression. Skip records a reversible manual skip; Done records a manual confirmation. Undo restores the last manual mark (up to 100 marks retained); use `/forlevel undo` or right-click Done. Right-click Back resumes automatic progression. A manual mark affects only this guide, never the quest log. Training, travel, hearth, flight-path discovery, flights, notes and death shortcuts require manual confirmation. Level checkpoints wait for the actual character level; solo catch-up checkpoints remain enabled. Optional death shortcuts can be skipped. Read the full current-step text by hovering over the window.

`/forlevel guides` lists compatible main and class side guides. `/forlevel guide ID` selects one. `/forlevel find QUESTID` opens the first available accept step for a missing prerequisite. Switching back to your previous guide is manual. `/forlevel show`, `/forlevel hide`, `/forlevel skip`, `/forlevel done`, `/forlevel undo`, `/forlevel back`, and `/forlevel help` are also available. Guide progress, position and visibility are saved per character by the game on logout/reload. Class side routes are available manually; they are not automatically woven into the main speed route.

The first selection uses faction, race and level. Starting at a higher level can reveal prerequisites from earlier chapters; use Find or select the earlier chapter, rather than assuming those quests were completed. Level-gated and item-start steps, plus dependent tasks, are automatically deferred without marking them done while other route work is available. Remaining missing prerequisites block explicitly; Find opens their accept step, and Skip records a manual bypass. If no other work is available at a level gate, grind XP to the required level. Unknown item-start quests require looting/using the item yourself. Some prerequisite chains can require manual recovery; the engine does not invent missing quests.

## Route provenance and limitations

Copied guide and static map/title/trainer data: BoostedXP 1.0.6 by Ragefarm, distributed under the full MIT notice in `LICENSE-BoostedXP.txt`. Source package downloaded from Wago; original ZIP SHA-256 `F956FAAA044646C1E65E1D495A35B0D7FB16D0B2FB9DE6805D137F90221A1088`. Original source pages: https://boostedxp.com/ and https://www.curseforge.com/wow/addons/boostedxp . The original addon implementation, automation, telemetry, export and announcement modules are not included. Core/UI/arrow implementation here is original.

The imported data has 28 leveling chapters and 18 class side guides. ALL 28 leveling chapters carry draft flags, including some early starters. The UI preserves draft and per-step verification warnings. The source author's public listing distinguishes checked/planned content to 30 from drafts above 30; neither statement establishes that every individual step was played or validated. No launch-client quest or XP validation has occurred here.

Solo mode excludes all 513 source dungeon-tagged steps and downstream chains whose only source accept requires them; it retains 36 no-dungeon grind checkpoints. Mixed quest batches retain eligible race/class quests, including per-quest filters. Non-dungeon elite, escort or otherwise difficult quests do not have reliable difficulty metadata in this source. Solo mode cannot guarantee every retained quest is safely soloable; skip unsuitable tasks and gain replacement XP at checkpoints.

The selected baseline is a researched speed candidate, not a proven optimum. Source comments describe the route planner as warrior-based; class filtering and side quests do not provide class-specific optimal speed routes. The original planner and timed dataset are absent. Source ETA fields include dungeon assumptions and are deliberately not displayed as solo completion estimates. Riverglades appears chiefly as boat travel; Mount Hyjal and Shen'dralas have no leveling quests in these guides. Those new-zone opportunities remain an optimization coverage gap. Normal XP without rested or other bonuses is the working assumption; the addon reads actual level but does not optimize for XP multipliers.

## Validation status

See `VALIDATION.md` for commands and results. Local static checks are not an in-game test. Before regular use, test cardinal arrow bearings, arrival, map transitions, secret/missing position handling, acceptance/abandonment/turn-in, split objectives, race/class filters, solo prerequisite chains, manual Undo and saved progress in the launch client. No fastest 1–60 time is promised.
