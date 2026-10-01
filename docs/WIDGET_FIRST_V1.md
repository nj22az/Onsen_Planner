# Onsen Planner / Vecka — widget-first version 1

Decision: 1 October 2026. This is the implementation and release plan, not a claim that native acceptance has passed.

## Product promise

Know the ISO week number immediately, and find the week of any date. Useful for Swedish work schedules, teaching, travel and appointments that are described by week. The widget is the product's primary daily surface; opening the app is optional.

Keep the installed name Onsen Planner and the existing bundle identifier for this development change. Proposed App Store positioning: **Vecka — Week Number**, with a subtitle such as **ISO weeks, dates and widgets**. Validate naming availability and Swedish/English metadata before publication. No new mascot, account, subscription, onboarding barrier or notification permission is needed.

## Design decision

Apple native is the default: system typography and semantic backgrounds, NavigationStack, TabView, List, Form, DatePicker, standard controls and system dark/light mode. The number is the hero. No thick box outlines, ornamental panels or animated mascot. The existing saved planner retains its separate legacy design for compatibility; its mascot has also been removed.

Three optional palette adaptations from [awesome-design-md-jp](https://github.com/kzhrknt/awesome-design-md-jp):

| Choice | Reference | Application |
| --- | --- | --- |
| MUJI — Quiet | [MUJI DESIGN.md](https://github.com/kzhrknt/awesome-design-md-jp/blob/main/design-md/muji/DESIGN.md) | Restrained burgundy, neutral surfaces and generous spacing. |
| note — Clear | [note DESIGN.md](https://github.com/kzhrknt/awesome-design-md-jp/blob/main/design-md/note/DESIGN.md) | Readability and a dark teal accent, using the reference's readable success colour rather than pale brand green for text. |
| KINTO — Neutral | [KINTO DESIGN.md](https://github.com/kzhrknt/awesome-design-md-jp/blob/main/design-md/kinto/DESIGN.md) | Charcoal and warm grey, with content given space. |

[Apple Japan reference](https://github.com/kzhrknt/awesome-design-md-jp/blob/main/design-md/apple/DESIGN.md) informs restraint; this app uses platform controls rather than copying a marketing website. These are independent adaptations, not branded products or endorsements. Original source documentation remains linked; there are no copied logos, commercial fonts or assets.

All four choices use the same native layout. Dark-mode accents are adapted for legibility. Themes are free, shared with Home Screen widgets through the existing App Group, and invalid/missing preferences fall back to Apple. Lock Screen and tinted widgets respect the system's rendering. Older planner theme preferences are preserved separately.

## First-version scope

| Ship in v1 | Keep outside the core v1 flow |
| --- | --- |
| Current ISO week, Monday–Sunday range and explicit ISO week-year | New planner features, holiday feeds and calendar integration |
| Previous/next week and return to today | Contacts, expenses, trips and personal reminders |
| Date lookup | Cloud sync, accounts, AI, subscriptions and Pro sales |
| Small week-number widget; medium week strip; large month grid with week numbers | Random facts, decorative mascots, weather and animated backgrounds |
| Circular, rectangular and inline Lock Screen widgets | Notifications, Live Activities and extra calendar systems |
| Apple default plus the three palettes | Redesigning every legacy editor before proving widget demand |
| Swedish and English release copy; Vietnamese translation included | Claiming completed translation of all nine older app languages |
| Widget setup instructions, accessible labels and offline operation | Marketing as a replacement for Apple Calendar |

Existing planner records, backup/restore, bundle IDs, App Group and URL scheme remain available. They are not deleted or migrated for the new core screen. Access is through Settings → Saved planner. Old fact/upcoming deep links still route to the saved planner. A storage failure opens recovery there and does not block the native week utility.

## Resilience implementation

- One shared Foundation-only ISO date engine supplies the app and widget. Monday start and four-day first-week rule are fixed, independent of locale, holiday region and saved database rules.
- A date has both a week number and a week-year. Links contain both; invalid week/year combinations are rejected rather than silently normalised.
- The widget builds the current entry and fourteen future local-midnight entries. Calendar-day arithmetic handles 23/25-hour DST days. WidgetKit controls rendering and refresh timing; this is not a guarantee of unlimited background freshness.
- The app recomputes current-week content on its foreground timeline. The Today mode follows the date across midnight; browsed weeks remain selected. The older week calculator no longer caches time-dependent fields.
- Foreground activation and palette changes request a widget refresh. After travel, time-zone changes or manual clock changes, opening the app requests a fresh timeline. Verify travel behaviour on device before release.
- The core does not open SwiftData or request Contacts, Calendar, Camera or Photos access. No network task supplies the week number. Shared settings failure yields Apple styling while date calculation still works.
- No automatic deletion, replacement database, writable in-memory fallback or Pro gating is introduced. Existing recovery remains separate and explicit.

## Release gates, in order

1. **Native compilation:** build Debug and Release with the app and embedded widget; confirm shared source membership, packaged localisations, privacy manifests and preserved signing identities. Resolve the CI account/runner problem or run the same commands on a Mac. Keep xcresult evidence.
2. **Date correctness:** run ISOWeekCalendarTests and existing unit/recovery tests. New checks cover known New Year boundaries, a 400-year week round-trip, valid week 53, rejected invalid weeks, DST midnights, time-zone differences, six-row months, stale day counts and appearance fallback.
3. **Real UI:** run the new UI tests against the actual WeekRootView. Then manually verify iPhone/iPad, the smallest supported screens, largest accessibility text, VoiceOver, light/dark, Reduce Motion and all four palettes. Confirm theme persistence after relaunch.
4. **Widget acceptance:** add every family to real Home/Lock Screens. Check standard, tinted/accented and vibrant rendering, widget-gallery previews, midnight/week/year rollover, DST, device restart, delayed refresh and Stockholm ↔ Vietnam travel. The app and widget must agree for the same local date.
5. **Saved-data safety:** upgrade a copy of the old database; compare notes, photos, contacts and relationships. Open the saved planner, export/restore a backup twice, test a corrupt/failed store, and return to the week screen. The original store must remain intact. Schema migration is not proven by a clean installation.
6. **Publication:** verify product name availability, sign/archive, TestFlight a small Swedish/English cohort, review privacy disclosures and screenshots, then submit. Keep cloud and new Pro sales disabled.

No release should be described as fail-safe in an absolute sense. Acceptance means the above failure cases are tested and no known data-loss or date-correctness defect remains.

## Relevance after launch

Test the core question with five to ten people who already use week numbers for work or study: can they identify the week without opening the app, look up a date, and understand week 53/New Year? Collect feedback directly; no analytics SDK is required. Review clarity, widget legibility and reliability before enlarging scope.

After a stable v1, prioritise per-widget palette selection and a year overview if users request them. Optional holiday labels can follow as a separate feature. Calendar permissions, reminders, sync and monetisation require independent demand and acceptance; they must not become dependencies of the week widget.

## Evidence for this change

Linux source validation is recorded in the pull request. Xcode compilation, XCTest/UI execution, signed archive, device layout, widget rollover and old-store upgrade acceptance are pending. English/Swedish/Vietnamese utility strings are supplied; the other six existing locales use English fallback for new utility copy.
