# ZentraPay Frontend — Technical Documentation

Project: `zentrapay_application` (Flutter)

## 1. Technology stack

| Concern | Choice |
|---|---|
| Framework | Flutter (Dart SDK `^3.11.5`) |
| HTTP client | `dio` (^5.7.0) — **not** the `http` package (present in pubspec but unused) |
| State management | Plain `StatefulWidget` / `setState` — no provider/riverpod/bloc/get |
| Secure storage | `flutter_secure_storage` (JWT token) |
| Env config | `flutter_dotenv`, loaded from `.env` at startup |
| Auth SDK | `privy_flutter` (initialized in `main.dart`, used alongside the app's own JWT auth) |
| Toasts | `toastification`, wrapped by `ZentraNotifier` |
| External payment | `paystack_flutter_sdk` |
| Fonts | Bundled `Inter` variable font (400–900 weight range), no network font fetch |
| Charts | None — chart-like widgets are hand-drawn/static, no `fl_chart`/`syncfusion` etc. |

Target platforms: Android, iOS, Web, Windows, Linux, macOS (standard Flutter
multi-platform scaffolding is present for all of them).

## 2. HTTP layer

### 2.1 `ApiClient` (`core/utils/interceptor.dart`)

A singleton wrapping one shared `Dio` instance:

- **Base URL**: `dotenv.get('BASE_URL', fallback: "https://localhost:3000")` — set
  the real value in `.env` (not committed).
- **Timeouts**: 10s connect / 10s receive.
- **TLS**: `badCertificateCallback` unconditionally returns `true` — self-signed
  certs are accepted. This is a **dev-only setting with no environment guard**; it
  must not ship as-is to a build users install expecting certificate validation.
- **Request interceptor**: attaches `X-Client-Platform: zentrapay_application.com`
  and, if a token is cached, `Authorization: Bearer <token>` to every outgoing
  request.
- **Error interceptor**: currently a pass-through (`handler.next(e)`) — there is no
  automatic retry-on-401 or global redirect-to-login on auth failure.

Every feature's `*_service.dart` gets the shared client via `ApiClient().dio` and
should not construct its own `Dio` instance.

### 2.2 Response envelope convention

The backend wraps every response as `{success, data, message}`
(`common.ApiResponse<T>` on the Spring Boot side). **`response.data` from Dio is
this whole envelope, not the inner payload** — callers must unwrap `['data']`
themselves. This is the convention followed throughout `api_home_wallet_services.dart`
and every service written/touched in this codebase; a new service that just returns
`Map<String, dynamic>.from(response.data)` and expects it to be the raw payload will
be wrong.

### 2.3 Token storage (`core/utils/storage_service.dart`)

`SecureStorageService`:
- Persists the JWT under key `auth_token` in `flutter_secure_storage`, with an
  in-memory cache (`_memoryToken`) populated once at `init()` (called from
  `main()`) so reads elsewhere are synchronous.
- `getUserId()` decodes the JWT's `sub` claim locally (manual base64url decode) —
  no network round-trip needed to know "who am I".
- `refreshToken()` exists and correctly calls `POST /api/users/refresh`, but is
  **not wired into the Dio error interceptor** — nothing calls it automatically on
  a 401. It would need to be invoked explicitly (or wired into `ApiClient`'s
  `onError`) to actually take effect.

## 3. Theme system (`core/theme/`)

### 3.1 `app_theme.dart` — the single source of design tokens

- **Brand colors**: `primaryPink` (`0xFFF21773`), `secondaryNavy` (`0xFF210163`),
  `accentPurple`, `accentBlue`, `successGreen`, `warningOrange`, `errorRed`, a
  `gray900…gray50` neutral scale, and per-feature accent colors (`zpayColor`,
  `zbankColor`, `zremitColor`, `zvoiceColor`, `zinvestColor`, `zgrowColor`,
  `payAnywhereColor`, `secureColor`).
- **Typography**: `displayLarge/Medium/Small`, `headlineLarge/Medium/Small`,
  `titleLarge`, `bodyLarge/Medium/Small`, `labelLarge/Small`, plus `white*`
  variants for dark backgrounds. Font family `Inter`.
- **Spacing/radii/shadows**: `spacingXs…Xxl`, `radiusSm…Full`, `cardShadow`,
  `elevatedShadow`.
- **Gradients**: `primaryGradient` (pink→purple), `secondaryGradient`
  (navy→blue), `successGradient` (green), and `heroGradient` — deep electric blue
  (`electricBlue`, `0xFF1230D8`) → hot pink (`primaryPink`), left-to-right. This is
  the wireframe-spec'd full-bleed screen background; use it via
  `GradientScreenBackground` rather than duplicating the `LinearGradient` inline.
- **Glassmorphism tokens**: `glassSurface`, `glassSurfaceStrong` (semi-transparent
  white), `glassBorder` (semi-transparent white border), `glassBlurSigma`. Use via
  `GlassCard` rather than hand-rolling `Container(color: Colors.white.withAlpha(...))`.
- **Responsive helpers**: `isTablet(context)` (≥600px width), `responsivePadding`,
  `responsiveMaxWidth`, `responsiveBottomPadding`.

### 3.2 `material_theme.dart`

`buildAppTheme()` builds the Material 3 `ThemeData` consumed by `MaterialApp` in
`main.dart` — `colorScheme`, `AppBarTheme`, button themes, `InputDecorationTheme`,
`CardTheme`, all keyed off `AppTheme` tokens. No dark theme is defined.

### 3.3 `common_widgets.dart` — reusable widgets

| Widget | Purpose |
|---|---|
| `FeatureScreenHeader` | Colored header block with title/subtitle/icon/back button |
| `FeatureScreenBody` | White rounded-top container wrapping screen content |
| `ActionItemCard` | Icon-chip + title/subtitle + chevron row (feature menu items) |
| `QuickActionButton` | Circular icon + label button |
| `InfoCard` / `AIInsightCard` | Icon + text info cards |
| `SectionTitle` | Row with title + optional trailing widget |
| `SearchBarWidget` | Pill-shaped search field |
| `AppCard` | Generic opaque white elevated card |
| `PrimaryButton` / `SecondaryButton` | Full-width themed buttons with loading state |
| `AmountText` / `TransactionListItem` | Sign-colored amount text / transaction row |
| `EmptyStateWidget` | Icon + message + optional action, for empty/loading states |
| `AppTextField` / `PinDots` | Themed text field / PIN-entry progress dots |
| `showComingSoon(context, feature)` | Snackbar helper for unimplemented actions |
| `GradientScreenBackground` | Paints `AppTheme.heroGradient` (or any gradient) as a full-bleed screen background |
| `GlassCard` | Frosted-glass card: `BackdropFilter` blur + semi-transparent surface + subtle border, per the wireframe's glassmorphism spec |

### 3.4 Legacy `AppColors` / `AppStyles` (in `main.dart`)

`main.dart` defines `class AppColors` and `class AppStyles` that alias `AppTheme`
values 1:1 (e.g. `AppColors.main == AppTheme.primaryPink`). They exist purely for
backward compatibility with screens written before `AppTheme` was centralized —
**functionally identical**, no visual difference either way. New code should
reference `AppTheme.*` directly. A handful of files still import `main.dart` for
`AppColors`/`AppStyles`; most of the genuinely ad-hoc ones have been migrated to
`AppTheme` directly (see §7 "Known gaps" for the few still outstanding).

One gotcha: because `AppColors` is a *class* in `main.dart` and some screens
historically declared their own *extension* also named `AppColors` on `AppTheme`
(a local shim), importing both in the same file causes an `ambiguous_import`
compile error. If you see that error, it means a file still has a local `AppColors`
extension shim that needs removing (see `zpay_screen.dart`'s history for the fix
pattern).

## 4. Navigation & routing

- `MaterialApp.routes` in `main.dart` is the single source of named routes.
  `/home` is special-cased via `onGenerateRoute` because it must pass `userData`
  (from the login response) into `ResponsiveNavigation`.
- `ResponsiveNavigation` (`core/theme/navigation_bar/responsive_navigation.dart`)
  is the post-login shell. It owns `_pages`, a fixed 5-element list matching the
  bottom nav's index: `[HomeWalletMain, ZPayScreen, ZRemitScreen, ZGrowScreen,
  PayAnywhereScreen]` for tabs **Home / Wallet / Move / Grow / Merchant**.
- `NavigationBarMain` (`navigation_bar_main.dart`) renders the 5 tabs; each item is
  wrapped in `Expanded` (not a fixed-width `SizedBox`) so the bar doesn't overflow
  on narrow screens.
- Screens with no dedicated tab (ZBank Lite, ZInvest, ZVoice AI, Secure) are reached
  via: (a) the mobile "More" bottom sheet (`_showMoreSheet()` in
  `responsive_navigation.dart`, triggered by the app-bar `apps` icon), or (b) the
  tablet drawer, or (c) directly via their named route (`/zbanking`, `/zinvest`,
  `/zvoice`, `/secure`).
- Two screens (`ZPayScreen`, `ZInvestScreen`) had their own top-level `Scaffold`
  removed so they can be embedded directly as tab bodies without a nested/duplicate
  `AppBar` — if you add a new screen to `_pages`, make sure it returns a plain
  `Container`/`CustomScrollView` at the top level, not a `Scaffold`.

## 5. Screen ↔ service wiring status

Every screen with real backend data follows the same pattern: instantiate its
`*_service.dart` as a field, fetch in `initState`/an explicit async method, hold
results in mutable state fields, show a loading/empty state via
`EmptyStateWidget`/inline `CircularProgressIndicator` while unset.

| Area | Status |
|---|---|
| `home/` (balances, cards, transactions, transfers), `auth/` (login/register) | Real API, fully wired — the most mature part of the app |
| `converter_screen.dart`, `fraud_detection_screen.dart`, `liquidity_hub_screen.dart`, `milestones_screen.dart`, `profile_screen.dart` (partially — see below), `settings_screen.dart` | Real API, wired this pass |
| `payments/ai_assistance_screen.dart`, `payments/voice_recording_screen.dart` | Real API against `ZVoiceController` (`/api/zvoice/command`, `/history`, `/fraud-alerts`) — voice screen has no on-device speech-to-text, so a stopped recording submits a clearly-labeled placeholder transcript rather than fabricated text |
| `zbanking_screen.dart`, `zgrow_screen.dart`, `zinvest_screen.dart`, `zvoice_screen.dart`, `secure_screen.dart`, `payanywhere_screen.dart` | Static/mock UI — real backend endpoints exist for most of this data (see backend docs) but these screens haven't been wired to call them yet |
| `zpay_screen.dart`, `zremit_screen.dart` + `zremit_header.dart` | `zpay` is mock UI; `zremit_header.dart` shows a **live** example GHS→USD conversion via `ConverterService`, the rest of `zremit_screen.dart` is mock |
| `payments/instant_transfer_screen.dart`, `transfer_user_selection.dart`, `SendingForm.dart`, `RecentSends.dart`, `Op_Button.dart`, `ai_couch.dart`, `learn_and_earn.dart`, `saving_challenges.dart`, `financial_tools.dart`, `payments/widgets/*` | Static/mock UI |

`profile_service.dart` note: there is no backend concept of "linked banks" or a
server-generated settlement QR. `getLinkedBanks()`/`generateQRCode()` were
intentionally **not** carried forward into the rewritten service — `profile_screen.dart`
renders that content as static placeholder data rather than calling a nonexistent
endpoint. Generate any QR client-side from the user's own `zentag`/`userId` if that
UI is built out further, don't add a network round-trip for it.

`milestones_service.dart` note: there is no dedicated "goals" table in the backend
— a "goal" is modeled as a ZBank Lite savings account with an optional
`targetAmount`. `addToGoal()` maps to the savings deposit endpoint (there's no
generic "update goal metadata" endpoint); deleting a goal has no backend
counterpart and isn't wired.

## 6. Response-shape reference for the newer services

Quick reference for the exact backend routes each recently-wired service calls
(see the backend Technical Documentation for full request/response shapes):

| Service | Backend route(s) |
|---|---|
| `converter_service.dart` | `GET /api/converter/rates`, `POST /api/converter/convert`, `GET /api/converter/history` |
| `fraud_detection_service.dart` | `GET /api/secure/fraud-alerts` |
| `liquidity_hub_service.dart` | `GET /api/zinvest/liquidity-profile`, `/liquidity-trend`, `/risks`, `/alerts` |
| `milestones_service.dart` | `GET /api/zbanking/savings`, `POST /api/zbanking/savings/create`, `POST /api/zbanking/savings/{id}/deposit` |
| `profile_service.dart` | `GET /api/users/me`, `GET /api/currencyBalances/all` |
| `settings_service.dart` | `GET /api/secure/status`, `POST /api/secure/biometric/enable`, `POST /api/secure/fraud-protection/enable`, `GET /api/secure/login-history` |
| `ai_assistance_service.dart` / `voice_recording_service.dart` | `POST /api/zvoice/command`, `GET /api/zvoice/history`, `GET /api/zvoice/fraud-alerts` |

## 7. Known gaps / deliberately deferred work

- 3 widgets still use raw hex `Color(0x...)` literals instead of `AppTheme` tokens:
  `payments/transfer_user_selection.dart`, `payments/widgets/investment_list.dart`,
  `payments/widgets/auto_invest_card.dart`. Left alone rather than guessing color
  mappings without visual QA.
- A full `heroGradient`/`GlassCard` re-skin of the screens that already use
  `AppTheme`/`common_widgets` consistently (ZBanking, ZGrow, ZVoice, Secure,
  PayAnywhere, ZInvest) has not been done — they render correctly with their
  existing distinct per-feature accent colors, but don't yet use the new
  gradient/glass look applied to `zpay_screen.dart`. This is a visual-design pass
  best done with live device/browser feedback, not a blind mechanical edit.
- No automated widget/integration tests exercise the newly-wired screens — `flutter
  analyze` and a full `flutter build web --release` are the current verification
  signal; there's no CI-run widget test suite yet.
- `ZGrowScreen`, `ZBankingScreen`, `ZInvestScreen`, `ZVoiceScreen`, `SecureScreen`,
  `PayAnywhereScreen` are still largely `showComingSoon(...)`-driven mock UIs even
  though several have real backend endpoints available now (see backend docs §3)
  — wiring them is the natural next increment.
