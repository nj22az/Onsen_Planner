# Native week utility

Apple's native iOS design is the default. Use NavigationStack, TabView, List,
Form, DatePicker, semantic text styles, system backgrounds and platform controls.
Respect system appearance, accessibility text, VoiceOver, Reduce Motion and
widget rendering modes. Week numbers are the primary content; label the ISO
week-year explicitly. Dates and weekday names use the user's locale.

No mascot, thick outlined cards, ornamental packaging panels or custom fonts.
No account/onboarding/permission barrier before displaying the week. Week data
comes from the shared ISOWeekCalendar, never from SwiftData or a network API.

Apple plus three optional palette adaptations: MUJI (quiet burgundy), note
(readable teal), KINTO (charcoal/warm grey). Native layout is identical in every
palette. Colour is supplementary; selection and today also have labels or weight.
Palette values are centralised in Core/WeekAppearance.swift, with a safe Apple
fallback and system-compatible dark colours. Reference links and scope are in
docs/WIDGET_FIRST_V1.md. No third-party assets or logos are used.

The older saved planner remains reachable and retains its Joho component system;
docs/JDS-MAN-SFW-001_joho-design-system.md governs that surface. Its mascot has
been removed too. Existing user data and theme settings must be preserved.

Native week surfaces explicitly exempted from the Joho style ratchets:
Core/WeekAppearance.swift, Views/WeekRootView.swift, and the widget entry and
Small/Medium/Large widget views. The rest of the code stays under the existing
lint rules. Adding an exemption requires updating this contract and review.

Xcode compilation and real device layout/widget checks are required before
publication. Static source checks and design documentation are not screenshots
or native acceptance evidence.
