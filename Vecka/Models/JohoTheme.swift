//
//  JohoTheme.swift
//  Vecka
//
//  Theme preset system for unified category color theming
//  Themes change category colors + icons + UI accent
//  Month seasonal colors (季節の色) are identity-locked and never change
//

import SwiftUI

// MARK: - Theme Preset Model

struct JohoThemePreset: Codable, Identifiable {
    let id: String              // "default", "sakura", "nordic"
    let name: String            // Display name
    let description: String     // One-liner
    let previewIcon: String     // SF Symbol for theme card

    // Category colors (hex)
    let holidayColorHex: String
    let observanceColorHex: String
    let memoColorHex: String

    // Category icons (nil = keep default)
    let holidayIcon: String?
    let observanceIcon: String?
    let memoIcon: String?

    // UI accent
    let systemAccent: String    // "black", "indigo", "navy", "blue", "slate"

    // Vecka Pro gating (nil/false = free; paid themes unlock with Vecka Pro)
    let isPremium: Bool?

    // Category foreground colors (nil = auto-derive from background)
    let holidayForegroundHex: String?
    let observanceForegroundHex: String?
    let memoForegroundHex: String?

    // Dark mode category colors (nil = use light mode value)
    let holidayDarkColorHex: String?
    let observanceDarkColorHex: String?
    let memoDarkColorHex: String?

    // Dark mode foreground colors (nil = auto-derive)
    let holidayDarkForegroundHex: String?
    let observanceDarkForegroundHex: String?
    let memoDarkForegroundHex: String?

    // Structural overrides (nil = use JohoScheme defaults)
    let lightBorderHex: String?
    let lightSurfaceHex: String?
    let lightCanvasHex: String?
    let darkBorderHex: String?
    let darkSurfaceHex: String?
    let darkCanvasHex: String?

    init(
        id: String, name: String, description: String, previewIcon: String,
        holidayColorHex: String, observanceColorHex: String, memoColorHex: String,
        holidayIcon: String?, observanceIcon: String?, memoIcon: String?,
        systemAccent: String,
        isPremium: Bool? = nil,
        holidayForegroundHex: String? = nil, observanceForegroundHex: String? = nil, memoForegroundHex: String? = nil,
        holidayDarkColorHex: String? = nil, observanceDarkColorHex: String? = nil, memoDarkColorHex: String? = nil,
        holidayDarkForegroundHex: String? = nil, observanceDarkForegroundHex: String? = nil, memoDarkForegroundHex: String? = nil,
        lightBorderHex: String? = nil, lightSurfaceHex: String? = nil, lightCanvasHex: String? = nil,
        darkBorderHex: String? = nil, darkSurfaceHex: String? = nil, darkCanvasHex: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.previewIcon = previewIcon
        self.holidayColorHex = holidayColorHex
        self.observanceColorHex = observanceColorHex
        self.memoColorHex = memoColorHex
        self.holidayIcon = holidayIcon
        self.observanceIcon = observanceIcon
        self.memoIcon = memoIcon
        self.systemAccent = systemAccent
        self.isPremium = isPremium
        self.holidayForegroundHex = holidayForegroundHex
        self.observanceForegroundHex = observanceForegroundHex
        self.memoForegroundHex = memoForegroundHex
        self.holidayDarkColorHex = holidayDarkColorHex
        self.observanceDarkColorHex = observanceDarkColorHex
        self.memoDarkColorHex = memoDarkColorHex
        self.holidayDarkForegroundHex = holidayDarkForegroundHex
        self.observanceDarkForegroundHex = observanceDarkForegroundHex
        self.memoDarkForegroundHex = memoDarkForegroundHex
        self.lightBorderHex = lightBorderHex
        self.lightSurfaceHex = lightSurfaceHex
        self.lightCanvasHex = lightCanvasHex
        self.darkBorderHex = darkBorderHex
        self.darkSurfaceHex = darkSurfaceHex
        self.darkCanvasHex = darkCanvasHex
    }
}

// MARK: - Theme Loader

enum JohoThemeLoader {

    /// Load theme presets from bundled JSON
    static func loadPresets() -> [JohoThemePreset] {
        BundleJSON.load("theme-presets", fallback: builtInPresets)
    }

