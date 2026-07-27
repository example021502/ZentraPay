# Zentrapay Deployment Guide

## Architecture Overview

Zentrapay uses a **triple-gateway payment architecture** with strategic failover capabilities:

### Gateway Hierarchy

1. **Paystack** (Primary Gateway)
   - Handles all Ghanaian national transactions
   - Default gateway for local payments (GHS)
   - Covers MoMo, card, and bank transfers within Ghana

2. **Onafriq** (International Gateway)
   - Targets international payment requests
   - Handles cross-border remittances
   - Supports multi-currency transactions

3. **Flutterwave** (Secondary/Failover Gateway)
   - Acts as backup for both Paystack and Onafriq
   - Ensures 99.9% uptime through intelligent failover
   - Provides redundancy for critical transactions

## Gateway Selection Logic

```java
// Transaction routing follows this priority:
1. Ghanaian National → Paystack (Primary)
2. International → Onafriq (Primary)
3. Failover (any) → Flutterwave (Secondary)
```

## Spring Boot Payment Architecture

### @Transactional Guarantees

All payment operations are wrapped in `@Transactional` boundaries to ensure:

- **Atomicity**: All-or-nothing transaction execution
- **Consistency**: Database remains in valid state
- **Isolation**: Concurrent transactions don't interfere
- **Durability**: Committed transactions persist

### Common Payment Flow

```java
@Service
@Transactional
public class PaymentService {
    public PaymentResponse processPayment(PaymentRequest request) {
        // 1. Validate request
        // 2. Select gateway based on transaction type
        // 3. Process payment via gateway
        // 4. Record transaction in database (guaranteed by @Transactional)
        // 5. Update wallet balances
        // 6. Return response
    }
}
```

## Environment Configuration

### Required Environment Variables

\`\`\`bash

# Paystack Configuration

PAYSTACK_SECRET_KEY=sk_live_xxxxxxxxxxxx
PAYSTACK_PUBLIC_KEY=pk_live_xxxxxxxxxxxx

# Flutterwave Configuration

FLUTTERWAVE_SECRET_KEY=FLWSECK-xxxxxxxxxxxx
FLUTTERWAVE_PUBLIC_KEY=FLWPUBK-xxxxxxxxxxxx

# Onafriq Configuration

ONAFRIQ_API_KEY=xxxxxxxxxxxx
ONAFRIQ_API_URL=https://api.ona friq.com/v1

# Database

DATABASE_URL=jdbc:postgresql://localhost:5432/zentrapay
DATABASE_USERNAME=zentrapay_user
DATABASE_PASSWORD=secure_password
\`\`\`

### Application Properties

\`\`\`properties

# Server Configuration

server.port=8080

# Database Configuration

spring.datasource.url=${DATABASE_URL}
spring.datasource.username=${DATABASE_USERNAME}
spring.datasource.password=${DATABASE_PASSWORD}

# JPA Configuration

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.format_sql=true

# Gateway Timeouts (milliseconds)

paystack.timeout=30000
flutterwave.timeout=30000
onafriq.timeout=45000

# Retry Configuration

payment.max.retries=3
payment.retry.delay=2000
\`\`\`

## Node.js Layer Integration

### API Endpoints (Node.js → Spring Boot)

The Node.js layer acts as an API gateway and communicates with Spring Boot:

\`\`\`javascript
// paymentsRoutes.js
router.post('/initiate', async (req, res) => {
// 1. Receive payment request from Flutter frontend
// 2. Forward to Spring Boot with authentication
// 3. Spring Boot handles gateway selection and processing
// 4. Return standardized response to frontend
});
\`\`\`

### Endpoint Alignment

| Flutter Frontend | Node.js Route                 | Spring Boot Controller           |
| ---------------- | ----------------------------- | -------------------------------- |
| `/pay/initiate`  | `POST /api/payments/initiate` | `POST /api/payments/process`     |
| `/pay/history`   | `GET /api/payments/history`   | `GET /api/payments/transactions` |
| `/pay/verify`    | `POST /api/payments/verify`   | `POST /api/payments/verify`      |

## Database Schema

### Core Tables

- \`transactions\` - All payment records (deposits, transfers, withdrawals)
- \`wallets\` - User wallet balances (fiat and crypto)
- \`cards\` - Virtual and physical card details
- \`remittances\` - Cross-border transfer records
- \`savings_accounts\` - Digital savings accounts
- \`investments\` - User investment portfolios
- \`voice_commands\` - Voice AI interaction logs
- \`challenges\` - ZGrow gamification challenges

### Transaction States

\`\`\`
PENDING → PROCESSING → COMPLETED
↓
FAILED (triggers failover)
\`\`\`

## Security Considerations

1. **API Keys**: Never commit to version control; use environment variables
2. **Authentication**: JWT tokens validated at Node.js layer before Spring Boot
3. **Encryption**: Sensitive data encrypted at rest using AES-256
4. **PCI Compliance**: Card data never stored; tokenized via payment gateways
5. **Audit Logging**: All transactions logged with timestamps and user IDs

## Failover Strategy

### Automatic Failover Process

1. Primary gateway fails (timeout or error)
2. System automatically attempts secondary gateway
3. Transaction continues without user intervention
4. User notified of gateway used for transparency

### Monitoring

- Real-time gateway health checks
- Transaction success rate monitoring
- Automatic alerting on failover events
- Performance metrics dashboard

## Development Setup

\`\`\`bash

# 1. Clone repository

git clone https://github.com/example021502/ZentraPay.git

# 2. Install dependencies

cd zentrapay-backend
npm install

# 3. Set environment variables

cp .env.example .env

# Edit .env with your API keys

# 4. Run Spring Boot

./mvnw spring-boot:run

# 5. Run Node.js layer (in another terminal)

npm start

# 6. Run Flutter app

cd zentrapay_application
flutter run
\`\`\`

## Production Deployment

### Container Configuration

- **Spring Boot**: Docker container with JVM 17
- **Node.js**: Docker container with Node.js 20
- **Database**: PostgreSQL 15 on managed service (AWS RDS / GCP Cloud SQL)
- **Redis**: For session management and caching

### Scaling

- Horizontal scaling for Node.js instances (load balancer)
- Database connection pooling (HikariCP)
- Gateway rate limiting per endpoint
- Circuit breaker pattern for external APIs

## Support

For technical issues or questions:

- Email: tech@zentrapay.com
- Slack: #zentrapay-support
- Documentation: [Internal Wiki]
