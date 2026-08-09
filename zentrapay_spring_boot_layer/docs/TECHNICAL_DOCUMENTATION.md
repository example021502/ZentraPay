# ZentraPay Backend — Technical Documentation

Project: `zentrapay_spring_boot_layer`

## 1. Technology stack

| Concern | Choice |
|---|---|
| Language / runtime | Java 21 |
| Framework | Spring Boot 4.1.0 |
| Web layer | Spring MVC (`spring-boot-starter-web`), servlet-based, **not** WebFlux |
| Persistence | Spring Data JPA + Hibernate, PostgreSQL |
| Security | Spring Security (stateless, JWT-based) |
| JWT | `io.jsonwebtoken` (jjwt) 0.12.6, HMAC-SHA256 |
| Validation | `spring-boot-starter-validation` (Jakarta Bean Validation, `@Valid`) |
| Outbound HTTP (payment gateways) | `RestTemplate` (one shared bean; no WebClient anywhere) |
| Boilerplate reduction | Lombok |
| Build | Gradle (Kotlin DSL), Gradle wrapper |
| Transport | HTTPS only — `server.ssl.enabled=true`, bundled `keystore.p12` |

The app runs as a single process on port `2000` (see `application.properties`).

## 2. Authentication & identity propagation

### 2.1 Token lifecycle

- `POST /api/users/register` and `POST /api/users/login` are the only public
  endpoints (plus `/actuator/**` and `/error`). Both return a JWT via
  `JwtService.generateToken(userId, email, fullName, zentag)`.
- The JWT's `sub` claim is the user's UUID; `email`, `full_name`, and `zentag` are
  additional claims. Default expiry is 24h (`app.jwt.expiration-ms`).
- `POST /api/users/refresh` accepts the current (possibly near-expiry) token via the
  `Authorization` header and returns a new one.

### 2.2 Request-time identity resolution

This is the mechanism that makes a request's identity trustworthy, and it is the
answer to "how does a controller know who's calling, and how do I add a new endpoint
that needs it":

1. `JwtAuthenticationFilter` (a `OncePerRequestFilter`, registered before
   `UsernamePasswordAuthenticationFilter`) runs on every request except the
   `shouldNotFilter` exemptions (`/api/users/register`, `/api/users/login`,
   `/actuator/**`, `/error`).
2. It validates the JWT via `JwtService.parseAndValidate`, then builds an
   `AuthenticatedUser` record from the claims: `AuthenticatedUser(userId, email,
   fullName, zentag)`. `AuthenticatedUser implements java.security.Principal` and its
   `getName()` returns `userId.toString()`.
3. That `AuthenticatedUser` is set as the **principal** of the
   `UsernamePasswordAuthenticationToken` placed on `SecurityContextHolder`. It is
   also stashed as a request attribute (`authenticatedUser`) for any non-Security
   code path that might need it.
4. **Two ways to consume this in a controller**, both reading the same principal:
   - `Authentication authentication` parameter → `UUID.fromString(authentication.getName())`.
     Use this when you only need the caller's `userId`. This is what the majority of
     controllers use.
   - `@CurrentUser AuthenticatedUser user` parameter → `user.userId()`, `user.email()`,
     `user.fullName()`, `user.zentag()`. Use this when you need more than just the
     ID (email in particular). Resolved by `CurrentUserArgumentResolver`, registered
     in `WebConfig`.
5. **Never trust a client-supplied `userId`/`email` in a request body or path for
   determining whose data to act on.** If a DTO happens to carry a `userId`/`email`
   field for backward-compatible deserialization, the controller must overwrite it
   with the value from `Authentication`/`@CurrentUser` before it reaches the service
   layer. `PaymentsController` and `CurrencyAccountsController` do this by
   reconstructing a "trusted" copy of the incoming DTO — follow that pattern for any
   new endpoint that accepts an optional/legacy `userId` field.
6. **Ownership checks on path-variable resource IDs.** Endpoints that mutate a
   specific resource by ID (`/savings/{savingsId}/deposit`, `/cards/{cardId}/nfc`,
   `/{investmentId}/sell`, etc.) must verify that resource belongs to the caller
   before mutating it. The established pattern (see `ZBankingService`,
   `ZPayService`, `ZInvestService`) is a private `getOwned<Resource>OrThrow(userId,
   resourceId)` helper that throws `ResourceNotFoundException` — not a 403 — on a
   mismatch, so an ownership failure looks identical to "doesn't exist" and doesn't
   leak whether the resource exists at all.

