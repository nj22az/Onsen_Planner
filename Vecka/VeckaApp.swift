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
    @AppStorage("appearancePreference") private var appearancePreferenceRaw = AppearancePreference.system.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    private var appearancePreference: AppearancePreference {
        AppearancePreference(rawValue: appearancePreferenceRaw) ?? .system
    }

    @State private var persistence = AppPersistence()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if AppEnvironment.isUITesting || AppEnvironment.isUnitTesting {
                    UITestRootView()
                        .environment(storeManager)
                } else if let sharedModelContainer = persistence.container {
                    AppearanceResolver(preference: appearancePreference) { resolvedMode in
                        ContentView()
                            .environment(navigationManager)
                            .environment(storeManager)
                            // 情報デザイン: Apply the resolved app color mode (binary).
                            .johoColorMode(resolvedMode)
                            // iOS chrome follows the user's preference. The nav-bar
                            // bg is set to `colors.surface` in JohoNavigationModifier,
                            // matching the canvas, so status-bar icons stay visible
                            // in both modes regardless of which page is on top.
                            .preferredColorScheme(appearancePreference.preferredColorScheme)
                    }
                        .onOpenURL { url in
                            handleWidgetURL(url)
                        }
                        .task {
                            // Entitlement checks must not wait for product/pricing servers.
                            // New sales remain disabled until release validation is complete.
                            await storeManager.refreshEntitlements()
                            if ReleaseFeatures.proSalesEnabled { await storeManager.loadProducts() }
                        }
                        .onChange(of: scenePhase) { _, phase in
                            if phase == .active { Task { await storeManager.refreshEntitlements() } }
                        }
                        .onAppear {
                            Log.i("App launched. System language: \(LanguageManager.shared.currentLanguageCode)")
                            // Show onboarding on first launch
                            if !hasCompletedOnboarding {
                                showOnboarding = true
                            }
                            // Seed quirky facts from JSON on first launch
                            QuirkyFactsLoader.seedIfNeeded(context: sharedModelContainer.mainContext)
                            // Seed calendar facts from JSON on first launch
                            CalendarFactsLoader.seedIfNeeded(context: sharedModelContainer.mainContext)
                        }
                        .fullScreenCover(isPresented: $showOnboarding) {
                            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        }
                        .modelContainer(sharedModelContainer)
                } else {
                    StorageRecoveryView(persistence: persistence)
                }
            }
            .task {
                if !AppEnvironment.isUITesting && !AppEnvironment.isUnitTesting {
                    persistence.open()
                }
            }
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
        targetDate = Date()
        targetPage = .landing  // 情報デザイン: Today goes to landing
        shouldNavigateToPage = true
        shouldScrollToWeek = true
    }

    func navigateToWeek(_ weekNumber: Int) {
        let calendar = Calendar.iso8601
        let year = calendar.component(.year, from: Date())

        // Find the date for the given week number
        if let weekDate = calendar.date(from: DateComponents(weekOfYear: weekNumber, yearForWeekOfYear: year)) {
            targetDate = weekDate
            targetPage = .landing  // 情報デザイン: Widget taps go to landing
            shouldNavigateToPage = true
            shouldScrollToWeek = true
        }
    }

    func navigateToWeek(_ weekNumber: Int, year: Int) {
        let calendar = Calendar.iso8601

        // Find the date for the given week number and year
        if let weekDate = calendar.date(from: DateComponents(weekOfYear: weekNumber, yearForWeekOfYear: year)) {
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
        configureGlassAppearance()
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return Self.orientationLock
    }
    
    /// Configures UIKit appearance with opaque backgrounds (情報デザイン: no glass/blur)
    ///
    /// iOS 27 note (Liquid Glass era): default system chrome is glass, but an
    /// explicitly provided appearance like this one still wins — 情報デザイン
    /// deliberately ships opaque, bordered chrome, and this proxy is how the
    /// UIKit-rendered bars (rare in this SwiftUI app) stay on-brand. The
    /// system-wide transparency slider does not override explicit
    /// appearances, so behavior is stable across iOS 26/27 settings.
    private func configureGlassAppearance() {
        // Tab Bar: Opaque background (情報デザイン forbids blur/glass)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Navigation Bar: Opaque background (情報デザイン forbids blur/glass)
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
}
