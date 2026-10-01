import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Independent presentation adaptations. Stored raw values preserve existing choices.
enum WeekAppearance: String, CaseIterable, Identifiable {
    case apple, muji, note, kinto
    var id: String { rawValue }
    static let storageKey = "weekAppearance"
    static var appGroup: String {
        #if os(macOS)
        return Bundle.main.object(forInfoDictionaryKey: "OnsenAppGroup") as? String ?? "P4LGU6F45C.OnsenPlanner"
        #else
        return "group.Johansson.Vecka"
        #endif
    }
    static var defaults: UserDefaults {
        let suite = ProcessInfo.processInfo.arguments.contains("-ui-testing") ? appGroup + ".uitests" : appGroup
        return UserDefaults(suiteName: suite) ?? .standard
    }
    static func resolve(_ value: String) -> Self { Self(rawValue: value) ?? .apple }

    var title: String {
        switch self {
        case .apple: return "Apple"
        case .muji: return "Quiet"
        case .note: return "Clear"
        case .kinto: return "Neutral"
        }
    }

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .apple: return "week.style_apple"
        case .muji: return "week.style_quiet"
        case .note: return "week.style_clear"
        case .kinto: return "week.style_neutral"
        }
    }
    var sectionSpacing: CGFloat { self == .muji ? 24 : self == .kinto ? 32 : 28 }

    var tint: Color {
        switch self {
        case .apple:
            #if os(macOS)
            return Color(nsColor: .systemBlue)
            #else
            return Color(uiColor: .systemBlue)
            #endif
        case .muji: return adaptive(light: 0x7F0019, dark: 0xE6B5BE)
        case .note: return adaptive(light: 0x1E7B65, dark: 0x77D8BD)
        case .kinto: return adaptive(light: 0x555555, dark: 0xD6D2CC)
        }
    }

    private func adaptive(light: UInt32, dark: UInt32) -> Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
        #else
        return Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
        #endif
    }
}
