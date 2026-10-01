# Native week companion

Apple is the default. Week and Widgets are the two primary destinations. Date
lookup, Settings and Add-ons use native sheets/navigation. Week numbers remain
usable without opening SwiftData, requesting permissions or verifying purchases.
No mascot, decorative outlines, ornamental panels or custom downloaded fonts.

The Week screen uses one unboxed hero, navigation directly beneath the range,
a compact day strip and a month calendar with an ISO week-number gutter. Month
rows select weeks with full-width touch targets. At accessibility sizes, controls,
days and calendar rows stack; text is not shrunk to fit a fixed screen. On iPad,
the bounded week overview can sit beside month context.

The free presentation choices are Apple, Quiet (MUJI-inspired), Clear
(note-inspired) and Neutral (KINTO-inspired). They change hierarchy, alignment,
spacing and hero weight, rather than merely tint. Preserve stored values
apple/muji/note/kinto for compatibility. References and rationale are in
[LAYOUT_AND_FREEMIUM_PLAN.md](docs/LAYOUT_AND_FREEMIUM_PLAN.md). These are
independent Onsen presentations, without third-party branding or assets.
Use semantic system colours/type, Dynamic Type, VoiceOver and platform controls.

Widgets is a gallery with free layouts and setup instructions. Preview illustrations
are not native screenshot evidence. Widget Studio adds two new small/medium
layouts with per-widget colour/date/year settings. The original VeckaWidget kind
and all its families stay free. Studio verifies local StoreKit transactions; without
verified ownership it displays a free working week layout and keeps configuration.
WidgetKit controls refresh timing, including the hourly re-verification request.

Add-ons uses separate product entitlements and native StoreKit checkout. Legacy
planner Pro remains separate with its original product IDs and restoration path.
No saved Boolean grants paid access. Prices come from StoreKit. New and legacy
sales remain disabled until release gates are complete. Core layouts and recovery
are never purchase dependencies.

The retained Saved planner has its existing schema and Joho design contract in
docs/JDS-MAN-SFW-001_joho-design-system.md. Its storage/recovery and backups must
remain intact across upgrades.

Native files exempt from Joho typography/colour/corner ratchets: Core/WeekAppearance,
Core/WeekStudioContent, Views/WeekRootView, Views/WidgetGalleryView, VeckaWidget/
VeckaWidget, WeekStudioWidget and Views/SmallWidgetView, MediumWidgetView and
LargeWidgetView (all .swift). Strict symbol, gradient and material rules still apply.
These exemptions express the separate native design contract; do not expand them
to legacy views.

Xcode compilation, unit/UI execution, real iPhone/iPad captures, actual widget
acceptance and StoreKit sandbox tests remain required. Static checks do not prove
native appearance, transaction behaviour or release readiness.
