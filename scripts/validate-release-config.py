#!/usr/bin/env python3
"""Validate release metadata and widget resources, optionally in a built app."""
import argparse
from pathlib import Path
import json
import plistlib
import re
import xml.etree.ElementTree as ET


def require(condition, message):
    if not condition:
        raise ValueError(message)


def plist(path):
    return plistlib.loads(path.read_bytes())


def strings(path, required_keys=None):
    data = path.read_bytes()
    if data.startswith((b'bplist', b'<?xml')):
        return plistlib.loads(data)
    try:
        text = data.decode('utf-8-sig')
    except UnicodeDecodeError:
        text = data.decode('utf-16')
    pairs = re.findall(r'^\s*"([^"\n]+)"\s*=\s*("(?:\\.|[^"\\])*");', text, re.M)
    if required_keys is not None:
        pairs = [(key, value) for key, value in pairs if key in required_keys]
    require(len(pairs) == len({key for key, _ in pairs}), f'Duplicate keys in {path}')
    return {key: json.loads(value) for key, value in pairs}


def validate_info(info):
    schemes = {scheme for item in info.get('CFBundleURLTypes', [])
               for scheme in item.get('CFBundleURLSchemes', [])}
    require('vecka' in schemes, 'Register the vecka widget URL scheme')
    require(bool(info.get('NSCameraUsageDescription')), 'Camera use requires an accurate permission description')
    require(info.get('UILaunchScreen', {}).get('UIColorName') == 'LaunchBackground', 'Missing launch background')
    require(info.get('ITSAppUsesNonExemptEncryption') is False, 'Review the encryption declaration')


def validate(root, app=None):
    flags = (root / 'Vecka/Core/ReleaseFeatures.swift').read_text()
    decisions = {}
    for name in ('proSalesEnabled', 'cloudSyncEnabled'):
        match = re.search(rf'static let {name} = (true|false)\b', flags)
        require(match is not None, f'Missing explicit {name} release decision')
        decisions[name] = match[1] == 'true'
    policy = re.search(r'privacyPolicyURL.*URL\(string: "(https://[^\"]+)"\)', flags)
    require(policy is not None and 'example.com' not in policy[1], 'Set a real HTTPS privacy policy')
    require((root / 'docs/PRIVACY.md').is_file(), 'Privacy policy is missing')

    info = plist(root / 'Vecka/Info.plist')
    validate_info(info)
    groups = []
    for relative in ('Vecka/Vecka.entitlements', 'VeckaWidget/VeckaWidget.entitlements'):
        entitlements = plist(root / relative)
        groups.append(entitlements.get('com.apple.security.application-groups'))
        require('com.apple.developer.weatherkit' not in entitlements, 'Unused WeatherKit entitlement')
        if not decisions['cloudSyncEnabled']:
            require(not any('icloud' in key for key in entitlements), 'Disabled cloud sync still has iCloud entitlements')
    require(groups == [['group.Johansson.Vecka']] * 2, 'Preserve the existing app/widget storage group')
    if not decisions['cloudSyncEnabled']:
        require('remote-notification' not in info.get('UIBackgroundModes', []), 'Unused cloud background mode')
    require(not any(key.startswith('NSLocation') for key in info), 'Unused location permission')
    json.loads((root / 'Vecka/Assets.xcassets/LaunchBackground.colorset/Contents.json').read_text())
    widget = plist(root / 'VeckaWidget/WidgetInfo.plist')
    require(widget['NSExtension']['NSExtensionPointIdentifier'] == 'com.apple.widgetkit-extension', 'Invalid widget extension')
    ET.parse(root / 'Vecka.xcodeproj/xcshareddata/xcschemes/Vecka.xcscheme')
    project = (root / 'Vecka.xcodeproj/project.pbxproj').read_text()
    require(project.count('PRODUCT_BUNDLE_IDENTIFIER = Johansson.Vecka;') == 2, 'App identity changed')
    require(project.count('PRODUCT_BUNDLE_IDENTIFIER = Johansson.Vecka.VeckaWidget;') == 2, 'Widget identity changed')
    require('"/Localized: HolidayNames.strings"' not in project, 'Widget holiday resources are excluded from the build')

    engine = (root / 'VeckaWidget/WidgetHolidayEngine.swift').read_text()
    keys = set(re.findall(r'WidgetHolidayRule\(name: "([^"]+)"', engine))
    require(bool(keys), 'No widget holiday rules found')
    require('tableName: "HolidayNames"' in engine, 'Widget must load its own holiday table')
    locales = sorted((root / 'Vecka').glob('*.lproj/Localizable.strings'))
    for source in locales:
        expected = strings(source, keys)
        table = strings(root / 'VeckaWidget' / source.parent.name / 'HolidayNames.strings')
        require(keys <= table.keys(), f'Missing widget holiday names for {source.parent.name}')
        require(all(table[key] == expected[key] for key in keys), f'App/widget holiday names differ for {source.parent.name}')
        if app is not None:
            built = strings(app / 'PlugIns/VeckaWidgetExtension.appex' / source.parent.name / 'HolidayNames.strings')
            require(all(built.get(key) == table[key] for key in keys), f'Packaged widget translations differ for {source.parent.name}')
    if app is not None:
        built_info = plist(app / 'Info.plist')
        validate_info(built_info)
        require(built_info.get('CFBundleIdentifier') == 'Johansson.Vecka', 'Built app identity changed')
        extension = plist(app / 'PlugIns/VeckaWidgetExtension.appex/Info.plist')
        require(extension.get('CFBundleIdentifier') == 'Johansson.Vecka.VeckaWidget', 'Built widget identity changed')
    print(f'Release configuration passed; {len(keys)} holiday names checked in {len(locales)} widget locales'
          + (' and the built app.' if app is not None else '.'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=Path, help='Built Vecka.app to verify packaged resources')
    args = parser.parse_args()
    validate(Path(__file__).resolve().parent.parent, args.app)
