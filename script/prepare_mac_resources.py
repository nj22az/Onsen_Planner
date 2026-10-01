#!/usr/bin/env python3
"""Combine shared utility copy with Mac-only copy for the native target."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]) if len(sys.argv) > 1 else root / 'build/mac-resources'
for language in ['en', 'sv']:
    shared = (root / f'Vecka/{language}.lproj/Localizable.strings').read_text()
    utility = '\n'.join(line for line in shared.splitlines() if line.startswith('"week.'))
    desktop = (root / f'Mac/{language}.lproj/Mac.strings').read_text()
    combined = utility + '\n' + desktop
    keys = re.findall(r'^"([^"]+)"\s*=', combined, re.M)
    if len(keys) != len(set(keys)):
        raise ValueError('Duplicate Mac resource key')
    directory = out / f'{language}.lproj'
    directory.mkdir(parents=True, exist_ok=True)
    (directory / 'Localizable.strings').write_text(combined)
