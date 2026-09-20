#!/usr/bin/env python3
"""Fail release configuration checks before incomplete paid features can ship."""
from pathlib import Path
import plistlib
import re
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parent.parent
flags = (root / 'Vecka/Core/ReleaseFeatures.swift').read_text()
for name in ('proSalesEnabled', 'cloudSyncEnabled'):
    assert re.search(rf'static let {name} = (true|false)\b', flags), f'Missing explicit {name} release decision'
if 'static let proSalesEnabled = true' in flags:
    policy = re.search(r'privacyPolicyURL.*URL\(string: "(https://[^\"]+)"\)', flags)
    assert policy and 'example.com' not in policy[1], 'Set a real HTTPS privacy policy before enabling Pro sales'
with (root / 'VeckaWidget/WidgetInfo.plist').open('rb') as file:
    widget = plistlib.load(file)
assert widget['NSExtension']['NSExtensionPointIdentifier'] == 'com.apple.widgetkit-extension'
ET.parse(root / 'Vecka.xcodeproj/xcshareddata/xcschemes/Vecka.xcscheme')
assert 'https://example.com/vecka/privacy' not in (root / 'Vecka/Views/PaywallView.swift').read_text()
print('Release switches, privacy link, shared scheme and widget configuration checked.')
