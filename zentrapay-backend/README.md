# ZentraPay Backend - Multi-Rail Payment Architecture

## Overview

ZentraPay Backend is a robust, scalable payment processing platform built on a multi-rail architecture. It integrates four payment providers to ensure high availability, reliability, and seamless payment experiences across domestic, cross-border, and offline channels.

## Architecture

### Multi-Rail Payment System

```
┌─────────────────────────────────────────────────────────────┐
│                    ZentraPay Backend                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐ │
│  │   Paystack   │  │  Flutterwave │  │     Onafriq      │ │
│  │   Ghana      │  │   Ghana      │  │  (Cross-Border)  │ │
│  │  (Primary)   │  │ (Secondary)  │  │                  │ │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘ │
│         │                 │                    │           │
│         └─────────────────┼────────────────────┘           │
│                           │                                │
│                    ┌──────┴──────┐                         │
│                    │   Hubtel    │                         │
│                    │ (Offline)   │                         │
│                    └─────────────┘                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Payment Rails

1. **Primary Rail - Paystack Ghana**
   - Domestic wallet funding
   - Local collections
   - Bank/mobile money payouts
   - Primary payment processor

2. **Secondary Rail - Flutterwave Ghana**
   - Automatic failover when Paystack is unavailable
   - Secondary payment processor
   - Backup for domestic transactions

3. **Cross-Border Rail - Onafriq**
   - International remittances
   - Cross-border transfers across Africa
   - Multi-currency support

4. **Offline Rail - Hubtel/AppsNmobile**
   - USSD payment initiation
   - Offline transaction processing
   - Mobile money collections without internet

## Features

### Core Features

- **Multi-Rail Payment Processing**: Automatic routing to optimal payment provider
- **Circuit Breaker Pattern**: Automatic failover when rails are unavailable
- **Transaction Management**: Complete transaction lifecycle management
- **Webhook Handling**: Centralized webhook processing for all providers
- **Health Monitoring**: Real-time health checks for all payment rails
- **Compliance**: PCI DSS, AML/KYC compliance built-in

### Security Features

- Rate limiting (General, Payment, Authentication)
- Helmet security headers
- CORS configuration
- Request validation
- IP whitelisting (optional)
- Sensitive data sanitization
- HTTPS enforcement (production)

### Transaction Features

- Transaction creation and tracking
- Status monitoring and updates
- Transaction history and reporting
- Cancellation and refund support
- Audit logging
- Statistics and analytics

## Project Structure

```
zentrapay-backend/
├── .env.example                 # Environment variables template
├── .env                         # Environment variables (not in git)
├── package.json                 # Dependencies and scripts
├── server.js                    # Main application entry point
├── config/
│   └── db.js                    # Database configuration
├── middleware/
│   ├── requestInterceptor.js    # Request routing middleware
│   ├── authMiddleware.js        # JWT authentication
│   └── compliance.js            # Security & compliance middleware
├── services/
│   ├── paystackService.js       # Paystack API integration
│   ├── flutterwaveService.js    # Flutterwave API integration
│   ├── onafriqService.js        # Onafriq API integration
│   ├── hubtelService.js         # Hubtel API integration
│   ├── paymentRouter.js         # Multi-rail routing logic
│   └── transactionService.js    # Transaction management
├── routes/
│   ├── payments.js              # Multi-rail payment endpoints
│   ├── webhooks.js              # Webhook handlers
│   ├── authentication.js        # Auth endpoints
│   ├── userRoutes.js            # User management
│   ├── login.js                 # Login endpoints
│   ├── registering.js           # Registration endpoints
│   └── ...                      # Other application routes
└── migrations/                  # Database migrations
```

## Installation

### Prerequisites

- Node.js (v18 or higher)
- PostgreSQL (v12 or higher)
- npm or yarn

### Setup Steps

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd zentrapay-backend
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Configure environment variables**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and add your configuration:
   - Database credentials
   - JWT secret key
   - Payment provider API keys (Paystack, Flutterwave, Onafriq, Hubtel)
   - Security settings

4. **Set up database**

   ```bash
   # Create PostgreSQL database
   createdb zentrapay_db

   # Run migrations (if applicable)
   npm run migrate
   ```

5. **Start the server**

   ```bash
   # Development
   npm start

   # Production
   NODE_ENV=production npm start
   ```

The server will start on `http://localhost:3000` (or configured PORT).

## API Documentation

### Base URL

```
http://localhost:3000/api
```

### Authentication

All protected endpoints require a Bearer token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

### Payment Endpoints

