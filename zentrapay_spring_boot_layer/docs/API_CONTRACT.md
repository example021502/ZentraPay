# ZentraPay API Contract (v1)

This is the single source of truth for every REST endpoint the Flutter app
uses. Backend controllers and the Flutter service layer must both match this
document exactly — it supersedes any older ad-hoc endpoint the code
currently calls (see "Superseded" notes per module).

Conventions:
- Envelope: `{"success": bool, "data": <T|null>, "message": string|null}` (existing `ApiResponse<T>` record — unchanged).
- Auth: `Authorization: Bearer <jwt>` unless marked **Public**.
- All JSON keys are `camelCase`. All money fields are strings holding a decimal (never float) — Dart `Decimal`/`String`, Java `BigDecimal` serialized as string via a custom Jackson module, to avoid floating-point rounding entirely across the wire.
- All timestamps are ISO-8601 UTC strings.
- IDs are UUID strings.
- Country codes are ISO 3166-1 alpha-2. Currency codes are ISO 4217 (or `BTC`/`ETH`/`USDT` for crypto).

---

## 1. Auth & Users — `/api/users` (Backend Agent 1)

| Verb | Path | Auth | Request | Response `data` |
|---|---|---|---|---|
| POST | `/api/users/register` | Public | `{firstName,lastName,email,phoneNumber,countryCode,password,pin,zentag}` | `{token,userId,email,fullName,zentag}` |
| POST | `/api/users/login` | Public | `{email?,phoneNumber?,password}` (one of email/phoneNumber) | `{token,userId,email,fullName,zentag}` |
| POST | `/api/users/refresh` | Bearer (may be expired — refresh must work on an expired-but-validly-signed token) | — | `{token}` |
| POST | `/api/users/pin/verify` | Bearer | `{pin}` | `{valid:boolean}` |
| GET | `/api/users/me` | Bearer | — | `{userId,firstName,lastName,email,phoneNumber,countryCode,zentag,userType,status,kycTier}` |
| PATCH | `/api/users/me` | Bearer | `{firstName?,lastName?}` (only self-service editable fields) | same as GET |
| GET | `/api/users/me/profile` | Bearer | — | `UserProfile` (see `user_profiles`): `{dateOfBirth,idDocumentType,idDocumentNumber,idDocumentCountryCode,addressLine1,addressLine2,city,regionState,postalCode,occupation,amlStatus,isPep}` — nulls until KYC submitted |
| PUT | `/api/users/me/profile` | Bearer | same shape as GET (upsert) | updated `UserProfile` |
| GET | `/api/users/me/merchant-profile` | Bearer | — | `{businessName,businessRegistrationNumber,taxIdentificationNumber,businessCategoryCode,businessCountryCode,businessAddress}` or `null` if not a merchant |
| PUT | `/api/users/me/merchant-profile` | Bearer | same shape (upsert; sets `userType=MERCHANT`) | updated merchant profile |

**Superseded**: none — this module already matched; adds `/me` PATCH, `/me/profile`, `/me/merchant-profile` (new, needed for Profile screen + Merchant tab to stop being hardcoded).

---

## 2. Reference Data — `/api/reference` (Backend Agent 2, new module)

All **Public**, all cacheable client-side indefinitely (or until app restart) — this is exactly the "load once" case since reference data changes essentially never during a session.

| Verb | Path | Response `data` |
|---|---|---|
| GET | `/api/reference/countries` | `[{countryCode,iso3Code,countryName,dialCode,defaultCurrencyCode,region}]` |
| GET | `/api/reference/currencies` | `[{currencyCode,currencyName,symbol,isCrypto,decimalPlaces}]` |
| GET | `/api/reference/provider-categories` | `[{categoryCode,categoryName}]` |

---

## 3. Wallets & Balances — `/api/wallets` (Backend Agent 1)

