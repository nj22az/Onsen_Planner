# Onsen Planner (Vecka)

iOS 18+ ISO week-number utility with native Apple UI and Home/Lock Screen widgets.
Week display and date lookup work offline without permissions or database access.
Existing planner data remains available from Settings → Saved planner.

The widget-first overhaul is described in [`docs/WIDGET_FIRST_V1.md`](docs/WIDGET_FIRST_V1.md), including the three optional palettes, version-one scope and pending native acceptance.
The active design specification is [`DESIGN.md`](DESIGN.md); Joho documentation below describes the retained planner surfaces.

## Build

```bash
./build.sh build      # Debug build
./build.sh test       # Run tests
./build.sh widget-test # Build widget target only
./build.sh archive    # Release archive
./build.sh clean
```

Or open `Vecka.xcodeproj` in Xcode 16+.

## Documentation

The repo is documented under the **Johansson Documentation System (JDS)** conventions — numbered documents with revision headers and a changelog. Start in [`docs/`](docs/):

| Doc | Purpose |
|---|---|
| [`docs/JDS-PRJ-SFW-002_onsen-planner.md`](docs/JDS-PRJ-SFW-002_onsen-planner.md) | Project card — scope, surfaces, tech inventory |
| [`docs/JDS-MAN-SFW-001_joho-design-system.md`](docs/JDS-MAN-SFW-001_joho-design-system.md) | Joho Design System manual — colors, icons, components, modifiers, rules |
| [`docs/CHANGELOG.md`](docs/CHANGELOG.md) | Document-level revision log |

The parent system catalogue lives at [nj22az/JDS_Documentation](https://github.com/nj22az/JDS_Documentation).

## Project structure

```
Vecka/                 Main app
├── Core/              Week calculation, category engine, region selection
├── Models/            SwiftData models, holiday engine, theme presets
├── Views/             SwiftUI views
├── Services/          External APIs (Contacts, calendars, lunar, PDF, CSV)
├── Intents/           Siri Shortcuts
├── JohoSymbols.swift  IconCatalog
├── JohoColors via JohoFoundations.swift
├── JohoTokens.swift   Typography & dimensions
├── JohoComponents.swift
├── JohoViewModifiers.swift
└── JohoSettings.swift Theme cache, category color overrides

VeckaWidget/           Widget extension
VeckaTests/            Unit tests
VeckaUITests/          UI tests
```

## House rules

The retained planner uses the Joho Design System. Native week surfaces follow `DESIGN.md`. Don't hardcode SF Symbol strings or raw colors — see the [design-system manual](docs/JDS-MAN-SFW-001_joho-design-system.md) for the full ruleset.
