# ZentraPay Backend — Structural Documentation

Project: `zentrapay_spring_boot_layer`
Base package: `com.zentrapay_application.zentrapay_spring_boot_layer`

## 1. Top-level layout

```
zentrapay_spring_boot_layer/
├── build.gradle.kts            Gradle build script (dependencies, plugins, Java toolchain)
├── settings.gradle.kts         Gradle project settings
├── gradlew / gradlew.bat       Gradle wrapper scripts
├── src/
│   ├── main/
│   │   ├── java/com/zentrapay_application/zentrapay_spring_boot_layer/
│   │   │   ├── ZentrapaySpringBootLayerApplication.java   Spring Boot entry point + shared beans
│   │   │   ├── common/         Cross-cutting types shared by every module
│   │   │   ├── config/         App-wide @Configuration classes (CORS, MVC)
│   │   │   ├── security/       JWT auth filter, principal type, @CurrentUser mechanism
│   │   │   └── modules/        One package per business feature (see §2)
│   │   └── resources/
│   │       ├── application.properties   All runtime configuration
│   │       └── keystore.p12             TLS keystore (server runs HTTPS)
│   └── test/
│       ├── java/…ZentrapaySpringBootLayerApplicationTests.java   Context-load smoke test
│       └── resources/application.properties   Test-only config overrides
└── docs/                        This documentation
```

The project is a **single Spring Boot application** — there is no separate Node.js
gateway layer. An earlier architecture document described a 2-layer system (Node.js
Gateway + Spring Boot Core); that layer was deliberately removed and the Flutter
client now calls this service directly. Do not resurrect a gateway layer based on
older documentation without confirming with the team first.

## 2. Module structure

Every feature lives under `modules/<featureName>/` and follows the same internal
layout (not every module has every layer — see the table below):

```
modules/<featureName>/
├── controller/    @RestController classes — HTTP endpoints, thin, no business logic
├── service/       @Service classes — business logic, transaction boundaries
├── repository/    Spring Data JPA repository interfaces
├── model/         @Entity JPA-mapped classes (the persistence layer)
└── dto/           Request/response records used at the HTTP boundary
```

A few older modules deviate from this exact naming (`dtos` instead of `dto`,
`Controller`/`services` capitalization, `cardsController`/`CardsRepository` casing in
the `cards` module) — these are historical inconsistencies, not a different pattern.
New modules should use the lower-case singular convention (`controller`, `service`,
`repository`, `model`, `dto`).

### Module inventory

