// Home services against a fake backend: the section is absent until the user adds something (from
// the More overlay), then lists ONLY what they added, and the picker adds/removes.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentrapay_application/core/theme/material_theme.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/features/home/home_quick_actions.dart';
import 'package:zentrapay_application/features/home/home_services_grid.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/home/repository/cache_user_services_data.dart';

class _FakeBackend implements HttpClientAdapter {
  final List<Map<String, dynamic>> mine = [];
  final List<String> calls = [];

  static const billers = [
    {'providerId': 'b-1', 'billerName': 'Electric Co', 'categoryCode': 'ELECTRICITY', 'countryCode': 'GH'},
    {'providerId': 'b-2', 'billerName': 'Water Works', 'categoryCode': 'WATER', 'countryCode': 'GH'},
  ];
  static const services = [
    {'providerId': 's-1', 'providerName': 'Stream TV', 'categoryCode': 'ENTERTAINMENT', 'countryCode': 'GH'},
  ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add('${options.method} ${options.path}');
    Object? data = <Object>[];
    final path = options.path;
    if (path == '/api/bill-providers') {
      data = billers;
    } else if (path == '/api/service-providers') {
      data = services;
    } else if (path == '/api/user-services' && options.method == 'GET') {
      data = mine;
    } else if (path == '/api/user-services' && options.method == 'POST') {
      final body = options.data as Map;
      final isBill = body['kind'] == 'BILL';
      final source = (isBill ? billers : services).firstWhere((p) => p['providerId'] == body['providerId']);
      final row = {
        'kind': body['kind'],
        'providerId': body['providerId'],
        'name': isBill ? source['billerName'] : source['providerName'],
        'logoUrl': null,
        'categoryCode': source['categoryCode'],
        'countryCode': source['countryCode'],
      };
      mine.add(row);
      data = row;
    } else if (path.startsWith('/api/user-services/') && options.method == 'DELETE') {
      final parts = path.split('/');
      mine.removeWhere((r) => r['kind'] == parts[3] && r['providerId'] == parts[4]);
      data = null;
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

/// Quick actions (with their More overlay) above the grid, wired the way HomeWalletMain does.
Widget _home() => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          const HomeQuickActions(),
          ListenableBuilder(
            listenable: UserServicesRepository.instance,
            builder: (context, _) => HomeServicesGrid(
              services: [
                for (final s in UserServicesRepository.instance.services)
                  {'providerId': s.providerId, 'providerName': s.name, 'logoUrl': s.logoUrl, 'category': s.categoryCode, 'countryCode': s.countryCode},
              ],
              bills: [
                for (final s in UserServicesRepository.instance.bills)
                  {'providerId': s.providerId, 'billerName': s.name, 'logoUrl': s.logoUrl, 'category': s.categoryCode, 'countryCode': s.countryCode},
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

Future<void> _openPickerFromMore(WidgetTester t, String entry) async {
  await t.tap(find.text('More'));
  await t.pumpAndSettle();
  await t.tap(find.text(entry));
  await t.pumpAndSettle();
}

Future<void> _closeSheet(WidgetTester t) async {
  await t.tapAt(const Offset(10, 10));
  await t.pumpAndSettle();
}

void main() {
  late _FakeBackend backend;

  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:2000'));

  setUp(() {
    backend = _FakeBackend();
    ApiClient().dio.httpClientAdapter = backend;
    UserServicesRepository.instance.clear();
    BillProvidersRepository.instance.clear();
    ServiceProvidersRepository.instance.clear();
  });

  testWidgets('nothing added: no services section on Home, adding is in the More overlay', (t) async {
    await t.pumpWidget(_home());
    await t.pumpAndSettle();

    expect(find.text('Bills'), findsNothing);
    expect(find.text('Services'), findsNothing);
    expect(find.text('New'), findsNothing);

    await t.tap(find.text('More'));
    await t.pumpAndSettle();
    expect(find.text('New Bill Providers'), findsOneWidget);
    expect(find.text('New Service Providers'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('adding one puts only it on Home; long-press removes it and the section disappears', (t) async {
    await t.pumpWidget(_home());
    await t.pumpAndSettle();

    await _openPickerFromMore(t, 'New Bill Providers');
    expect(find.text('Electric Co'), findsOneWidget);
    expect(find.text('Water Works'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('home-toggle-b-1')));
    await t.pumpAndSettle();
    expect(backend.calls, contains('POST /api/user-services'));
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await _closeSheet(t);

    // Home now has the section with just the one provider, and both New tiles
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Electric Co'), findsOneWidget);
    expect(find.text('Water Works'), findsNothing);
    expect(find.text('New'), findsNWidgets(2));

    await t.longPress(find.text('Electric Co'));
    await t.pumpAndSettle();
    expect(find.text('Remove from Home?'), findsOneWidget);
    await t.tap(find.text('Remove'));
    await t.pumpAndSettle();
    expect(backend.calls, contains('DELETE /api/user-services/BILL/b-1'));

    // nothing left -> the whole section is gone again
    expect(find.text('Electric Co'), findsNothing);
    expect(find.text('Bills'), findsNothing);
    expect(find.text('New'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('a service goes to the Services row, not Bills', (t) async {
    await t.pumpWidget(_home());
    await t.pumpAndSettle();

    await _openPickerFromMore(t, 'New Service Providers');
    await t.tap(find.byKey(const ValueKey('home-toggle-s-1')));
    await t.pumpAndSettle();
    expect(backend.mine.single['kind'], 'SERVICE');
    await _closeSheet(t);

    expect(find.text('Stream TV'), findsOneWidget);
    expect(UserServicesRepository.instance.bills, isEmpty);
    expect(UserServicesRepository.instance.services.single.name, 'Stream TV');
    expect(t.takeException(), isNull);
  });
}
