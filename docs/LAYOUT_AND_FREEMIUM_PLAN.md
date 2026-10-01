# Onsen Planner: layout and freemium release plan

Decision proposal, 1 October 2026. This is the revised specification. The draft now implements the compact layout and Widget Studio source; native acceptance and release approval remain pending. It supersedes the palette-only direction and the recommendation to postpone all monetisation in WIDGET_FIRST_V1.md. The implementation status below distinguishes source work from native evidence.

## Product decision

A reliable ISO week companion for people who organise work, study and travel by week. The free app must solve that task completely. Sell optional presentation and specialised planning tools as one-time non-consumable purchases. Start with one paid pack; expand only after actual use supports it. Do not start with monthly/yearly subscriptions, advertising, accounts or a server dependency.

Installed name and bundle identity stay unchanged during development. App Store positioning should clearly say “week numbers and widgets”; verify naming availability before changing listing or installed name. Do not promise to replace Apple Calendar.

## What was wrong with the previous layout

The seven full-height weekday rows dominate the main view; the week number and date range already supply most of that information. Navigation comes after the list, and date lookup gets a permanent tab despite being an occasional task. The rounded list containers repeat the same visual weight. Theme options change only tint, so they fail to express the references' spatial and typographic decisions. The previews are browser interpretations rather than native screenshots and must not be release evidence.

## Reference selection and adaptation

Read the actual DESIGN.md files, not just a gallery or colour swatch. These describe websites; translate their hierarchy and spacing into an iOS utility instead of importing desktop widths, marketing photography or web font stacks.

| Reference | Principle to use | Concrete layout rule |
| --- | --- | --- |
| Apple Japan, default | Dominant content, strong typographic hierarchy, generous space | Week number is the only hero; dates sit immediately beneath it; platform toolbar, sheets, selection and accessibility remain native. |
| MUJI, optional Quiet presentation | Consistent spacing scale, flat surfaces, restrained decoration | Left-aligned number, compact metadata, fine rules and a functional calendar grid; no enclosing hero card or ornamental shadow. |
| note, optional Clear presentation | Readability, bounded reading width, content first | Date/context lead the reading order; optional notes use a comfortable column with clear headings and full text; iPad notes do not stretch across the screen. |
| KINTO, optional Neutral presentation | Hierarchy through position/size, lightweight typography and open space | Centred number, separated date caption, open day strip and minimal labels; native controls remain recognisable. No stock lifestyle imagery. |

Apple remains the default presentation. Optional references change alignment, density, hierarchy and secondary-content placement, with colours as a secondary property. All presentations share the same navigation, ISO engine and feature meanings. They are independent Onsen adaptations; use original public names such as Quiet, Clear and Neutral in the product, rather than selling MUJI/note/KINTO branded packs. Do not copy logos or unlicensed fonts/assets. Preserve source/licence attribution if redistributing source material.

Source files inspected on 1 October 2026:
- https://github.com/kzhrknt/awesome-design-md-jp/blob/main/design-md/apple/DESIGN.md
- https://github.com/kzhrknt/awesome-design-md-jp/blob/main/design-md/muji/DESIGN.md
- https://github.com/kzhrknt/awesome-design-md-jp/blob/main/design-md/note/DESIGN.md
- https://github.com/kzhrknt/awesome-design-md-jp/blob/main/design-md/kinto/DESIGN.md

## Screen architecture

Use two primary destinations: **Week** and **Widgets**. The latter contains a useful free gallery and setup help, rather than being a shop-only tab. Date lookup opens from the Week toolbar. Settings and Add-ons open from the toolbar/menu; no purchase prompt on launch. Preserve Saved planner in Settings, including recovery. Do not add a third destination until a genuinely used planner workflow warrants it.

| Screen | Top-to-bottom content | Interaction |
| --- | --- | --- |
| Week | Small current-date heading; week number; date range; secondary ISO year; seven-day strip; compact month grid with week-number gutter | Previous/Today/Next immediately beneath the range; tap a calendar date to choose its week; Find date opens a native date sheet. |
| Date lookup sheet | DatePicker, selected date's week number and range | Done returns to the chosen week; cancellation leaves the current selection intact. No repeated seven-row list. |
| Widgets | Real previews grouped by Home Screen / Lock Screen; free templates first; setup help | Select a template for details and installation instructions. Paid variants carry a clear label and preview before the store sheet. |
| Add-ons | One launch pack with representative preview, exact included features and one-time price | Native StoreKit confirmation; Restore purchases; owned/pending/unavailable states. Never an initial launch barrier. |
| Settings | Presentation and appearance; purchase restore/help; Saved planner and recovery; privacy/about | Native Form; no custom settings chrome. |

