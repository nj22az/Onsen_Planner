# Native Mac companion

The first Mac version ports the current offline ISO week utility to macOS 14 or later. It uses a separate SwiftUI app and WidgetKit extension, sharing the iOS week calculation, presentation styles, widget views and independently verified Widget Studio entitlement code. Apple presentation is the default.

## Included

- Resizable sidebar window with Week, Widgets and Add-ons destinations.
- Week summary, selectable month grid, previous/next week and date lookup.
- Per-window selected date; Today follows the clock and updates while open.
- Week menu with Command-left/right, Command-T and Command-F shortcuts.
- Native Settings window with appearance, menu-bar toggle and restore purchases.
- Optional menu-bar week number and small, medium and large desktop widgets.
- Widget Studio layouts using the existing purchase verification and free fallback.
- English and Swedish copy assembled from the shared week strings plus Mac-specific text.

The retained saved planner, its database and iOS permission-dependent integrations are outside this Mac version. This port does not migrate or access that database. Purchases remain disabled by the shared release feature flags; existing verified ownership can still be restored. No new products or paid access claims are enabled.

## Build and test on a Mac

Install Xcode with the macOS SDK, select it with `xcode-select`, and configure the existing development team in Signing & Capabilities. Open `OnsenMac.xcodeproj`, using the shared `OnsenMac` scheme, or run:

```bash
./script/build_and_run.sh            # Stop old instance, build, launch
./script/build_and_run.sh --verify   # Launch and check process presence
./script/build_and_run.sh --debug    # Build and start LLDB
./script/build_and_run.sh --logs     # Launch and stream process logs
./script/test_mac.sh --unit-only
./script/test_mac.sh                 # Unit and UI tests, screenshot attachment
```

The Run action in `.codex/environments/environment.toml` calls the same build script. Scripts deliberately report a missing Mac/Xcode environment before stopping anything. The process check is a launch smoke check, not a substitute for UI or widget acceptance.

`script/prepare_mac_resources.py` creates ignored `build/mac-resources` strings. The widget build phase produces them first; the app depends on and embeds that extension. `scripts/generate-mac-project.py` deterministically regenerates the explicit source target lists. Regenerate after adding source files, then run `python3 scripts/validate-mac-port.py`.

The app uses bundle identifier `Johansson.Vecka`; the extension uses `Johansson.Vecka.MacWidgets`. Both use the sandboxed Mac group `$(DEVELOPMENT_TEAM).OnsenPlanner`, obtained at runtime from their Info.plist. The iOS group and legacy storage remain unchanged. Configure/register the Mac group and extension provisioning under the actual team. Confirm Mac platform and universal purchase configuration in App Store Connect before promising cross-platform ownership; matching source product IDs alone is insufficient.

## Acceptance and shipping gates

This port was prepared in a Linux workspace without Swift, Xcode or a macOS SDK. Structural checks validate source partitions, project references, localisation and sandbox metadata. They do not prove compilation, runtime behaviour or signing. The CI compiler job is also unsigned and does not prove widget installation.

Before releasing:

1. Run a native build, unit tests and UI tests on a Mac. Inspect the attached real-app screenshot, narrow/wide windows, keyboard focus and Settings.
2. Install the signed app and extension. Add each widget size to desktop and Notification Centre, test midnight/week/year rollover, daylight-saving changes, appearance changes and widget links with the app closed.
3. Check multiple windows, Today after sleep/time-zone changes, menu-bar restoration, deep links and accessibility with VoiceOver and larger text.
4. Exercise verified, pending, cancelled, revoked and offline StoreKit states in the Mac sandbox. Keep both sales flags disabled until products, restore behaviour and policy links pass acceptance.
5. Supply a Mac app icon, confirm signing/provisioning, archive and validate the Mac App Store build, and finish Mac screenshots and listing metadata.

The initial release should offer free current-week display, lookup, default widgets and all four presentation styles. Widget Studio is the first optional one-time add-on after purchase acceptance. Saved-planner migration and new permission-heavy integrations require a separate design and data-recovery review.

Apple references: [macOS widgets](https://developer.apple.com/documentation/widgetkit), [app groups](https://developer.apple.com/documentation/xcode/configuring-app-groups), [universal purchase](https://developer.apple.com/support/universal-purchase/).