**Supersedes** `/api/accounts/*`, `/api/currencyBalances/*` (both retired — the frontend's two divergent paths collapse into one).

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| GET | `/api/wallets` | — | `{fiatWallets:[{walletId,walletName,currencyCode,countryCode,balance,isDefault,status}], cryptoWallets:[{cryptoWalletId,currencyCode,network,walletAddress,balance,status}]}` |
| POST | `/api/wallets/fiat` | `{walletName,currencyCode,countryCode?}` | created fiat wallet |
| POST | `/api/wallets/crypto` | `{currencyCode,network,walletAddress}` — **TODO, not implemented this pass** (crypto logic deferred); returns 501 `ApiResponse.error("Crypto wallets are not yet supported")` | — |

---

## 4. Cards — `/api/cards` (Backend Agent 1)

**Supersedes** the old `cards.CardsModel`/`zpay.CardModel` split — one table, one controller.

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| GET | `/api/cards` | — | `[{cardId,brand,cardType,last4,expiryMonth,expiryYear,nfcEnabled,qrEnabled,status}]` |
| POST | `/api/cards/virtual` | `{brand}` | created card |
| PATCH | `/api/cards/{cardId}/nfc` | `{enabled}` | updated card |
| PATCH | `/api/cards/{cardId}/qr` | `{enabled}` | updated card |
| POST | `/api/cards/{cardId}/pay` | `{amount,currencyCode,merchantName,method:"NFC"|"QR"}` | `{transactionId,status}` — debits the card's linked wallet, writes a `CARD_PAYMENT` transaction |

---

## 5. Transactions & History — `/api/transactions` (Backend Agent 1)

**Supersedes** `/api/history*`.

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| GET | `/api/transactions?page=&size=&type=&status=` | query params, all optional | `{content:[Transaction], page,size,totalElements,totalPages}` |
| GET | `/api/transactions/{transactionId}` | — | `Transaction` |

`Transaction` shape: `{transactionId,typeCode,amount,currencyCode,status,gateway,reference,counterpartyName,counterpartyIdentifier,description,createdAt}`.

---

## 6. Payments — `/api/payments` (Backend Agent 1)

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| POST | `/api/payments/internal` | `{pin,recipient:{phoneNumber?,zentag?},amount,currencyCode}` | `Transaction` |
| POST | `/api/payments/bank-transfer` | `{pin,amount,currencyCode,channelCode,accountNumber,accountName,description?}` | `Transaction` |
| GET | `/api/payments/paystack/access-code?amount=&currencyCode=` | — | `{accessCode,reference,authorizationUrl}` — real Paystack `transaction/initialize` call; creates a `PENDING` `WALLET_FUNDING` transaction row keyed by `reference` |
| POST | `/api/payments/paystack/webhook` | Paystack webhook payload, **Public** (verified via `x-paystack-signature`) | — marks the matching transaction `SUCCESS`/`FAILED` and credits the wallet on success |

**Supersedes** `/api/payment/bankTransfer` (typo'd path, never existed) → `/api/payments/bank-transfer`; `/api/paystackAccessCode/accessCode` → `/api/payments/paystack/access-code`.

---

## 7. Payment Channels (bank/mobile-money directory) — `/api/payment-channels` (Backend Agent 2)

**Supersedes** `/api/bankAccounts/paystack`, `/paystack/bank/resolve`.

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| GET | `/api/payment-channels?countryCode=&type=BANK|MOBILE_MONEY` | query params | `[{channelCode,channelName,channelType,countryCode,gateway}]` (served from the `payment_channels` table, refreshed by a scheduled `PaymentChannelSyncService` that calls each gateway's bank-list API) |
| GET | `/api/payment-channels/resolve?channelCode=&accountNumber=` | query params | `{accountName}` — live passthrough to the owning gateway's account-resolution API |

---

## 8. Bill Providers & Bill Payments — `/api/bill-providers` (Backend Agent 2)

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| GET | `/api/bill-providers?countryCode=&categoryCode=` | query params, optional | `[{providerId,billerName,categoryCode,logoUrl,fetchRequirement}]` |
| POST | `/api/bill-providers/validate` | `{providerId,customerReference}` | `{valid:boolean,customerName?}` |
| POST | `/api/bill-providers/pay` | `{pin,providerId,customerReference,amount,currencyCode}` | `{payment:{paymentId,status},transaction:Transaction}` |
| GET | `/api/bill-providers/history` | — | `[{paymentId,providerName,customerReference,amount,currencyCode,status,createdAt}]` (current user's `bill_payments`) |

---

## 9. Service Providers — `/api/service-providers` (Backend Agent 2, unchanged path)

| Verb | Path | Response `data` |
|---|---|---|
| GET | `/api/service-providers?countryCode=&categoryCode=` | `[{providerId,providerName,categoryCode,logoUrl,minAmount,maxAmount}]` |

---

## 10. Search Contacts — `/api/search-contacts/{query}` (Backend Agent 2)

Unchanged shape, consolidated onto the new tables: `{appUsers:[{userId,fullName,phoneNumber,zentag}], billProviders:[{providerId,billerName,categoryCode}], fundingSources:[{sourceId,sourceName,accountIdentifier}]}`.

---

## 11. Converter / FX — `/api/converter` (Backend Agent 2)

Backed by the real `exchange_rates` table instead of an in-memory static map.

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| GET | `/api/converter/rates?base=` | — | `{base,rates:{<currencyCode>:<rate>}}` (latest row per pair) |
| POST | `/api/converter/convert` | `{from,to,amount}` | `{convertedAmount,rate}` |
| GET | `/api/converter/history` | — | `[{fromCurrency,toCurrency,amount,convertedAmount,createdAt}]` — **now actually persisted** (each conversion writes a row) |

---

## 12. Remittance — `/api/remittance` (Backend Agent 2)

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| POST | `/api/remittance/send` | `{pin,amount,sourceCurrencyCode,destinationCurrencyCode,channel,recipientName,recipientPhoneNumber?,recipientUserId?,recipientCountryCode}` | `{remittance:{remittanceId,status,exchangeRate,fee},transaction:Transaction}` |
| GET | `/api/remittance/history` | — | `[{remittanceId,amount,sourceCurrencyCode,destinationCurrencyCode,recipientName,status,createdAt}]` |
| GET | `/api/remittance/rates?source=&destination=` | — | `{exchangeRate,fee}` — real quote, sourced from `exchange_rates` |

---

## 13. ZBanking (Savings & Loans) — `/api/zbanking` (Backend Agent 2)

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| GET | `/api/zbanking/savings` | — | `[{savingsId,savingsName,currencyCode,balance,targetAmount,targetDate,status}]` |
| POST | `/api/zbanking/savings` | `{savingsName,currencyCode,initialDeposit,targetAmount?,targetDate?,description?}` | created savings account |
| POST | `/api/zbanking/savings/{savingsId}/deposit` | `{amount}` | updated savings account |
| POST | `/api/zbanking/savings/{savingsId}/withdraw` | `{amount}` | updated savings account |
| GET | `/api/zbanking/loans` | — | `[{loanId,principalAmount,interestRate,termMonths,outstandingBalance,status,dueDate}]` |
| POST | `/api/zbanking/loans/apply` | `{amount,currencyCode,termMonths}` | created loan (`status:PENDING`, auto-approved by a simple eligibility rule — see service) |
| POST | `/api/zbanking/loans/{loanId}/repay` | `{amount}` | updated loan |
| GET | `/api/zbanking/insights` | — | `{monthlySpend,monthlyIncome,topCategories:[{categoryCode,amount}]}` — aggregated from `transactions` |
| GET | `/api/zbanking/budget` | — | `{monthlyLimit,spentThisMonth,remaining}` — reads a per-user budget row (new `user_budgets` table, see migration V4) |
| PUT | `/api/zbanking/budget` | `{monthlyLimit}` | updated budget |

---

## 14. ZGrow (Challenges, Literacy, Rewards) — `/api/zgrow` (Backend Agent 2)

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| GET | `/api/zgrow/challenges?category=` | — | `[{challengeId,title,description,category,durationDays,pointsReward,difficulty,participantsCount,joined:boolean,progressPercent}]` (`participantsCount` derived via COUNT; `joined`/`progressPercent` are for the current user) |
| POST | `/api/zgrow/challenges/{challengeId}/join` | — | updated challenge participation row |
| GET | `/api/zgrow/literacy` | — | `[{contentId,title,category,contentUrl,durationMinutes,pointsReward,completed:boolean}]` |
| POST | `/api/zgrow/literacy/{contentId}/complete` | — | `{pointsEarned}` — idempotent (unique constraint on content+user) |
| GET | `/api/zgrow/rewards` | — | `{totalPoints,tier,recentLedger:[{points,reason,createdAt}]}` |

---

## 15. ZInvest — `/api/zinvest` (Backend Agent 2)

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| GET | `/api/zinvest/portfolio` | — | `[{investmentId,name,investmentType,symbol,quantity,buyPrice,currentPrice,currencyCode,status}]` (`currentPrice` = latest `investment_price_snapshots` row, falls back to `buyPrice`) |
| POST | `/api/zinvest/invest` | `{name,investmentType,symbol,quantity,buyPrice,currencyCode}` — **TODO for `investmentType:"CRYPTO"`**, returns 501 | created investment |
| POST | `/api/zinvest/{investmentId}/sell` | — | closed investment + `Transaction` |
| GET | `/api/zinvest/liquidity-profile` | — | `{totalValue,totalGainLossPercent,riskProfile}` |
| GET | `/api/zinvest/liquidity-trend` | — | `[{recordedAt,totalValue}]` — real historical series from snapshots |
| GET | `/api/zinvest/risks` | — | `[{investmentId,name,type,message,severity}]` |
| GET | `/api/zinvest/alerts` | — | `[{investmentId,symbol,changePercent}]` |

---

## 16. Secure — `/api/secure` (Backend Agent 1)

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| GET | `/api/secure/status` | — | `{biometricEnabled,biometricType,twoFactorEnabled,twoFactorMethod,fraudProtectionEnabled}` |
| POST | `/api/secure/biometric` | `{enabled,type?}` | updated settings |
| POST | `/api/secure/2fa` | `{enabled,method?}` | updated settings |
| POST | `/api/secure/fraud-protection` | `{enabled}` | updated settings |
| GET | `/api/secure/fraud-alerts` | — | `[{alertId,alertType,message,severity,isResolved,createdAt}]` — **now backed by real `fraud_alerts` rows**, populated whenever `PaymentsServices`/`RemittanceServices` flag an anomaly (large-amount / new-recipient heuristics) |
| GET | `/api/secure/login-history` | — | `[{loginId,ipAddress,deviceInfo,location,success,createdAt}]` — **now populated** by `JwtAuthenticationFilter`/`UsersService.login` writing a row per login attempt |
| GET | `/api/secure/tips` | Public | `[{title,body}]` (static content, fine as-is) |

---

## 17. ZVoice — `/api/zvoice` (Backend Agent 1)

**Supersedes**: `POST /api/zvoice/command` now takes a **JSON body**, not query params (frontend was posting query params against a `@RequestParam`-only endpoint — a real bug).

| Verb | Path | Request | Response `data` |
|---|---|---|---|
| POST | `/api/zvoice/command` | `{commandType:"VOICE"|"CHAT",language,transcript,fraudAlert?,fraudReason?}` | `{commandId,transcript,responseText,createdAt}` — for `CHAT`, `responseText` is a real (simple, rule-based — no external LLM call in this pass) assistant reply so the AI Assistance screen can render an actual conversation |
| GET | `/api/zvoice/history?language=` | — | `[{commandId,commandType,transcript,responseText,createdAt}]` |
| GET | `/api/zvoice/fraud-alerts` | — | `[{commandId,transcript,fraudReason,createdAt}]` |

---

## Retired endpoints (module deleted, no replacement route — client switches to the listed replacement)

- `/api/accounts/*`, `/api/currencyBalances/*` → `/api/wallets` (§3)
- `/api/cards/allCards`, `/api/zpay/*` → `/api/cards` (§4)
- `/api/history/*` → `/api/transactions` (§5)
- `/api/paystackAccessCode/accessCode` → `/api/payments/paystack/access-code` (§6)
- `/api/payment/bankTransfer` → `/api/payments/bank-transfer` (§6)
- `/api/bankAccounts/paystack`, `/paystack/bank/resolve` → `/api/payment-channels` (§7)
- `/api/supportedCurrencyAccounts` → `/api/reference/currencies` (§2) — the `supportedCurrencyAccounts` module/table is retired entirely; "supported currencies" is just the `currencies` reference table filtered `is_active=true`.

## New tables added on top of `V1__init_schema.sql`

`V4__additional_tables.sql` (written alongside this contract) adds:
- `user_budgets` (user_id PK/FK, monthly_limit, created_at, updated_at) — for ZBanking budget.
