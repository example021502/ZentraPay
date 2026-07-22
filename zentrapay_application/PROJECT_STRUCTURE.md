# ZentraPay Application - Project Structure

## Overview

This document outlines the complete project structure for the ZentraPay application, including all newly created sections and their organization.

## Folder Structure

### Frontend (Flutter/Dart)

```
lib/
├── ai_assistance/                    # AI Chat Assistance Section
│   ├── ai_assistance_screen.dart    # Main UI screen (120 lines)
│   └── ai_assistance_service.dart   # API service layer
│
├── converter/                        # Smart Currency Converter Section
│   ├── converter_screen.dart        # Main UI screen (450 lines)
│   └── converter_service.dart       # API service layer
│
├── milestones/                       # Goals & Milestones Section
│   ├── milestones_screen.dart       # Main UI screen (280 lines)
│   └── milestones_service.dart      # API service layer
│
├── profile/                          # User Profile & Wallet Section
│   ├── profile_screen.dart          # Main UI screen (450 lines)
│   └── profile_service.dart         # API service layer
│
├── liquidity_hub/                    # Global Liquidity Hub Section
│   ├── liquidity_hub_screen.dart    # Main UI screen (580 lines)
│   └── liquidity_hub_service.dart   # API service layer
│
├── voice_recording/                  # Voice Recording Section
│   ├── voice_recording_screen.dart  # Main UI screen (100 lines)
│   └── voice_recording_service.dart # API service layer
│
├── settings/                         # Settings & Security Section
│   ├── settings_screen.dart         # Main UI screen (320 lines)
│   └── settings_service.dart        # API service layer
│
├── fraud_detection/                  # Fraud Detection Section
│   ├── fraud_detection_screen.dart  # Main UI screen (280 lines)
│   └── fraud_detection_service.dart # API service layer
│
├── main.dart                         # Main app entry point with routes
├── navigation_bar/                   # Global navigation bar
│   └── navigation_bar_main.dart     # Bottom navigation component
│
└── [existing folders...]            # Other existing modules
```

### Backend (Node.js/Express)

```
zentrapay-backend/
├── server.js                         # Main server with all route mountings
├── routes/
│   ├── aiAssistance.js              # AI chat endpoints
│   ├── converter.js                 # Currency conversion endpoints
│   ├── milestones.js                # Goals management endpoints
│   ├── profile.js                   # User profile endpoints
│   ├── liquidityHub.js              # Liquidity hub endpoints
│   ├── voiceRecording.js            # Voice recording endpoints
│   ├── settings.js                  # Settings & security endpoints
│   ├── fraudDetection.js            # Fraud detection endpoints
│   └── [existing routes...]         # Other existing routes
│
└── [existing files...]              # Other backend files
```

## Navigation Routes

All new sections are accessible via the following routes:

| Route              | Screen               | Description                 |
| ------------------ | -------------------- | --------------------------- |
| `/ai_assistance`   | AIAssistanceScreen   | Chat with AI assistant      |
| `/converter`       | ConverterScreen      | Smart currency converter    |
| `/milestones`      | MilestonesScreen     | Goals and savings targets   |
| `/profile`         | ProfileScreen        | User profile and wallet     |
| `/liquidity_hub`   | LiquidityHubScreen   | Global liquidity management |
| `/voice_recording` | VoiceRecordingScreen | Voice command interface     |
| `/settings`        | SettingsScreen       | Security and app settings   |
| `/fraud_detection` | FraudDetectionScreen | Fraud monitoring and alerts |

## API Endpoints

### AI Assistance

- `POST /api/ai/chat` - Send message to AI
- `GET /api/ai/history` - Get chat history

### Converter

- `GET /api/converter/rates` - Get exchange rates
- `POST /api/converter/convert` - Convert currency
- `GET /api/converter/history` - Get conversion history

### Milestones

- `GET /api/milestones/goals` - Get all goals
- `POST /api/milestones/goals` - Create new goal
- `PUT /api/milestones/goals/:id` - Update goal
- `DELETE /api/milestones/goals/:id` - Delete goal

