#!/usr/bin/env python3
"""Structural release checks. These do not compile Swift or exercise WidgetKit."""
from pathlib import Path
import plistlib
import re
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]

def read(path):
    return (root / path).read_text()

def require(value, message):
    if not value:
        raise ValueError(message)

app = read('Vecka/VeckaApp.swift')
require('WeekRootView(persistence: persistence)' in app, 'Native utility must be the default')
require('persistence.open()' not in app, 'Core launch must not open planner storage')
require('configureGlassAppearance' not in app, 'Do not override native system chrome globally')
provider = read('VeckaWidget/Provider.swift')
require('ISOWeekCalendar.timelineDates' in provider, 'Widget must use shared midnight timeline')
require(not any(x in provider for x in ['EventKit', 'SwiftData', 'URLSession', 'EKEventStore']),
        'Week provider must not depend on permissions, database or network')
project = read('Vecka.xcodeproj/project.pbxproj')
require('Core/ISOWeekCalendar.swift,' in project and 'Core/WeekAppearance.swift,' in project,
        'Shared core and palettes must be included in the widget target')
families = read('VeckaWidget/VeckaWidget.swift')
for name in ['systemSmall', 'systemMedium', 'systemLarge', 'accessoryCircular',
             'accessoryRectangular', 'accessoryInline']:
    require(f'.{name}' in families, f'Missing widget family {name}')
for tree in ['Vecka', 'VeckaWidget']:
    for path in (root / tree).rglob('*.swift'):
        require(not re.search(r'\b(?:JohoMascot|KaomojiMascot|WidgetMascot)\s*\(', path.read_text()),
                f'Mascot remains in {path}')
    privacy = plistlib.loads((root / tree / 'PrivacyInfo.xcprivacy').read_bytes())
    require(privacy['NSPrivacyTracking'] is False, 'Tracking declaration changed')
    require(any(x['NSPrivacyAccessedAPIType'] == 'NSPrivacyAccessedAPICategoryUserDefaults'
                for x in privacy['NSPrivacyAccessedAPITypes']), 'Shared preferences need a privacy manifest')

def utility_keys(path):
    keys = re.findall(r'^"(week\.[^"]+)"\s*=', path.read_text(), re.M)
    require(len(keys) == len(set(keys)), f'Duplicate utility key in {path}')
    return set(keys)

expected = utility_keys(root / 'Vecka/en.lproj/Localizable.strings')
require(len(expected) >= 30, 'Native utility copy is incomplete')
for path in (root / 'Vecka').glob('*.lproj/Localizable.strings'):
    require(expected <= utility_keys(path), f'Missing native utility strings in {path}')
scheme = ET.parse(root / 'Vecka.xcodeproj/xcshareddata/xcschemes/Vecka.xcscheme')
tests = {node.attrib.get('BlueprintName') for node in scheme.findall('.//TestableReference/BuildableReference')}
require({'VeckaTests', 'VeckaUITests'} <= tests, 'Scheme must run unit and real UI tests')
require('-only-testing:VeckaUITests' in read('build.sh'), 'Build script omits UI acceptance')
require('UI Test Mode' not in read('Vecka/VeckaApp.swift'), 'Tests must exercise the actual UI')
print(f'Widget core structural checks passed; {len(expected)} utility keys in 9 locales. Native execution remains required.')

# Revised native layout / independent add-on boundaries. Structural only.
root_view = read('Vecka/Views/WeekRootView.swift')
require(root_view.count('.tabItem') == 2, 'Week and Widgets must be the only main destinations')
require('WeekMonthView' in root_view and 'WeekDayStrip' in root_view,
        'Compact week needs day strip and month context')
require('typeSize.isAccessibilitySize' in root_view, 'Compact layout must reflow for accessibility')
require('pendingPlanner' in root_view and 'onDismiss:' in root_view, 'Saved planner must wait for sheet dismissal')
store = read('Vecka/Services/AddOnStore.swift')
require('pendingIDs.contains(product.rawValue)' in store, 'Pending purchases must prevent repeated checkout')
require('store: UserDefaults' not in store and 'defaults.bool' not in store, 'Preferences cannot grant paid ownership')
require('ownedIDs.contains(transaction.productID)' in store, 'Finish only the delivered product transaction')
require('static let addOnSalesEnabled = false' in read('Vecka/Core/ReleaseFeatures.swift'),
        'Add-on sales must stay disabled pending native acceptance')
studio = read('VeckaWidget/WeekStudioWidget.swift')
require('AppIntentConfiguration' in studio and 'AddOnVerifier.current()' in studio,
        'Studio configuration must verify StoreKit independently of shared flags')
require('VeckaWidgetEntryView(entry: VeckaWidgetEntry(date: entry.date))' in studio,
        'Unowned Studio widget must preserve a useful free week display')
require('StaticConfiguration(kind: kind' in families and 'VeckaWidget()' in families,
        'Original widget configuration must remain installed-compatible')
for source in ['AddOnEntitlements', 'AddOnVerification', 'WeekStudioContent']:
    require(f'Core/{source}.swift,' in project, f'Missing shared widget source {source}')
require('AddOnStoreTests' in read('VeckaTests/AddOnStoreTests.swift'), 'Add-on regressions missing')
print('Compact layout and independent add-on structural checks passed; StoreKit/native execution remains required.')
