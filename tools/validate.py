"""Validate actual addon source with an explicitly supplied Lua 5.1 toolchain."""
from pathlib import Path
import argparse
import re
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--lua', required=True)
parser.add_argument('--luac', required=True)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
addon = repo / 'ForLevel'
lua, luac = str(Path(args.lua).resolve()), str(Path(args.luac).resolve())

for source in sorted(addon.rglob('*.lua')):
    subprocess.run([luac, '-p', str(source)], check=True, cwd=repo)
print(f'PASS: {len(list(addon.rglob("*.lua")))} Lua syntax checks', flush=True)
for test in ('test_engine.lua', 'test_ui.lua'):
    subprocess.run([lua, str(addon / 'Tests' / test), str(addon) + '/'], check=True, cwd=repo)

toc = (addon / 'ForLevel.toc').read_text(encoding='utf-8')
for entry in toc.splitlines():
    if entry and not entry.startswith('#'):
        assert (addon / entry.replace('\\', '/')).is_file(), entry
guide_texts = [p.read_text(encoding='utf-8') for p in (addon / 'Guides').rglob('*.lua')]
assert len(guide_texts) == 46
assert sum(len(re.findall(r'\bdungeon\s*=', s)) for s in guide_texts) == 513
assert sum(len(re.findall(r'\bnodungeon\s*=', s)) for s in guide_texts) == 36
for filename in ('Core.lua', 'UI.lua'):
    code = (addon / filename).read_text(encoding='utf-8')
    for forbidden in ('AcceptQuest(', 'GetQuestReward(', 'SendAddonMessage(', 'SendChatMessage(', 'MoveForwardStart(', 'RunScript('):
        assert forbidden not in code, (filename, forbidden)
assert 'Copyright (c) 2026 Ragefarm' in (addon / 'LICENSE-BoostedXP.txt').read_text()
print('PASS: TOC, solo source counts, license and guidance-only checks')
