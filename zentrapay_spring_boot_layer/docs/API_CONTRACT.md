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
| POST | `/initialize` | Send money. Body in `PAYMENTS_AND_GATEWAYS.md` / `TransactionRequest`. `transactionType` = `P2P_TRANSFER` or `CASH_OUT_BANK` (older apps may send `channelType` = `INTERNAL`/`BANK`). `TXN_Ref` makes retries safe. Returns the transaction in the same shape as `/api/history` rows. |
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
| POST | `/api/wallet/supportedCurrencies` | currencies the user can still open |
| GET | `/api/notifications?limit=&offset=` / PATCH `/{id}/read` | |
| GET | `/api/converter/rates?base=` / POST `/convert` / GET `/history` | |

## Directory and search
| Verb | Path | Auth |
|---|---|---|
| GET | `/api/reference/countries`, `/currencies`, `/provider-categories`, `/banks?query=&country=` | Public |
| GET | `/api/payment-channels?countryCode=&type=` | Bearer |
| GET | `/api/payment-channels/resolve?channelCode=&accountNumber=` | Bearer - account holder name (Paystack, then Flutterwave) |
| GET | `/api/search/search-contacts/{query}`, `/search-contact/{query}` | Bearer |
| GET | `/api/service-providers` | Bearer |

## Bills - `/api/bill-providers`
`GET /` directory, `POST /validate {providerId, customerReference}`, `POST /pay {pin, providerId, customerReference, amount, currencyCode}`,
`GET /history`. Only providers wired to Flutterwave (gateway + item code filled by the directory sync) can be paid.

## Remittance - `/api/remittance`
`POST /send`, `GET /history`, `GET /rates?source=&destination=&amount=`. Cross-border only; the recipient must be a ZentraPay user for now.

## Bank accounts (ZBank) - `/api/zbanking`
`GET /userAccounts`, `POST /link`, `POST /primary/{id}`, `DELETE /unlink/{id}` (linking goes through AfriqLink).

## Cards - `/api/cards`
`GET /userCards`, `GET /otherCards`.

## ZGrow - `/api/zgrow`
`challenges`, `challenges/{id}`, `challenges/enroll`, `challenges/{id}/decline`, `challenges/declined`, `myChallenges`,
`myChallenges/{id}`, `challenges/{userChallengeId}/progress`, `gamification` (GET/PUT), `rewards`, `savings`, `tutorials`.

## Called by the app but NOT built yet
The database tables exist for most of these; there is no controller/service yet:
`/api/zinvest/*`, `/api/zvoice/*`, `/api/secure/*`, `/api/zbanking/{savings,loans,budget,insights}*`,
`/api/cards/virtual`, `/api/cards/{id}/nfc`, `/api/cards/{id}/qr`, `/api/zgrow/literacy*`, `/api/wallets/crypto`.
