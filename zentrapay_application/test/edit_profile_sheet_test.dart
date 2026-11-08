// The edit-profile overlay must keep a usable scroll area when the keyboard opens: the sheet is
// lifted above the keyboard once, and nothing inside may shrink for the keyboard a second time
// (that left a blank block from the focused field to the bottom).

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentrapay_application/features/profile/edit_profile_sheet.dart';

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:2000'));

  testWidgets('keyboard does not shrink the edit-profile sheet twice', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(400, 900);
    addTearDown(t.view.reset);

    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showEditProfileSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();

    final sheetBodyBefore = t.getSize(find.byType(SingleChildScrollView).first).height;

    t.view.viewInsets = const FakeViewPadding(bottom: 320);
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(TextField, 'First name'));
    await t.pumpAndSettle();

    final sheetBodyAfter = t.getSize(find.byType(SingleChildScrollView).first).height;
    // Available height went from 900 to 580 (x0.92 max). The scroll area must follow that, and
    // not lose another 320 on top of it.
    expect(sheetBodyAfter, greaterThan(sheetBodyBefore - 320 - 120));
    expect(sheetBodyAfter, greaterThan(300));
    expect(t.takeException(), isNull);
  });
}
