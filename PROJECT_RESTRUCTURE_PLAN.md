# ZentraPay Project Restructure Plan

## Current Structure Issues

- Mixed organization of routes and services
- No clear separation of concerns
- Payment implementations scattered
- Missing proper error handling and logging
- No comprehensive testing setup

## New Backend Structure

```
zentrapay-backend/
├── src/
│   ├── config/
│   │   ├── database.js
│   │   └── constants.js
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── paymentController.js
│   │   ├── userController.js
│   │   └── webhookController.js
│   ├── middleware/
│   │   ├── auth.js
│   │   ├── compliance.js
│   │   ├── errorHandler.js
│   │   └── requestLogger.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── payment.routes.js
│   │   ├── user.routes.js
│   │   └── webhook.routes.js
│   ├── services/
│   │   ├── payment/
│   │   │   ├── PaymentRouter.js
│   │   │   ├── PaystackService.js
│   │   │   ├── FlutterwaveService.js
│   │   │   ├── OnafriqService.js
│   │   │   └── HubtelService.js
│   │   ├── auth.service.js
│   │   ├── user.service.js
│   │   └── transaction.service.js
│   ├── utils/
│   │   ├── logger.js
│   │   ├── validators.js
│   │   └── helpers.js
│   └── app.js
├── migrations/
├── tests/
├── .env.example
├── package.json
└── server.js
```

## New Frontend Structure

```
zentrapay_application/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── errors/
│   ├── data/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── datasources/
│   ├── features/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── payments/
│   │   ├── wallet/
│   │   └── profile/
│   ├── services/
│   │   ├── payment_service.dart
│   │   ├── auth_service.dart
│   │   └── api_service.dart
│   └── main.dart
├── pubspec.yaml
└── README.md
```

## Payment Gateway Implementation Priority

1. **Paystack Ghana** (Primary) - Domestic payments, wallet funding, bank/mobile money payouts
2. **Flutterwave Ghana** (Secondary) - Automatic failover
3. **Onafriq** (Cross-border) - International remittances
4. **Hubtel** (Offline) - USSD for low connectivity

## Database Schema Updates

- Add payment_gateways table
- Add transaction_rails table
- Add webhook_logs table
- Add circuit_breaker_metrics table
- Enhance transactions table with rail tracking

## Next Steps

1. Restructure backend code
2. Update package.json with all dependencies
3. Implement comprehensive payment services
4. Create proper controllers and routes
5. Update frontend services
6. Create database migrations
7. Add comprehensive error handling
8. Write documentation
