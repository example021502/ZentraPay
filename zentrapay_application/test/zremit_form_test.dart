// ZRemit: the receiver name comes AFTER the recipient is chosen and fills itself in (a ZentraPay
// user's name, or the account holder's name once the bank / mobile-money account is verified),
// and searching with the keyboard open must not overflow.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentrapay_application/core/theme/material_theme.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profile_data.dart';
import 'package:zentrapay_application/features/zremit/zremit_screen.dart';

class _Backend implements HttpClientAdapter {
  final List<String> calls = [];
  Map<String, dynamic>? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add('${options.method} ${options.path}');
    Object? data = <Object>[];
    final path = options.path;
    if (path == '/api/users/me') {
      data = {
        'user': {
          'userId': 'u-1',
          'firstName': 'Ama',
          'lastName': 'Mensah',
          'email': 'ama@test.com',
          'phoneNumber': '+233200000000',
          'countryCode': 'GH',
        },
        'profile': null,
      };
    } else if (path == '/api/reference/countries') {
      data = [
        {'countryCode': 'GH', 'countryName': 'Ghana', 'defaultCurrencyCode': 'GHS', 'dialCode': '+233', 'iso3Code': 'GHA'},
        {'countryCode': 'NG', 'countryName': 'Nigeria', 'defaultCurrencyCode': 'NGN', 'dialCode': '+234', 'iso3Code': 'NGA'},
      ];
    } else if (path == '/api/wallet/balances') {
      data = {
        'fiatBalances': [
          {
            'accountId': 'acc-1',
            'accountName': 'Main',
            'currencyCode': 'GHS',
            'zentag': 'ama',
            'balance': 1000,
            'isDefault': true,
            'status': 'ACTIVE',
            'createdAt': '2026-01-01T00:00:00Z',
          },
        ],
        'cryptoBalances': <Object>[],
      };
    } else if (path.startsWith('/api/search/search-contacts/')) {
      data = {
        'appUsers': [
          {'userId': 'u-2', 'firstName': 'Chidi', 'lastName': 'Okafor', 'phoneNumber': '+2348000000000', 'zentag': 'chidi', 'countryCode': 'NG', 'type': 'INDIVIDUAL'},
        ],
        'billProviders': <Object>[],
        'banks': [
          {'bankId': 'b-1', 'bankName': 'Access Bank', 'bankCode': '044', 'countryCode': 'NG'},
          {'bankId': 'b-2', 'bankName': 'Zenith Bank', 'bankCode': '057', 'countryCode': 'NG'},
          {'bankId': 'b-3', 'bankName': 'GTBank', 'bankCode': '058', 'countryCode': 'NG'},
        ],
        'mobileMoney': [
          {'providerId': 'm-1', 'name': 'Opay', 'providerCode': 'opay', 'countryCode': 'NG'},
        ],
      };
    } else if (path == '/api/payments/verify-account') {
      data = {
        'verified': true,
        'gatewayId': 'gw-1',
        'accountName': 'CHIDI OKAFOR',
        'accountNumber': '******7890',
        'destinationName': 'Access Bank',
        'countryCode': 'NG',
        'verificationToken': 'tok-123',
      };
    } else if (path == '/api/remittance/send') {
      lastBody = Map<String, dynamic>.from(options.data as Map);
      data = {
        'remittance': {'status': 'PENDING'},
      };
    }
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'message': 'ok', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Backend backend;

  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:2000'));

  setUp(() {
    backend = _Backend();
    ApiClient().dio.httpClientAdapter = backend;
    WalletsRepository.instance.clear();
    CountriesRepository.instance.clear();
    UserProfileRepository.instance.clear();
  });

  Future<void> pumpScreen(WidgetTester t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(400, 800);
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: ZRemitScreen()),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> pickNigeria(WidgetTester t) async {
    await t.ensureVisible(find.text('Select a country'));
    await t.tap(find.text('Select a country'));
    await t.pumpAndSettle();
    await t.tap(find.text('Nigeria'));
    await t.pumpAndSettle();
  }

