# Documentation Changelog

Logs all changes to documents under `docs/`. Follows JDS conventions: one heading per revision, newest first. System-level changes (registry entries in `nj22az/JDS_Documentation`) are noted but not duplicated.

## Rev I — 2026-09-20

**JDS-PRJ-SFW-002 Rev F: reliability and safe recovery; staged CloudKit and Pro sales.**

- Documented observable holiday completion, optional contact relationships, persistent-store recovery and portable backup/restore.
- CloudKit and paid restrictions are disabled pending explicit release gates; removed the live privacy placeholder.
- Added `RELEASE_CHECKLIST.md` covering exact-head Mac validation, upgrades from main, fault recovery, real-device CloudKit and StoreKit tests.
- Build instructions now use the shared scheme and available simulator; test failures are fatal. Source-level checks are not reported as a Mac build.

## Rev H — 2026-09-19

**JDS-PRJ-SFW-002 Rev E + JDS-REF-SFW-002 Rev B: theme catalog batch 2 (10 more brand palettes).**

- PRJ §Tech inventory: Theme presets bullet updated — fourteen presets
  (ten free brand palettes + four Vecka Pro artisan themes); premium
  list extended (Vermilion, Sometsuke join Wagashi and Kincha).
- JDS-REF-SFW-002 Rev B: provenance tables added for the ten Batch-2
  themes — Vibes (freee), Cobalt (Findy), Journey (NEWT), Neon (ABEMA),
  Paddock (JRA), Vision (21_21 DESIGN SIGHT), Wakaba (CAMK 熊本市現代美術館),
  Utsuwa (KINTO) free; Vermilion (aeru), Sometsuke (1616/arita japan)
  Vecka Pro. Gating principle recorded: mostly free, artisan set Pro.

Companion code changes (not docs): ten presets appended to
`theme-presets.json` and `JohoThemeLoader.builtInPresets` (kept in
sync); `PaywallView` feature row renamed to the shipped Premium themes
benefit.

## Rev G — 2026-09-19

**JDS-PRJ-SFW-002 Rev D + new JDS-REF-SFW-002: Japanese-brand theme palettes.**

- PRJ §Tech inventory: Monetization bullet extended — Vecka Pro now also
  unlocks premium theme presets (`JohoThemePreset.isPremium`; locked
  cards show a PRO pill and open the paywall); new Theme presets bullet
  documenting the JSON-canonical/builtInPresets-fallback sync rule and
  the eight presets.
