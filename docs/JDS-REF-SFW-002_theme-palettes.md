# JDS-REF-SFW-002 — Japanese Brand Theme Palettes (awesome-design-md-jp)

**Doc No:** JDS-REF-SFW-002
**Rev:** B
**Status:** CURRENT
**Date:** 2026-09-19
**Author:** Nils Johansson
**Type:** Reference (design source material + provenance, not normative engineering spec)

---

This document records the provenance of the fourteen brand-palette themes shipped in Vecka's theme preset system, the design tokens each theme was distilled from, and the checklist for adding future themes.

**Rev A** added Batch 1 (Teal, Stone, Wagashi, Kincha).
**Rev B** added Batch 2 (Vibes, Cobalt, Journey, Neon, Paddock, Vision, Wakaba, Utsuwa, Vermilion, Sometsuke) — a balanced mix of tech, culture/sport and lifestyle/craft brands, gated mostly free with only the two striking artisan themes Pro.

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

### Vibes (free) ← freee (`design-md/freee`)

| Source token | Value | Theme role |
|---|---|---|
| Primary Blue / Danger / Warning | `#2864F0` / `#DC1E32` / `#FFB91E` | Holiday pastel `#F8D6DA` (fg `#A51428`), observance pastel `#DCE8FF` (fg `#1E46AA`), memo pastel `#FEF0D2` (fg `#8C6C0E`) |
| Text / surfaces | `#323232` / `#F7F5F5` | Light border + light surface; dark family re-graded `#20242C`/`#16181F` |

### Cobalt (free) ← Findy (`design-md/findy`)

| Source token | Value | Theme role |
|---|---|---|
| FCDS main blue | `#155AA8` | Observance pastel `#D8E6F5` (fg `#155AA8`) |
| Orange / yellow tags | `#F27127` / `#F2CB05` | Holiday pastel `#FCE3D4` (fg `#B04E12`), memo pastel `#FCF5CD` (fg `#8A720A`) |
| Text black / surface blue | `#1B2025` / `#F4F7FC` | Light border + light surface; dark family `#141A21`/`#0E1218` |

### Journey (free) ← NEWT (`design-md/newt`)

| Source token | Value | Theme role |
|---|---|---|
| Brand green / green-5 | `#00CD68` / `#E4F8EA` | Observance pastel `#E4F8EA` (fg dark `#006E0F`) |
| Danger / warning lights | `#FFE9EE` / `#FFFDE7` | Holiday pastel `#FFE9EE` (fg `#B72B3D`), memo pastel `#FCF3C4` (fg `#7A6116`) |
| Gray-80 (greenish) heading | `#28332E` | Light border + dark canvas family (`#14201A`/`#0D1511`) |

### Neon (free) ← ABEMA (`design-md/abema`)

| Source token | Value | Theme role |
|---|---|---|
| Green / Pink | `#00B900` / `#FF0077` | Obs-v pastel `#D6F5DC` (fg `#008A00`), holiday pastel `#FFD7E5` (fg `#B3005C`) |
| Warning | `#FF9800` | Memo pastel `#FFF3D6` (fg `#8A6D1F`) |
| Black-first surfaces | `#000000` / `#1A1A1A` | True-black dark canvas + dark surface; light side re-derived `#F5F5F5`/`#1A1A1A` border |

### Paddock (free) ← JRA (`design-md/jra`)

| Source token | Value | Theme role |
|---|---|---|
| Primary / dark / tint | `#007853` / `#004E36` / `#E8F4EF` | Holiday pastel `#E8F4EF` (fg `#004E36`) |
| Danger (GⅠ/締切) | `#D81920` | Observance pastel `#FADDDC` (fg `#A11319`) |
| Warning | `#E05A12` | Memo pastel `#FCE9DB` (fg `#8A4113`) |
| Swiss rule | text `#0A0A0A`, surface `#F4F4F4` | Light border (1px-black-rule mood) + surface; dark family `#141818`/`#0E1111` |

### Vision (free) ← 21_21 DESIGN SIGHT (`design-md/2121designsight`)

| Source token | Value | Theme role |
|---|---|---|
| Cyan blue | `#0090DF` | Observance pastel `#D9EEFB` (fg darkened `#006BB0`) |
| NEW badge orange | `#FF9900` | Holiday pastel `#FFE8D1` (fg `#A65C00`) |
| Text `#333333`, gray `#F3F3F3` | — | Memo pastel `#ECECEC` (fg `#333333`), light surface `#F3F3F3`; theme name honors the museum's 20/20-vision naming origin |

### Wakaba (free) ← CAMK 熊本市現代美術館 (`design-md/camk`)

| Source token | Value | Theme role |
|---|---|---|
| CAMK green | `#5BB016` | Holiday pastel `#E2F3D4` (fg `#3D7A0E`) |
| Black-by-alpha neutrals | `#000000` | Light border (pure black) + observance mono-green-gray pastel `#E9EFE7` (fg `#4E5A4C`) |
| Young-leaf family extended | — | Memo pastel `#F3F6DC` (fg `#6E7A2E`) keeps the single-hue family readable across roles |

### Utsuwa (free) ← KINTO (`design-md/kinto`)

| Source token | Value | Theme role |
|---|---|---|
| KINTO orange | `#FF4500` | Holiday pastel `#FFDFD3` (fg `#B73908`) |
| Warm beige | `#CEC7BB` | Observance pastel `#EFE9DE` (fg `#6E6150`) |
| Charcoal + soft surfaces | `#555555` / `#F7F8F8` | Light border `#4E4E4E` + surface `#F7F8F8`; memo cool-neutral pastel `#EBEDEC` (fg `#44514B`) |

### Vermilion (Vecka Pro) ← aeru (`design-md/aeru`)

| Source token | Value | Theme role |
|---|---|---|
| 朱色 / dark | `#C73120` / `#A52819` | Holiday pastel `#F9DDDA` (fg `#A52819`) |
| Success (craft green) | `#2E7D4F` | Observance pastel `#DFEEE5` (fg `#2E7D4F`) |
| Washi creams | `#FBF9F7` / `#FAF7F4` / `#F7F2ED` | Light surface `#FBF9F7`; memo warm cream `#F6EDE3` (fg `#6B4E32`); border `#262626` 墨色 |

### Sometsuke (Vecka Pro) ← 1616/arita japan (`design-md/1616arita`)

| Source token | Value | Theme role |
|---|---|---|
| Accent yellow (Horve Journal) | `#FFF100` | Holiday pastel `#FFF6C9` (fg `#6B5E00`) |
| Sometsuke cobalt (有田焼染付 tradition) | — | Observance pastel `#DCE6F0` (fg `#2E4A66`) — culturally grounded extension beyond the near-monochrome site |
| Warm dark grays | `#595757` / `#231F20` | Memo pastel `#EDECE8` (fg `#595757`), border `#231F20`, surface `#F5F5F3`; dark family `#1F1C1D`/`#141112` |

## Schema & Gating

- `JohoThemePreset.isPremium: Bool?` (nil/false = free, true = Vecka Pro). Optional for backward compatibility with older bundled JSON.
- Free themes: Teal, Stone, Vibes, Cobalt, Journey, Neon, Paddock, Vision, Wakaba, Utsuwa. Premium themes: Wagashi, Kincha, Vermilion, Sometsuke (`isPremium: true`) — the artisan/craft set.
- Gating principle: mostly free (adoption + delight); striking artisan themes carry the Pro value.
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
