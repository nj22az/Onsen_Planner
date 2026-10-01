#!/usr/bin/env python3
"""Validate native target partition/resources. Does not compile or run Swift."""
from pathlib import Path
import importlib.util
import json
import plistlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('mac_project', root / 'scripts/generate-mac-project.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
project = module.make_project()
objects = project['objects']
assert len(objects) == len(set(objects))
assert (root / 'OnsenMac.xcodeproj/project.pbxproj').read_text() == module.project_text(), 'Generated project is stale'
for key in objects:
    assert re.fullmatch('[0-9A-F]{24}', key), 'Invalid Xcode object ID'
reference_keys = {'children', 'fileRef', 'productReference', 'buildConfigurationList', 'buildConfigurations',
                  'buildPhases', 'dependencies', 'target', 'targetProxy', 'mainGroup', 'productRefGroup',
                  'targets', 'files', 'containerPortal', 'remoteGlobalIDString'}
for obj in objects.values():
    for key, value in obj.items():
        if key not in reference_keys:
            continue
        for reference in value if isinstance(value, list) else [value]:
            assert reference in objects, f'Broken Xcode reference: {reference}'
for path in module.APP_SOURCES + module.WIDGET_SOURCES + module.UNIT_SOURCES + module.UI_SOURCES:
    assert (root / path).is_file(), f'Missing target source: {path}'
assert 'Vecka/VeckaApp.swift' not in module.APP_SOURCES
assert 'Vecka/Views/WeekRootView.swift' not in module.APP_SOURCES
assert 'Vecka/Services/AppPersistence.swift' not in module.APP_SOURCES
assert 'Mac/App/OnsenMacApp.swift' in module.APP_SOURCES
assert 'VeckaWidget/VeckaWidget.swift' in module.WIDGET_SOURCES
assert module.UNIT_SOURCES and module.UI_SOURCES
for name in ['OnsenPlannerMac', 'OnsenMacWidgets', 'OnsenMacTests', 'OnsenMacUITests']:
    target = objects[module.identifier('target:' + name)]
    assert target['isa'] == 'PBXNativeTarget'
    configs = objects[target['buildConfigurationList']]['buildConfigurations']
    for config in configs:
        settings = objects[config]['buildSettings']
        assert settings['SUPPORTED_PLATFORMS'] == 'macosx'
        assert settings['MACOSX_DEPLOYMENT_TARGET'] == '14.0'
app = objects[module.identifier('target:OnsenPlannerMac')]
embed = objects[module.identifier('embed-widgets')]
assert embed['dstSubfolderSpec'] == '13'
assert module.identifier('embed-widgets') in app['buildPhases']
assert app['dependencies']
for name in ['OnsenMac', 'OnsenMacWidgets']:
    entitlement = plistlib.loads((root / f'Mac/{name}.entitlements').read_bytes())
    assert entitlement['com.apple.security.app-sandbox'] is True
    assert entitlement['com.apple.security.application-groups'] == ['$(DEVELOPMENT_TEAM).OnsenPlanner']
for filename in ['Info.plist', 'WidgetInfo.plist']:
    info = plistlib.loads((root / 'Mac' / filename).read_bytes())
    assert info['OnsenAppGroup'] == '$(DEVELOPMENT_TEAM).OnsenPlanner'
assert 'NSCameraUsageDescription' not in plistlib.loads((root / 'Mac/Info.plist').read_bytes())
subprocess.run([sys.executable, str(root / 'script/prepare_mac_resources.py')], check=True)
for language in ['en', 'sv']:
    content = (root / f'build/mac-resources/{language}.lproj/Localizable.strings').read_text()
    keys = re.findall(r'^"([^"]+)"\s*=', content, re.M)
    assert len(keys) == len(set(keys))
    used = set()
    for path in module.APP_SOURCES + module.WIDGET_SOURCES:
        used |= set(re.findall(r'"((?:week|mac)\.[^"\\]*)"', (root / path).read_text()))
    # Interpolated ISO-year/week labels have canonical .strings format keys.
    used.discard('week.iso_year ')
    used.discard('week.widget_label ')
    used -= {'mac.destination', 'mac.showMenuBarWeek', 'mac.followsToday', 'mac.selectedTimestamp'}
    assert used <= set(keys), f'Missing {language} copy: {used - set(keys)}'
scheme = ET.parse(root / 'OnsenMac.xcodeproj/xcshareddata/xcschemes/OnsenMac.xcscheme')
assert {'OnsenMacTests', 'OnsenMacUITests'} == {n.attrib['BlueprintName'] for n in scheme.findall('.//TestableReference/BuildableReference')}
for node in scheme.findall('.//BuildableReference'):
    assert node.attrib['BlueprintIdentifier'] in objects
assert 'static let addOnSalesEnabled = false' in (root / 'Vecka/Core/ReleaseFeatures.swift').read_text()
assert 'WindowGroup(' in (root / 'Mac/App/OnsenMacApp.swift').read_text()
assert 'Settings {' in (root / 'Mac/App/OnsenMacApp.swift').read_text()
assert 'MenuBarExtra(' in (root / 'Mac/App/OnsenMacApp.swift').read_text()
assert '@SceneStorage' in (root / 'Mac/Views/MacRootView.swift').read_text()
print(f'Native Mac structure passed: {len(objects)} project objects, app/widget/unit/UI targets, English/Swedish resources. Native build remains required.')
