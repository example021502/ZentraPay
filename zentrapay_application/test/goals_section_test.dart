// Save Goal screen against a fake backend: the goals list must stay on screen after a goal is
// created, and the activity list must show at the bottom.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentrapay_application/core/theme/material_theme.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/features/goals/goals_screen.dart';
import 'package:zentrapay_application/features/goals/repository/cache_goals_data.dart';

class _FakeBackend implements HttpClientAdapter {
  final List<Map<String, dynamic>> goals = [];
  final List<String> calls = [];

  Map<String, dynamic> _goal(String name, num balance) => {
    'savingsId': 'g-${goals.length + 1}',
    'savingsName': name,
    'currencyCode': 'GHS',
    'balance': balance,
    'targetAmount': 500,
    'targetDate': null,
    'status': 'ACTIVE',
    'description': null,
    'frozenUntil': null,
    'autoSaveEnabled': false,
    'autoSaveAmount': null,
    'autoSaveFrequency': null,
    'autoSaveNextRun': null,
    'createdAt': '2026-11-04T10:00:00Z',
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add('${options.method} ${options.path}');
    Object? data;
    if (options.path == '/api/zbanking/savings' && options.method == 'GET') {
      data = goals;
    } else if (options.path == '/api/zbanking/savings' && options.method == 'POST') {
      final body = options.data as Map;
      final g = _goal(
        body['savingsName'].toString(),
        double.tryParse(body['initialDeposit'].toString()) ?? 0,
      );
      goals.insert(0, g);
      data = g;
    } else if (options.path == '/api/zbanking/savings/activity') {
      data = [
        for (final g in goals)
          {
            'activityId': 'a-${g['savingsId']}',
            'savingsId': g['savingsId'],
            'savingsName': g['savingsName'],
            'type': 'DEPOSIT',
            'auto': false,
            'amount': g['balance'],
            'currencyCode': 'GHS',
            'status': 'SUCCESS',
            'failureReason': null,
            'createdAt': '2026-11-04T10:00:00Z',
          },
      ];
    } else if (options.path == '/api/wallet/balances') {
      data = {
        'fiatBalances': [
          {
            'accountId': 'acc-1',
            'accountName': 'Main',
            'currencyCode': 'GHS',
            'zentag': 'tester',
            'balance': 1000,
            'isDefault': true,
            'status': 'ACTIVE',
            'createdAt': '2026-01-01T00:00:00Z',
          },
        ],
        'cryptoBalances': <Object>[],
      };
    } else {
      data = <Object>[];
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
  late _FakeBackend backend;

  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:2000'));

  setUp(() {
    backend = _FakeBackend();
    ApiClient().dio.httpClientAdapter = backend;
    GoalsRepository.instance.clear();
  });

  testWidgets('goal list stays on screen after creating a goal', (t) async {
    await t.pumpWidget(MaterialApp(theme: buildAppTheme(), home: const GoalsScreen()));
    await t.pumpAndSettle();
    expect(find.text('Create my first goal'), findsOneWidget);

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    expect(find.text('New savings goal'), findsOneWidget);

    await t.enterText(find.widgetWithText(TextField, 'Goal name'), 'Rent fund');
    await t.pump();
    await t.tap(find.text('Create goal'));
    await t.pumpAndSettle();

    expect(tester(t), isNull);
    expect(find.text('Rent fund'), findsWidgets);
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Saved to Rent fund'), findsOneWidget);
  });

  testWidgets('every goal sheet lays out under the app theme', (t) async {
    backend.goals.add({
      'savingsId': 'g-0',
      'savingsName': 'Holiday',
      'currencyCode': 'GHS',
      'balance': 120,
      'targetAmount': 500,
      'targetDate': null,
      'status': 'ACTIVE',
      'description': null,
      'frozenUntil': null,
      'autoSaveEnabled': true,
      'autoSaveAmount': 20,
      'autoSaveFrequency': 'WEEKLY',
      'autoSaveNextRun': '2030-01-01T00:00:00Z',
      'createdAt': '2026-11-04T10:00:00Z',
    });
    await t.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const GoalsScreen()),
    );
    await t.pumpAndSettle();
    expect(find.text('Holiday'), findsWidgets);
    expect(find.textContaining('Auto-save'), findsWidgets);

    Future<void> closeSheet() async {
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
    }

    await t.tap(find.text('Add money'));
    await t.pumpAndSettle();
    expect(find.text('Save money'), findsOneWidget);
    await closeSheet();

    await t.tap(find.text('Withdraw'));
    await t.pumpAndSettle();
    expect(find.text('Withdraw'), findsWidgets);
    await closeSheet();

    await t.tap(find.byIcon(Icons.more_vert_rounded));
    await t.pumpAndSettle();
    await t.tap(find.text('Freeze goal'));
    await t.pumpAndSettle();
    expect(find.text('1 week'), findsOneWidget);
    await closeSheet();

    await t.tap(find.byIcon(Icons.more_vert_rounded));
    await t.pumpAndSettle();
    await t.tap(find.text('Change auto-save'));
    await t.pumpAndSettle();
    expect(find.text('Weekly'), findsWidgets);
    await closeSheet();

    expect(t.takeException(), isNull);
  });
}

Object? tester(WidgetTester t) => t.takeException();