- New document `JDS-REF-SFW-002_theme-palettes.md` (Rev A): provenance
  for the four brand-palette themes adapted from
  [kzhrknt/awesome-design-md-jp](https://github.com/kzhrknt/awesome-design-md-jp)
  (MIT) — Teal (note.com) and Stone (SmartHR) free; Wagashi (Funabashiya
  船橋屋) and Kincha (Adachi Museum 足立美術館) Vecka Pro. Includes
  source-token → theme-role tables and the add-a-theme checklist.

Companion code changes (not docs): `isPremium` added to the theme preset
schema; four presets added to `theme-presets.json` and
`JohoThemeLoader.builtInPresets`; `SettingsView.themePresetCard` gates
premium themes behind the shared paywall binding; `PaywallView` feature
list now names premium themes as a shipped Pro feature.

## Rev F — 2026-09-19

**JDS-PRJ-SFW-002 Rev C: CloudKit enabled; iOS 27 chrome stance documented.**

- §Tech inventory: CloudKit moved from "disabled pending model updates" to
  ENABLED with the three model-rule changes that made it possible called
  out (no unique constraints; optional-or-defaulted stored properties;
  inverse relationships); added duplicate-tolerance note for id-keyed
  lookups and the `remote-notification`/aps-environment Xcode checklist
  item; added the iOS 27 Liquid Glass stance (explicit opaque chrome is
  deliberate and overrides default glass).

Companion code changes (not docs): all nine `@Model` files migrated for
CloudKit mirroring; `VeckaApp` flipped to `cloudKitDatabase: .automatic`;
duplicate-tolerant dictionaries in `HolidayManager`/`CalendarManager`;
`Info.plist` gained the remote-notification background mode. Ship-readiness:
this fulfills the onboarding page-4 "Sync Everywhere" promise.

## Rev E — 2026-09-19

**JDS-PRJ-SFW-002 Rev B: async holiday pipeline, iOS 27 `@State` readiness, StoreKit 2 monetization.**

- §Tech inventory: added "Holiday cache pipeline" (main-actor snapshot →
  detached compute → main-actor apply, with cancellation + generation
  guard); added "Monetization" (StoreKit 2, Vecka Pro feature gating);
  added "iOS 27 readiness" (single-point `@State` initialization rule).
- Source layout unchanged in table; new files are
  `Vecka/Services/StoreManager.swift` and `Vecka/Views/PaywallView.swift`.

Companion code changes (not docs): `HolidayManager`/`HolidayEngine`
moved the years × rules date computation off the main thread;
`AppInitializer` comments updated; `@State` declaration/init conflicts
fixed in `ExpenseEntryView`, `JohoEditorSheets`, `MemoEditorView`;
`StoreManager` + `PaywallView` added; Pro gates wired into
`CountdownListView` (event cap), `TripListView` (trip cap),
`ExpenseListView` (PDF/CSV export), `SettingsView` (Pro section);
`VeckaApp` injects `StoreManager` and warms products/entitlements at
launch; two pre-existing `Image(systemName: "literal")` violations in
`JohoPackagingPanels.swift` moved to `IconCatalog` so the design-system
lint passes clean.

## Rev D — 2026-05-29

**JDS-MAN-SFW-001: fill DS-component documentation gaps; tighten validator.**

A JDS source-of-truth audit found the design-system surface in
`Vecka/JohoCalendarWidgets.swift` undocumented, and a naming bug in §7.10
where the SF Symbol picker was labeled `JohoSymbolPickerSheet` (which is
actually the Japanese-symbol picker) instead of `JohoSFSymbolPickerSheet`.

- §1 (Overview): added `Vecka/JohoCalendarWidgets.swift` to the file
  inventory.
- §7.1 (Containers): added `JohoCalendarContainer`.
- §7.7 (Buttons): added `JohoActionButton`.
- §7.10 (Pickers): rewrote — split `JohoSFSymbolPickerSheet` (SF Symbols,
  in `JohoSettings.swift`) from `JohoSymbolPickerSheet` (Japanese symbols,
  in `JohoSymbols.swift`); added `JohoCalendarPicker`,
  `JohoCalendarPickerSheet`, `JohoYearPicker`; removed the confusing
  `JohoIconPicker` row (the private struct of that name lives in
  `Vecka/Views/CountdownViews.swift` and is not DS API).
- §8 (View modifiers): broadened the leading source-location note to
  cover all four files modifiers now live in; added `.johoCalendarPicker(...)`,
  `.johoYearPicker(...)`, and `.johoColorMode(_:)`.

Companion validator changes (not docs): `scripts/validate-docs.sh` gained
§1 file-existence, §7.1–7.11 struct-existence, and §8 modifier-existence
checks; also fixed a latent prefix-match bug in `extract_section_rows`
(querying section "N.1" would also match "N.10" / "N.11" / "N.12").

## Rev C — 2026-05-29

**JDS-MAN-SFW-001: document automated enforcement.**

A JDS house-rule audit expanded `scripts/lint-design-system.sh` from 3 to
8 enforced rules. This revision documents that coverage.

- Added §10.1 (Automated enforcement): table mapping each house rule to its
  linter id and mode (strict vs. ratchet), and noting the two rules (black
  borders, status-bar legibility) that remain review-only.
- No token, icon, component, or modifier tables changed — `./build.sh
  validate-docs` still passes 52/52.

Companion code changes (not docs): linter now also enforces `colorraw`,
`corners`, `fonts`, `glass`, `weights`; small fixes converted 5 corners to
`.continuous`, 4 sub-`.medium` weights to `.medium`, and added `design:
.rounded` to 9 widget fonts.

## Rev B — 2026-05-27

**JDS-MAN-SFW-001: sync manual with post-cleanup code.**

The IconCatalog and JohoColors dead-code sweeps removed constants the
manual still listed. This revision drops the stale rows.

- §2.4 (Utility tokens): removed `eventPurple`, `inputBackground`,
  `editAction`, `deleteAction` rows — constants deleted from
  `Vecka/JohoFoundations.swift` because they had zero call sites.
- §6.2 (Icon Catalog key constants): removed `.countdown` row —
  constant deleted from `Vecka/JohoSymbols.swift`. Countdowns continue
  to use `.event` (same SF Symbol value), already documented.

No tokens added. No semantic changes. Register entry on the JDS side
needs to be bumped from Rev A to Rev B (see jds-handoff/ in this repo).

## Rev A — 2026-05-27

**Initial documentation set.**

- Created [`JDS-PRJ-SFW-002_onsen-planner.md`](JDS-PRJ-SFW-002_onsen-planner.md) — project card for Onsen Planner. Rev A, CURRENT.
- Created [`JDS-MAN-SFW-001_joho-design-system.md`](JDS-MAN-SFW-001_joho-design-system.md) — Joho Design System manual covering colors, typography, dimensions, icon catalog, components, view modifiers, theme system, and house rules. Rev A, CURRENT.
- Created [`README.md`](README.md) — folder entry point and JDS convention summary.
- Created root [`/README.md`](../README.md) — repo landing page with links into `docs/`.
- Added a Documentation pointer section to [`/CLAUDE.md`](../CLAUDE.md) so the design-system reference is discoverable from the agent context.

**Register entries to mirror into `nj22az/JDS_Documentation/jds/registry/document-register.md`:**

```
JDS-PRJ-SFW-002  Onsen Planner               Rev A  CURRENT  2026-05-27  Nils Johansson
JDS-MAN-SFW-001  Joho Design System Manual   Rev A  CURRENT  2026-05-27  Nils Johansson
```
