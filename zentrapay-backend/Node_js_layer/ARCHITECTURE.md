# ZentraPay Backend - Multi-Rail Payment Architecture

## Executive Summary

This document provides a comprehensive technical overview of the ZentraPay backend architecture, focusing on the multi-rail payment system that integrates four payment providers (Paystack, Flutterwave, Onafriq, and Hubtel) to ensure high availability, reliability, and optimal user experience.

## Architecture Principles

### 1. High Availability

- **Multi-rail redundancy**: Four independent payment rails ensure no single point of failure
- **Circuit breaker pattern**: Automatic failover when rails become unavailable
- **Health monitoring**: Real-time health checks every 30 seconds

### 2. Scalability

- **Service-oriented architecture**: Each payment provider is encapsulated in its own service
- **Stateless design**: Enables horizontal scaling
- **Async processing**: Webhooks processed asynchronously for better performance

### 3. Security & Compliance

- **PCI DSS compliant**: No sensitive card data stored or logged
- **AML/KYC enabled**: Transaction monitoring and limits
- **Rate limiting**: Protection against abuse
- **Webhook verification**: All webhooks cryptographically verified

### 4. Maintainability

- **Clear separation of concerns**: Services, routes, middleware are modular
- **Comprehensive logging**: Full audit trail for debugging
- **Documentation**: Extensive inline documentation and README

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Client Applications                          │
│                    (Web, Mobile, USSD, API)                          │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      API Gateway / Load Balancer                     │
│                    (SSL Termination, Rate Limiting)                  │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Express.js Application                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │              Request Interceptor Middleware                   │  │
│  │  - Request ID generation                                      │  │
│  │  - Route detection (Paystack vs App Server)                   │  │
│  │  - Request metadata enrichment                                │  │
│  │  - Logging and monitoring                                     │  │
│  └────────────────────────┬─────────────────────────────────────┘  │
│                           │                                         │
│          ┌────────────────┴────────────────┐                       │
│          │                                 │                       │
│          ▼                                 ▼                       │
│  ┌─────────────────┐           ┌─────────────────────┐            │
│  │  PayStack Proxy │           │  App Server Handler  │            │
│  │  - Auth headers │           │  - Microservice      │            │
│  │  - Proxying     │           │    routing           │            │
│  │  - Response fmt │           │  - Auth middleware    │            │
│  └────────┬────────┘           └──────────┬──────────┘            │
│           │                               │                        │
│           ▼                               ▼                        │
│  ┌─────────────────┐           ┌─────────────────────┐            │
│  │  Payment Routes │           │  Other App Routes    │            │
│  │  - Initiate     │           │  - Users             │            │
│  │  - Verify       │           │  - Profile           │            │
│  │  - Cancel       │           │  - History           │            │
│  │  - Refund       │           │  - Settings          │            │
│  └────────┬────────┘           └─────────────────────┘            │
│           │                                                         │
│           ▼                                                         │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Transaction Service                        │  │
│  │  - Transaction creation                                      │  │
│  │  - Rail selection via Payment Router                         │  │
│  │  - Status management                                         │  │
│  │  - History and audit logging                                 │  │
│  └────────────────────────┬─────────────────────────────────────┘  │
│                           │                                         │
│                           ▼                                         │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                     Payment Router                            │  │
│  │  - Rail selection logic                                       │  │
│  │  - Circuit breaker management                                 │  │
│  │  - Health monitoring                                          │  │
│  │  - Failover orchestration                                     │  │
│  └────────────────────────┬─────────────────────────────────────┘  │
│                           │                                         │
│          ┌────────────────┼────────────────┐                       │
│          │                │                │                       │
│          ▼                ▼                ▼                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   Paystack   │  │  Flutterwave │  │   Onafriq    │            │
│  │   Service    │  │   Service    │  │   Service    │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Multi-Rail Payment Flow

### 1. Payment Initiation Flow

```
Client → POST /api/payments/initiate
    ↓
Request Interceptor (route detection, logging)
    ↓
Authentication Middleware (JWT validation)
    ↓
Payment Route Handler
    ↓
Transaction Service (create transaction)
    ↓
Payment Router (select optimal rail)
    ↓
Circuit Breaker Check
    ↓
Provider Service (Paystack/Flutterwave/Onafriq/Hubtel)
    ↓
Response to Client
```

### 2. Rail Selection Logic

