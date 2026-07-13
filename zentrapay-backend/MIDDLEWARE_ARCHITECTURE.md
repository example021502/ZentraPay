# Request Interceptor Middleware Architecture

## Overview

The request interceptor middleware intercepts all incoming requests from the frontend and intelligently routes them to either:

1. **PayStack API** - For payment-related operations
2. **App Server** - For internal application logic

## Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Incoming Request                          │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              requestInterceptor (Global)                     │
│  - Generates unique request ID                               │
│  - Determines request type (PayStack vs App Server)          │
│  - Adds request metadata                                     │
│  - Logs request for debugging                                │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    Route Detection                           │
│  Is it a PayStack route? (/api/paystack, /api/payments/*)  │
└───────────────────────┬─────────────────────────────────────┘
                        │
         ┌──────────────┴──────────────┐
         │                             │
         ▼ YES                         ▼ NO
┌──────────────────────┐   ┌──────────────────────┐
│   payStackProxy      │   │  appServerHandler    │
│  - Adds PayStack     │   │  - Adds app server   │
│    auth headers      │   │    config            │
│  - Proxies request   │   │  - Checks for        │
│    to PayStack API   │   │    microservices     │
│  - Returns PayStack  │   │  - Routes to handler │
│    response to client│   │    or proxies to     │
└──────────────────────┘   │    microservice       │
                           └──────────────────────┘
```

## Components

### 1. requestInterceptor (Global Middleware)

**Location:** `middleware/requestInterceptor.js`

**Purpose:** First middleware that intercepts ALL incoming requests

**Functionality:**

- Generates unique request ID for tracking
- Determines if request is for PayStack or App Server
- Sets `req.requestMetadata` with routing information
- Adds PayStack configuration if needed
- Logs request details for debugging

**Request Metadata Structure:**

```javascript
{
  type: "paystack_route" | "app_server_route",
  target: "https://api.paystack.co" | "app_server",
  requiresAuth: true | false,
  originalUrl: "/api/paystack/bank",
  method: "POST"
}
```

### 2. payStackProxy (PayStack Route Handler)

**Purpose:** Handles all requests to PayStack-related routes

**Routes Handled:**

- `/api/paystack/*`
- `/api/payments/external`

**Functionality:**

- Receives request from frontend
- Adds PayStack authentication headers
- Proxies request to PayStack API (`https://api.paystack.co`)
- Returns formatted PayStack response to client

**Flow:**

```
Frontend → /api/paystack/bank
    ↓
requestInterceptor (detects PayStack route)
    ↓
payStackProxy
    ↓
PayStack API (https://api.paystack.co/bank)
    ↓
Response returned to Frontend
```

### 3. appServerHandler (App Server Route Handler)

**Purpose:** Handles all internal app server requests

**Routes Handled:**

- All routes except PayStack routes
- Can proxy to microservices if configured

**Functionality:**

- Processes app server requests
- Checks for microservice routing (AI, Voice, Fraud services)
- Adds app server configuration
- Continues to route handlers or proxies to microservices

**Microservice Support:**

```javascript
const microserviceRoutes = {
  "/api/ai": process.env.AI_SERVICE_URL,
  "/api/voice": process.env.VOICE_SERVICE_URL,
  "/api/fraud": process.env.FRAUD_SERVICE_URL,
};
```

### 4. routeValidator (Validation Middleware)

**Purpose:** Validates that requests have proper metadata

**Functionality:**

- Ensures `req.requestMetadata` exists
- Validates request type is valid
- Logs validation status

## Integration in server.js

### Middleware Chain Order

```javascript
// 1. CORS
app.use(cors());

// 2. JSON Parser
app.use(express.json());

// 3. Request Interceptor (GLOBAL - Must be first)
app.use(requestInterceptor);

// 4. Request Logger
app.use((req, res, next) => {
  console.log(`[${req.method}] ${req.url}`);
  next();
});

// 5. PayStack Routes (Proxied to PayStack API)
app.use("/api/paystack", payStackProxy);

// 6. App Server Routes (Processed internally)
// Public routes
app.use("/api/login", loginRoute);
app.use("/api/register", registeringRoute);

// Protected routes (with conditional auth)
app.use("/api/users", authMiddleware, userRoutes);
// ... etc
```

## Authentication Flow

The middleware supports conditional authentication based on the route:

```javascript
app.use(
  "/api/users",
  (req, res, next) => {
    // Only apply auth if route requires it
    if (req.requestMetadata.requiresAuth) {
      return authenticateToken(req, res, next);
    }
    next();
  },
  userRoutes,
);
```

## Usage Examples

### Example 1: PayStack Route Request

**Request:**

```bash
POST /api/paystack/bank
Headers: Authorization: Bearer <token>
Body: { "user_id": 123 }
```

**Processing:**

1. `requestInterceptor` detects `/api/paystack` → type: "paystack_route"
2. `payStackProxy` intercepts and proxies to `https://api.paystack.co/bank`
3. PayStack API responds with bank list
4. Response formatted and returned to frontend

**Console Output:**

```
[2026-06-08T00:35:00.000Z] [req_1717724100000_abc123] POST /api/paystack/bank | Type: paystack_route | Auth Required: true
[2026-06-08T00:35:00.100Z] [req_1717724100000_abc123] Proxying to PayStack API: POST /bank
```

### Example 2: App Server Route Request

**Request:**

```bash
GET /api/users/profile
Headers: Authorization: Bearer <token>
```

**Processing:**

1. `requestInterceptor` detects `/api/users` → type: "app_server_route"
2. `authenticateToken` validates JWT token
3. Route handler processes request
4. Response returned to frontend

**Console Output:**

```
[2026-06-08T00:35:00.000Z] [req_1717724100000_xyz789] GET /api/users/profile | Type: app_server_route | Auth Required: true
[2026-06-08T00:35:00.100Z] [req_1717724100000_xyz789] Routing to App Server
```

## Configuration

### Environment Variables

```env
# PayStack Configuration
PAYSTACK_TEST_SK=sk_test_22d375cb6070b2fb9c3934d6359f424208c62a1a
PAYSTACK_TEST_PK=pk_test_xxxxxxxxxxxxx

# Microservice URLs (Optional)
AI_SERVICE_URL=http://localhost:3001
VOICE_SERVICE_URL=http://localhost:3002
FRAUD_SERVICE_URL=http://localhost:3003

# Base URL
BASE_URL=http://localhost:3000
PORT=3000
```

## Benefits

1. **Centralized Request Handling:** All requests go through one interceptor
2. **Clear Separation:** PayStack vs App Server logic is clearly separated
3. **Request Tracking:** Unique IDs for debugging and monitoring
4. **Flexible Routing:** Easy to add new PayStack routes or microservices
5. **Conditional Auth:** Authentication applied based on route requirements
6. **Logging:** Comprehensive request logging for debugging

## Adding New Routes

### Adding a New PayStack Route

```javascript
// In middleware/requestInterceptor.js
const PAYSTACK_ROUTES = [
  "/api/paystack",
  "/api/payments/external",
  "/api/payments/new-external-route", // Add new route
];

// In server.js - Already handled by payStackProxy
app.use("/api/paystack", payStackProxy);
```

### Adding a New App Server Route

```javascript
// In middleware/requestInterceptor.js
const PROTECTED_ROUTES = [
  // ... existing routes
  "/api/new-feature", // Add new route
];

// In server.js
app.use(
  "/api/new-feature",
  (req, res, next) => {
    if (req.requestMetadata.requiresAuth) {
      return authenticateToken(req, res, next);
    }
    next();
  },
  newFeatureRoute,
);
```

### Adding a New Microservice

```javascript
// In middleware/requestInterceptor.js
const microserviceRoutes = {
  "/api/ai": process.env.AI_SERVICE_URL,
  "/api/voice": process.env.VOICE_SERVICE_URL,
  "/api/fraud": process.env.FRAUD_SERVICE_URL,
  "/api/new-service": process.env.NEW_SERVICE_URL, // Add new microservice
};
```

## Testing

Run the test server to see the middleware in action:

```bash
node test_request_interceptor.js
```

Then test with:

```bash
# Test PayStack route
curl -X POST http://localhost:3001/api/paystack/test -H "Content-Type: application/json" -d '{}'

# Test App Server route
curl http://localhost:3001/api/users/test

# Test with auth header
curl http://localhost:3001/api/users/test -H "Authorization: Bearer test_token"
```

## Monitoring

The middleware provides comprehensive logging:

```
[2026-06-08T00:35:00.000Z] [req_1717724100000_abc123] POST /api/paystack/bank | Type: paystack_route | Auth Required: true
[2026-06-08T00:35:00.100Z] [req_1717724100000_abc123] Proxying to PayStack API: POST /bank
[2026-06-08T00:35:00.200Z] [req_1717724100000_xyz789] GET /api/users/profile | Type: app_server_route | Auth Required: true
[2026-06-08T00:35:00.300Z] [req_1717724100000_xyz789] Routing to App Server
[2026-06-08T00:35:00.400Z] [req_1717724100000_xyz789] Request validated - Type: app_server_route
```

## Error Handling

### PayStack API Errors

```javascript
{
  "success": false,
  "message": "PayStack API request failed",
  "error": { /* PayStack error details */ }
}
```

### Microservice Errors

```javascript
{
  "success": false,
  "message": "Microservice request failed",
  "error": "Error message"
}
```

### Validation Errors

```javascript
{
  "success": false,
  "message": "Request interceptor not properly configured",
  "error": "Missing request metadata"
}
```

## Future Enhancements

1. **Rate Limiting:** Add rate limiting per route type
2. **Caching:** Cache PayStack responses where appropriate
3. **Circuit Breaker:** Add circuit breaker for microservices
4. **Request/Response Transformation:** Transform data between frontend and APIs
5. **Metrics:** Add Prometheus/metrics for monitoring
6. **Request Logging to Database:** Persist request logs for audit trail
