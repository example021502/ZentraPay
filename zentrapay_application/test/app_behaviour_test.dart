import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';
import 'package:zentrapay_application/core/models/security.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/theme_controller.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/core/utils/double_back_to_exit.dart';

DioException _dioError({int? status, Object? body}) {
  final request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    response: status == null
        ? null
        : Response(requestOptions: request, statusCode: status, data: body),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Secure storage has no platform implementation under `flutter test`.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  group('errorMessage', () {
    test('keeps a business message from the server', () {
      final e = _dioError(
        status: 400,
        body: {'message': 'Insufficient balance'},
      );
      expect(errorMessage(e), 'Insufficient balance');
    });

    test('hides provider names and technical wording', () {
      final e = _dioError(
        status: 502,
        body: {'message': 'AfriqLink gateway timeout while calling /v1/link'},
      );
      expect(errorMessage(e), kConnectionErrorMessage);
      final e2 = _dioError(
        status: 502,
        body: {'message': 'AfriqLink rejected the request'},
      );
      expect(errorMessage(e2), kGenericErrorMessage);
    });

    test('says the connection failed when no response arrived', () {
      expect(errorMessage(_dioError()), kConnectionErrorMessage);
    });

    test('never shows a raw exception', () {
      expect(
        errorMessage(StateError('type \'Null\' is not a subtype of String')),
        kGenericErrorMessage,
      );
      expect(errorMessage(Exception('Invalid PIN')), 'Invalid PIN');
    });
  });

  group('models', () {
    test(
      'SecuritySettings reads preferences and defaults the missing ones',
      () {
        final full = SecuritySettings.fromJson({
          'biometricEnabled': true,
          'twoFactorEnabled': false,
          'fraudProtectionEnabled': true,
          'darkMode': true,
          'pushNotificationsEnabled': false,
          'transactionAlertsEnabled': true,
        });
        expect(full.darkMode, isTrue);
        expect(full.pushNotificationsEnabled, isFalse);

        final legacy = SecuritySettings.fromJson({});
        expect(legacy.darkMode, isFalse);
        expect(legacy.pushNotificationsEnabled, isTrue);
        expect(legacy.transactionAlertsEnabled, isTrue);

        final flipped = full.copyWith(darkMode: false);
        expect(flipped.darkMode, isFalse);
        expect(flipped.biometricEnabled, isTrue);
      },
    );

    test('LoanEligibility parses limits and blockers', () {
      final e = LoanEligibility.fromJson({
        'eligible': false,
        'kycTier': 1,
        'grade': null,
        'currencyCode': 'GHS',
        'minAmount': 50,
        'maxAmount': '2000.00',
        'maxTermMonths': 6,
        'interestRate': 0.18,
        'requirements': ['Complete identity verification (level 2).'],
      });
      expect(e.eligible, isFalse);
      expect(e.kycTier, 1);
      expect(e.maxAmount, 2000);
      expect(e.interestRate, 0.18);
      expect(e.requirements, hasLength(1));
    });

    test('LoanApplication sends every field the backend needs', () {
      final json = LoanApplication(
        amount: '500',
        termMonths: 3,
        purpose: 'RENT',
        employmentStatus: 'EMPLOYED',
        employerName: 'Acme',
        jobTitle: 'Clerk',
        monthlyIncome: '3000',
        monthlyObligations: '0',
        nextOfKinName: 'Ama',
        nextOfKinRelationship: 'Parent',
        nextOfKinPhone: '0244000000',
        creditCheckConsent: true,
        termsAccepted: true,
      ).toJson();
      expect(
        json.keys,
        containsAll(<String>[
          'amount',
          'currencyCode',
          'termMonths',
          'purpose',
          'employmentStatus',
          'employerName',
          'jobTitle',
          'monthlyIncome',
          'monthlyObligations',
          'nextOfKinName',
          'nextOfKinRelationship',
          'nextOfKinPhone',
          'creditCheckConsent',
          'termsAccepted',
        ]),
      );
    });
  });

  group('ThemeController', () {
    tearDown(() => AppTheme.isDark = false);

    testWidgets('switches the palette to dark and back', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final lightBackground = AppTheme.gray50;
      final lightText = AppTheme.textBlack;

      ThemeController.instance.setDark(true);
      expect(AppTheme.isDark, isTrue);
      expect(AppTheme.gray50, isNot(lightBackground));
      expect(AppTheme.textBlack, isNot(lightText));

      ThemeController.instance.setDark(false);
      expect(AppTheme.isDark, isFalse);
      expect(AppTheme.gray50, lightBackground);
    });
  });

  group('DoubleBackToExit', () {
    final closed = <MethodCall>[];

    setUp(() {
      closed.clear();
      toastification.dismissAll(delayForAnimation: false);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'SystemNavigator.pop') closed.add(call);
            return null;
          });
    });

    Widget app({bool Function()? onBack}) => ToastificationWrapper(
      child: MaterialApp(
        home: DoubleBackToExit(
          onBack: onBack,
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );

    testWidgets('one back press never closes the app', (tester) async {
      await tester.pumpWidget(app());
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      expect(closed, isEmpty);
      expect(find.textContaining('Tap back again'), findsOneWidget);
      // Let the notice finish so no timer outlives the test.
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a second press inside the window closes it', (tester) async {
      await tester.pumpWidget(app());
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(closed, hasLength(1));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('onBack can consume the press', (tester) async {
      var handled = 0;
      await tester.pumpWidget(
        app(
          onBack: () {
            handled++;
            return true;
          },
        ),
      );
      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(handled, 1);
      expect(closed, isEmpty);
      expect(find.textContaining('Tap back again'), findsNothing);
    });
  });
}