    /// Fallback built-in presets if JSON fails to load
    static let builtInPresets: [JohoThemePreset] = [
        JohoThemePreset(
            id: "default", name: "Default", description: "Original 情報デザイン palette",
            previewIcon: "circle.hexagongrid.fill",
            holidayColorHex: "FECDD3", observanceColorHex: "A5F3FC", memoColorHex: "FFE566",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "indigo",
            holidayForegroundHex: "9F1239", observanceForegroundHex: "155E75", memoForegroundHex: "854D0E",
            holidayDarkColorHex: "881337", observanceDarkColorHex: "164E63", memoDarkColorHex: "854D0E",
            holidayDarkForegroundHex: "FECDD3", observanceDarkForegroundHex: "A5F3FC", memoDarkForegroundHex: "FFE566"
        ),
        JohoThemePreset(
            id: "nordic", name: "Nordic", description: "Scandinavian minimalism",
            previewIcon: "snowflake",
            holidayColorHex: "93C5FD", observanceColorHex: "C4B5FD", memoColorHex: "CBD5E1",
            holidayIcon: "star.fill", observanceIcon: "diamond.fill", memoIcon: "note.text",
            systemAccent: "navy",
            holidayForegroundHex: "1E40AF", observanceForegroundHex: "5B21B6", memoForegroundHex: "334155",
            holidayDarkColorHex: "1E3A5F", observanceDarkColorHex: "4C1D95", memoDarkColorHex: "334155",
            holidayDarkForegroundHex: "93C5FD", observanceDarkForegroundHex: "C4B5FD", memoDarkForegroundHex: "CBD5E1",
            lightBorderHex: "475569", lightSurfaceHex: "F8FAFC", lightCanvasHex: nil,
            darkBorderHex: "64748B", darkSurfaceHex: "1E293B", darkCanvasHex: nil
        ),
        JohoThemePreset(
            id: "earth", name: "Earth", description: "Warm, natural tones",
            previewIcon: "mountain.2.fill",
            holidayColorHex: "86EFAC", observanceColorHex: "FDBA74", memoColorHex: "FDE68A",
            holidayIcon: "leaf.fill", observanceIcon: "sun.max.fill", memoIcon: "note.text",
            systemAccent: "slate",
            holidayForegroundHex: "15803D", observanceForegroundHex: "9A3412", memoForegroundHex: "854D0E",
            holidayDarkColorHex: "14532D", observanceDarkColorHex: "7C2D12", memoDarkColorHex: "713F12",
            holidayDarkForegroundHex: "86EFAC", observanceDarkForegroundHex: "FDBA74", memoDarkForegroundHex: "FDE68A",
            lightBorderHex: "92400E", lightSurfaceHex: "FFFBEB", lightCanvasHex: nil,
            darkBorderHex: "A0896D", darkSurfaceHex: "1C1917", darkCanvasHex: nil
        ),
        JohoThemePreset(
            id: "ink", name: "Ink", description: "AMOLED high-contrast mono",
            previewIcon: "drop.fill",
            holidayColorHex: "E4E4E7", observanceColorHex: "A1A1AA", memoColorHex: "71717A",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "black",
            holidayForegroundHex: "27272A", observanceForegroundHex: "27272A", memoForegroundHex: "18181B",
            holidayDarkColorHex: "3F3F46", observanceDarkColorHex: "52525B", memoDarkColorHex: "52525B",
            holidayDarkForegroundHex: "E4E4E7", observanceDarkForegroundHex: "D4D4D8", memoDarkForegroundHex: "A1A1AA",
            lightBorderHex: "52525B", lightSurfaceHex: "000000", lightCanvasHex: "000000",
            darkBorderHex: "3F3F46", darkSurfaceHex: "000000", darkCanvasHex: "000000"
        ),
        // MARK: Japanese brand-palette themes (tokens adapted from awesome-design-md-jp, MIT — see docs/JDS-REF-SFW-002)
        JohoThemePreset(
            id: "teal", name: "Teal", description: "Editorial calm — inspired by note.com",
            previewIcon: "doc.text.fill",
            holidayColorHex: "F6DEE4", observanceColorHex: "D5EFEA", memoColorHex: "FCEFC7",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "blue",
            holidayForegroundHex: "A03050", observanceForegroundHex: "1E7B65", memoForegroundHex: "7A6E22",
            holidayDarkColorHex: "5A2432", observanceDarkColorHex: "14332D", memoDarkColorHex: "4A3F14",
            holidayDarkForegroundHex: "F6DEE4", observanceDarkForegroundHex: "B8E6DC", memoDarkForegroundHex: "FCEFC7",
            lightBorderHex: "33454F", lightSurfaceHex: "F5F8FA", lightCanvasHex: nil,
            darkBorderHex: "3D5561", darkSurfaceHex: "0E1B22", darkCanvasHex: "08131A"
        ),
        JohoThemePreset(
            id: "stone", name: "Stone", description: "Warm neutral clarity — inspired by SmartHR",
            previewIcon: "square.grid.2x2.fill",
            holidayColorHex: "F8DDE5", observanceColorHex: "D8EAF7", memoColorHex: "FBF0C4",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "blue",
            holidayForegroundHex: "B21B48", observanceForegroundHex: "075E9C", memoForegroundHex: "7D6608",
            holidayDarkColorHex: "4A1626", observanceDarkColorHex: "123A55", memoDarkColorHex: "4A3D10",
            holidayDarkForegroundHex: "F8DDE5", observanceDarkForegroundHex: "D8EAF7", memoDarkForegroundHex: "FBF0C4",
            lightBorderHex: "23221E", lightSurfaceHex: "F8F7F6", lightCanvasHex: nil,
            darkBorderHex: "57534E", darkSurfaceHex: "1C1B1A", darkCanvasHex: "141312"
        ),
        JohoThemePreset(
            id: "wagashi", name: "Wagashi", description: "Beni & kuro elegance — inspired by Funabashiya 船橋屋",
            previewIcon: "cup.and.saucer.fill",
            holidayColorHex: "F1B7C1", observanceColorHex: "DCD5E2", memoColorHex: "F4EBDD",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "black",
            isPremium: true,
            holidayForegroundHex: "450510", observanceForegroundHex: "3E3A47", memoForegroundHex: "6B4F2E",
            holidayDarkColorHex: "6B2430", observanceDarkColorHex: "3A3444", memoDarkColorHex: "453620",
            holidayDarkForegroundHex: "F3C9D1", observanceDarkForegroundHex: "DCD5E2", memoDarkForegroundHex: "F4EBDD",
            lightBorderHex: "080604", lightSurfaceHex: "F6F5F8", lightCanvasHex: nil,
            darkBorderHex: "565049", darkSurfaceHex: "171412", darkCanvasHex: "0D0B09"
        ),
        JohoThemePreset(
            id: "kincha", name: "Kincha", description: "金茶 garden gold — inspired by Adachi Museum 足立美術館",
            previewIcon: "building.columns.fill",
            holidayColorHex: "E7DCC3", observanceColorHex: "D5E5D9", memoColorHex: "EAE6DD",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "navy",
            isPremium: true,
            holidayForegroundHex: "69592A", observanceForegroundHex: "2C5D43", memoForegroundHex: "5C5A56",
            holidayDarkColorHex: "57481F", observanceDarkColorHex: "203A2C", memoDarkColorHex: "3B3A36",
            holidayDarkForegroundHex: "E7DCC3", observanceDarkForegroundHex: "D5E5D9", memoDarkForegroundHex: "EAE6DD",
            lightBorderHex: "3B3A36", lightSurfaceHex: "FAF9F6", lightCanvasHex: nil,
            darkBorderHex: "57544C", darkSurfaceHex: "211F1C", darkCanvasHex: "171512"
        ),
        // MARK: Batch 2 — tech brands (free)
        JohoThemePreset(
            id: "vibes", name: "Vibes", description: "Friendly business blue — inspired by freee",
            previewIcon: "bolt.fill",
            holidayColorHex: "F8D6DA", observanceColorHex: "DCE8FF", memoColorHex: "FEF0D2",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "blue",
            holidayForegroundHex: "A51428", observanceForegroundHex: "1E46AA", memoForegroundHex: "8C6C0E",
            holidayDarkColorHex: "4A1420", observanceDarkColorHex: "143278", memoDarkColorHex: "3F3410",
            holidayDarkForegroundHex: "F8D6DA", observanceDarkForegroundHex: "DCE8FF", memoDarkForegroundHex: "FEF0D2",
            lightBorderHex: "323232", lightSurfaceHex: "F7F5F5", lightCanvasHex: nil,
            darkBorderHex: "4A5260", darkSurfaceHex: "20242C", darkCanvasHex: "16181F"
        ),
        JohoThemePreset(
            id: "cobalt", name: "Cobalt", description: "Deep career blue — inspired by Findy",
            previewIcon: "briefcase.fill",
            holidayColorHex: "FCE3D4", observanceColorHex: "D8E6F5", memoColorHex: "FCF5CD",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "blue",
            holidayForegroundHex: "B04E12", observanceForegroundHex: "155AA8", memoForegroundHex: "8A720A",
            holidayDarkColorHex: "4A2410", observanceDarkColorHex: "123A5C", memoDarkColorHex: "3F3610",
            holidayDarkForegroundHex: "FCE3D4", observanceDarkForegroundHex: "D8E6F5", memoDarkForegroundHex: "FCF5CD",
            lightBorderHex: "1B2025", lightSurfaceHex: "F4F7FC", lightCanvasHex: nil,
            darkBorderHex: "3F4A55", darkSurfaceHex: "141A21", darkCanvasHex: "0E1218"
        ),
        JohoThemePreset(
            id: "journey", name: "Journey", description: "Bright travel green — inspired by NEWT",
            previewIcon: "airplane",
            holidayColorHex: "FFE9EE", observanceColorHex: "E4F8EA", memoColorHex: "FCF3C4",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "slate",
            holidayForegroundHex: "B72B3D", observanceForegroundHex: "006E0F", memoForegroundHex: "7A6116",
            holidayDarkColorHex: "4A1620", observanceDarkColorHex: "123D22", memoDarkColorHex: "3D3212",
            holidayDarkForegroundHex: "FFE9EE", observanceDarkForegroundHex: "D6F5DE", memoDarkForegroundHex: "FCF3C4",
            lightBorderHex: "28332E", lightSurfaceHex: "F4F6F6", lightCanvasHex: nil,
            darkBorderHex: "3F4D46", darkSurfaceHex: "14201A", darkCanvasHex: "0D1511"
        ),
        JohoThemePreset(
            id: "neon", name: "Neon", description: "Night-TV black + green — inspired by ABEMA",
            previewIcon: "tv.fill",
            holidayColorHex: "FFD7E5", observanceColorHex: "D6F5DC", memoColorHex: "FFF3D6",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "black",
            holidayForegroundHex: "B3005C", observanceForegroundHex: "008A00", memoForegroundHex: "8A6D1F",
            holidayDarkColorHex: "5C0F33", observanceDarkColorHex: "0E3D18", memoDarkColorHex: "3D3012",
            holidayDarkForegroundHex: "FFD7E5", observanceDarkForegroundHex: "C9F0D1", memoDarkForegroundHex: "FFF3D6",
            lightBorderHex: "1A1A1A", lightSurfaceHex: "F5F5F5", lightCanvasHex: nil,
            darkBorderHex: "4D4D4D", darkSurfaceHex: "1A1A1A", darkCanvasHex: "000000"
        ),
        // MARK: Batch 2 — culture & sport (free)
        JohoThemePreset(
            id: "paddock", name: "Paddock", description: "Swiss racing green — inspired by JRA",
            previewIcon: "flag.checkered",
            holidayColorHex: "E8F4EF", observanceColorHex: "FADDDC", memoColorHex: "FCE9DB",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "black",
            holidayForegroundHex: "004E36", observanceForegroundHex: "A11319", memoForegroundHex: "8A4113",
            holidayDarkColorHex: "0F3D2C", observanceDarkColorHex: "4A1517", memoDarkColorHex: "3D2B14",
            holidayDarkForegroundHex: "D6EEE2", observanceDarkForegroundHex: "FADDDC", memoDarkForegroundHex: "FCE9DB",
            lightBorderHex: "0A0A0A", lightSurfaceHex: "F4F4F4", lightCanvasHex: nil,
            darkBorderHex: "4A524F", darkSurfaceHex: "141818", darkCanvasHex: "0E1111"
        ),
        JohoThemePreset(
            id: "vision", name: "Vision", description: "Cyan-on-white museum — inspired by 21_21 DESIGN SIGHT",
            previewIcon: "eye.fill",
            holidayColorHex: "FFE8D1", observanceColorHex: "D9EEFB", memoColorHex: "ECECEC",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "blue",
            holidayForegroundHex: "A65C00", observanceForegroundHex: "006BB0", memoForegroundHex: "333333",
            holidayDarkColorHex: "4A2E10", observanceDarkColorHex: "123A55", memoDarkColorHex: "2E3236",
            holidayDarkForegroundHex: "FFE8D1", observanceDarkForegroundHex: "D9EEFB", memoDarkForegroundHex: "ECECEC",
            lightBorderHex: "1E2126", lightSurfaceHex: "F3F3F3", lightCanvasHex: nil,
            darkBorderHex: "46555F", darkSurfaceHex: "181D22", darkCanvasHex: "101419"
        ),
        JohoThemePreset(
            id: "wakaba", name: "Wakaba", description: "若葉 gallery green — inspired by CAMK 熊本市現代美術館",
            previewIcon: "paintpalette.pointed.fill",
            holidayColorHex: "E2F3D4", observanceColorHex: "E9EFE7", memoColorHex: "F3F6DC",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "black",
            holidayForegroundHex: "3D7A0E", observanceForegroundHex: "4E5A4C", memoForegroundHex: "6E7A2E",
            holidayDarkColorHex: "26400F", observanceDarkColorHex: "2E332D", memoDarkColorHex: "33381C",
            holidayDarkForegroundHex: "DDF0D1", observanceDarkForegroundHex: "E9EFE7", memoDarkForegroundHex: "F3F6DC",
            lightBorderHex: "000000", lightSurfaceHex: "F6F6F4", lightCanvasHex: nil,
            darkBorderHex: "4A4D48", darkSurfaceHex: "161816", darkCanvasHex: "0E0F0E"
        ),
        // MARK: Batch 2 — lifestyle & craft (Utsuwa free; Vermilion & Sometsuke Vecka Pro)
        JohoThemePreset(
            id: "utsuwa", name: "Utsuwa", description: "Warm tableware neutral — inspired by KINTO",
            previewIcon: "fork.knife",
            holidayColorHex: "FFDFD3", observanceColorHex: "EFE9DE", memoColorHex: "EBEDEC",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "slate",
            holidayForegroundHex: "B73908", observanceForegroundHex: "6E6150", memoForegroundHex: "44514B",
            holidayDarkColorHex: "4A1F0E", observanceDarkColorHex: "383228", memoDarkColorHex: "2E3331",
            holidayDarkForegroundHex: "FFDFD3", observanceDarkForegroundHex: "EFE9DE", memoDarkForegroundHex: "EBEDEC",
            lightBorderHex: "4E4E4E", lightSurfaceHex: "F7F8F8", lightCanvasHex: nil,
            darkBorderHex: "5C5C58", darkSurfaceHex: "1E1E1D", darkCanvasHex: "151514"
        ),
        JohoThemePreset(
            id: "vermilion", name: "Vermilion", description: "朱色 craft heritage — inspired by aeru",
            previewIcon: "flame.fill",
            holidayColorHex: "F9DDDA", observanceColorHex: "DFEEE5", memoColorHex: "F6EDE3",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "black",
            isPremium: true,
            holidayForegroundHex: "A52819", observanceForegroundHex: "2E7D4F", memoForegroundHex: "6B4E32",
            holidayDarkColorHex: "4A1B16", observanceDarkColorHex: "1C3527", memoDarkColorHex: "3D2C1B",
            holidayDarkForegroundHex: "F9DDDA", observanceDarkForegroundHex: "DFEEE5", memoDarkForegroundHex: "F6EDE3",
            lightBorderHex: "262626", lightSurfaceHex: "FBF9F7", lightCanvasHex: nil,
            darkBorderHex: "52443F", darkSurfaceHex: "1E1715", darkCanvasHex: "151010"
        ),
        JohoThemePreset(
            id: "sometsuke", name: "Sometsuke", description: "染付 porcelain blue — inspired by 1616/arita japan",
            previewIcon: "circle.grid.cross.fill",
            holidayColorHex: "FFF6C9", observanceColorHex: "DCE6F0", memoColorHex: "EDECE8",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "black",
            isPremium: true,
            holidayForegroundHex: "6B5E00", observanceForegroundHex: "2E4A66", memoForegroundHex: "595757",
            holidayDarkColorHex: "40390F", observanceDarkColorHex: "1C3045", memoDarkColorHex: "332F2C",
            holidayDarkForegroundHex: "FFF6C9", observanceDarkForegroundHex: "DCE6F0", memoDarkForegroundHex: "EDECE8",
            lightBorderHex: "231F20", lightSurfaceHex: "F5F5F3", lightCanvasHex: nil,
            darkBorderHex: "57504F", darkSurfaceHex: "1F1C1D", darkCanvasHex: "141112"
        ),
    ]
}

