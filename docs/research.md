# Route research and selection

Research snapshot: October 29, 2026. Target: official Blizzard WoW: Forever, solo 1–60, normal XP, all starting races/classes as coverage goals. No reviewed source provides an independently timed, complete launch-client 1–60 solo benchmark. "Best" means a candidate supported by the available evidence, not an established optimum.

## Candidate route sources

See [the guide comparison](guide-comparison.md) for BoostedXP, Wowdee, 4Ever, Forever Routes, WoW Forever Guides, LFCarry, Mmonster and LootWoW. The concrete baseline uses MIT-licensed BoostedXP 1.0.6 quest-level data rather than reconstructing quest IDs or redistributing paid guides. The original planner and timed dataset are absent; its warrior/dungeon assumptions do not establish class-specific solo optimality.

[ExpCarry Alliance](https://expcarry.com/wow-forever-leveling-guide-alliance) and [ExpCarry Horde](https://expcarry.com/wow-forever-leveling-guide-horde), both updated October 27, provide zone and travel plans. They are useful cross-checks but do not supply a measured per-quest ordering or prove their advertised total time. The existing route data is not silently changed to match a broad zone bracket without verified quest/prerequisite/coordinate data.

[RestedXP's official Forever update](https://community.restedxp.com/word-of-warcraft-forever-updates-10-09-2026/) labels its Forever 1–35 phase complete. That makes it another route comparator, not evidence that other step-by-step guides do not exist. No paid RestedXP text or dataset is copied here.

## New-zone coverage gap

Blizzard describes [Riverglades as mid-30s to mid-40s with more than 150 quests](https://news.blizzard.com/en-us/article/24303862/world-of-warcraft-forever-whats-next-panel-recap). The chosen source guides mention it primarily for boat travel and contain no Mount Hyjal or Shen'dralas leveling quests. These are material candidates for future route improvements. Their absence prevents claiming an exhaustive or fastest Forever route. Adding them requires launch-client quest IDs, coordinates, prerequisites and timed solo observations.

## Dungeon evidence kept separate from the solo objective

The [October 1 development notes](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-october-15/2360696/4) reduce the *extra* dungeon quest XP by 50%; this is not a blanket 50% reduction of all dungeon quest rewards. The [October 8 update](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-october-15/2360696/5) increases dungeon creature XP by approximately 20% and bases mixed-level party XP on individual level. These changes make old generic dungeon-versus-quest comparisons unreliable.

Blizzard's [October 20 dungeon overview](https://news.blizzard.com/en-us/article/24301455/explore-the-new-dungeons-of-world-of-warcraft-forever) is the current primary reference for new five-player dungeon brackets, including Excavation Site 24–29. Older beta brackets and larger-group assumptions in some commercial guides are stale. [Timesaver's comparison](https://timesaver.gg/blog/wow-forever-dungeon-leveling-vs-questing) acknowledges the absence of a complete 1–60 benchmark; a suggested one-clear strategy remains an inference. None of these group strategies changes this addon's solo-only target.

## Concrete current-data findings

The downloaded Wago BoostedXP 1.0.6 ZIP has SHA-256 `F956FAAA044646C1E65E1D495A35B0D7FB16D0B2FB9DE6805D137F90221A1088`. Direct inspection found 28 main leveling guides, all `draft=true`, and 18 class side guides. The addon excludes 513 dungeon-tagged steps and propagates exclusion through chains whose only accept step requires excluded content; all 36 no-dungeon grind checkpoints remain enabled. Group/elite/escort difficulty is not reliably encoded, so retained tasks still need solo validation. Advertised 120/150-hour totals and unclear played-versus-calendar estimates are not used as targets.

## Route acceptance gate

A future improvement should demonstrate higher expected solo XP per elapsed hour after travel, kills, drop rates, turn-ins, class training, transport, quest-log limits and deaths. Preserve quest prerequisites and eligibility. Compare the same class, XP modifiers and congestion conditions; record actual elapsed time and identify unplayed sections. Until then, show source draft/verification flags and permit reversible manual recovery. All current guide chapters remain drafts.