### 2.3 Password/PIN hashing

`UsersService` hashes passwords and transaction PINs with BCrypt plus an
application-level "pepper" (`app.password.pepper`, `app.pin.pepper` — static secrets
appended before hashing, distinct from the per-hash salt BCrypt already applies).

## 3. API reference

All responses are wrapped in `ApiResponse<T>`: `{ "success": bool, "data": T | null,
"message": string }`. All routes below require a valid `Authorization: Bearer
<token>` header unless marked **public**.

### `/api/users` — `UserController`
| Method | Path | Auth param | Notes |
|---|---|---|---|
| POST | `/register` | — | **public** |
| POST | `/login` | — | **public** |
| POST | `/refresh` | reads `Authorization` header directly | |
| GET | `/me` | `Authentication` | returns `UserProfileDTO` |
| POST | `/pin/verify` | `Authentication` | |

### `/api/payments` — `PaymentsController`
| Method | Path | Auth param | Notes |
|---|---|---|---|
| POST | `/internal` | `@CurrentUser` | wallet-to-wallet transfer between app users |
| POST | `/disbursement` | `@CurrentUser` | external payout — routed via the gateway factory (§4) |

### `/api/remittance` — `RemittanceController` (the "ZRemit" feature)
| Method | Path | Auth param | Notes |
|---|---|---|---|
| POST | `/transfer` | `Authentication` | `@RequestParam`, not JSON body |
| GET | `/history` | `Authentication` | |
| GET | `/rates` | — | stub — exchange rate hardcoded to `1` |
| GET | `/supported` | — | stub |

### `/api/zpay` — `ZPayController`
| Method | Path | Auth param | Notes |
|---|---|---|---|
| GET | `/balance` | `Authentication` | stub |
| GET | `/cards` | `Authentication` | |
| POST | `/cards/virtual` | `Authentication` | |
| POST | `/payment/nfc-qr` | `Authentication` | stub |
| GET | `/transactions` | `Authentication` | stub |
| PATCH | `/cards/{cardId}/nfc` | `Authentication` | ownership-checked |
| PATCH | `/cards/{cardId}/qr` | `Authentication` | ownership-checked |

### `/api/zbanking` — `ZBankingController`
| Method | Path | Auth param | Notes |
|---|---|---|---|
| GET | `/savings` | `Authentication` | |
| POST | `/savings/create` | `Authentication` | |
| POST | `/savings/{savingsId}/deposit` | `Authentication` | ownership-checked |
| POST | `/savings/{savingsId}/withdraw` | `Authentication` | ownership-checked |
| GET | `/loans`, POST `/loans/apply`, GET `/budget`, GET `/insights` | `Authentication` | stubs |

### `/api/zgrow` — `ZGrowController`
| Method | Path | Auth param | Notes |
|---|---|---|---|
| GET | `/challenges` | — | |
| GET | `/challenges/category/{category}` | — | |
| POST | `/challenges/{challengeId}/join` | `Authentication` | increments an aggregate counter — no per-user participant table yet |
| GET | `/rewards` | `Authentication` | stub |
| GET | `/literacy` | — | stub |

### `/api/zinvest` — `ZInvestController`
| Method | Path | Auth param | Notes |
|---|---|---|---|
| GET | `/portfolio` | `Authentication` | |
| POST | `/create` | `Authentication` | |
| GET | `/type/{type}` | `Authentication` | |
| GET | `/performance` | `Authentication` | stub |
| POST | `/{investmentId}/sell` | `Authentication` | ownership-checked |
| GET | `/liquidity-profile` | `Authentication` | aggregated from portfolio: totalInvested/totalValue/gainLoss/riskProfile/allocationByType |
| GET | `/liquidity-trend` | `Authentication` | single current-value point — no historical price snapshots stored |
| GET | `/risks` | `Authentication` | concentration-risk warnings (>50% in one holding) |
| GET | `/alerts` | `Authentication` | price-drop alerts (≥10% down vs. buy price) |

### `/api/zvoice` — `ZVoiceController`
| Method | Path | Auth param | Notes |
|---|---|---|---|
| POST | `/command` | `Authentication` | `@RequestParam`: commandType, language, transcript, fraudAlert, fraudReason |
| GET | `/history` | `Authentication` | |
| GET | `/fraud-alerts` | `Authentication` | |
| GET | `/language/{language}` | `Authentication` | |