// MARK: - Structural Color Overrides

extension JohoThemePreset {

    /// Apply structural color overrides from this theme to a base color scheme.
    /// Auto-derives text colors from surface luminance — guarantees readable text on any surface.
    func applyStructuralOverrides(to base: JohoScheme, mode: JohoColorMode) -> JohoScheme {
        let surfaceHex: String?
        let borderHex: String?
        let canvasHex: String?

        switch mode {
        case .light:
            surfaceHex = lightSurfaceHex
            borderHex = lightBorderHex
            canvasHex = lightCanvasHex
        case .dark:
            surfaceHex = darkSurfaceHex
            borderHex = darkBorderHex
            canvasHex = darkCanvasHex
        }

        let surface = surfaceHex.map { Color(hex: $0) } ?? base.surface
        let border = borderHex.map { Color(hex: $0) } ?? base.border
        let canvas = canvasHex.map { Color(hex: $0) } ?? base.canvas

        // Auto-derive text colors from surface luminance
        let lum = surface.relativeLuminance
        let isDark = lum <= 0.5

        let primary = isDark ? Color(hex: "F0F0F0") : Color(hex: "000000")
        let secondary = isDark ? Color(hex: "F0F0F0").opacity(0.6) : Color(hex: "000000").opacity(0.6)
        let surfaceInverted = isDark ? Color(hex: "F0F0F0") : Color(hex: "000000")
        let primaryInverted = isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFFFF")
        let inputBackground = isDark ? surface.adjustedBrightness(by: 0.08) : surface.adjustedBrightness(by: -0.04)

        return JohoScheme(
            primary: primary,
            secondary: secondary,
            surface: surface,
            border: border,
            canvas: canvas,
            surfaceInverted: surfaceInverted,
            primaryInverted: primaryInverted,
            inputBackground: inputBackground
        )
    }