```
Transaction Type Check
    ├─ USSD/Offline → Hubtel
    ├─ Cross-border/International → Onafriq
    └─ Domestic
        ├─ Paystack Healthy? → Paystack (Primary)
        └─ No → Flutterwave (Secondary/Failover)
```

### 3. Webhook Processing Flow

```
Provider → POST /api/webhooks/:rail
    ↓
Signature Verification
    ↓
Immediate 200 Response (prevent timeout)
    ↓
Async Processing (setImmediate)
    ↓
Transaction Service (update status)
    ↓
Audit Logging
```

## Component Details

### Services Layer

#### 1. Payment Router Service

**Location**: `services/paymentRouter.js`

**Responsibilities**:

- Rail selection based on transaction type, currency, and health status
- Circuit breaker management for each rail
- Health monitoring and failover orchestration
- Webhook signature verification

**Key Features**:

- Circuit breaker pattern with configurable thresholds
- Automatic failover from primary to secondary rail
- Real-time health checks
- Reference-based rail detection

#### 2. Transaction Service

**Location**: `services/transactionService.js`

**Responsibilities**:

- Transaction lifecycle management
- Status tracking and updates
- Transaction history and audit logging
- Statistics and reporting

**Key Features**:

- UUID-based transaction IDs
- Unique reference generation with rail-specific prefixes
- Verification attempt tracking
- Webhook processing and status updates

#### 3. Provider Services

Each provider has its own service class:

**Paystack Service** (`services/paystackService.js`)

- Primary domestic payment rail
- Payment initialization and verification
- Transfer processing
- Bank and mobile money operations

**Flutterwave Service** (`services/flutterwaveService.js`)

- Secondary/failover rail
- Payment initialization and verification
- Bank transfers
- Mobile money payments
- Refund processing

**Onafriq Service** (`services/onafriqService.js`)

- Cross-border payment rail
- International remittances
- Multi-currency support
- Mobile money network across Africa

**Hubtel Service** (`services/hubtelService.js`)

- Offline USSD rail
- USSD payment initiation
- Mobile money collections
- Offline transaction processing

### Middleware Layer

#### 1. Request Interceptor

**Location**: `middleware/requestInterceptor.js`

**Responsibilities**:

- Intercept all incoming requests
- Generate unique request IDs
- Detect route type (Paystack vs App Server)
- Add request metadata
- Logging and monitoring

**Request Metadata**:

```javascript
{
  type: "paystack_route" | "app_server_route",
  target: "https://api.paystack.co" | "app_server",
  requiresAuth: true | false,
  originalUrl: "/api/paystack/bank",
  method: "POST"
}
```

#### 2. Compliance Middleware

**Location**: `middleware/compliance.js`

**Responsibilities**:

- Security headers (Helmet)
- Rate limiting (General, Payment, Authentication)
- PCI DSS compliance checks
- AML/KYC validation
- Request validation
- IP whitelisting

**Rate Limits**:

- General API: 100 requests/15 minutes
- Payment API: 10 requests/minute
- Authentication: 5 requests/5 minutes

### Routes Layer

#### 1. Payment Routes

**Location**: `routes/payments.js`

**Endpoints**:

- `POST /initiate` - Initiate payment
- `POST /verify` - Verify payment status
- `GET /status/:reference` - Get payment status
- `POST /cancel` - Cancel transaction
- `POST /refund` - Refund transaction
- `GET /history` - Get transaction history
- `GET /:transactionId` - Get transaction details
- `GET /rails` - Get rail health status
- `GET /statistics` - Get payment statistics

#### 2. Webhook Routes

**Location**: `routes/webhooks.js`

**Endpoints**:

- `POST /paystack` - Paystack webhooks
- `POST /flutterwave` - Flutterwave webhooks
- `POST /onafriq` - Onafriq webhooks
- `POST /hubtel` - Hubtel webhooks
- `POST /:rail` - Generic webhook handler
- `POST /test/:rail` - Test webhook (dev only)

## Circuit Breaker Pattern

### States

1. **CLOSED**: Normal operation, all requests allowed
2. **OPEN**: Circuit tripped, requests blocked
3. **HALF_OPEN**: Testing recovery, limited requests allowed

### Configuration

```javascript
{
  threshold: 5,           // Failures before opening
  timeout: 30000,         // Request timeout (ms)
  resetTimeout: 60000     // Time before retry (ms)
}
```

