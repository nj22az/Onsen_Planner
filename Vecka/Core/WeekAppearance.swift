import SwiftUI
import UIKit

/// These are palette adaptations; navigation, type and controls stay native.
enum WeekAppearance: String, CaseIterable, Identifiable {
    case apple, muji, note, kinto
    var id: String { rawValue }
    static let storageKey = "weekAppearance"
    static let appGroup = "group.Johansson.Vecka"
    static var defaults: UserDefaults {
        let suite = ProcessInfo.processInfo.arguments.contains("-ui-testing") ? appGroup + ".uitests" : appGroup
        return UserDefaults(suiteName: suite) ?? .standard
    }
    static func resolve(_ value: String) -> Self { Self(rawValue: value) ?? .apple }

    var title: String {
        switch self {
        case .apple: return "Apple"
        case .muji: return "MUJI — Quiet"
        case .note: return "note — Clear"
        case .kinto: return "KINTO — Neutral"
        }
    }

    var tint: Color {
        switch self {
        case .apple: return Color(uiColor: .systemBlue)
        case .muji: return adaptive(light: 0x7F0019, dark: 0xE6B5BE)
        case .note: return adaptive(light: 0x1E7B65, dark: 0x77D8BD)
        case .kinto: return adaptive(light: 0x555555, dark: 0xD6D2CC)
        }
    }

    private func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }
}