    /// Whether this theme has any structural overrides
    var hasStructuralOverrides: Bool {
        lightBorderHex != nil || lightSurfaceHex != nil || lightCanvasHex != nil ||
        darkBorderHex != nil || darkSurfaceHex != nil || darkCanvasHex != nil
    }
}

// MARK: - Theme Cache (avoids JSON parsing on every colors(for:) call)

enum JohoThemeCache {
    private static var cachedThemeId: String?
    private static var cachedTheme: JohoThemePreset?

    /// Get the active theme, using cache when possible
    static func activeTheme() -> JohoThemePreset? {
        guard let themeId = UserDefaults.standard.string(forKey: "activeThemeId") else {
            cachedThemeId = nil
            cachedTheme = nil
            return nil
        }
        if themeId == cachedThemeId, let theme = cachedTheme {
            return theme
        }
        let theme = JohoThemeLoader.loadPresets().first { $0.id == themeId }
        cachedThemeId = themeId
        cachedTheme = theme
        return theme
    }

    /// Invalidate the theme preset cache AND the JohoScheme color cache.
    /// Call when theme, appearance preference, or AMOLED toggle changes.
    static func invalidate() {
        cachedThemeId = nil
        cachedTheme = nil
        JohoScheme.invalidateSchemeCache()
    }

