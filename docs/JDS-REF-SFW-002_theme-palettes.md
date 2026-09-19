# JDS-REF-SFW-002 — Japanese Brand Theme Palettes (awesome-design-md-jp)

**Doc No:** JDS-REF-SFW-002
**Rev:** A
**Status:** CURRENT
**Date:** 2026-09-19
**Author:** Nils Johansson
**Type:** Reference (design source material + provenance, not normative engineering spec)

---

This document records the provenance of the four brand-palette themes added to Vecka's theme preset system (Teal, Stone, Wagashi, Kincha), the design tokens each theme was distilled from, and the checklist for adding future themes.

## Source

- **Repository:** [kzhrknt/awesome-design-md-jp](https://github.com/kzhrknt/awesome-design-md-jp) — community collection of `DESIGN.md` files documenting the design tokens (color, typography, spacing) of major Japanese web brands, in Google Stitch format extended for CJK typography.
- **License:** MIT — Copyright (c) 2026 awesome-design-md-jp contributors. Used with permission per the license; attribution retained here.
- **Method:** each brand's `DESIGN.md` (fetched from `design-md/<brand>/DESIGN.md`) was distilled into Vecka's `JohoThemePreset` schema — three category colors (holiday / observance / memo) as pastel fills with darker foregrounds, light + dark mode variants, a `SystemUIAccent`, and structural overrides (border / surface / canvas).

Vecka themes are *inspired adaptations*, not reproductions: hue/role relationships come from the source brands, but values are re-graded for JDS contrast rules (darker foreground on pastel fill, stronger borders, dark-mode deep fills with light text).

## Theme → Brand Mapping

### Teal (free) ← note.com (`design-md/note`)

| Source token | Value | Theme role |
|---|---|---|
| Brand green | `#5AC8B8` | Observance hue family (pastel `#D5EFEA`, fg `#1E7B65`) |
| Gray-900 text | `#08131A` | Dark canvas + light border family (`#33454F`) |
| Gray-50 surface | `#F5F8FA` | Light surface |
| Like rose | `#D13E5C` | Holiday hue family (pastel `#F6DEE4`, fg `#A03050`) |
| Point yellow | `#8B7F2C` | Memo hue family (pastel `#FCEFC7`, fg `#7A6E22`) |
| Success | `#1E7B65` | Observance foreground |

### Stone (free) ← SmartHR (`design-md/smarthr`)

| Source token | Value | Theme role |
|---|---|---|
| Text black | `#23221E` | Light border + dark surface family |
| Stone background | `#F8F7F6` | Light surface |
| Danger | `#E01E5A` | Holiday hue family (pastel `#F8DDE5`, fg `#B21B48`) |
| Product blue | `#0077C7` | Observance hue family (pastel `#D8EAF7`, fg `#075E9C`) |
| Warning | `#FFCC17` | Memo hue family (pastel `#FBF0C4`, fg `#7D6608`) |
| Border | `#D6D3D0` | Dark border family (`#57534E`) |

### Wagashi (Vecka Pro) ← Funabashiya 船橋屋 (`design-md/funabashiya`)

| Source token | Value | Theme role |
|---|---|---|
| Notice Red (臙脂) | `#CF1030` | Holiday hue family (pale pink `#F1B7C1`, fg dark maroon `#450510`) |
| Sumi black | `#080604` | Light border, dark canvas family |
| Surface lavender | `#F6F5F8` | Light surface + observance hue family (`#DCD5E2`, fg `#3E3A47`) |
| Pale pink | `#F0B3BE` / `#F1B7C1` | Holiday fill |
| Kuzumochi cream | — | Memo hue family (`#F4EBDD`, fg `#6B4F2E`) |

### Kincha (Vecka Pro) ← Adachi Museum 足立美術館 (`design-md/adachi-museum`)

| Source token | Value | Theme role |
|---|---|---|
| Gold 金茶 (label帯 `#69592A`, links `#907B3D`) | `#69592A`–`#927D3E` | Holiday hue family (pastel `#E7DCC3`, fg `#69592A`) |
| Garden green | `#007746` | Observance hue family (pastel `#D5E5D9`, fg `#2C5D43`) |
| Dark fill (greenish black) | `#3B3A36` | Light border + memo dark fill |
| Border light (warm gray) | `#E1DED7` | Warm-neutral surface/canvas family (`#FAF9F6` light, `#211F1C` dark) |
| Text primary 墨 | `#121212` | Canvas family |

## Schema & Gating

- `JohoThemePreset.isPremium: Bool?` (nil/false = free, true = Vecka Pro). Optional for backward compatibility with older bundled JSON.
- Free themes: Teal, Stone. Premium themes: Wagashi, Kincha (`isPremium: true`).
- Gating is enforced in `SettingsView.themePresetCard(_:)`: locked cards show a PRO pill and route to the paywall on tap instead of applying. The same binding (`showPaywall`) shares the paywall sheet already attached to the Pro section. Entitlements are checked against `StoreManager.isPro` at apply time; an already-active premium theme is never revoked.

## Adding a Future Theme — Checklist

1. Pick a brand in `awesome-design-md-jp/design-md/<brand>/` and fetch its `DESIGN.md`.
2. Distill tokens → `JohoThemePreset` fields (all hex values uppercase, no `#`); grade for JDS contrast (foregrounds clearly darker/lighter than fills; dark variants readable).
3. Add the preset to **both** `Vecka/Resources/theme-presets.json` (canonical, runtime-loaded) **and** `JohoThemeLoader.builtInPresets` in `Vecka/Models/JohoTheme.swift` (fallback) — they must stay in sync.
4. Choose a valid `systemAccent`: `black | slate | indigo | navy | blue`.
5. Choose `previewIcon` (SF Symbol) that exists on the minimum deployment target.
6. Decide gating (`isPremium`) — free themes drive adoption, premium themes drive Pro.
7. Record provenance in this document (Rev bump) with source tokens → theme roles.
8. Run `scripts/lint-design-system.sh` and `scripts/validate-docs.sh`; bump CHANGELOG.

Month seasonal colors (季節の色) are identity-locked and are **never** part of any theme.
