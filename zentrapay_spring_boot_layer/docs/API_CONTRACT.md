# ZentraPay API Contract

The endpoints the backend serves today. Base URL `https://<host>:2000`. This replaces the older contract, which
described modules that no longer exist.

**Conventions**
* Every response uses one envelope: `{"success": boolean, "message": string, "data": object|null}`.
  Errors use the same envelope with `success=false` (HTTP 400 business rule, 401 not signed in, 404 not found,
  409 duplicate, 502 payment gateway problem, 500 unexpected).
* Auth: `Authorization: Bearer <jwt>` on everything except the **Public** rows.
* JSON keys are camelCase (except `TXN_Ref`, kept for the app). Money is a decimal number. Timestamps are ISO-8601.

## Users - `/api/users`
| Verb | Path | Auth | Notes |
|---|---|---|---|
| POST | `/register` | Public | creates user, wallets and default account, returns token |
| POST | `/login` | Public | by `email` or `phoneNumber` + `password`; wrong details always answer "Invalid credentials" |
| POST | `/refresh` | Public* | new token for an expired (but correctly signed, < 30 days old) token in the `Authorization` header |
| POST | `/pin/verify` | Bearer | `{pin}` -> `data.valid`; a wrong PIN is HTTP 200 with `success=false`, never 401 |
| GET | `/me`, `/qr_me`, `/me/profile` | Bearer | |
| PATCH | `/me` (also `/update`) | Bearer | |
| PUT | `/me/profile` | Bearer | KYC profile |
| GET/POST | `/me/documents/{type}` | Bearer | KYC images |

## Payments - `/api/payments`
| Verb | Path | Notes |
|---|---|---|
| POST | `/initialize` | Send money. Body in `PAYMENTS_AND_GATEWAYS.md` / `TransactionRequest`. `transactionType` = `P2P_TRANSFER` or `CASH_OUT_BANK` (older apps may send `channelType` = `INTERNAL`/`BANK`). `TXN_Ref` makes retries safe. For `CASH_OUT_BANK` / `CASH_OUT_MOMO` send `bank` / `mobileMoney` = `{verificationToken, gatewayId}` (both returned by `POST /verify-account`); the gateway that verified the account is tried first, the others only if it refuses. Returns the transaction in the same shape as `/api/history` rows. |
| POST | `/verify-account` | Check a bank / mobile-money account before paying -> `{verified, gatewayId, accountName, accountNumber (masked), destinationName, countryCode, verificationToken}`. `gatewayId` is the gateway that did the verification; it is also inside `verificationToken` (AES-GCM, 15 min, bound to the caller). Send `verificationToken` + `gatewayId` back with the payment so that gateway is used first. |
| POST | `/retry/{transactionId}/check` | Retry a FAILED transaction, step 1 (no PIN): checks that the sender and the receiver are still valid. -> `{retryable, message, receiverName, amount, currencyCode}` (`message` says why when `retryable` is false). If a party is no longer valid the failed transaction's failure reason is updated with why and nothing is retried. |
| POST | `/retry/{transactionId}` | Step 2: `{pin}`. Re-runs the check, verifies the PIN, then pays again under the idempotent reference `RTY-<transactionId>` (a double tap cannot pay twice). Returns the new transaction in the `/api/history` shape. Only wallet-to-wallet (P2P) transfers can be retried; bank / mobile-money payouts are only stored with a masked account number, so the user must start a new verified transfer. A retry that fails again creates a new FAILED row - retry that one. |
| POST | `/bank-transfer` | Flat bank transfer: `{pin, amount, currencyCode, channelCode, accountNumber, accountName, description?}` |
| GET | `/paystack/access-code?amount=&currencyCode=` | Start wallet top-up -> `{accessCode, reference, authorizationUrl, gateway}` |
| POST | `/paystack/customer`, `/flutterwave/customer` | Get/create my customer on that gateway -> `{id, code, email, first_name, last_name, phone}` |
| GET | `/{accountId}/qr` | PNG |
| POST | `/paystack/webhook`, `/flutterwave/webhook`, `/onafriq/webhook` | **Public**, signature-checked, see `PAYMENTS_AND_GATEWAYS.md` |

