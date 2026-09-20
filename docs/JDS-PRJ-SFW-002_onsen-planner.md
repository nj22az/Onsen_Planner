# JDS-PRJ-SFW-002 — Onsen Planner

**Doc No:** JDS-PRJ-SFW-002
**Rev:** F
**Status:** CURRENT
**Date:** 2026-09-20
**Author:** Nils Johansson

---

## Scope

Onsen Planner (internal name **Vecka**) is an iOS 18+ app for working with ISO 8601 week numbers, calendar overlays, holidays, contacts, trips, expenses, memos, and countdowns. The app uses semantic color coding (one color per concept) drawn from the Joho Design System and exposes its data through home-screen widgets and Siri Shortcuts.

Built with SwiftUI, SwiftData, WidgetKit, EventKit, and the Contacts framework. Targets iOS 18.0+ for the main app, iOS 17.0+ for the widget extension.

## Surfaces

| Surface | Bundle ID | Notes |
|---|---|---|
| Main app | `Johansson.Vecka` | iOS 18+, portrait-only on iPhone, all-but-upside-down on iPad |
| Widget extension | `Johansson.Vecka.VeckaWidget` | iOS 17+, multiple sizes, deep-links via `vecka://` scheme |
| Siri Intents | — | `CurrentWeekIntent`, `WeekOverviewIntent`, `WeekForDateIntent`, shortcuts via `AppShortcuts` |

## Tech inventory

- **UI:** SwiftUI exclusively. No UIKit views (UIKit only via `AppDelegate` for orientation lock and appearance defaults).
- **Persistence:** durable local SwiftData store; a pre-upgrade recovery copy, explicit local-only configuration, and a recovery screen if opening fails. No editable in-memory fallback. Portable JSON backup/restore is available without Pro; restore adds missing records and preserves existing entries. See `docs/RELEASE_CHECKLIST.md` for scope and migration gates.
- **CloudKit:** staged behind `ReleaseFeatures.cloudSyncEnabled = false`. Contact relationships are optional with explicit inverses and nil-safe accessors. Activation requires migration, duplicate reconciliation, remote-import refresh, signing and two-device tests; it is not currently advertised as active.
- **iOS 27 (Liquid Glass era) stance:** the design system deliberately ships opaque, bordered chrome. Navigation bars use `.toolbarBackground(colors.surface, visible)` (`JohoViewModifiers`) and UIKit bars use explicit opaque appearances (`AppDelegate.configureGlassAppearance`) — explicit appearances override default glass and are stable across the system transparency slider. No glass materials anywhere (enforced by lint rule `glass`). Onboarding's `fullScreenCover` roots its own opaque surface.
- **Holiday cache pipeline:** `HolidayManager.calculateAndCacheHolidays` snapshots rules into `Sendable` value types on the main actor, computes the years × rules date engine on a detached background task (cancellable; generation-guarded so stale results never apply), and posts the cache back to the main actor. Keeps launch and year-scrolling off the main thread. Accepted results increment an observable cache revision; calendar indicators rebuild after completion. Background/static readers retain the lock-protected cache.
- **External data:** EventKit (calendars), Contacts, Core Location (weather context, optional), Photos, Camera (QR import).
- **Monetization:** staged behind `ReleaseFeatures.proSalesEnabled = false`, keeping existing capabilities available. `StoreManager` has explicit catalog, entitlement and purchase states with retries, restore feedback, pending-approval protection and verified transaction updates. Product-fetch failures do not revoke access. Cached ownership is presentation-only until StoreKit verification. `AppleProStoreClient` isolates StoreKit for recovery tests.
- **Theme presets:** JSON-driven (`Vecka/Resources/theme-presets.json` is canonical at runtime, `JohoThemeLoader.builtInPresets` is the fallback — the two must stay in sync). Eighteen presets: Default, Nordic, Earth, Ink plus fourteen brand-palette themes adapted from Japanese brand `DESIGN.md` files ([kzhrknt/awesome-design-md-jp](https://github.com/kzhrknt/awesome-design-md-jp), MIT) — Teal (note.com), Stone (SmartHR), Vibes (freee), Cobalt (Findy), Journey (NEWT), Neon (ABEMA), Paddock (JRA), Vision (21_21 DESIGN SIGHT), Wakaba (CAMK) and Utsuwa (KINTO) free; Wagashi (Funabashiya 船橋屋), Kincha (Adachi Museum 足立美術館), Vermilion (aeru) and Sometsuke (1616/arita japan) on Vecka Pro. Provenance and add-a-theme checklist in `docs/JDS-REF-SFW-002_theme-palettes.md`.
- **iOS 27 readiness:** `@State` properties are initialized in exactly one place (declaration or init) per the iOS 27 `@State` macro semantics; unresolved hazards were fixed in `ExpenseEntryView`, `JohoEditorSheets`, and `MemoEditorView` (`JohoTimePicker`).
- **Build:** `./build.sh build|test|widget-test|archive|clean`, shared Vecka scheme, automatic available simulator selection (override `VECKA_DESTINATION`). Unit-test failures fail CI. Mac build, migration and device evidence remain required.

## Source layout

| Folder | Contents |
|---|---|
| `Vecka/Core/` | Week calculation, category engine, region selection, personnummer parser, app initializer |
| `Vecka/Models/` | SwiftData models, holiday engine, calendar rules, theme presets, world clocks, facts, memos |
| `Vecka/Views/` | All SwiftUI views (calendar, landing, contacts, special days, settings, sheets, mascots, sharables) |
| `Vecka/Services/` | External APIs (CSV/PDF export, lunar calendar, world clock sync, contacts, random facts, month theme sync) |
| `Vecka/Intents/` | Siri Shortcuts intents |
| `Vecka/JohoSymbols.swift` | `IconCatalog` and Japanese symbol vocabulary |
| `Vecka/JohoFoundations.swift` | `JohoColors`, `JohoScheme`, `SystemUIAccent`, `JohoColorMode`, hex/luminance helpers |
| `Vecka/JohoTokens.swift` | `JohoFont`, `JohoDimensions`, `SectionZone`, `JohoCardSize`, `Squircle`, `HalfCircle` |
| `Vecka/JohoComponents.swift` | Reusable UI components |
| `Vecka/JohoViewModifiers.swift` | `.johoBackground()`, `.johoNavigation()`, `.johoBordered()`, etc. |
| `Vecka/JohoSettings.swift` | `JohoThemeCache`, category color/icon overrides |
| `VeckaWidget/` | Widget extension (provider, views, holiday engine, month theme, facts) |
| `VeckaTests/`, `VeckaUITests/` | Unit and UI tests |

## Design system

The app's visual language is the **Joho Design System** — documented in full at [`JDS-MAN-SFW-001`](JDS-MAN-SFW-001_joho-design-system.md). Anything visual (colors, icons, layout primitives) flows through that manual; this card does not duplicate it.

## Cross-references

- **External register:** `nj22az/JDS_Documentation` → `projects/software/JDS-PRJ-SFW-002_onsen-planner/`
- **Manual:** [`JDS-MAN-SFW-001_joho-design-system.md`](JDS-MAN-SFW-001_joho-design-system.md)
- **Source:** [`github.com/nj22az/onsen_planner`](https://github.com/nj22az/onsen_planner)

## Open items

- CloudKit sync remains disabled; re-enabling requires schema rework (inverse relationships, optional attributes, removal of unique constraints).
- No `docs/` PDF artifacts yet; `md2pdf.py` from the JDS_Documentation repo can be run against this folder when needed.
- No public release notes document. Will be created as `JDS-LOG-SFW-XXX` when the first versioned release ships.