At default text on a small iPhone, the number, range and week navigation must be visible without scrolling. The day strip replaces seven repeated weekday rows. At accessibility sizes, reflow into stacked labelled days or a concise selected-date summary; allow page scrolling rather than shrinking text or touch targets. Month context may move below the fold. On iPad, use a bounded summary column beside the month grid when space permits; stack in narrow split view.

Initial layout tokens for native review: 20-point phone content inset; 8/12/16/24/32-point spacing scale; 16 points within related groups, 24–32 between sections. Hero initially 72 points relative to largeTitle and dynamically scaled. Standard semantic body/caption styles; minimum 44-point action targets. These are Onsen proposal values, not claims of Apple requirements or direct copies of website CSS. No fixed screen heights, enclosing boxes around every section, unnecessary gradients or content glass. Use system bars/materials where appropriate to the supported OS.

## Free / paid boundary

| Offering | Included features | Release |
| --- | --- | --- |
| Free core | ISO weeks/ranges/year, previous/next/today, date lookup, month with week numbers, basic small/medium/large and Lock Screen widgets, Apple + Quiet/Clear/Neutral presentations, accessibility, offline use, help | Freemium v1 |
| Widget Studio, non-consumable | New typographic templates, independently configured presentation per widget, custom accessible colour choices, optional metadata controls | Only paid pack at v1, once fully implemented and device-tested |
| Work & Study, non-consumable | Year overview, reusable week-based term/project markers, print/PDF planning exports | Later, after demand validation |
| Travel & Holidays, non-consumable | Selected-region holiday overlays/comparison and offline reference data with source/version information | Later, after coverage and update responsibility are proven |

Do not place existing bundled widget families/presentations behind a new paywall. Basic data export, backup/recovery and reading existing user records remain available; premium planning PDF output is a separate new capability. No arbitrary event/trip caps in the new core. Existing legacy planner behaviour stays unchanged until upgrade compatibility is independently tested. Any verified historic Pro purchase needs an explicit mapping to the capabilities originally promised; never infer purchase from a saved Boolean or require re-purchase.

Pricing hypothesis, not configured/live prices: test Widget Studio around SEK 39–59 as a single payment; test later functional packs around SEK 59–99. Use Product.displayPrice at runtime for each storefront. Do not advertise an unconfigured SEK price or hardcode currency conversion. Validate willingness to pay with a small cohort before choosing App Store price points. No “all future add-ons forever” promise or bundle at launch; it creates unclear future obligations and duplicate-payment questions.

## Purchase implementation gap

Current source: StoreManager.swift, ProStoreClient.swift and PaywallView.swift. Products are yearly/monthly/lifetime Pro; access is collapsed into isPro. ReleaseFeatures.proSalesEnabled is false. This is useful infrastructure, but is not a modular add-on store. App Store Connect product/contract status has not been inspected.

1. Introduce an add-on catalogue with stable identifiers and explicit capability mapping; keep legacy Pro identifiers for compatible restoration. Finalise IDs before creating App Store products because identifiers become part of the compatibility contract.
2. Replace the global Pro Boolean for new features with a set of verified product entitlements. Iterate all relevant currentEntitlements instead of returning at the first recognised purchase. Handle revocation per product and map historical Pro explicitly.
3. Observe Transaction.updates from app startup; serialise entitlement refreshes; deliver the particular product's capability before finishing its verified transaction. One owned pack must not permit finishing or granting another pack indiscriminately.
4. Handle cancel, pending approval, interrupted purchases, missing products and verification failures separately. No second charge prompt while a purchase is pending. Restore uses user-initiated AppStore.sync; normal launch refresh uses local StoreKit entitlement verification.
5. Verify available local StoreKit transactions when offline. An unavailable product/price service must not revoke already verified ownership. A presentation-only preferences Boolean must never grant paid access; do not promise cross-device restoration without connectivity.
6. Share only the minimum derived widget configuration/access snapshot through the App Group. The extension does not fetch prices or run checkout. Refresh after purchase/restore/revocation. The app is the entitlement authority; an extension preferences flag is not independent proof of purchase. Verify stale/revoked access behaviour on device.
7. When a paid template becomes unavailable, retain its configuration for possible restoration and render a free, working week template. Never delete saved records or obstruct the free number. Keep checkout out of the actual widget.
8. Localise store copy and support status messages in release languages. Render real product prices and an explicit “one-time purchase” description. Do not promise refunds or include untested Family Sharing claims.

