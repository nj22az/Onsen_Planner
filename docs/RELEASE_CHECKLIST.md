# Onsen Planner — reliability acceptance gates

This checklist describes tests that must be performed; unchecked items are **not** evidence of success.

## Current build decisions

- `ReleaseFeatures.cloudSyncEnabled = false`: the application uses persistent local storage. Optional contact relationships and inverses are prepared for future CloudKit validation.
- `ReleaseFeatures.proSalesEnabled = false`: events, trips, exports and themes remain available. No new purchase can start. This does **not** mark the user as owning Pro.
- `ReleaseFeatures.privacyPolicyURL` points to the public `docs/PRIVACY.md` on main. Settings and the purchase screen use the same policy. Review it again before enabling sales or cloud sync.
- The existing `Johansson.Vecka` bundle identifier and `group.Johansson.Vecka` App Group are preserved. Unused WeatherKit/iCloud entitlements, location descriptions and remote-notification background mode have been removed; camera permission is retained for the existing image picker.
- Widget holiday names use an independently bundled `HolidayNames.strings` table in all nine existing app languages. `./build.sh build` checks the actual embedded widget resources after Xcode completes.
- Storage opening failures show recovery, never an editable in-memory planner. No failed store is deleted.

## Before merging this branch

- [ ] Run `./build.sh build` and `./build.sh test` on the reviewed head using Xcode. The environment used to author these changes was Linux, without Xcode.
- [ ] Confirm `HolidayRefreshTests`, `StorageRecoveryTests` and `StoreRecoveryTests` actually execute and pass. CI test failures are fatal; retain the `.xcresult` evidence.
- [ ] Upgrade a **copy** of a store written by main (`60566e1`) containing contacts with every relationship type, notes, expense photos, trips, clocks and edited holidays. Confirm counts, relationships, photos, edits and a second cold launch. Current-schema round-trip tests do not prove migration from main.
- [ ] Verify the pre-upgrade `PlannerRecovery` copy includes SQLite, WAL and external photo storage on a real device. Do not remove the original store to make a test pass.
- [ ] Change holiday regions/year quickly, disable holidays during calculation, and create/edit a holiday. Verify indicators update without another tap or navigation.
- [ ] Open existing expenses, special days and time pickers; verify every initial value and saved value.
- [ ] Force storage/open/save failures. Verify no success message or editor dismissal, no lost draft, and no writable memory fallback.
- [ ] Export a backup including photos and contact children; restore into an empty planner, restart, and compare contents. Restore twice and confirm no duplication or overwritten newer edits.
- [ ] Check recovery and backup sheets on iPhone/iPad, light/dark mode and larger text.
- [ ] Check the black launch background, Settings privacy link, widget holiday labels in English/Swedish, and widget taps to `vecka://today` and `vecka://facts/...`.

## Before enabling CloudKit

- [ ] Verify all relationships are optional and inverse links persist after save/reopen.
- [ ] Decide and implement deterministic reconciliation for logical IDs seeded on two devices; simply picking the first duplicate must not discard user changes.
- [ ] Validate capabilities, signing and push entitlement using a signed device build.
- [ ] Restore the validated CloudKit container/services entitlements and remote-notification background mode before enabling cloud sync. The current local-only build deliberately omits them.
- [ ] Test initial sync, offline changes, account changes, two-device edits, deletion and local-only fallback using the same persistent URL.
- [ ] Verify remote imports invalidate derived holiday data. The local completion signal alone is not a remote-import observer.
- [ ] Initialise the development schema, then promote the validated schema to production before release.
- [ ] Enable the release switch only with recorded device evidence. The app must not label data as synchronised without confirmation.

## Before enabling Vecka Pro sales

- [ ] Create yearly/monthly subscriptions in one subscription group, and the lifetime non-consumable, matching `VeckaProduct` identifiers.
- [ ] Configure prices, availability and any introductory offer; complete the App Store agreements and purchase metadata.
- [ ] Verify the published privacy-policy URL is reachable and review App Store privacy disclosures for actual behaviour, including CloudKit if enabled.
- [ ] Use an Xcode StoreKit configuration and then Apple's sandbox to test purchase, cancellation, pending approval, approval delivery, restore, refund, expiration and grace period.
- [ ] Test missing/partial products and network failures, retry after recovery, and a cold launch with existing verified purchases.
- [ ] Confirm an ineligible customer never sees a free-trial promise and an introductory paid offer is not described as free.
- [ ] Audit every event/trip creation and export entry point before enforcing limits, including legacy creators, shortcuts and share screens. Existing entries and backups must remain accessible.
- [ ] Check full device layout/accessibility, the purchase button, product selection, prices, legal links and restore messages.
- [ ] Enable `proSalesEnabled` only after these checks pass. Run `python3 scripts/validate-release-config.py`.

## Backup contract

The portable JSON snapshot includes memos (notes, expenses, trips and photo attachments), contacts and all seven child relationships, holiday rules/history, calendar rules, clocks, bundled fact records and legacy custom countdowns/tasks. It excludes device appearance/preferences, permissions and StoreKit entitlements. Backups contain private information and are exported only at the user's request through Files.

Restore validates the format and record identifiers before mutation. It adds missing records in one SwiftData save and keeps existing records unchanged. Legacy countdowns are merged after that save; if the process stops between the two, the portable backup can be reapplied safely. This cross-store step is not an atomic transaction with UserDefaults.

Automatic pre-upgrade copies are local recovery checkpoints, not portable exports. They are taken before the store opens and retained. Recovery from a portable backup writes a separate database; the original failed database is preserved. A successful clean launch and the presence of a checkpoint do not by themselves prove that migration or two-device sync is correct.

## Validation environment

The CI workflow uses the shared Vecka scheme, macOS 15 / Xcode 26.3, and an available iOS 18-or-newer simulator. Override `VECKA_DESTINATION` for a specific installed simulator. Check iOS 27 separately using the corresponding Xcode SDK/runtime before claiming iOS 27 readiness.

At the initial review, GitHub's Mac job was blocked before starting by an account billing issue. A green static-check job cannot substitute for the Mac build, unit tests or device checks.
