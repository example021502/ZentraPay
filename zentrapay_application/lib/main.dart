import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:privy_flutter/privy_flutter.dart'
    as privy_sdk; // Official Privy Flutter SDK package
import 'package:toastification/toastification.dart'; // Notification package for toast alerts
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/material_theme.dart';
import 'package:zentrapay_application/core/theme/navigation_bar/responsive_navigation.dart';
import 'package:zentrapay_application/core/utils/LoadingOverlay.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/features/auth/login_screen.dart';
import 'package:zentrapay_application/features/home/HomePayments/pay.dart';
import 'package:zentrapay_application/features/home/external_payment_screen.dart';
import 'package:zentrapay_application/features/home/zentrapay_splash_screen_main.dart';
import 'package:zentrapay_application/features/payanywhere/payanywhere_screen.dart';
import 'package:zentrapay_application/features/payments/ai_assistance_screen.dart';
import 'package:zentrapay_application/features/payments/converter_screen.dart';
import 'package:zentrapay_application/features/payments/fraud_detection_screen.dart';
import 'package:zentrapay_application/features/payments/instant_transfer_screen.dart';
import 'package:zentrapay_application/features/payments/liquidity_hub_screen.dart';
import 'package:zentrapay_application/features/payments/milestones_screen.dart';
import 'package:zentrapay_application/features/payments/voice_recording_screen.dart';
import 'package:zentrapay_application/features/profile/profile_screen.dart';
import 'package:zentrapay_application/features/zbanking/zbanking_screen.dart';
import 'package:zentrapay_application/features/zgrow/zgrow_screen.dart';
import 'package:zentrapay_application/features/zinvest/zinvest_screen.dart';
import 'package:zentrapay_application/features/zremit/zremit_screen.dart';
import 'package:zentrapay_application/features/zvoice/zvoice_screen.dart';

import 'features/auth/onboarding_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/verify_screen.dart';

// Declare a globally accessible instance of the Privy client engine.
// Nullable + only initialised on mobile (Android/iOS) where the native
// plugin exists. Web/Windows/Desktop have no privy_flutter implementation,
// so initialising unconditionally crashes those targets with
// MissingPluginException.
privy_sdk.Privy? privyClient;

void main() async {
  // Ensure that plugin services are initialized properly before running the application
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load your configuration keys from the local .env file into memory
    await dotenv.load(fileName: ".env");
    await SecureStorageService.init();
    // Privy native SDK only exists on Android/iOS. Skip on web/desktop so
    // `flutter run -d chrome/windows` boots without MissingPluginException.
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (isMobile) {
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
    }
  } catch (e) {
    // Fallback error logging if the environmental file fails to load or cannot be found
    print("WARNING:: Could not load configuration infrastructure keys: $e");
  }

  // Launch the core application widget
  runApp(const MainApp());
}

// Global UI theme colors matching the Zentrapay design system guidelines.
// These now alias AppTheme's tokens so there's one source of truth for
// actual values, while every existing AppColors.* reference across the app
// keeps working unchanged.
class AppColors {
  static const Color main = AppTheme.primaryPink;
  static const Color primary = AppTheme.primaryWhite;
  static const Color secondary = AppTheme.secondaryNavy;
  static const Color textBlack = AppTheme.textBlack;
  static const Color purple = AppTheme.accentPurple;
  static const Color blue = AppTheme.accentBlue;
  static const Color green = AppTheme.successGreen;
  static const Color orange = AppTheme.warningOrange;
  static Color lightGrey = AppTheme.lightGrey;
}

// Reusable text styling components used throughout application screens.
// @deprecated for new code — prefer AppTheme.headlineSmall / bodyMedium etc.
// Kept as-is since several out-of-scope screens still reference these.
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

  @override
  Widget build(BuildContext context) {
    // Wrap the app tree with ToastificationWrapper to handle interactive alerts Globally
    return Portal(
      child: ToastificationWrapper(
        child: Center(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            // Mounts the app's one global "processing, please wait" barrier
            // (see LoadingOverlay) above the Navigator so LoadingOverlay.show()
            // works from any screen without each one managing its own overlay.
            builder: (context, child) =>
                LoadingOverlay.wrap(child ?? const SizedBox.shrink()),
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
              '/fraud_detection': (context) => const FraudDetectionScreen(),
              '/external_payment': (context) => const ExternalPaymentScreen(),
              '/zbanking': (context) => const ZBankingScreen(),
              '/zremit': (context) => const ZRemitScreen(),
              '/zvoice': (context) => const ZVoiceScreen(),
              '/zgrow_new': (context) => const ZGrowScreen(),
              '/pay_anywhere': (context) => const PayAnywhereScreen(),
            },
          ),
        ),
      ),
    );
  }
}