Transaction `status`: `INITIATED`, `PENDING`, `SUCCESS`, `FAILED`, `REVERSED`, `EXPIRED`.

## Money views
| Verb | Path | Notes |
|---|---|---|
| GET | `/api/history?page=&size=` | paged transactions `{content, page, size, totalElements, totalPages}`; `amount` is signed ("-GHS 25.50" / "+USD 10.00") |
| GET | `/api/wallet/balances` | |
| POST | `/api/wallet/newFiat` | open a currency account |
| POST | `/api/wallet/supportedCurrencies` | currencies the user can still open (the countries' default currencies, minus the ones they hold) |
| GET | `/api/notifications?limit=&offset=` / PATCH `/{id}/read` | |
| GET | `/api/converter/rates?base=` / POST `/convert` / GET `/history` | `/convert` is refused unless the user holds a wallet account in BOTH currencies; the error names the missing one so the app can offer "Create XXX wallet" (`POST /api/wallet/newFiat`). Quotes for previews (ZRemit) use `GET /api/remittance/rates`, which does not write converter history. |
| GET | `/api/user-services` | The services the user added to Home (`user_services` table): `[{kind: BILL\|SERVICE, providerId, name, logoUrl, categoryCode, countryCode}]`. Home shows only these, never the whole directory. |
| POST | `/api/user-services` | `{kind, providerId}` - add one (idempotent; the provider must exist and be active). |
| DELETE | `/api/user-services/{kind}/{providerId}` | Remove one from Home (no error if absent). |

## Directory and search
| Verb | Path | Auth |
|---|---|---|
| GET | `/api/reference/countries`, `/currencies`, `/provider-categories`, `/banks?query=&country=` | Public |

**Currencies come from the country table.** There is no currencies table: `gateway_countries.default_currency` is the only
source (`countries` returns it as `defaultCurrencyCode`; `currencies` is the distinct set of active countries' default
currencies, each with `{currencyCode, currencyName, symbol, isCrypto, decimalPlaces, countryCodes}`).
It also restricts payments, by where the sender is registered:
- **domestic** (P2P, bank, mobile money): the sender pays in their own country's default currency and the recipient
  receives that same currency;
- **cross-border** (`/api/remittance`): the sender still pays in their own country's default currency; the money arrives
  in the destination country's default currency.
Any other `currencyCode` / `destinationCurrencyCode` is refused with a message naming the allowed currency; a blank one takes
the allowed default. Change a country's `default_currency` in the table to change what it may use (the sync never overwrites it).
| GET | `/api/payment-channels?countryCode=&type=` | Bearer |
| GET | `/api/payment-channels/resolve?channelCode=&accountNumber=` | Bearer - account holder name (Paystack, then Flutterwave) |
| GET | `/api/search/search-contacts/{query}`, `/search-contact/{query}` (`?scope=DOMESTIC\|INTERNATIONAL`, `&country=NG` narrows INTERNATIONAL to one destination country) | Bearer |
| GET | `/api/service-providers` | Bearer |

## Bills - `/api/bill-providers`
`GET /` directory, `POST /validate {providerId, customerReference}`, `POST /pay {pin, providerId, customerReference, amount, currencyCode}`,
`GET /history`. Only providers wired to Flutterwave (gateway + item code filled by the directory sync) can be paid.

## Remittance - `/api/remittance`
`POST /send`, `GET /history`, `GET /rates?source=&destination=&amount=` (returns `destinationAmount` for the typed amount). Cross-border only.
`/send` to a bank / mobile-money recipient takes `verificationToken` + `gatewayId` from `POST /api/payments/verify-account`; the verifying
gateway is promoted first among the gateways routed for that corridor. The receiver name comes from the verification, not from the user.

## Bank accounts (ZBank) - `/api/zbanking`
`GET /userAccounts`, `POST /link`, `POST /primary/{id}`, `DELETE /unlink/{id}` (linking goes through AfriLink).
`GET /insights` -> `{currencyCode, monthlySpend, monthlyIncome, topCategories:[{categoryCode, amount}]}` for this calendar month in the
user's home currency (spend = transfers, payouts, bills, loan repayments, fees; income = money received from other users; savings
and investments are not spending). `GET /budget` and `PUT /budget {monthlyLimit}` -> `{currencyCode, monthlyLimit, spentThisMonth, remaining}`.
Loans (`/loans`) are documented in their own controller.