### `/api/secure` — `SecureController`
| Method | Path | Auth param | Notes |
|---|---|---|---|
| GET | `/status` | `Authentication` | real per-user `SecuritySettingsModel` |
| POST | `/biometric/enable` | `Authentication` | |
| GET | `/fraud-alerts` | `Authentication` | real query, currently always empty (no fraud-detection source wired up) |
| GET | `/login-history` | `Authentication` | real query, currently always empty (no login-capture source wired up) |
| POST | `/2fa/enable` | `Authentication` | |
| POST | `/fraud-protection/enable` | `Authentication` | |
| GET | `/tips` | — | static content |
| POST | `/report` | `Authentication` | |

### `/api/converter` — `ConverterController`
| Method | Path | Auth param | Notes |
|---|---|---|---|
| GET | `/rates?base=GHS` | — | static placeholder rate table, USD-pivoted |
| POST | `/convert` | — | body: `{from, to, amount}` |
| GET | `/history` | — | always empty — no conversion history persisted |

### `/api/transactions` — `TransactionsController`
| Method | Path | Auth param | Notes |
|---|---|---|---|
| GET | `/?page=0&size=20` | `Authentication` | paginated, backed by `TransactionModel` (also written by `PaymentsServices`) |
| GET | `/{transactionId}` | `Authentication` | ownership-checked |

### `/api/currencyBalances` — `WalletBalancesController`
| Method | Path | Auth param |
|---|---|---|
| GET | `/fiatBalances` | `Authentication` |
| GET | `/cryptoBalances` | `Authentication` |
| GET | `/all` | `Authentication` |

### `/api/accounts` — `CurrencyAccountsController`
| Method | Path | Auth param |
|---|---|---|
| POST | `/newAccount/fiat` | `Authentication` |
| POST | `/newAccount/crypto` | `Authentication` |

### Other read-mostly modules
| Base path | Controller | Notes |
|---|---|---|
| `/api/cards` | `CardsController` | `GET /allCards` |
| `/api/history` | `HistoryController` | `GET /paymentsHistory` |
| `/api/bill-providers` | `BillProvidersController` | pay/validate/history are stubs |
| `/api/searchContacts` | `SearchContactsController` | `GET /{query}` — global, not caller-scoped |
| `/api/supportedCurrencyAccounts` | `supportedCurrencyAccountsController` | `GET /` |

## 4. Payment gateway architecture

`modules/payments/gateway/PaymentGatewayFactory` decides which external gateway
handles a disbursement and applies automatic failover:

| Transaction type | Currency | Primary gateway | Failover gateway |
|---|---|---|---|
| International (`isInternational=true`) | any | **Onafriq** | **Flutterwave** |
| National, Ghana | `GHS` | **Paystack** | **Flutterwave** |
| National, other | any other | **Paystack** | **Flutterwave** |

- All three gateways (`PaystackGatewayService`/`PaystackService`,
  `OnafriqGatewayService`, `FlutterwaveGatewayService`) implement
  `PaymentGatewayService` and make real `RestTemplate` HTTP calls (not mocks).
- The factory checks `gateway.isOperational()` and `gateway.supportsCurrency(...)`
  before attempting each gateway in the chain, and catches exceptions to move to the
  next one. If every gateway in the chain fails, the caller's wallet is re-credited
  and the whole disbursement fails.
- `PaymentsServices.makeDisbursement()` wraps debit → gateway call → transaction
  save in a single `@Transactional` boundary: if the gateway call throws, the sender
  is re-credited before the exception propagates, so wallet balance and transaction
  history never desync.
- Internal wallet-to-wallet transfers (`PaymentsServices.makePaymentToAppUser`)
  never touch an external gateway — they're pure debit/credit against
  `UserWalletsRepository`.

## 5. Error handling

`common/GlobalExceptionHandler` (`@RestControllerAdvice`) maps exceptions to
`ApiResponse` + HTTP status:

| Exception | Status | Notes |
|---|---|---|
| `ResourceNotFoundException` | 404 | also used for ownership-check failures |
| `MethodArgumentNotValidException` | 400 | `@Valid` bean-validation failures, field messages joined |
| `RuntimeException` | 400 | generic business errors (e.g. "Insufficient balance") |
| `Exception` (catch-all) | 500 | safety net — no stack trace leaked to the client |

