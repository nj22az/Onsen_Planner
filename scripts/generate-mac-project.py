#!/usr/bin/env python3
"""Deterministic, explicit native Mac target graph. Does not alter the iOS project."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
SHARED_CORE = [
    'Vecka/Core/ISOWeekCalendar.swift', 'Vecka/Core/WeekAppearance.swift',
    'Vecka/Core/AddOnEntitlements.swift', 'Vecka/Core/AddOnVerification.swift',
    'Vecka/Core/WeekStudioContent.swift',
]
APP_SOURCES = SHARED_CORE + [
    'Vecka/Core/ReleaseFeatures.swift', 'Vecka/Services/AddOnStore.swift',
    'Vecka/Views/NativeWeekViews.swift', 'Vecka/Views/AddOnShopView.swift',
] + sorted(str(p.relative_to(ROOT)) for folder in ['App', 'Views', 'Models', 'Support']
           for p in (ROOT / 'Mac' / folder).glob('*.swift'))
WIDGET_SOURCES = SHARED_CORE + [
    'VeckaWidget/Provider.swift', 'VeckaWidget/VeckaWidget.swift', 'VeckaWidget/WeekStudioWidget.swift',
    'VeckaWidget/Views/SmallWidgetView.swift', 'VeckaWidget/Views/MediumWidgetView.swift',
    'VeckaWidget/Views/LargeWidgetView.swift',
]
UNIT_SOURCES = sorted(str(p.relative_to(ROOT)) for p in (ROOT / 'Mac/Tests').glob('*.swift'))
UI_SOURCES = sorted(str(p.relative_to(ROOT)) for p in (ROOT / 'Mac/UITests').glob('*.swift'))

def identifier(name):
    return hashlib.sha256(('OnsenMac:' + name).encode()).hexdigest()[:24].upper()

def make_project():
    objects = {}
    def add(label, isa, **values):
        key = identifier(label)
        if key in objects:
            raise ValueError('Duplicate project object: ' + label)
        objects[key] = dict(isa=isa, **values)
        return key
    refs = {}
    for path in sorted(set(APP_SOURCES + WIDGET_SOURCES + UNIT_SOURCES + UI_SOURCES)):
        refs[path] = add('file:' + path, 'PBXFileReference', lastKnownFileType='sourcecode.swift', path=path, sourceTree='<group>')
    for path in ['Mac/Info.plist', 'Mac/WidgetInfo.plist', 'Mac/OnsenMac.entitlements', 'Mac/OnsenMacWidgets.entitlements']:
        refs[path] = add('file:' + path, 'PBXFileReference', lastKnownFileType='text.plist.xml', path=path, sourceTree='<group>')
    privacy = add('privacy', 'PBXFileReference', lastKnownFileType='text.xml', path='Vecka/PrivacyInfo.xcprivacy', sourceTree='<group>')
    languages = [add('copy:' + lang, 'PBXFileReference', lastKnownFileType='text.plist.strings', name=lang,
                     path=f'build/mac-resources/{lang}.lproj/Localizable.strings', sourceTree='<group>') for lang in ['en', 'sv']]
    strings = add('localizations', 'PBXVariantGroup', name='Localizable.strings', children=languages, sourceTree='<group>')
    products = {}
    types = {'OnsenPlannerMac': ('app', 'wrapper.application'), 'OnsenMacWidgets': ('appex', 'wrapper.app-extension'),
             'OnsenMacTests': ('xctest', 'wrapper.cfbundle'), 'OnsenMacUITests': ('xctest', 'wrapper.cfbundle')}
    for name, (extension, kind) in types.items():
        products[name] = add('product:' + name, 'PBXFileReference', explicitFileType=kind, includeInIndex='0',
                             path=name + '.' + extension, sourceTree='BUILT_PRODUCTS_DIR')
    product_group = add('products', 'PBXGroup', name='Products', children=list(products.values()), sourceTree='<group>')
    source_group = add('sources', 'PBXGroup', name='Source Files', children=list(refs.values()) + [privacy, strings], sourceTree='<group>')
    group = add('rootgroup', 'PBXGroup', children=[source_group, product_group], sourceTree='<group>')
    project_id = identifier('project')
    target_ids = {name: identifier('target:' + name) for name in types}
    def dependency(name, target):
        proxy = add(name + ':proxy', 'PBXContainerItemProxy', containerPortal=project_id, proxyType='1',
                    remoteGlobalIDString=target_ids[target], remoteInfo=target)
        return add(name, 'PBXTargetDependency', target=target_ids[target], targetProxy=proxy)
    prepare = add('prepare', 'PBXShellScriptBuildPhase', buildActionMask='2147483647', files=[],
                  inputPaths=['$(SRCROOT)/script/prepare_mac_resources.py',
                              '$(SRCROOT)/Vecka/en.lproj/Localizable.strings', '$(SRCROOT)/Vecka/sv.lproj/Localizable.strings',
                              '$(SRCROOT)/Mac/en.lproj/Mac.strings', '$(SRCROOT)/Mac/sv.lproj/Mac.strings'],
                  outputPaths=['$(SRCROOT)/build/mac-resources/en.lproj/Localizable.strings',
                               '$(SRCROOT)/build/mac-resources/sv.lproj/Localizable.strings'],
                  runOnlyForDeploymentPostprocessing='0', shellPath='/bin/sh',
                  shellScript='python3 "$SRCROOT/script/prepare_mac_resources.py"\n', name='Prepare native Mac copy')
    source_map = {'OnsenPlannerMac': APP_SOURCES, 'OnsenMacWidgets': WIDGET_SOURCES,
                  'OnsenMacTests': UNIT_SOURCES, 'OnsenMacUITests': UI_SOURCES}
    for name, sources in source_map.items():
        source_builds = [add(name + ':source:' + path, 'PBXBuildFile', fileRef=refs[path]) for path in sources]
        phases = [add(name + ':sources', 'PBXSourcesBuildPhase', buildActionMask='2147483647', files=source_builds, runOnlyForDeploymentPostprocessing='0'),
                  add(name + ':frameworks', 'PBXFrameworksBuildPhase', buildActionMask='2147483647', files=[], runOnlyForDeploymentPostprocessing='0')]
        resource_builds = []
        if name in ['OnsenPlannerMac', 'OnsenMacWidgets']:
            resource_builds = [add(name + ':strings', 'PBXBuildFile', fileRef=strings), add(name + ':privacy', 'PBXBuildFile', fileRef=privacy)]
        phases.append(add(name + ':resources', 'PBXResourcesBuildPhase', buildActionMask='2147483647', files=resource_builds, runOnlyForDeploymentPostprocessing='0'))
        deps = []
        if name == 'OnsenMacWidgets': phases.insert(0, prepare)
        if name == 'OnsenPlannerMac':
            embedded = add('embedded-widget', 'PBXBuildFile', fileRef=products['OnsenMacWidgets'], settings={'ATTRIBUTES': ['CodeSignOnCopy', 'RemoveHeadersOnCopy']})
            phases.append(add('embed-widgets', 'PBXCopyFilesBuildPhase', buildActionMask='2147483647', dstPath='', dstSubfolderSpec='13',
                              files=[embedded], name='Embed Mac Widgets', runOnlyForDeploymentPostprocessing='0'))
            deps.append(dependency('app-widget', 'OnsenMacWidgets'))
        if name in ['OnsenMacTests', 'OnsenMacUITests']: deps.append(dependency(name + ':app', 'OnsenPlannerMac'))
        configs = []
        for configuration in ['Debug', 'Release']:
            settings = dict(PRODUCT_NAME=name, PRODUCT_MODULE_NAME=name, SWIFT_VERSION='5.0', MACOSX_DEPLOYMENT_TARGET='14.0',
                            SDKROOT='macosx', SUPPORTED_PLATFORMS='macosx', CODE_SIGN_STYLE='Automatic', DEVELOPMENT_TEAM='P4LGU6F45C',
                            ENABLE_USER_SCRIPT_SANDBOXING='NO', ENABLE_HARDENED_RUNTIME='YES', CLANG_ENABLE_MODULES='YES',
                            SWIFT_OPTIMIZATION_LEVEL='-Onone' if configuration == 'Debug' else '-O',
                            ENABLE_TESTABILITY='YES' if configuration == 'Debug' else 'NO',
                            LD_RUNPATH_SEARCH_PATHS='$(inherited) @executable_path/../Frameworks @loader_path/../Frameworks',
                            CURRENT_PROJECT_VERSION='1', MARKETING_VERSION='1.0', COMBINE_HIDPI_IMAGES='YES')
            if name == 'OnsenPlannerMac':
                settings.update(PRODUCT_BUNDLE_IDENTIFIER='Johansson.Vecka', INFOPLIST_FILE='Mac/Info.plist',
                                GENERATE_INFOPLIST_FILE='NO', CODE_SIGN_ENTITLEMENTS='Mac/OnsenMac.entitlements')
            elif name == 'OnsenMacWidgets':
                settings.update(PRODUCT_BUNDLE_IDENTIFIER='Johansson.Vecka.MacWidgets', INFOPLIST_FILE='Mac/WidgetInfo.plist',
                                GENERATE_INFOPLIST_FILE='NO', CODE_SIGN_ENTITLEMENTS='Mac/OnsenMacWidgets.entitlements',
                                APPLICATION_EXTENSION_API_ONLY='YES', SKIP_INSTALL='YES')
            else:
                settings.update(PRODUCT_BUNDLE_IDENTIFIER='Johansson.Vecka.' + name, GENERATE_INFOPLIST_FILE='YES')
                if name == 'OnsenMacTests':
                    settings.update(TEST_HOST='$(BUILT_PRODUCTS_DIR)/OnsenPlannerMac.app/Contents/MacOS/OnsenPlannerMac', BUNDLE_LOADER='$(TEST_HOST)')
                else: settings['TEST_TARGET_NAME'] = 'OnsenPlannerMac'
            configs.append(add(name + ':' + configuration, 'XCBuildConfiguration', name=configuration, buildSettings=settings))
        config_list = add(name + ':configurations', 'XCConfigurationList', buildConfigurations=configs,
                          defaultConfigurationIsVisible='0', defaultConfigurationName='Release')
        product_type = 'com.apple.product-type.application' if name == 'OnsenPlannerMac' else 'com.apple.product-type.app-extension' if name == 'OnsenMacWidgets' else 'com.apple.product-type.bundle.unit-test' if name == 'OnsenMacTests' else 'com.apple.product-type.bundle.ui-testing'
        add('target:' + name, 'PBXNativeTarget', name=name, productName=name, productType=product_type, productReference=products[name],
            buildConfigurationList=config_list, buildPhases=phases, buildRules=[], dependencies=deps)
    configs = [add('project:' + c, 'XCBuildConfiguration', name=c, buildSettings={'MACOSX_DEPLOYMENT_TARGET': '14.0', 'SDKROOT': 'macosx'}) for c in ['Debug', 'Release']]
    config_list = add('project-configurations', 'XCConfigurationList', buildConfigurations=configs, defaultConfigurationIsVisible='0', defaultConfigurationName='Release')
    attrs = {target_ids[name]: {'CreatedOnToolsVersion': '16.4', **({'TestTargetID': target_ids['OnsenPlannerMac']} if name in ['OnsenMacTests', 'OnsenMacUITests'] else {})} for name in types}
    add('project', 'PBXProject', attributes={'LastUpgradeCheck': '2610', 'TargetAttributes': attrs}, buildConfigurationList=config_list,
        compatibilityVersion='Xcode 14.0', developmentRegion='en', hasScannedForEncodings='0', knownRegions=['en', 'sv', 'Base'],
        mainGroup=group, productRefGroup=product_group, projectDirPath='', projectRoot='', targets=list(target_ids.values()))
    return dict(archiveVersion='1', classes={}, objectVersion='56', objects=objects, rootObject=project_id)

def encode(value, indent=0):
    tab = '\t' * indent
    if isinstance(value, dict):
        return '{\n' + ''.join('\t' * (indent + 1) + json.dumps(k) + ' = ' + encode(v, indent + 1) + ';\n' for k,v in value.items()) + tab + '}'
    if isinstance(value, list):
        return '(\n' + ''.join('\t' * (indent + 1) + encode(v, indent + 1) + ',\n' for v in value) + tab + ')'
    return json.dumps(value)

def project_text():
    return '// !$*UTF8*$!\n' + encode(make_project()) + '\n'

if __name__ == '__main__':
    (ROOT / 'OnsenMac.xcodeproj/project.pbxproj').write_text(project_text())
