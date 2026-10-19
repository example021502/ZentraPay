import 'package:flutter/material.dart';

import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/utils/LoadingOverlay.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/makePayment.dart';
import 'package:zentrapay_application/features/home/repository/cache_homeData.dart';

/// Latch for the shared "send again" pipeline. Set synchronously before the
/// first `await` of a run and cleared in its `finally`, so a double-tap (or
/// a second screen firing while one is already resolving) can never start a
/// second flow and an exception can never latch it shut.
bool _sendAgainInFlight = false;

/// Whether a send-again flow started by any screen is currently running.
bool get sendAgainInFlight => _sendAgainInFlight;

/// Whether [transaction] is a transfer the user *sent*.
///
/// The ledger row only ever stores the RECEIVER's identifiers, so on an
/// incoming payment (amount signed "+") the recorded counterparty is the
/// user themself — "send again" on such a row would prefill a transfer to
/// yourself. Outgoing rows (amount signed "-") hold the real counterparty,
/// which is the only case where re-sending makes sense.
bool canSendAgain(AppTransaction transaction) => transaction.isDebit;

/// Every "pay this past counterparty again" entry point runs through here —
/// Pay's Recent Payments strip, the History page's details sheet and the
/// Home screen's Latest Activities sheet — so all three behave identically:
///
/// 1. The app's global [LoadingOverlay] (mounted above the Navigator in
///    main.dart, so it sits on top of the whole stack) is raised the moment
///    the user taps, and the backend re-search runs underneath it.
/// 2. When the search returns, the overlay drops and the regular payment
///    flow takes over: Enter Amount -> PIN -> POST /api/payments/initialize.
///
/// The re-search is best-effort: if the stored row can't satisfy the search
/// contract, the request fails, or the contact isn't an app user, a
/// recipient is rebuilt from the identifiers on the [AppTransaction] itself
/// so tapping ALWAYS reaches the amount screen instead of dead-ending.
///
/// [controller]/[onStateChanged] let the Pay screen keep its own in-flight
/// flag in sync with this flow; other screens can omit them.
Future<void> sendAgainFromTransaction({
  required BuildContext context,
  required AppTransaction transaction,
  PaymentController? controller,
  void Function(bool inFlight)? onStateChanged,
}) async {
  if (_sendAgainInFlight) return;
  _sendAgainInFlight = true;

  try {
    onStateChanged?.call(true);

    // 1. Resolve the counterparty while the global overlay is up, so the
    //    user always sees that the app is working on their tap.
    final Map<String, dynamic>? contact = await LoadingOverlay.run(
      () => _resolveContact(transaction),
      message: "Loading contact…",
    );

    if (!context.mounted) return;

    final _ResolvedRecipient recipient = _buildRecipient(transaction, contact);

    // 2. Hand over to the normal flow — Enter Amount -> PIN -> submit.
    await (controller ?? PaymentController()).processPayment(
      context: context,
      recipientNameForUI: recipient.name,
      channelType: recipient.channelType,
      recipientMap: recipient.payload,
      onStateChanged: onStateChanged ?? (_) {},
    );
  } finally {
    _sendAgainInFlight = false;
    // Covers every exit path — including the user cancelling the amount or
    // PIN sheet, where processPayment returns without ever reporting back —
    // so the caller's flag can never stay stuck on.
    onStateChanged?.call(false);
  }
}

/// `GET /api/search/search-contact/{query}` contract (SearchContactsService):
/// the path segment is parsed as `"<receiver UUID>+<TransactionType>"` via
/// `UUID.fromString()`/`TransactionType.valueOf()` and the backend throws on
/// anything it can't parse — so only spend a round-trip when the stored row
/// can actually satisfy it. Returns null whenever the contact can't be
/// resolved; the caller then falls back to the stored identifiers.
final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

Future<Map<String, dynamic>?> _resolveContact(
  AppTransaction transaction,
) async {
  final String receiverId = transaction.receiverId.trim();
  final String transactionType = transaction.transactionType.trim();
  if (transactionType.isEmpty || !_uuidPattern.hasMatch(receiverId)) {
    return null;
  }

  try {
    final Map<String, dynamic> response = await SearchRepository.targetSearch(
      '$receiverId+$transactionType',
    );
    return response.isEmpty ? null : response;
  } catch (e) {
    debugPrint("Recent-contact re-search failed, using stored details: $e");
    return null;
  }
}

/// The recipient payload plus display name handed to [PaymentController].
class _ResolvedRecipient {
  const _ResolvedRecipient({
    required this.name,
    required this.payload,
    required this.channelType,
  });

  final String name;
  final Map<String, dynamic> payload;
  final String channelType;
}

_ResolvedRecipient _buildRecipient(
  AppTransaction transaction,
  Map<String, dynamic>? contact,
) {
  final String storedName = transaction.receiverName.trim();
  final String fallbackName = storedName.isEmpty ? "Recipient" : storedName;

  // UserSearchDTO serializes the discriminator as `type`; older payloads
  // surfaced it as `userType` — accept either so INTERNAL routing never
  // silently drops to the fallback path.
  final dynamic resolvedType = contact?['type'] ?? contact?['userType'];
  if (contact != null && resolvedType?.toString() == 'APP_USER') {
    String name = "${contact['firstName'] ?? ''} ${contact['lastName'] ?? ''}"
        .trim();
    if (name.isEmpty) name = fallbackName;
    return _ResolvedRecipient(
      name: name,
      // A UserSearchDTO-shaped contact can only come from the backend's
      // INTERNAL branch, so the stored row was an INTERNAL transfer too.
      channelType: "INTERNAL",
      payload: {
        "userId": "${contact['userId'] ?? ''}",
        "name": name,
        "zentag": "${contact['zentag'] ?? ''}",
        "accountNumber": "",
        "countryCode": "${contact['countryCode'] ?? ''}",
        "phoneNumber": "${contact['phoneNumber'] ?? ''}",
        "type": "APP_USER",
      },
    );
  }

  // Fallback: rebuild the recipient from the identifiers stored on the
  // transaction itself. POST /api/payments/initialize only executes INTERNAL
  // transfers and resolves the receiver by zentag first, falling back to
  // phone number — so stamp the stored counterparty contact in there.
  final String storedPhone = (transaction.receiverIdentifier ?? '').trim();
  return _ResolvedRecipient(
    name: fallbackName,
    channelType: "INTERNAL",
    payload: {
      "userId": transaction.receiverId.trim(),
      "name": fallbackName,
      "zentag": "",
      "accountNumber": "",
      "countryCode": "",
      "phoneNumber": storedPhone.isNotEmpty
          ? storedPhone
          : transaction.destinationId.trim(),
      "type": "APP_USER",
    },
  );
}