## 6. Configuration (`application.properties`)

| Property prefix | Purpose |
|---|---|
| `server.*` | Port `2000`, HTTPS enabled, `keystore.p12` |
| `spring.datasource.*` | PostgreSQL connection (`zentrapay_db`, local by default) |
| `spring.jpa.hibernate.ddl-auto=validate` + `spring.flyway.*` | Schema is version-controlled SQL in `src/main/resources/db/migration` (`V1`–`V5`), applied by Flyway on boot. Hibernate only validates that the `@Entity` classes match — it never generates DDL. See "First-time database setup" below. |
| `app.jwt.secret` / `app.jwt.expiration-ms` | JWT signing key + 24h expiry |
| `app.password.pepper` / `app.pin.pepper` | Static peppers appended before BCrypt hashing |
| `app.cors.allowed-origins` | Comma-separated origin patterns (`*` by default) consumed by `CorsConfig` |
| `paystack.*` | Base URL, secret/public keys, default currency, webhook/callback URLs |
| `onafriq.*` | Base URL, API key, partner ID, default currency |
| `flutterwave.*` | Base URL, secret/public keys, webhook secret/URL |
| `hubtel.*` | Commented out — not active (offline/USSD, not implemented) |

All secret-bearing properties use the `${ENV_VAR:default}` pattern so they can be
overridden via environment variables in any real deployment; the checked-in
defaults are Paystack/Flutterwave **test-mode** keys and placeholder Onafriq
credentials, not production secrets.

`src/test/resources/application.properties` carries its own, separate set of
placeholder values for the same properties so the Spring context can boot during
`./gradlew test` without needing real gateway credentials.

### First-time database setup

The schema was rebuilt from scratch as normalized, Flyway-managed SQL (see
`docs/API_CONTRACT.md` for the full endpoint spec this schema backs). If you
have a pre-existing local `zentrapay_db` created by the old
`ddl-auto=update` behavior, its tables (`cards`, `crypto_currencies`,
`user_wallets`, etc.) won't match the new schema and Flyway will refuse to
run against it. Since that data was all placeholder/test data from the old
buggy dual-entity mappings, the simplest path is to drop and recreate the
database and let Flyway build it fresh on next boot:

```sql
-- Connect as a superuser (e.g. psql -U postgres)
DROP DATABASE IF EXISTS zentrapay_db;
CREATE DATABASE zentrapay_db;
```

Then just start the app (`./gradlew bootRun`) — Flyway runs `V1__init_schema.sql`
through `V5__seed_exchange_rates.sql` automatically on boot, creating every
table and seeding reference data (countries, currencies, transaction types,
provider categories, a starter bill/service-provider and bank directory
across Ghana/Nigeria/Kenya/South Africa/Uganda, financial literacy content,
and illustrative exchange rates). No manual seeding step is needed beyond
that. `psql` wasn't available in the sandbox this schema was built in, so
this step hasn't been run yet — do it once, locally, before first boot.

## 7. Testing & verification

- `./gradlew build` — compiles and runs `ZentrapaySpringBootLayerApplicationTests`
  (a full `@SpringBootTest` context-load test — this boots every bean, including
  security config, all controllers/services, and the JPA layer against a real
  Postgres instance).
- There is currently no dedicated unit/integration test suite beyond the
  context-load smoke test — new business logic (especially in `PaymentsServices`
  and the gateway factory) is a good candidate for adding real unit tests going
  forward.

## 8. Known gaps / deliberately deferred work

- `serviceProviders` module: model only, no controller/service/repository.
- `billProviders` pay/validate/history, `zbanking` loans/budget/insights, `zgrow`
  rewards/literacy, `zinvest` performance analytics: stub endpoints, TODO in code.
- `remittance` (ZRemit) exchange rate is hardcoded to `1` and fee to `0` — no real
  forex integration, and it does not go through `PaymentGatewayFactory`/Onafriq
  despite being cross-border.
- `converter` module uses a static, illustrative rate table — no live forex
  provider is integrated anywhere in the codebase.
- No per-user challenge-participation tracking in `zgrow` (join just increments an
  aggregate counter).
- No fraud-detection or login-history event sources are wired up yet, so
  `/api/secure/fraud-alerts` and `/api/secure/login-history` are real queries that
  currently always return empty lists.

