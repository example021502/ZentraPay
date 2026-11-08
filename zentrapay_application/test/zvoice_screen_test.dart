// ZVoice AI screen under the real app theme: it must render (it used to be blank - an Expanded inside
// a scroll view), keep back / title / voice icon / help in the app bar, and scroll as ONE body.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentrapay_application/core/theme/material_theme.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/features/zvoice/repository/cache_zvoice_data.dart';
import 'package:zentrapay_application/features/zvoice/zvoice_screen.dart';

class _FakeBackend implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final items = [
      for (var i = 0; i < 12; i++)
        {
          'commandId': 'c-$i',
          'commandType': i.isEven ? 'VOICE' : 'CHAT',
          'transcript': 'What is my balance $i?',
          'intent': 'CHECK_BALANCE',
          'responseText': 'You have GHS 100.',
          'language': 'en',
          'fraudAlert': false,
          'createdAt': '2026-11-04T10:00:00Z',
        },
    ];
    final data = options.path.contains('voice') ? items : <Object>[];
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
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:2000'));

  setUp(() {
    ApiClient().dio.httpClientAdapter = _FakeBackend();
    VoiceCommandHistoryRepository.instance.clear();
    VoiceFraudAlertsRepository.instance.clear();
  });

  Future<void> pumpScreen(WidgetTester t) async {
    t.view.physicalSize = const Size(360 * 3, 640 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('home')),
          ),
          onGenerateInitialRoutes: (_, _) => [
            MaterialPageRoute(builder: (_) => const Scaffold(body: Text('home'))),
            MaterialPageRoute(builder: (_) => const ZVoiceScreen()),
          ],
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('renders with back, title, voice icon and help in the app bar', (t) async {
    await pumpScreen(t);

    final appBar = find.byType(AppBar);
    expect(find.descendant(of: appBar, matching: find.text('ZVoice AI')), findsOneWidget);
    expect(find.descendant(of: appBar, matching: find.byIcon(Icons.graphic_eq_rounded)), findsOneWidget);
    expect(find.descendant(of: appBar, matching: find.byIcon(Icons.arrow_back)), findsOneWidget);
    expect(find.descendant(of: appBar, matching: find.byIcon(Icons.help_outline_rounded)), findsOneWidget);

    // body: tab strip + the Talk tab
    expect(find.text('Talk'), findsOneWidget);
    expect(find.text('Tap the microphone and speak'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('help opens and back leaves the screen', (t) async {
    await pumpScreen(t);

    await t.tap(find.byIcon(Icons.help_outline_rounded));
    await t.pumpAndSettle();
    expect(find.text('Got it'), findsOneWidget);
    await t.tap(find.text('Got it'));
    await t.pumpAndSettle();

    await t.tap(find.byIcon(Icons.arrow_back));
    await t.pumpAndSettle();
    expect(find.byType(ZVoiceScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('every tab shows and the whole body scrolls as one', (t) async {
    await pumpScreen(t);

    // Activity: 12 tiles are taller than the phone, so the single body must scroll to the last one
    await t.tap(find.text('Activity'));
    await t.pumpAndSettle();
    expect(find.text('What is my balance 0?'), findsOneWidget);
    await t.drag(find.byType(SingleChildScrollView).first, const Offset(0, -2500));
    await t.pumpAndSettle();
    expect(find.text('What is my balance 11?'), findsOneWidget);
    // the app bar stays put while the body scrolls
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('ZVoice AI')), findsOneWidget);

    await t.drag(find.byType(SingleChildScrollView).first, const Offset(0, 2500));
    await t.pumpAndSettle();

    await t.tap(find.text('Safety'));
    await t.pumpAndSettle();
    expect(find.text('Flagged instructions'), findsOneWidget);
    expect(find.text('Account alerts'), findsOneWidget);

    await t.tap(find.text('Talk'));
    await t.pumpAndSettle();
    expect(find.text('Tap the microphone and speak'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