| Module | Layers present | Purpose |
|---|---|---|
| `users` | controller, service, repository, model, dto, exception | Registration, login, JWT issuance, profile, PIN verification. The reference module — every other module's auth pattern should match this one. |
| `payments` | controller, services, repository, model, dto(s), **gateway**, **paystack** | Internal wallet-to-wallet transfers and external disbursements. Contains the payment gateway abstraction (see §3). |
| `remittance` | controller, service, repository, model, dtos | Cross-border transfer feature — this is the actual "ZRemit" implementation (the `zremit` name is not used as a package; see note below). |
| `zpay` | controller, service, repository, model | Card management (virtual/physical), NFC/QR toggle. |
| `zbanking` | controller, service, repository, model, dto | Savings accounts (create/deposit/withdraw). Loans/budget/insights endpoints exist but are stubs. |
| `zgrow` | controller, service, repository, model | Gamified savings challenges. Rewards/literacy endpoints are stubs. |
| `zinvest` | controller, service, repository, model | Micro-investment portfolio (stocks/crypto/commodities) plus a "Liquidity Hub" (profile/trend/risks/alerts) computed from portfolio data. |
| `zvoice` | controller, service, repository, model | Voice command logging, history, fraud-alert flagging, per-language filtering. |
| `secure` | controller, service, repository, model | Per-user security settings (biometric/2FA/fraud-protection flags), fraud alerts, login history, static security tips. |
| `converter` | controller, service | Currency conversion (static/placeholder rate table — no live forex integration yet). |
| `transactions` | controller, service, repository, model | Generic, paginated transaction feed. Model/repository are also used internally by `payments`. |
| `walletBalances` | controller, service, repository, model, dto | Aggregated fiat/crypto balance queries. Routes live under `/api/currencyBalances`. |
| `currencyAccounts` | controller, service, repository, model, dto | Creates new fiat/crypto currency accounts for a wallet. |
| `cards` | controller, service, repository, model, dto | Simple "list all cards" read endpoint (separate from `zpay`'s card management). |
| `history` | controller, service, dto | Payments/bills history read endpoint. No dedicated repository/model — delegates to other modules' repositories. |
| `billProviders` | controller, service, repository, model, dto | Bill provider catalog. Pay/validate/history endpoints are stubs. |
| `searchContacts` | controller, service, repository, model, dto | Global search across app users, bill providers, and funding sources. |
| `supportedCurrencyAccounts` | controller, service, repository, model, dto | Read-only lookup of currencies the platform supports. |
| `serviceProviders` | model only | Stub — no controller/service/repository yet. |

Note on naming: the wireframe/marketing feature is called "ZRemit", but the backend
package implementing it is `remittance`, not `zremit`. There is no `zremit` package —
do not create one; extend `remittance` instead.

## 3. Payment gateway sub-structure

`modules/payments/` has two extra subpackages beyond the standard layout:

```
modules/payments/
├── gateway/
│   ├── PaymentGatewayService.java        Interface every gateway implementation follows
│   ├── PaymentGatewayFactory.java        Routes a disbursement to the right gateway + failover
│   ├── PaystackGatewayService.java       Wraps paystack/PaystackService for the gateway interface
│   ├── OnafriqGatewayService.java        Real RestTemplate client for Onafriq
│   └── FlutterwaveGatewayService.java    Real RestTemplate client for Flutterwave
└── paystack/
    ├── PaystackConfig.java               @ConfigurationProperties(prefix = "paystack")
    └── PaystackService.java              Real RestTemplate client for Paystack, implements PaymentGatewayService directly
```

See the Technical Documentation for the routing rules (which gateway handles which
transaction type).

## 4. `security/` package

```
security/
├── JwtService.java                  Issues and validates JWTs (HS256)
├── JwtAuthenticationFilter.java      OncePerRequestFilter — runs before every request
├── AuthenticatedUser.java            Principal record (userId, email, fullName, zentag)
├── CurrentUser.java                  Parameter annotation
├── CurrentUserArgumentResolver.java  Resolves @CurrentUser AuthenticatedUser params
└── SecurityConfig.java               Spring Security filter chain + permitAll rules
```

## 5. `config/` package

```
config/
├── CorsConfig.java     CorsConfigurationSource bean, origins from app.cors.allowed-origins
└── WebConfig.java      Registers CurrentUserArgumentResolver with Spring MVC
```

## 6. `common/` package

Shared, cross-module types with no business logic of their own:

```
common/
├── ApiResponse.java              Generic {success, data, message} envelope every controller returns
├── GlobalExceptionHandler.java   @RestControllerAdvice — maps exceptions to ApiResponse + HTTP status
├── ResourceNotFoundException.java  404 exception (also used for ownership-check failures, to avoid leaking existence)
└── AppUsersModelCommon.java      Shared base fields for app-user-related models
```

## 7. Where to add new code

- New feature → new package under `modules/`, following the `controller/service/
  repository/model/dto` layout.
- New cross-cutting concern (another `@RestControllerAdvice`, another filter) →
  `common/` or `security/` depending on whether it's auth-related.
- New Spring `@Configuration` (a new external API client, a new bean) → `config/`.
- New payment gateway → add an implementation of `PaymentGatewayService` next to
  `PaystackGatewayService`/`OnafriqGatewayService`/`FlutterwaveGatewayService` in
  `modules/payments/gateway/`, then add it to `PaymentGatewayFactory`'s routing logic.