### Profile

- `GET /api/profile/user` - Get user profile
- `GET /api/profile/wallet` - Get wallet info
- `GET /api/profile/banks` - Get linked banks
- `POST /api/profile/qr/generate` - Generate QR code

### Liquidity Hub

- `GET /api/liquidity/profile` - Get liquidity profile
- `GET /api/liquidity/trend` - Get financial trend
- `GET /api/liquidity/risks` - Get top risks
- `GET /api/liquidity/alerts` - Get recent alerts

### Voice Recording

- `POST /api/voice/start` - Start recording
- `POST /api/voice/stop` - Stop recording
- `POST /api/voice/process` - Process voice command

### Settings

- `GET /api/settings/security-score` - Get security score
- `POST /api/settings/biometric` - Update biometric auth
- `POST /api/settings/fraud-protection` - Update fraud protection
- `GET /api/settings/protection-history` - Get protection history

### Fraud Detection

- `GET /api/fraud/status` - Get fraud status
- `GET /api/fraud/alerts` - Get fraud alerts
- `GET /api/fraud/monitoring` - Get monitoring items
- `POST /api/fraud/report` - Report fraud

## Design Features

### UI/UX Improvements

- **Consistent Color Scheme**: All sections use the ZentraPay brand colors (Main: #F21773, Primary: #FFFFFF, Purple: #661E98)
- **Responsive Design**: All screens are optimized for mobile devices
- **Card-Based Layout**: Modern card-based UI with rounded corners
- **Smooth Animations**: Animated transitions and interactions
- **Intuitive Navigation**: Clear back buttons and navigation patterns

### Code Organization

- **Maintainability**: Each file is kept under 100 lines for easy maintenance
- **Separation of Concerns**: UI screens separated from API services
- **Reusable Components**: Common widgets and patterns reused across sections
- **Type Safety**: Proper typing for all data structures

## Global Liquidity Hub Features

Based on the PDF specification, the Global Liquidity Hub includes:

1. **Unified Treasury Wallet** - Manage multiple currencies from single dashboard
2. **Just-In-Time Liquidity** - Convert and settle funds only when required
3. **AI-Powered Liquidity Optimization** - Forecast liquidity needs
4. **Capital Efficiency Score** - Measure trapped liquidity and efficiency
5. **Global Liquidity Marketplace** - Generate yield on idle funds
6. **Multi-Country Settlement Engine** - Seamless global payments

## Getting Started

### Prerequisites

- Flutter SDK
- Node.js & npm
- MongoDB (for production)

### Running the Backend

```bash
cd zentrapay-backend
npm install
npm start
```

### Running the Frontend

```bash
flutter pub get
flutter run
```

## Navigation Integration

To navigate to any section from existing screens:

```dart
// Navigate to AI Assistance
Navigator.pushNamed(context, '/ai_assistance');

// Navigate to Converter
Navigator.pushNamed(context, '/converter');

// Navigate to Milestones
Navigator.pushNamed(context, '/milestones');

// Navigate to Profile
Navigator.pushNamed(context, '/profile');

// Navigate to Liquidity Hub
Navigator.pushNamed(context, '/liquidity_hub');

// Navigate to Voice Recording
Navigator.pushNamed(context, '/voice_recording');

// Navigate to Settings
Navigator.pushNamed(context, '/settings');

// Navigate to Fraud Detection
Navigator.pushNamed(context, '/fraud_detection');
```

## Notes

- All API endpoints currently return mock data for demonstration
- The global navigation bar (Home, ZRemit, ZGrow, ZBank) remains unchanged
- Each section maintains the ZentraPay brand identity and color scheme
- All screens follow Material Design 3 guidelines
- Code is organized for easy scalability and maintenance

## Future Enhancements

- Integration with real AI/ML services for chat assistance
- Real-time exchange rate updates
- Push notifications for fraud alerts
- Biometric authentication implementation
- Voice recognition integration
- Advanced analytics and reporting