  testWidgets('searching with the keyboard open does not overflow', (t) async {
    await pumpScreen(t);
    await pickNigeria(t);

    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    await t.pumpAndSettle();
    final field = find.byType(SearchBar);
    await t.ensureVisible(field);
    await t.enterText(field, 'chi');
    await t.pump(const Duration(milliseconds: 700));
    await t.pumpAndSettle();

    expect(find.text('Access Bank'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('searching inside the real shell on a small phone does not overflow', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(360, 640);
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          extendBody: true,
          appBar: AppBar(toolbarHeight: 24),
          bottomNavigationBar: const SizedBox(height: 70, child: Placeholder()),
          body: IndexedStack(index: 0, children: const [ZRemitScreen()]),
        ),
      ),
    );
    await t.pumpAndSettle();
    await pickNigeria(t);

    t.view.viewInsets = const FakeViewPadding(bottom: 280);
    await t.pumpAndSettle();
    final field = find.byType(SearchBar);
    await t.ensureVisible(field);
    await t.enterText(field, 'chi');
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 700));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('receiver name fills itself from a ZentraPay user', (t) async {
    await pumpScreen(t);
    await pickNigeria(t);

    // Nothing to type before a recipient is chosen
    expect(find.widgetWithText(TextFormField, 'Receiver name'), findsNothing);

    await t.enterText(find.byType(SearchBar), 'chi');
    await t.pump(const Duration(milliseconds: 700));
    await t.pumpAndSettle();
    await t.tap(find.text('Chidi Okafor'));
    await t.pumpAndSettle();

    final name = find.byKey(const ValueKey('remit-receiver-name'));
    await t.ensureVisible(name);
    final field = t.widget<TextFormField>(name);
    expect(field.controller!.text, 'Chidi Okafor');
    expect(t.widget<TextField>(find.descendant(of: name, matching: find.byType(TextField))).readOnly, isTrue);
    expect(t.takeException(), isNull);
  });

  testWidgets('bank: name fills after verification and the gateway goes with the send', (t) async {
    await pumpScreen(t);
    await pickNigeria(t);

    await t.enterText(find.byType(SearchBar), 'acc');
    await t.pump(const Duration(milliseconds: 700));
    await t.pumpAndSettle();
    await t.tap(find.text('Access Bank'));
    await t.pumpAndSettle();

    await t.enterText(find.widgetWithText(TextField, 'Account number'), '0123456789');
    await t.pump();
    await t.tap(find.text('Verify account'));
    await t.pumpAndSettle();
    expect(find.text('CHIDI OKAFOR'), findsWidgets);
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();

    final name = find.byKey(const ValueKey('remit-receiver-name'));
    await t.ensureVisible(name);
    expect(t.widget<TextFormField>(name).controller!.text, 'CHIDI OKAFOR');

    // Send it: the token and the verifying gateway must travel with the request
    final amount = find.widgetWithText(TextFormField, '0.00');
    await t.ensureVisible(amount);
    await t.enterText(amount, '5000');
    await t.pump();
    final reason = find.widgetWithText(TextFormField, 'Enter reason for transfer...');
    await t.ensureVisible(reason);
    await t.enterText(reason, 'Rent');
    await t.pump();
    final send = find.text('Continue to Payment');
    await t.ensureVisible(send);
    await t.tap(send);
    await t.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await t.tap(find.text('1').first);
      await t.pump();
    }
    await t.pumpAndSettle();

    final body = backend.lastBody;
    expect(body, isNotNull, reason: 'the send request was never made');
    expect(body!['verificationToken'], 'tok-123');
    expect(body['gatewayId'], 'gw-1');
    expect(body['recipientType'], 'BANK');
    expect(body['recipientName'], 'CHIDI OKAFOR');
    expect(t.takeException(), isNull);
  });
}
