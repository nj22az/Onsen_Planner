# Branch integration — 20 September 2026

The development base is `arena/01a0ba00-onsen-planner` at `e001fc2`, seven commits ahead of main `60566e1`. It contains the holiday, editor-state, persistence/recovery and disabled Pro-sales changes from PR #2.

## Incorporated fixes

| Source | Integration |
| --- | --- |
| `release/1.0` (`05cdb95`) | Widget holiday-name coverage, `vecka` URL registration, encryption declaration and removal of unused capabilities. Holiday labels are placed in the widget's own `HolidayNames.strings` table, with the existing app translations reused for all nine languages. |
| `claude/publish-readiness-v1` (`ca4109e`) | Black launch-screen asset and release metadata cleanup. The privacy policy has been adapted for the actual backup, contact export, widget, external-link and StoreKit behaviour, then linked from Settings and the purchase screen. |

The current Xcode project excludes the widget's `Localizable.strings` and shares the app's table instead. Adding holiday names only to the excluded files would not guarantee that those changes ship. A separate holiday table avoids that ambiguity; the build script now checks the compiled app and embedded widget after Xcode completes.

The publication branch's bundle-ID/App-Group rename is not applied: retaining the current identifiers preserves the app identity and existing shared settings. Its camera-permission removal is also not applied because camera code still exists. The remaining old release-branch layout changes, folder restructuring and audit-only branches are separate design/refactoring work, rather than missing fixes required by this integration.

Cloud synchronisation and new Pro purchases remain disabled. The app's current privacy policy describes that configuration.

## Verification limits

Source validation covers release switches, URL registration, camera permission, app/widget identifiers, entitlements, the launch asset, the shared Xcode scheme and every holiday label in each widget locale. The native build additionally checks packaged metadata and translations.

Local validation passed: design-system lint, 112/112 documentation assertions, release configuration, shell syntax and Git whitespace checks. Six validator checks confirmed acceptance of the current source configuration and a binary-resource fixture, plus rejection of a missing Swedish holiday, missing widget URL scheme, changed storage group and missing packaged Swedish table. The binary-resource fixture tests the validator; it is not a compiled app.

The authoring environment is Linux without Xcode. GitHub's latest attempted workflow was blocked before starting by an account billing issue. Native compilation, XCTest, migration from a main-version database, signed capabilities and device behaviour remain unverified. The outstanding checks in `RELEASE_CHECKLIST.md` remain outstanding; updating main is not an App Store release or a claim that those checks passed.
