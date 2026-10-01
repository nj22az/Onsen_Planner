//
//  VeckaApp.swift
//  Vecka
//
//  Created by Nils Johansson on 2025-08-09.
//

import SwiftUI
import UIKit
import SwiftData

@main
struct VeckaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var navigationManager = NavigationManager()
    @State private var storeManager = StoreManager.shared
    @State private var persistence = AppPersistence()

    var body: some Scene {
        WindowGroup {
            WeekRootView(persistence: persistence)
                .environment(navigationManager)
                .environment(storeManager)
                .onOpenURL { handleWidgetURL($0) }
        }
    }

    // MARK: - Widget URL Handling
    private func handleWidgetURL(_ url: URL) {
        guard url.scheme == "vecka" else { return }
        
        switch url.host {
        case "today":
            // Widget tapped to show today - no special action needed
            navigationManager.navigateToToday()
            
        case "week":
            // Widget tapped to show specific week - parse week/year from path
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if pathComponents.count >= 2,
               let weekNumber = Int(pathComponents[0]),
               let year = Int(pathComponents[1]) {
                navigationManager.navigateToWeek(weekNumber, year: year)
            } else if pathComponents.count >= 1,
                      let weekNumber = Int(pathComponents[0]) {
                navigationManager.navigateToWeek(weekNumber)
            } else {
                navigationManager.navigateToToday()
            }
            
        case "calendar":
            // Large widget calendar view tapped - navigate to today
            navigationManager.navigateToToday()

        case "facts":
            // Random fact widget tapped - show fact detail
            // URL format: vecka://facts/{factId}
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let factId = pathComponents.first {
                navigationManager.navigateToFact(factId)
            } else {
                navigationManager.navigateToLanding()
            }

        case "upcoming":
            // Large widget upcoming specials tapped - navigate to star page
            navigationManager.navigateToStarPage()

        default:
            // Unknown URL - navigate to today as fallback
            navigationManager.navigateToToday()
        }
    }
}

// MARK: - Navigation Manager for Widget Deep Links
// MainActor-isolated to ensure thread-safe state updates from widget URL handling
@MainActor
@Observable
class NavigationManager {
    var targetDate = Date()
    var shouldScrollToWeek = false
    var targetPage: SidebarSelection = .landing  // 情報デザイン: Landing is home
    var shouldNavigateToPage = false
    var factIdToShow: String?  // Deep link from widget to show fact detail

    /// Navigate to landing page (情報デザイン: Onsen is home)
    func navigateToLanding() {
        targetPage = .landing
        shouldNavigateToPage = true
    }

    func navigateToToday() {
        factIdToShow = nil
        targetDate = Date()
        targetPage = .landing  // 情報デザイン: Today goes to landing
        shouldNavigateToPage = true
        shouldScrollToWeek = true
    }

    func navigateToWeek(_ weekNumber: Int) {
        factIdToShow = nil
        let year = ISOWeekCalendar.week(for: Date()).year

        // Find the date for the given week number
        if let weekDate = ISOWeekCalendar.date(week: weekNumber, year: year) {
            targetDate = weekDate
            targetPage = .landing  // 情報デザイン: Widget taps go to landing
            shouldNavigateToPage = true
            shouldScrollToWeek = true
        }
    }

    func navigateToWeek(_ weekNumber: Int, year: Int) {
        factIdToShow = nil

        // Find the date for the given week number and year
        if let weekDate = ISOWeekCalendar.date(week: weekNumber, year: year) {
            targetDate = weekDate
            targetPage = .landing  // 情報デザイン: Widget taps go to landing
            shouldNavigateToPage = true
            shouldScrollToWeek = true
        }
    }

    /// Navigate to show a specific fact from widget deep link
    func navigateToFact(_ factId: String) {
        targetPage = .landing
        shouldNavigateToPage = true
        factIdToShow = factId
    }

    /// Navigate to star page (holidays, specials, upcoming events)
    func navigateToStarPage() {
        targetPage = .specialDays
        shouldNavigateToPage = true
    }
}

// MARK: - Appearance Resolver
// Reads the system colorScheme and the user's AppearancePreference, then
// hands the resolved binary JohoColorMode to its content. Lives at the app
// root so child views see a single, settled mode via the environment.
struct AppearanceResolver<Content: View>: View {
    let preference: AppearancePreference
    let content: (JohoColorMode) -> Content

    @Environment(\.colorScheme) private var systemColorScheme

    init(preference: AppearancePreference, @ViewBuilder content: @escaping (JohoColorMode) -> Content) {
        self.preference = preference
        self.content = content
    }

    var body: some View {
        content(resolvedMode)
    }

    private var resolvedMode: JohoColorMode {
        switch preference {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return systemColorScheme == .dark ? .dark : .light
        }
    }
}

// MARK: - AppDelegate for Orientation Lock and Glass Appearance
class AppDelegate: NSObject, UIApplicationDelegate {
    /// Controls the supported interface orientations.
    /// iPad: all orientations except upside down
    /// iPhone: portrait-only
    static var orientationLock: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .allButUpsideDown
        } else {
            return .portrait
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return Self.orientationLock
    }
    
}