    /// Opt-in AMOLED True Black override for dark mode.
    /// When true, the dark-mode canvas becomes pure `#000000` instead of
    /// the comfortable default off-black. Read by `JohoScheme.colors(for:)`.
    static var amoledTrueBlack: Bool {
        UserDefaults.standard.bool(forKey: "amoledTrueBlack")
    }
}

// MARK: - Theme Application

extension CategoryColorSettings {

    /// Apply a theme preset, updating all category colors, foregrounds, and icons
    func applyTheme(_ theme: JohoThemePreset) {
        // Update category background colors
        setColorHex(theme.holidayColorHex, for: .holiday)
        setColorHex(theme.observanceColorHex, for: .observance)
        setColorHex(theme.memoColorHex, for: .memo)

        // Update foreground colors (direct UserDefaults write + in-memory update)
        let holFg = theme.holidayForegroundHex ?? Self.autoDerivedForeground(theme.holidayColorHex)
        let obsFg = theme.observanceForegroundHex ?? Self.autoDerivedForeground(theme.observanceColorHex)
        let memFg = theme.memoForegroundHex ?? Self.autoDerivedForeground(theme.memoColorHex)
        holidayForegroundHex = holFg
        observanceForegroundHex = obsFg
        memoForegroundHex = memFg
        UserDefaults.standard.set(holFg, forKey: "categoryForeground_holiday")
        UserDefaults.standard.set(obsFg, forKey: "categoryForeground_observance")
        UserDefaults.standard.set(memFg, forKey: "categoryForeground_memo")

        // Update dark mode background colors
        let holDk = theme.holidayDarkColorHex ?? theme.holidayColorHex
        let obsDk = theme.observanceDarkColorHex ?? theme.observanceColorHex
        let memDk = theme.memoDarkColorHex ?? theme.memoColorHex
        holidayDarkColorHex = holDk
        observanceDarkColorHex = obsDk
        memoDarkColorHex = memDk
        UserDefaults.standard.set(holDk, forKey: "categoryDarkColor_holiday")
        UserDefaults.standard.set(obsDk, forKey: "categoryDarkColor_observance")
        UserDefaults.standard.set(memDk, forKey: "categoryDarkColor_memo")

        // Update dark mode foreground colors
        let holDkFg = theme.holidayDarkForegroundHex ?? Self.autoDerivedLightForeground(holDk)
        let obsDkFg = theme.observanceDarkForegroundHex ?? Self.autoDerivedLightForeground(obsDk)
        let memDkFg = theme.memoDarkForegroundHex ?? Self.autoDerivedLightForeground(memDk)
        holidayDarkForegroundHex = holDkFg
        observanceDarkForegroundHex = obsDkFg
        memoDarkForegroundHex = memDkFg
        UserDefaults.standard.set(holDkFg, forKey: "categoryDarkForeground_holiday")
        UserDefaults.standard.set(obsDkFg, forKey: "categoryDarkForeground_observance")
        UserDefaults.standard.set(memDkFg, forKey: "categoryDarkForeground_memo")

        // Update category icons (set if specified, reset to default if nil)
        if let icon = theme.holidayIcon {
            CategoryIconSettings.setIcon(icon, for: .holiday)
        } else {
            CategoryIconSettings.reset(for: .holiday)
        }
        if let icon = theme.observanceIcon {
            CategoryIconSettings.setIcon(icon, for: .observance)
        } else {
            CategoryIconSettings.reset(for: .observance)
        }
        if let icon = theme.memoIcon {
            CategoryIconSettings.setIcon(icon, for: .memo)
        } else {
            CategoryIconSettings.reset(for: .memo)
        }

        // Update system UI accent
        UserDefaults.standard.set(theme.systemAccent, forKey: "systemUIAccent")

        // Save active theme ID
        UserDefaults.standard.set(theme.id, forKey: "activeThemeId")

        // Invalidate theme cache so colors(for:) picks up the new theme
        JohoThemeCache.invalidate()

        // Sync to widget (includes structural colors)
        CategoryColorStorage.save()
    }

