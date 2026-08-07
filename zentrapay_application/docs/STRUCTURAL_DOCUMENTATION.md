# ZentraPay Frontend — Structural Documentation

Project: `zentrapay_application` (Flutter)

## 1. Top-level layout

```
zentrapay_application/
├── lib/
│   ├── main.dart              App entry point, MaterialApp, named-route table, legacy AppColors/AppStyles shims
│   ├── core/                  Cross-cutting building blocks — theme, shared widgets, HTTP client, storage
│   └── features/              One folder per product feature (see §3)
├── android/ ios/ web/ windows/ linux/ macos/   Platform shells (standard Flutter output)
├── assets/ images/            Static assets referenced from pubspec.yaml
├── test/                      Flutter widget/unit tests
├── pubspec.yaml                Dependency manifest
├── .env                        Runtime config (BASE_URL, Privy keys) — not committed
└── docs/                       This documentation
```

There is **no backend code in this repository** — a `zentrapay-backend` folder that
used to hold a leftover Node.js layer has been removed. The app talks directly to
the Spring Boot backend (`zentrapay_spring_boot_layer`, a sibling project) over
HTTPS, with the base URL configured via `.env`.

## 2. `lib/core/` — shared infrastructure

```
core/
├── theme/
│   ├── app_theme.dart                 Single source of truth for colors, typography, spacing,
│   │                                   radii, shadows, gradients, glassmorphism tokens
│   ├── material_theme.dart            buildAppTheme() — builds the Flutter ThemeData from AppTheme
│   ├── common_widgets.dart            Reusable widgets every feature screen should use
│   └── navigation_bar/
│       ├── navigation_bar_main.dart       Bottom nav bar widget (5 tabs)
│       └── responsive_navigation.dart     Shell: bottom nav (mobile) / drawer (tablet), owns the 5 tab pages
├── utils/
│   ├── interceptor.dart               ApiClient — configures the shared Dio instance (base URL, auth header, timeouts)
│   ├── storage_service.dart           SecureStorageService — JWT storage/retrieval/refresh, decodes userId from the token
│   ├── Notifier.dart                  ZentraNotifier — toast notification wrapper
│   └── Common/
│       ├── AppPinSheet.dart            Shared bottom-sheet for PIN set/verify/confirm
│       ├── EnterAmount.dart            Shared "enter amount" input widget/sheet
│       └── api_authentication.dart     PIN-verification API call
```

Any new screen should build on `AppTheme` (colors/typography/spacing) and
`common_widgets.dart` (headers, cards, buttons) rather than defining its own
colors or hand-rolled containers — see the Technical Documentation §3 for the
specific tokens/widgets available.

## 3. `lib/features/` — one folder per feature

```
features/
├── auth/          Onboarding, login, register, OTP verification
├── home/           Home tab: wallet balances, cards carousel, quick actions, services grid,
│                    recent transactions, "create wallet" flow, Paystack external-payment flow
├── zpay/            ZPay Wallet screen (maps to the "Wallet" bottom-nav tab)
├── zremit/           ZRemit screen + header (maps to the "Move" bottom-nav tab)
├── zvoice/           ZVoice AI screen (reachable via the "Move" tab's paired "More" sheet, or /zvoice)
├── zgrow/            ZGrow gamified-savings screen (maps to the "Grow" bottom-nav tab)
├── zinvest/          ZInvest micro-investments screen (paired with Grow via the "More" sheet, or /zinvest)
├── zbanking/         ZBank Lite screen (paired with Home via the "More" sheet, or /zbanking)
├── payanywhere/      Pay Anywhere / merchant screen (maps to the "Merchant" bottom-nav tab)
├── secure/           Security Hub screen (paired with Home via the "More" sheet, or /secure)
├── profile/          Profile screen + Settings screen (+ their *_service.dart API clients)
└── payments/         Everything that doesn't have its own top-level feature folder yet:
                        money-movement flows (instant transfer, recipient selection, sending
                        forms), ZInvest's Liquidity Hub, savings Milestones, currency Converter,
                        Fraud Detection, ZVoice's AI-chat and voice-recording screens, and
                        small gamification/education widgets (ai_couch, learn_and_earn,
                        saving_challenges, financial_tools), plus payments/widgets/ (ZInvest
                        chart/list/header widgets used elsewhere)
```

Each screen file (`*_screen.dart`) generally has a matching `*_service.dart` in the
same folder holding its Dio API calls (e.g. `converter_screen.dart` /
`converter_service.dart`). Not every screen has real backend wiring yet — see the
Technical Documentation §5 for which ones do.

## 4. Navigation structure

`ResponsiveNavigation` (in `core/theme/navigation_bar/responsive_navigation.dart`)
is the app's shell once a user is logged in — pushed at route `/home`. It renders:

- **Mobile** (`width < 600`): an `AppBar` + `NavigationBarMain` bottom nav with 5
  tabs — **Home / Wallet / Move / Grow / Merchant** — plus a "More" (`apps` icon)
  button in the app bar that opens a bottom sheet linking to the 4 feature screens
  that don't have a dedicated tab (ZBank Lite, ZInvest, ZVoice AI, Secure).
- **Tablet** (`width >= 600`): a `Drawer` listing the same 5 tabs plus all
  supplementary screens (the 4 "More" screens, Profile, Settings, Converter,
  Milestones, AI Assistant, Liquidity Hub, Voice Recording, Fraud Detection).

Named routes are declared once, centrally, in `lib/main.dart`'s `MaterialApp.routes`
map — every screen that can be reached via `Navigator.pushNamed` has an entry
there. `/home` is handled specially via `onGenerateRoute` because it needs to pass
`userData` (from login) into `ResponsiveNavigation`.

## 5. Where to add new code

- New screen for an existing feature → add to that feature's folder.
- New standalone feature screen with no natural home yet → new folder under
  `lib/features/<feature_name>/`, following the `*_screen.dart` + `*_service.dart`
  pairing.
- New shared widget used by 2+ screens → `core/theme/common_widgets.dart`.
- New design token (color, spacing, gradient) → `core/theme/app_theme.dart`, never
  hardcode a new raw `Color(0x...)` in a screen.
- New named route → add to `lib/main.dart`'s `routes` map, and to the "More" sheet
  or drawer in `responsive_navigation.dart` if it should be reachable from the main
  nav shell.
