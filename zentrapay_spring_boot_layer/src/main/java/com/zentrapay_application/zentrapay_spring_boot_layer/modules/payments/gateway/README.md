# Payment Gateway Architecture

## Overview

The ZentraPay payment system supports three payment gateways with intelligent routing and automatic failover:

1. **Paystack** - PRIMARY gateway for all Ghanaian national transactions (GHS)
2. **Onafriq** - INTERNATIONAL gateway for cross-border African transfers
3. **Flutterwave** - FAILOVER gateway for both national and international transactions

## Gateway Roles

### Paystack (Primary - Ghana)

- **Primary for**: All Ghanaian national transactions (GHS currency)
- **Use cases**:
  - Mobile money transfers to Ghanaian networks (MTN, Vodafone, AirtelTigo)
  - Bank transfers via GHIPSS network
  - All disbursements within Ghana
- **Advantages**: Lowest fees for Ghana, excellent mobile money support

### Onafriq (International)

- **Primary for**: Cross-border/international transactions
- **Use cases**:
  - Remittances across African borders
  - International money transfers
  - Multi-country transactions
- **Advantages**: Pan-African coverage, unified API for multiple mobile money networks

### Flutterwave (Failover)

- **Secondary for**: Both national and international transactions
- **Use cases**:
  - Backup when primary gateways fail
  - Fallback when primary gateways don't support specific currencies
- **Advantages**: Broadest currency and country support across Africa

## Transaction Flow

### Internal Wallet-to-Wallet Transfer

```
Client → Node.js → Spring Boot → Database
                                    ├─ Debit sender wallet
                                    ├─ Credit receiver wallet
                                    └─ Save transaction record (ZentraPayInternal)
```

**No external gateway involved** - all processing is internal.

### External Disbursement (National - GHS)

```
Client → Node.js → Spring Boot → Gateway Factory
                                    ├─ Try Paystack (primary)
                                    └─ Fallback to Flutterwave if Paystack fails

                                    ├─ Debit sender wallet
                                    ├─ Gateway processes transfer
                                    └─ Save transaction record (@Transactional)
```

### External Disbursement (International)

```
Client → Node.js → Spring Boot → Gateway Factory
                                    ├─ Try Onafriq (primary)
                                    └─ Fallback to Flutterwave if Onafriq fails

                                    ├─ Debit sender wallet
                                    ├─ Gateway processes transfer
                                    └─ Save transaction record (@Transactional)
```

## Gateway Routing Logic

The `PaymentGatewayFactory` determines the optimal gateway based on:

1. **Transaction type** (`isInternational` flag)
2. **Currency** (GHS, NGN, USD, etc.)
3. **Gateway availability** (operational status check)
4. **Currency support** (gateway capability check)

### Decision Matrix

| Transaction Type | Currency | Primary Gateway | Failover Gateway |
| ---------------- | -------- | --------------- | ---------------- |
| National         | GHS      | Paystack        | Flutterwave      |
| National         | NGN, KES | Paystack        | Flutterwave      |
| International    | Any      | Onafriq         | Flutterwave      |

## Transactional Guarantee

All payment operations are wrapped in `@Transactional` to ensure atomicity:

### What This Means:

1. **Wallet updates** (debit/credit) and **transaction history** are saved in ONE database transaction
2. If **ANY** step fails:
   - Wallet changes are automatically rolled back
   - Transaction record is NOT saved
   - Caller receives an exception
3. If **ALL** gateways fail:
   - Sender is re-credited before exception is thrown
   - No transaction record is created

### Example Flow:

```java
@Transactional
public PaymentsResponseDTO makeDisbursement(DisbursementRequestDTO request) {
    // Step 1: Debit sender wallet
    userWalletsRepository.debit(userId, currency, amount);

    // Step 2: Try gateway (with failover)
    PaymentsResponseDTO response = gatewayFactory.processDisbursement(request);

    // Step 3: Save transaction record
    saveTransaction(...);

    // ALL THREE succeed = COMMIT
    // ANY failure    = ROLLBACK
}
```

## Component Architecture

```
PaymentGatewayService (Interface)
├── processDisbursement()
├── getGatewayName()
├── supportsCurrency()
└── isOperational()

Implementations:
├── PaystackGatewayService (wraps existing PaystackService)
├── OnafriqGatewayService (new implementation)
└── FlutterwaveGatewayService (new implementation)

PaymentGatewayFactory (Routes requests)
├── Resolves gateway chain based on transaction type
├── Tries gateways in sequence
├── Handles failover automatically
└── Returns first successful response

PaymentsServices (Main service)
├── @Transactional on all methods
├── makePaymentToAppUser() (internal transfers)
└── makeDisbursement() (external disbursements via factory)
```

## API Endpoints

### Spring Boot Backend

- `POST /api/payments/internal` - Internal wallet-to-wallet transfer
- `POST /api/payments/disbursement` - External disbursement (national/international)

### Node.js Layer (Proxies)

- `POST /api/payments/internal` - Forwards to Spring Boot `/api/payments/internal`
- `POST /api/payments/disbursement` - Forwards to Spring Boot `/api/payments/disbursement`

**Note**: The Node.js layer does NOT process payments directly. It acts as a proxy/API gateway that forwards requests to Spring Boot. All payment processing logic resides in Spring Boot.

## Configuration

### Spring Boot (application.properties)

```properties
# Paystack (Primary - Ghana)
paystack.secret-key=your_paystack_secret_key
paystack.base-url=https://api.paystack.co

# Flutterwave (Failover)
flutterwave.secret-key=your_flutterwave_secret_key
flutterwave.base-url=https://api.flutterwave.com/v1

# Onafriq (International)
onafriq.secret-key=your_onafriq_secret_key
onafriq.base-url=https://api.onafriq.com/v1
onafriq.partner-id=your_partner_id
```

## Monitoring & Logging

All gateway operations include comprehensive logging:

- `[PAYMENT_SERVICE]` - Main payment service operations
- `[GATEWAY_FACTORY]` - Gateway routing decisions
- `[PAYSTACK_GATEWAY]` - Paystack-specific operations
- `[ONAFRIQ_GATEWAY]` - Onafriq-specific operations
- `[FLUTTERWAVE_GATEWAY]` - Flutterwave-specific operations
- `[SPRING_CTRL]` - Controller layer

Logs include:

- Transaction reference
- User ID
- Amount and currency
- Gateway used
- Status and errors

## Future Enhancements

1. **Health Checks**: Implement actual API health checks for each gateway
2. **Circuit Breaker**: Add circuit breaker pattern to prevent cascading failures
3. **Metrics**: Track success rates, latency, and failover frequency per gateway
4. **Dynamic Configuration**: Allow gateway routing rules to be updated without code changes
5. **Currency Mapping**: More sophisticated currency-to-gateway mapping

## Error Handling

### Gateway Failure

- Primary gateway fails → Automatic failover to next gateway
- All gateways fail → Sender re-credited, exception thrown
- Transaction record NOT saved if gateway fails

### Transaction Rollback

- Wallet debit succeeds but transaction save fails → Automatic rollback
- Gateway processing fails → Sender re-credited within transaction
- Any exception → Full rollback of all changes

## Testing Strategy

1. **Unit Tests**: Test each gateway service independently
2. **Integration Tests**: Test gateway factory routing logic
3. **Transaction Tests**: Verify rollback behavior
4. **Failover Tests**: Simulate gateway failures and verify failover
5. **End-to-End Tests**: Test complete payment flow through all layers
