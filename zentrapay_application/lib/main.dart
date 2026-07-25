import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Secure storage package for sensitive tokens
import 'package:privy_flutter/privy_flutter.dart'
    as privy_sdk; // Official Privy Flutter SDK package
import 'package:toastification/toastification.dart'; // Notification package for toast alerts
import 'package:zentrapay_application/core/theme/navigation_bar/responsive_navigation.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/features/auth/login_screen.dart';
import 'package:zentrapay_application/features/home/external_payment_screen.dart';
import 'package:zentrapay_application/features/home/pay.dart';
import 'package:zentrapay_application/features/home/zentrapay_splash_screen_main.dart';
import 'package:zentrapay_application/features/payanywhere/payanywhere_screen.dart';
import 'package:zentrapay_application/features/payments/ai_assistance_screen.dart';
import 'package:zentrapay_application/features/payments/converter_screen.dart';
import 'package:zentrapay_application/features/payments/fraud_detection_screen.dart';
import 'package:zentrapay_application/features/payments/instant_transfer_screen.dart';
import 'package:zentrapay_application/features/payments/liquidity_hub_screen.dart';
import 'package:zentrapay_application/features/payments/milestones_screen.dart';
import 'package:zentrapay_application/features/payments/voice_recording_screen.dart';
import 'package:zentrapay_application/features/payments/zinvest_screen.dart';
import 'package:zentrapay_application/features/profile/profile_screen.dart';
import 'package:zentrapay_application/features/profile/settings_screen.dart';
import 'package:zentrapay_application/features/secure/secure_screen.dart';
import 'package:zentrapay_application/features/zbanking/zbanking_screen.dart';
import 'package:zentrapay_application/features/zgrow/zgrow_screen.dart';
import 'package:zentrapay_application/features/zinvest/zinvest_screen.dart'
    as zinvest_new;
import 'package:zentrapay_application/features/zpay/zpay_screen.dart';
import 'package:zentrapay_application/features/zremit/zremit_screen.dart';
import 'package:zentrapay_application/features/zvoice/zvoice_screen.dart';

import 'features/auth/onboarding_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/verify_screen.dart';

// Declare a globally accessible instance of the Privy client engine
// This will be initialized by api_auth_services.dart with custom auth support
late final privy_sdk.Privy privyClient;

void main() async {
  // Ensure that plugin services are initialized properly before running the application
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load your configuration keys from the local .env file into memory
    await dotenv.load(fileName: ".env");
    await SecureStorageService.init();
    // Initialize Privy with custom auth configuration
    // This is done here to ensure it's initialized before any auth operations
    final privyConfig = privy_sdk.PrivyConfig(
      appId: dotenv.get('PRIVY_APP_ID', fallback: ''),
      appClientId: dotenv.get('PRIVY_CLIENT_ID', fallback: ''),
      customAuthConfig: privy_sdk.LoginWithCustomAuthConfig(
        tokenProvider: () async => SecureStorageService.getToken(),
      ),
    );

    // Initialize the global Privy instance with custom auth support
    privyClient = privy_sdk.Privy.init(config: privyConfig);
  } catch (e) {
    // Fallback error logging if the environmental file fails to load or cannot be found
    print("WARNING:: Could not load configuration infrastructure keys: $e");
  }

  // Launch the core application widget
  runApp(const MainApp());
}

// Global UI theme colors matching the Zentrapay design system guidelines
class AppColors {
  static const Color main = Color(0xFFF21773);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF210163);
  static const Color textBlack = Color(0xFF000000);
  static const Color purple = Color(0xFF661E98);
  static const Color blue = Color(0xFF396FD4);
  static const Color green = Color(0xFF06881C);
  static const Color orange = Color(0xFFF79E1B);
  static Color lightGrey = const Color(0x80808080);
}

// Reusable text styling components used throughout application screens
class AppStyles {
  static final TextStyle header = const TextStyle(
    fontWeight: FontWeight.bold,
    color: AppColors.textBlack,
    fontSize: 15,
  );
  static final TextStyle text = const TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    color: AppColors.textBlack,
    height: 1.5,
  );
}

// Root application widget setting up routing, wrapping alerts, and configuring initialization targets
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // Global static instance of storage so your login screen can write tokens to it easily
  static const secureStorage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    // Wrap the app tree with ToastificationWrapper to handle interactive alerts Globally
    return ToastificationWrapper(
      child: Center(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
          // Sets the application to load into the splash screen initially upon startup
          home: const ZentrapaySplashScreenMain(),
          // Route settings interceptor to extract dynamically passed arguments safely
          onGenerateRoute: (settings) {
            if (settings.name == '/home') {
              final args =
                  settings.arguments
                      as Map<String, dynamic>; // Extract the token map safely
              return MaterialPageRoute(
                builder: (context) => ResponsiveNavigation(userData: args),
              );
            }
            return null; // Let the standard static routes table handle other navigation paths
          },
          // Collection of static named routes for navigation redirection rules
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/verify': (context) => const VerifyScreen(),
            '/zinvest': (context) => const ZInvestScreen(),
            '/pay': (context) => const PaySectionMain(),
            '/instant_transfer': (context) => const InstantTransferScreen(),
            '/ai_assistance': (context) => const AIAssistanceScreen(),
            '/converter': (context) => const ConverterScreen(),
            '/milestones': (context) => const MilestonesScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/liquidity_hub': (context) => const LiquidityHubScreen(),
            '/voice_recording': (context) => const VoiceRecordingScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/fraud_detection': (context) => const FraudDetectionScreen(),
            '/external_payment': (context) => const ExternalPaymentScreen(),
            '/zpay': (context) => const ZPayScreen(),
            '/zbanking': (context) => const ZBankingScreen(),
            '/zremit': (context) => const ZRemitScreen(),
            '/zvoice': (context) => const ZVoiceScreen(),
            '/zinvest_new': (context) => const zinvest_new.ZInvestScreen(),
            '/zgrow_new': (context) => const ZGrowScreen(),
            '/pay_anywhere': (context) => const PayAnywhereScreen(),
            '/secure': (context) => const SecureScreen(),
          },
        ),
      ),
    );
  }
}