#### Initiate Payment

```http
POST /api/payments/initiate
```

**Request Body:**

```json
{
  "type": "domestic_transfer",
  "amount": 100.0,
  "currency": "GHS",
  "recipient": {
    "name": "John Doe",
    "phone": "+233XXXXXXXXX",
    "email": "john@example.com",
    "bank_code": "044",
    "account_number": "1234567890"
  },
  "channel": "web",
  "description": "Payment for services",
  "metadata": {}
}
```

**Response:**

```json
{
  "success": true,
  "message": "Payment initiated successfully",
  "data": {
    "transaction_id": "uuid",
    "reference": "TXN_ABC123",
    "rail": "paystack",
    "payment_url": "https://paystack.com/pay/...",
    "ussd_code": null,
    "status": "processing"
  }
}
```

#### Verify Payment

```http
POST /api/payments/verify
```

**Request Body:**

```json
{
  "reference": "TXN_ABC123"
}
```

#### Get Payment Status

```http
GET /api/payments/status/:reference
```

#### Cancel Payment

```http
POST /api/payments/cancel
```

**Request Body:**

```json
{
  "transaction_id": "uuid",
  "reason": "User cancelled"
}
```

#### Refund Payment

```http
POST /api/payments/refund
```

**Request Body:**

```json
{
  "transaction_id": "uuid",
  "amount": 100.0,
  "reason": "Refund requested"
}
```

#### Get Transaction History

```http
GET /api/payments/history?status=success&page=1&limit=20
```

#### Get Payment Rails

```http
GET /api/payments/rails
```

**Response:**

```json
{
  "success": true,
  "data": {
    "rails": [
      {
        "id": "paystack",
        "name": "Paystack Ghana",
        "type": "primary",
        "currency": ["GHS"],
        "health": {
          "healthy": true,
          "lastCheck": 1234567890,
          "responseTime": 150
        }
      }
    ]
  }
}
```

### Webhook Endpoints

All webhooks are public endpoints but require signature verification.

#### Paystack Webhook

```http
POST /api/webhooks/paystack
Header: X-Paystack-Signature: <signature>
```

#### Flutterwave Webhook

```http
POST /api/webhooks/flutterwave
Header: Verif-Hash: <signature>
```

#### Onafriq Webhook

```http
POST /api/webhooks/onafriq
Header: X-Onafriq-Signature: <signature>
```

#### Hubtel Webhook

```http
POST /api/webhooks/hubtel
Header: X-Hubtel-Signature: <signature>
```

### Test Webhook (Development Only)

```http
POST /api/webhooks/test/:rail
```

## Configuration

### Environment Variables

See `.env.example` for complete list of configuration options.

#### Required Variables

```env
# Database
DB_USER=postgres
DB_HOST=localhost
DB_DATABASE=zentrapay_db
DB_PASSWORD=your_password
DB_PORT=5432

# Server
PORT=3000
NODE_ENV=development
BASE_URL=http://localhost:3000

# JWT
JWT_SECRET_KEY=your_jwt_secret_key
JWT_EXPIRY=24h

# Security
PASSWORD_PEPPER=your_pepper
PIN_PEPPER=your_pin_pepper
```

#### Payment Provider Configuration

```env
# Paystack (Primary)
PAYSTACK_TEST_SK=sk_test_...
PAYSTACK_TEST_PK=pk_test_...

# Flutterwave (Secondary)
FLUTTERWAVE_TEST_SK=FLWSECK_TEST_...
FLUTTERWAVE_TEST_PK=FLWPUBK_TEST_...

# Onafriq (Cross-Border)
ONAFRIQ_API_KEY=your_api_key
ONAFRIQ_API_SECRET=your_api_secret
ONAFRIQ_BASE_URL=https://api.onafriq.com/v1

# Hubtel (Offline)
HUBTEL_CLIENT_ID=your_client_id
HUBTEL_CLIENT_SECRET=your_client_secret
HUBTEL_API_KEY=your_api_key
```

## Circuit Breaker Configuration

The system uses circuit breakers to automatically failover when a payment rail is unavailable.

```env
CIRCUIT_BREAKER_THRESHOLD=5          # Failures before opening circuit
CIRCUIT_BREAKER_TIMEOUT=30000        # Timeout in ms (30s)
CIRCUIT_BREAKER_RESET_TIMEOUT=60000  # Reset timeout in ms (60s)
HEALTH_CHECK_INTERVAL=30000          # Health check interval in ms (30s)
```

### Circuit Breaker States

