// Tests for the shared "send again" pipeline used by the Pay strip, the
// History sheet and the Home transactions sheet.
//
// ignore_for_file: use_build_context_synchronously
// (context is captured from a freshly pumped host and used immediately —
// the async gaps are test-harness plumbing, not real screen transitions.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/features/home/HomePayments/send_again_flow.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/makePayment.dart';

/// Stands in for the real payment pipeline so the flow can be exercised
/// end-to-end without dialogs, PIN sheets or network calls.
class _RecordingPaymentController extends PaymentController {
  int invocationCount = 0;
  String? recipientName;
  String? channelType;
  Map<String, dynamic>? recipientMap;

  @override
  Future<void> processPayment({
    required BuildContext context,
    required String recipientNameForUI,
    required String channelType,
    required Map<String, dynamic> recipientMap,
    required void Function(bool) onStateChanged,
    String purpose = "",
    String? preferredCurrencyCode,
  }) async {
    invocationCount++;
    recipientName = recipientNameForUI;
    this.channelType = channelType;
    this.recipientMap = recipientMap;
  }
}

AppTransaction _transaction({
  String amount = '-GHS 20.00',
  String receiverId = 'not-a-uuid',
  String receiverName = 'Ama Mensah',
  String receiverPhoneNumber = '+233201234567',
}) => AppTransaction(
  transactionId: 'txn-1',
  receiverId: receiverId,
  TXN_Ref: 'REF-1',
  destinationId: '+233209999999',
  amount: amount,
  status: 'SUCCESS',
  receiverName: receiverName,
  receiverIdentifier: receiverPhoneNumber,
  completedAt: '2026-01-05T09:30:00',
  transactionType: 'INTERNAL',
);

void main() {
  group('canSendAgain', () {
    test('allows only outgoing (debit) rows', () {
      expect(canSendAgain(_transaction(amount: '-GHS 20.00')), isTrue);
      expect(canSendAgain(_transaction(amount: '+GHS 20.00')), isFalse);
      expect(canSendAgain(_transaction(amount: 'GHS 20.00')), isFalse);
      expect(canSendAgain(_transaction(amount: '')), isFalse);
    });
  });

  group('sendAgainFromTransaction', () {
    late BuildContext hostContext;

    Future<void> pumpHost(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              hostContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    testWidgets('falls back to the stored counterparty and reaches pay', (
      tester,
    ) async {
      await pumpHost(tester);
      final controller = _RecordingPaymentController();
      final states = <bool>[];

      await sendAgainFromTransaction(
        context: hostContext,
        transaction: _transaction(),
        controller: controller,
        onStateChanged: states.add,
      );

      expect(controller.invocationCount, 1);
      expect(controller.channelType, 'INTERNAL');
      expect(controller.recipientName, 'Ama Mensah');
      expect(controller.recipientMap?['phoneNumber'], '+233201234567');
      expect(controller.recipientMap?['type'], 'APP_USER');
      // The caller is told the flow started, then that it settled — even
      // though this run never went through the real payment controller's
      // own state reporting.
      expect(states, [true, false]);
      expect(sendAgainInFlight, isFalse);
    });

    testWidgets('a second tap while one is in flight is ignored', (
      tester,
    ) async {
      await pumpHost(tester);
      final controller = _RecordingPaymentController();

      // The latch is taken synchronously, before the first await…
      final Future<void> first = sendAgainFromTransaction(
        context: hostContext,
        transaction: _transaction(),
        controller: controller,
      );
      expect(sendAgainInFlight, isTrue);

      // …so a second tap in the same frame is a no-op. Note it must not be
      // awaited before the check below — awaiting yields to the microtask
      // queue and lets the first run advance to the payment step.
      final Future<void> second = sendAgainFromTransaction(
        context: hostContext,
        transaction: _transaction(),
        controller: controller,
      );
      expect(controller.invocationCount, 0);

      await second;
      await first;
      expect(controller.invocationCount, 1);
      expect(sendAgainInFlight, isFalse);
    });

    testWidgets('skips the pay flow when the screen is no longer mounted', (
      tester,
    ) async {
      await pumpHost(tester);
      final BuildContext gone = hostContext;
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      final controller = _RecordingPaymentController();
      final states = <bool>[];
      await sendAgainFromTransaction(
        context: gone,
        transaction: _transaction(),
        controller: controller,
        onStateChanged: states.add,
      );

      expect(controller.invocationCount, 0);
      expect(states, [true, false]);
      expect(sendAgainInFlight, isFalse);
    });
  });
}
