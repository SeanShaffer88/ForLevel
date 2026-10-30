# ForLevel

**ForLevel** is a solo leveling guide addon for WoW Forever. A small movable ordered quest list contains its own direction arrow. Guidance only, without quest or movement automation or external runtime libraries.

**Draft alpha:** real Lua 5.1 syntax and mocked-engine tests pass; launch-client and in-game tests are still outstanding. All 28 main route chapters are source-marked drafts. This is a researched candidate route, not a proven fastest 1–60 path.

## Install and use

Copy the `ForLevel` folder into the official Forever client's `Interface/AddOns` folder. The resulting path must end in `ForLevel/ForLevel.toc`. Enable it and type `/forlevel` (or `/fl`). Drag the window to move it; Back, Skip, Done and Undo handle recovery. Hover for full step details.

See [addon instructions and limitations](ForLevel/README.md), [guide comparison](docs/guide-comparison.md), [route research](docs/research.md), [mockup](docs/window-mockup.svg), and [validation](ForLevel/VALIDATION.md), and [behavior verification matrix](docs/parity.md).

## Test

Use an existing Lua 5.1 interpreter and compiler: `python tools/validate.py --lua PATH_TO_LUA --luac PATH_TO_LUAC`. Tests run real addon code against mocked game APIs, not a game client. CI builds the official Lua 5.1.5 test tool from a verified checksum using the runner's native compiler; nothing is added to the addon runtime.

## License

Original project code is covered by the root [MIT license](LICENSE). Imported BoostedXP 1.0.6 guide and static data retain the separate [Ragefarm MIT notice](ForLevel/LICENSE-BoostedXP.txt). No upstream automation, telemetry, export or announcement module is included.