- **CLOSED**: Normal operation, requests are allowed
- **OPEN**: Circuit is open, requests are blocked
- **HALF_OPEN**: Testing if service has recovered

## Compliance

### PCI DSS Compliance

- No sensitive card data is logged or stored
- TLS/HTTPS enforced in production
- Sensitive field sanitization
- Secure header configuration

### AML/KYC Compliance

- Transaction amount limits:
  - Single transaction: GHS 50,000
  - Daily limit: GHS 100,000
  - Monthly limit: GHS 500,000
- Suspicious activity flagging
- Enhanced due diligence for large transactions
- Audit trail generation

## Rate Limiting

### General API

- 100 requests per 15 minutes per IP

### Payment API

- 10 requests per minute per IP

### Authentication

- 5 requests per 5 minutes per IP
- Successful requests don't count toward limit

## Monitoring and Logging

### Request Logging

All requests are logged with:

- Request ID (unique identifier)
- Timestamp
- HTTP method and URL
- Request type (paystack_route or app_server_route)
- Authentication status

### Transaction Logging

- Transaction creation
- Rail selection
- Payment initiation
- Verification attempts
- Status changes
- Webhook events

### Health Monitoring

- Real-time health checks for all payment rails
- Circuit breaker state monitoring
- Response time tracking
- Automatic failover logging

## Error Handling

### Standard Error Response

```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "details": "Detailed error information"
  }
}
```

### Common Error Codes

- `400` - Bad Request (validation errors)
- `401` - Unauthorized (invalid/missing token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `429` - Too Many Requests (rate limit exceeded)
- `500` - Internal Server Error
- `503` - Service Unavailable (all payment rails down)

## Development

### Running Tests

```bash
npm test
```

### Linting

```bash
npm run lint
```

### Database Migrations

```bash
# Run migrations
npm run migrate

# Rollback last migration
npm run migrate:rollback
```

## Production Deployment

### Prerequisites

- Node.js v18+
- PostgreSQL v12+
- SSL certificate (HTTPS)
- Environment variables configured

### Deployment Steps

1. **Set environment to production**

   ```bash
   export NODE_ENV=production
   ```

2. **Install dependencies**

   ```bash
   npm install --production
   ```

3. **Run database migrations**

   ```bash
   npm run migrate
   ```

4. **Start the server**

   ```bash
   npm start
   ```

5. **Use a process manager (recommended)**
   ```bash
   # Using PM2
   pm2 start server.js --name zentrapay-backend
   pm2 save
   pm2 startup
   ```

### Using PM2

```bash
# Install PM2 globally
npm install -g pm2

# Start application
pm2 start server.js --name zentrapay-backend

# Monitor
pm2 monit

# View logs
pm2 logs zentrapay-backend

# Restart
pm2 restart zentrapay-backend
```

### Using Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

```bash
# Build image
docker build -t zentrapay-backend .

# Run container
docker run -p 3000:3000 --env-file .env zentrapay-backend
```

## Security Considerations

1. **Never commit `.env` file** - Contains sensitive credentials
2. **Use strong JWT secret** - Minimum 32 characters, random
3. **Enable HTTPS in production** - TLS 1.2 or higher
4. **Rotate API keys regularly** - Especially for payment providers
5. **Monitor rate limits** - Adjust based on traffic patterns
6. **Review logs regularly** - Monitor for suspicious activity
7. **Keep dependencies updated** - Regular security patches
8. **Use environment-specific configs** - Separate dev/staging/production

## Troubleshooting

### Common Issues

1. **Payment initialization fails**
   - Check API keys are correct
   - Verify network connectivity to payment providers
   - Check circuit breaker status

2. **Webhooks not received**
   - Verify webhook URLs are publicly accessible
   - Check signature verification keys
   - Review webhook logs

3. **Rate limit errors**
   - Adjust rate limits in compliance.js
   - Implement request caching
   - Use exponential backoff in clients

4. **Database connection errors**
   - Verify database is running
   - Check credentials in .env
   - Ensure database exists

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit a pull request

## License

ISC License

## Support

For technical support or questions:

- Email: support@zentrapay.com
- Documentation: https://docs.zentrapay.com
- Issues: https://github.com/zentrapay/backend/issues

## Changelog

### Version 1.0.0

- Initial multi-rail payment architecture
- Integration with Paystack, Flutterwave, Onafriq, and Hubtel
- Circuit breaker pattern implementation
- Comprehensive compliance middleware
- Webhook handling for all providers
- Transaction management system
- Health monitoring and failover logic
