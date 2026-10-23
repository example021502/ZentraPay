# ZentraPay Backend - Structure

Project `zentrapay_spring_boot_layer`, base package `com.zentrapay.backend`. One Spring Boot application
(Java 21, Spring Boot 4, PostgreSQL, Flyway). The Flutter app calls it directly.

## Layout

```
src/main/java/com/zentrapay/backend/
  ZentrapayApplication.java   entry point + shared beans (PasswordEncoder, RestTemplate)
  config/        CORS, MVC argument resolver, HTTP client (RestClient with timeouts)
  security/      JWT filter + service, @CurrentUser, SecurityConfig (which paths are public)
  controller/    thin REST controllers - no business logic
  dto/           request / response records (dto/common/ApiResponse is the envelope)
  entity/        JPA entities (one per table)
  repository/    Spring Data repositories
  exception/     GlobalExceptionHandler, ResourceNotFoundException, PaymentGatewayException
  service/
    payment/     PaymentServices (send money), BankTransferServices (bank payout + failover),
                 LedgerOperations (every balance change), PaymentWebhookService,
                 PaymentReconciliationService, WalletFundingService, PaymentChannelsService
    gateway/     PaystackServices, FlutterwaveServices, OnafriqServices (raw API calls),
                 GatewayHttp (shared HTTP + error classification), GatewayServices (routing,
                 customers, recipients)
    bank/        BankAccountsServices (linked banks), BankAccountLinkService + AfriqLinkClient,
                 BankCatalogService (bank code per gateway)
    fx/          ExchangeRateService (one rate logic for everyone), ConverterService
    bill/ remit/ wallet/ card/ user/ search/ transaction/ notification/ reference/ provider/ zgrow/ qr/
    schedule/    daily directory sync of banks, bill providers, countries and currencies
    common/      Datatypes (enums), NanoIdGenerator, WebhookSignature, QRCodeService
src/main/resources/
  application.properties      all settings (secrets can be overridden by environment variables)
  db/migration/               V1-V5 tables, V6-V10 seed / test data
docs/
  PAYMENTS_AND_GATEWAYS.md    how money moves, gateways, webhooks, reconciliation
  API_CONTRACT.md             the endpoints served today
  TECHNICAL_DOCUMENTATION.md  older, general notes (parts are out of date, prefer the two files above)
```

## Rules the code follows

* **Controllers** only read the request, call one service method and wrap the result in `ApiResponse`.
* **Every balance change** goes through `LedgerOperations`: the balance, the `transactions` row and the
  `ledger_entries` rows are written in one database transaction.
* **Gateway calls** go through `GatewayHttp`, which tells the caller whether the gateway definitely refused
  (safe to refund / fail over) or the outcome is unknown (wait for the webhook).
* **Every response** is `{success, message, data}`, including errors (see `GlobalExceptionHandler`) and 401s from the JWT filter.
* Larger methods start with a one-line comment saying what they do and a `log.info`, so the log reads like the flow.

## Adding things

* New endpoint: controller method -> service method -> (repository). Return `ApiResponse.success(data, "message")`.
* New payment gateway: add `XxxServices` (raw calls), add it to the `Datatypes.PaymentGateway` enum, to the
  `switch` statements in `GatewayServices` / `BankTransferServices`, and to `GatewayServices.gatewaysFor(...)`.
* New table: add it to the matching schema file (V1-V5) while the project is pre-release; once a database exists
  that you cannot drop, add a new `V11__...` file instead of editing old ones (Flyway validates checksums).