    /// Auto-derive a dark foreground from a light background hex (darken by luminance)
    private static func autoDerivedForeground(_ bgHex: String) -> String {
        let color = Color(hex: bgHex)
        return color.adjustedBrightness(by: -0.45).toHex()
    }

    /// Auto-derive a light foreground from a dark background hex (lighten by luminance)
    private static func autoDerivedLightForeground(_ bgHex: String) -> String {
        let color = Color(hex: bgHex)
        return color.adjustedBrightness(by: 0.45).toHex()
    }

    /// Get the currently active theme ID (nil if custom/no theme)
    var activeThemeId: String? {
        UserDefaults.standard.string(forKey: "activeThemeId")
    }

    /// Set category icon for a display category
    func setCategoryIcon(_ icon: String, for category: DisplayCategory) {
        UserDefaults.standard.set(icon, forKey: "categoryIcon_\(category.rawValue)")
    }

    /// Get category icon for a display category (nil = use default)
    func categoryIcon(for category: DisplayCategory) -> String? {
        UserDefaults.standard.string(forKey: "categoryIcon_\(category.rawValue)")
    }

    /// Reset category icon to default
    func resetCategoryIcon(for category: DisplayCategory) {
        UserDefaults.standard.removeObject(forKey: "categoryIcon_\(category.rawValue)")
    }

    /// Check if current colors match a specific theme
    func matchesTheme(_ theme: JohoThemePreset) -> Bool {
        holidayColorHex == theme.holidayColorHex &&
        observanceColorHex == theme.observanceColorHex &&
        memoColorHex == theme.memoColorHex
    }
}
