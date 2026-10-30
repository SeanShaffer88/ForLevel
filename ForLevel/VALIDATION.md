# Validation — draft alpha

## Executed local gates

October 29, 2026. Real native tools; no simulated build or test results.

1. Downloaded official `https://www.lua.org/ftp/lua-5.1.5.tar.gz`; SHA-256 verified against [Lua's official download index](https://www.lua.org/ftp/): `2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333`. Download/extraction command exit **0**.
2. Built temporary Lua 5.1.5 interpreter and compiler with installed Microsoft Visual C++ 2022 x64 (`/MD /O2 /W3 /D_CRT_SECURE_NO_DEPRECATE`), using official C sources. Build command exit **0**. Upstream source emitted C4334 shift-width warnings in `lgc.c:288` and `ltable.c:323,376`; no addon code or compiler flags were rewritten to hide these warnings.
3. Ran `python tools/validate.py --lua ../lua-toolchain/runtime/lua.exe --luac ../lua-toolchain/compiler/luac.exe` from the repository. Exit **0**: 53 actual Lua syntax checks, 5,762 engine/data assertions, 44 UI/event/save assertions, and TOC/source-count/license/guidance-only checks. UI tests use mock frames and are not visual or game-client tests.
4. Source checks confirmed 46 unique guide IDs, resolving next-guide links, 28 draft main guides plus 18 class guides, 513 dungeon steps, 36 solo catch-up steps, and 5,697 bounded step coordinates. Copied guide files and Ragefarm's full MIT notice match the source byte for byte. Producing Python command exit **0**.

Engine tests cover acceptance, abandonment versus turn-in, grouped and class-filtered quests, partial objective matches, secret/missing values, manual Undo, dungeon prerequisite exclusion, automatic level/item deferral, level-gated hunt-to-turn-in chains, cardinal/facing bearings, cross-continent suppression and distinct player/target coordinate conversion. UI tests additionally check mockup-04 geometry bounds, five rows, draft badge, real/secret XP, hover, review and right-click recovery. They execute actual handlers for login identity, quest events, visibility, drag position, manual controls, saved-state reuse, malformed saved fields and missing/restored APIs, renamed frame/asset/saved-state identities and both `/forlevel` and `/fl` aliases.

CI uses the same checksum-pinned official Lua test source and the hosted runner's native compiler. No interpreter, compiler, C source, Python dependency or telemetry is shipped in the addon folder.

## Outstanding gates

Launch-client API compatibility, real frame layout, arrow orientation in the game, terrain/transport behavior, actual game SavedVariables persistence and a timed 1–60 solo route have not been tested. The mock saved-state test proves table reuse and recovery, not a real logout/reload. The addon remains a draft alpha; local passing tests do not prove a fastest route.

## Exact local intermediate paths

- Source ZIP: `C:\Users\Sean Shaffer\Documents\Codex\2026-10-29\c\work\BoostedXP-1.0.6.zip`
- Extracted guide source: `C:\Users\Sean Shaffer\Documents\Codex\2026-10-29\c\work\boostedxp-source\BoostedXP`
- BoostedXP ZIP SHA-256: `F956FAAA044646C1E65E1D495A35B0D7FB16D0B2FB9DE6805D137F90221A1088`
- Lua archive/source: `C:\Users\Sean Shaffer\Documents\Codex\2026-10-29\c\work\lua-toolchain\lua-5.1.5.tar.gz` and sibling `lua-5.1.5` folder.
- Native build script: `C:\Users\Sean Shaffer\Documents\Codex\2026-10-29\c\work\lua-toolchain\build-lua.cmd`; `cmd.exe /c work\lua-toolchain\build-lua.cmd` exited **0**.
- Temporary interpreter/compiler: `C:\Users\Sean Shaffer\Documents\Codex\2026-10-29\c\work\lua-toolchain\runtime\lua.exe` and `compiler\luac.exe`.
- Repository: `C:\Users\Sean Shaffer\Documents\Codex\2026-10-29\c\work\ForLevel`.

Exa/web research tools do not provide process exit codes. Only actual shell results are reported as exit codes.