## Requirements to ship

| Gate | Required evidence |
| --- | --- |
| Native build | Debug/Release app + embedded widget build on Mac; correct source membership, deployment target, App Group, signing and archive validation. Current Linux checks do not fulfil this. |
| Layout | Simulator and real device captures of Week, lookup, gallery, owned/unowned store and Settings; small phone/iPad, light/dark, largest text, VoiceOver, Reduce Motion; no clipping or hidden primary actions. |
| Date/widget reliability | ISO year/week 53, DST, midnight/Monday/New Year, restart, delayed timelines and Stockholm–Vietnam travel. Free and paid templates must calculate the same week. WidgetKit controls refresh timing. |
| Purchase correctness | StoreKit local tests plus App Store sandbox/TestFlight: buy A does not unlock B; cancellation/pending; interrupted/repeated updates; offline launch; product outage; restore/reinstall/new device; refund/revocation; historical Pro mapping; widget fallback. |
| Data safety | Upgrade an old database copy, recover failed storage, export/restore, and prove purchase state changes cannot remove records or block recovery. |
| Apple business setup | Developer membership/distribution access, accepted Paid Apps Agreement, bank/tax details, appropriate availability and seller/trader information. Check EU requirements in App Store Connect for chosen storefronts. |
| Product submission | Create non-consumable(s), localised name/description, price/availability, review screenshot and reviewer steps. Submit the first IAP with a new app version as Apple requires. |
| Store listing | Actual native screenshots, icon, clear week utility description, support contact/URL, accessible published privacy policy and matching privacy labels; required privacy manifest/API reasons; age rating and export compliance answers. Reconcile policy with the submitted version. |

No server is proposed for the first local-only non-consumable release. Reconsider a backend only if paid server features, cross-platform accounts or additional fraud/support requirements justify it. Standard StoreKit IAP is the proposed checkout across launch storefronts; external-payment alternatives are outside this release.

## Delivery order and stop conditions

1. Review revised native Week + Widgets layouts in Apple default, then validate optional presentations. No further palette-only screenshots.
2. Implement the layout without modifying saved planner schemas. Obtain actual native evidence before calling the design accepted.
3. Implement and test Widget Studio; do not create a purchasable placeholder. If the pack is not compelling or complete, keep sales disabled and release the free utility first.
4. Refactor purchase capabilities, add real StoreKit regression scenarios, configure one product, test sandbox/TestFlight and historical ownership.
5. Submit free utility + tested pack. Defer subscription, cloud, region feeds and planner expansion.

Cohort tasks: identify the current week within a few seconds; find the week of a specified date; install a free widget; explain precisely what Widget Studio adds; restore on another installation. This is a usability target, not an analytics result. Test with people who already use week numbers for engineering/service rotas, teaching or travel; collect direct feedback without adding a tracking SDK.

## Primary platform references

Checked 1 October 2026:
- https://developer.apple.com/design/human-interface-guidelines/widgets
- https://developer.apple.com/app-store/review/guidelines/ (3.1.1, 3.1.2, 4.2)
- https://developer.apple.com/in-app-purchase/
- https://developer.apple.com/documentation/storekit/transaction/currententitlements
- https://developer.apple.com/documentation/storekit/transaction/updates
- https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-types/
- https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/
- https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase
- https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox

## Implementation status — revised draft

Implemented in source: two destinations; compact unboxed Week overview; four presentation hierarchies; month-week selection and accessibility reflow; lookup/settings sheets; free widget gallery; previewable Widget Studio; independent non-consumable catalogue/verified entitlements; a second AppIntent-configurable widget with editorial/minimal layouts, four accessible palette choices and per-widget date/year controls. Missing/unverified ownership renders the standard free widget. Existing widget kind/families and legacy planner Pro remain intact.

Widget Studio offers selectable palettes, not an arbitrary custom-colour editor. Work & Study and Travel & Holidays remain future proposals. Both purchase sales flags are disabled. No App Store Connect contracts/products have been configured or inspected.

Added nine add-on regression methods and updated real UI navigation/capture tests. Native tests, screenshots and actual StoreKit/WidgetKit behaviour are pending a Mac/device run. English/Swedish new store copy is supplied; the other seven app locales use English fallback for these new strings (older Vietnamese utility copy remains).