### Flow

```
CLOSED → (5 failures) → OPEN → (60s timeout) → HALF_OPEN
                                                    ├─ Success → CLOSED
                                                    └─ Failure → OPEN
```

## Data Models

### Transaction Object

```javascript
{
  id: "uuid",
  reference: "TXN_ABC123",
  user_id: "user_uuid",
  type: "domestic_transfer",
  status: "pending",
  amount: 100.00,
  currency: "GHS",
  fee: 2.50,
  net_amount: 97.50,
  rail: "paystack",
  provider_reference: "provider_ref",
  provider_transaction_id: "provider_txn_id",
  recipient: {},
  sender: {},
  metadata: {},
  description: "",
  channel: "web",
  ip_address: "127.0.0.1",
  user_agent: "Mozilla/...",
  created_at: "2026-06-08T00:00:00.000Z",
  updated_at: "2026-06-08T00:00:00.000Z",
  completed_at: null,
  failed_at: null,
  error_message: null,
  webhook_received: false,
  verification_attempts: 0
}
```

## Security Architecture

### Authentication

- JWT-based authentication
- Token expiration: 24 hours
- Refresh token mechanism
- Conditional auth based on route metadata

### Authorization

- Role-based access control (RBAC)
- Resource-level permissions
- Admin endpoints protected

### Data Protection

- Sensitive data redaction in logs
- No card data storage (PCI DSS)
- Encryption at rest (database)
- TLS/HTTPS in production

### Threat Protection

- Rate limiting
- CORS configuration
- Helmet security headers
- Input validation
- SQL injection prevention
- XSS protection

## Compliance Framework

### PCI DSS Compliance

- ✅ No sensitive authentication data stored
- ✅ No CVV data stored or logged
- ✅ Secure transmission (TLS)
- ✅ Regular security testing
- ✅ Access control measures
- ✅ Audit logging

### AML/KYC Compliance

- Transaction monitoring
- Amount thresholds:
  - Single: GHS 50,000
  - Daily: GHS 100,000
  - Monthly: GHS 500,000
- Suspicious activity flagging
- Enhanced due diligence
- Audit trail generation

## Monitoring and Observability

### Request Monitoring

- Unique request IDs
- Timestamp tracking
- Route type detection
- Response time measurement
- Error tracking

### Transaction Monitoring

- Transaction lifecycle events
- Rail selection tracking
- Payment initiation logging
- Verification attempt logging
- Status change events

### Health Monitoring

- Real-time rail health checks
- Circuit breaker state tracking
- Response time monitoring
- Automatic failover logging
- Provider API status

## Performance Considerations

### Optimization Strategies

1. **Connection Pooling**: Database connections pooled
2. **Caching**: Frequently accessed data cached
3. **Async Processing**: Webhooks processed asynchronously
4. **Circuit Breaker**: Prevents cascade failures
5. **Health Checks**: Efficient periodic checks

### Scalability

- Horizontal scaling supported (stateless)
- Database can be scaled independently
- Microservices can be added easily
- Load balancer compatible

## Disaster Recovery

### Failover Mechanisms

1. **Primary Rail Failure**: Automatic switch to secondary
2. **Secondary Rail Failure**: Error returned to client
3. **Database Failure**: Connection retry logic
4. **Provider API Outage**: Circuit breaker opens

### Data Backup

- Database backups (regular)
- Transaction logs persisted
- Audit trail maintained
- Webhook event logging

## Future Enhancements

### Phase 2

1. **Database Integration**: Replace in-memory storage with PostgreSQL
2. **Caching Layer**: Redis for session and data caching
3. **Message Queue**: RabbitMQ/Kafka for async processing
4. **API Versioning**: Support multiple API versions
5. **GraphQL API**: Alternative to REST

### Phase 3

1. **Machine Learning**: Fraud detection models
2. **Advanced Analytics**: Transaction pattern analysis
3. **Multi-currency Wallet**: Support for multiple currencies
4. **Recurring Payments**: Subscription billing
5. **Mobile Money Direct**: Direct mobile money integrations

## Conclusion

The ZentraPay backend architecture provides a robust, scalable, and secure foundation for a modern payment processing platform. The multi-rail design ensures high availability and reliability, while the comprehensive compliance and security features meet regulatory requirements.

The modular design allows for easy maintenance and future enhancements, positioning ZentraPay for growth and expansion across the African continent and beyond.
