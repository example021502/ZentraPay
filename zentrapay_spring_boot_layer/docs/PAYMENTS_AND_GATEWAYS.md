# Payments, gateways and webhooks

How money moves in the ZentraPay backend, in plain terms. Read this together with the code:
every class named here has a short comment at the top of its larger methods that says what it does.

## 1. The three gateways

| Corridor | Primary | Failover |
|---|---|---|
| National (sender and receiver in the same country) | **Paystack** | Flutterwave |
| Cross-border | **Onafriq** | Flutterwave |

Which gateway to try first is decided in one place: `GatewayServices.gatewaysFor(crossBorder)`.

> **Onafriq is not provisioned yet.** Its endpoint paths, field names and webhook signature in
> `OnafriqServices` / `OnafriqWebhookController` are best guesses. Until the partner account exists every
> Onafriq call fails cleanly and the payment fails over to Flutterwave (or is refunded).

## 2. Customers and recipients (the same-gateway rule)

* A **customer** is the user as the gateway knows them (Paystack `CUS_xxx`). Table `gateway_customers`, one row per (user, gateway).
* A **recipient** is a bank account / wallet registered on the gateway (Paystack `RCP_xxx`). Table `gateway_recipients`.
* A recipient **always points at the customer of the same gateway**. The database enforces it with a composite
  foreign key `(customer_id, gateway_id) -> gateway_customers(id, gateway_id)`.
* `GatewayServices.getOrCreateCustomer(...)` then `getOrCreateRecipient(customer, destination)` is the only way
  they are created. Both are cached, so the gateway is only called the first time.
* The same bank has a different code on each gateway. `BankCatalogService` turns the bank the app picked into the
  code of the gateway being used (looked up by name in that gateway's rows of the `banks` table). If a gateway has no
  matching bank it is skipped.

## 3. Sending money (`POST /api/payments/initialize`)

`PaymentServices.initialize` -> checks the PIN, the account, the balance and the KYC limits, then:

### P2P_TRANSFER (wallet to wallet, same or cross currency)
One database transaction (`LedgerOperations.transferBetweenWallets`): debit, credit, `transactions` row, two
`ledger_entries`, two notifications. All or nothing. Cross-currency uses the live rate from `ExchangeRateService`
(the amount the receiver gets is stored in `transactions.destination_amount`).

### CASH_OUT_BANK (wallet to bank account, same or cross currency)
1. `BankTransferServices.prepare` - find the first gateway that can take the bank account (customer + recipient
   created). Nothing is debited yet, so a failure here is a clean error.
2. `LedgerOperations.debitForPayout` - debit the sender, save the transaction as **INITIATED**, write the debit ledger entry.
3. `BankTransferServices.send` - call the gateway:
   * accepted -> **PENDING** (the webhook makes it SUCCESS);
   * **definitely refused** (4xx, never reached) -> try the next gateway; if all refuse -> **refund** (FAILED);
   * **outcome unknown** (timeout, 5xx) -> stays **PENDING**, is **not** refunded and **not** retried elsewhere
     (the money may already be on its way). The webhook / reconciliation job settles it.

`TXN_Ref` is the idempotency key: sending the same one again returns the first result and never pays twice.

### Statuses
`INITIATED` (money held, gateway not called) -> `PENDING` (gateway accepted) -> `SUCCESS` | `FAILED` (refunded) | `REVERSED`
(gateway took back a settled payout; refunded) | `EXPIRED`.

## 4. Wallet funding (`GET /api/payments/paystack/access-code`)
Saves a PENDING `CASH_IN_CARD` transaction, starts a checkout on Paystack (Flutterwave if Paystack refuses) and returns
`{accessCode, reference, authorizationUrl, gateway}`. Nothing is credited until the gateway confirms; then
`LedgerOperations.creditFunding` checks the **paid amount and currency** against the request before crediting.

## 5. Webhooks (all public, signature checked first)

| Gateway | URL | Check |
|---|---|---|
| Paystack | `POST /api/payments/paystack/webhook` | `x-paystack-signature` = HMAC-SHA512 of the body with the secret key |
| Flutterwave | `POST /api/payments/flutterwave/webhook` | `verif-hash` header = `flutterwave.webhook-secret` |
| Onafriq | `POST /api/payments/onafriq/webhook` | `x-onafriq-signature` = HMAC-SHA256 with `onafriq.webhook-secret` (**assumed**) |

Answers: `200` handled/ignored, `401` bad signature, `400` unreadable body, `500` our failure (the gateway retries).
Events handled: `transfer.success`, `transfer.failed`, `transfer.reversed`, `charge.success` (Paystack);
`transfer.completed`, `charge.completed` (Flutterwave). The reference we send to every gateway is `zp-<transactionId>`,
which is how an event finds its transaction. Every status change locks the transaction row, so a webhook delivered twice
(or racing a refund) changes nothing the second time.

Set the webhook URLs in each gateway dashboard to the URLs above (public HTTPS).

## 6. Reconciliation job
`PaymentReconciliationService` runs every 5 minutes (`app.reconcile.*`). Payments still INITIATED/PENDING after 10 minutes
are checked directly with the gateway and settled exactly like a webhook would.

## 7. Account name lookup
`GET /api/payment-channels/resolve` asks Paystack, then Flutterwave, using each gateway's own bank code.
AfriqLink is used only to **link** a bank account (`/api/zbanking/link`).

## 8. Database
Ten Flyway files in `src/main/resources/db/migration`:
`V1`-`V5` create the tables, `V6`-`V10` insert seed/test data. They replace the old 35 files and are **not** an upgrade of
them: on a database created from the old set, drop and recreate it once:

```
dropdb zentrapay_app && createdb zentrapay_app      # then start the app, Flyway builds everything
```
Seeded test data (5 users, wallets, banks, ...) lives in `V9`/`V10`; delete those two files (or add real data migrations
after them) before going to production. `gateway_customers` / `gateway_recipients` are deliberately not seeded.

## 9. Secrets
Every key in `application.properties` can be overridden by an environment variable (`PAYSTACK_SECRET_KEY`,
`FLUTTERWAVE_SECRET_KEY`, `FLUTTERWAVE_WEBHOOK_SECRET`, `ONAFRIQ_WEBHOOK_SECRET`, `JWT_SECRET_KEY`, `DB_PASSWORD`, ...).
The values still in the file are the old development ones - rotate them and keep real keys out of git.