### Savings goals ("Save Goal") - `/api/zbanking/savings`
A goal is in ONE currency (the wallet account it is funded from). Every money move is one all-or-nothing step and a `SAVINGS_DEPOSIT` /
`SAVINGS_WITHDRAWAL` transaction (refused attempts are stored as FAILED), so it appears in history and in ZGrow's "Overall Savings".
- `GET /` -> `[{savingsId, savingsName, currencyCode, balance, targetAmount, targetDate, status (ACTIVE|COMPLETED), description,
  frozenUntil, autoSaveEnabled, autoSaveAmount, autoSaveFrequency (DAILY|WEEKLY|MONTHLY), autoSaveNextRun, createdAt}]`.
  `frozenUntil` is null unless the goal is frozen right now; times are ISO instants.
- `POST /` `{savingsName, currencyCode, initialDeposit?, targetAmount?, targetDate?, description?}`; `POST /{id}/deposit` and `/{id}/withdraw` `{amount}`.
- `POST /{id}/freeze {days}` - `days` 1..7. While frozen NO money can be saved into the goal (manual or automatic); withdrawing still works.
  A frozen goal cannot be frozen again (no extending beyond a week); `POST /{id}/unfreeze` ends it early. The freeze simply runs out - no job.
- `PUT /{id}/auto-save {amount, frequency}` turns auto-save on (first save one full period from now); `DELETE /{id}/auto-save` turns it off.
  A background job (`SavingsAutoSaveJob`, every minute, `app.savings.auto-save-interval-ms`) claims each due run by moving `auto_next_run`
  forward in its own committed step BEFORE moving money, so a run can never happen twice. A frozen goal keeps its due run and saves right
  after the freeze ends; a goal that reached its target switches auto-save off; a save the wallet cannot cover is recorded as FAILED.
- `DELETE /{id}` -> `{savingsId, savingsName, currencyCode, returnedAmount}`: whatever was saved goes back to the wallet in the same step.
- `GET /activity?limit=30` (max 100) -> newest first `[{activityId, savingsId, savingsName, type (DEPOSIT|WITHDRAWAL), auto, amount, currencyCode,
  status (SUCCESS|FAILED ...), failureReason, createdAt}]`; `auto` = a scheduled save.

## ZInvest - `/api/zinvest`
`GET /portfolio` -> my positions `[{investmentId, name, investmentType, symbol, quantity, buyPrice, currentPrice, currencyCode, status}]`;
`POST /invest {name, investmentType (STOCK|ETF|COMMODITY|OTHER), symbol?, quantity, buyPrice, currencyCode}` takes `quantity x buyPrice`
from the wallet account in that currency (transaction `INVESTMENT_BUY`); `POST /{id}/sell` puts the position's current value back
(`INVESTMENT_SELL`) and closes it. `CRYPTO` is refused. There is no market-data feed: the current price is the newest row in
`investment_price_snapshots`, and only the buy-price row is written today, so a position sells for what it cost.

## Cards - `/api/cards`
`GET /userCards`, `GET /otherCards`.

## ZGrow - `/api/zgrow`
`challenges`, `challenges/{id}`, `challenges/enroll`, `challenges/{id}/decline`, `challenges/declined`, `myChallenges`,
`myChallenges/{id}`, `challenges/{userChallengeId}/progress`, `gamification` (GET/PUT), `rewards`, `savings`, `tutorials`.

## Called by the app but NOT built yet
Needs a third-party partner or has no screen using it; the app tolerates the 404 or shows a "not available yet" message:
`/api/zinvest/{liquidity-profile,liquidity-trend,risks,alerts}` (Liquidity Hub), `/api/cards/virtual`, `/api/cards/{id}/nfc`,
`/api/cards/{id}/qr` (card issuing), `/api/zgrow/literacy*` (no screen uses it), `/api/wallets/crypto`.
