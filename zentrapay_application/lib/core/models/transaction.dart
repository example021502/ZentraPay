class AppTransaction {
  final String transactionId;
  final String receiverId;
  final String txnRef;
  final String destinationId;

  /// Signed display amount straight from the backend — e.g. "-GHS 100.00"
  /// (debit) or "+GHS 100.00" (credit). The leading sign is the single
  /// source of truth for credit vs debit: it drives the green/red amount
  /// colors, the call_received/call_made icons and "Send Again" visibility
  /// (see [isCredit]/[isDebit]). The currency code is folded into the same
  /// string (see [currencyCode]).
  final String amount;
  final String status;
  final String receiverName;
  final String? receiverIdentifier;
  final String completedAt;
  final String transactionType;

  /// Why a FAILED / REVERSED payment did not go through (empty otherwise).
  final String failureReason;

  /// What the payment was for ("Wallet funding", "Saved to goal: Rent" ...).
  final String purpose;

  AppTransaction({
    required this.transactionId,
    required this.receiverId,
    required this.txnRef,
    required this.destinationId,
    required this.amount,
    required this.status,
    required this.receiverName,
    required this.receiverIdentifier,
    required this.completedAt,
    required this.transactionType,
    this.failureReason = '',
    this.purpose = '',
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    // ?.toString() everywhere: UUID/timestamp values can arrive as non-String
    // JSON types depending on the endpoint, and a hard cast used to throw a
    // TypeError that aborted the whole history parse.
    return AppTransaction(
      transactionId: (json['transactionId']?.toString()) ?? 'Undefined',
      receiverId: (json['receiverId']?.toString()) ?? 'Undefined',
      // The ledger's unique, human-quotable reference is internalReferenceId;
      // this model still exposes it under its legacy TXN_Ref name. Both
      // producers (GET /api/history and POST /api/payments/initialize) send
      // TXN_Ref; internalReferenceId is kept as a defensive fallback.
      txnRef:
          (json['TXN_Ref'] ?? json['internalReferenceId']?.toString()) ??
          'Undefined',
      destinationId: (json['destinationId']?.toString()) ?? 'Undefined',
      amount: (json['amount']?.toString()) ?? '',
      status: (json['status']?.toString()) ?? '',
      receiverName: (json['receiverName']?.toString()) ?? 'Undefined',
      receiverIdentifier: (json['receiverIdentifier']?.toString()),
      // completedAt for the payment response; the history endpoint's rows
      // carry createdAt instead.
      completedAt: (json['completedAt'] ?? json['createdAt'])?.toString() ?? '',
      transactionType: (json['transactionType']?.toString()) ?? '',
      failureReason: (json['failureReason']?.toString()) ?? '',
      purpose: (json['purpose']?.toString()) ?? '',
    );
  }

  /// True for money coming IN — the backend signs credits "+".
  bool get isCredit => amount.trim().startsWith('+');

  /// True for money going OUT — the backend signs debits "-".
  bool get isDebit => amount.trim().startsWith('-');

  /// Currency code folded into the signed amount string ("-GHS 100.00" -> "GHS").
  String get currencyCode {
    final trimmed = amount.trim();
    final body = (trimmed.startsWith('+') || trimmed.startsWith('-'))
        ? trimmed.substring(1)
        : trimmed;
    final spaceIndex = body.indexOf(' ');
    return spaceIndex > 0 ? body.substring(0, spaceIndex) : '';
  }

  /// The amount without its credit/debit sign ("+GHS 100.00" -> "GHS 100.00")
  /// for prose like "GHS 100.00 sent to Ama".
  String get absoluteAmount => amount.trim().replaceFirst(RegExp(r'^[+-]'), '');

  /// Terminal failure states the ledger can report — used to flip the
  /// post-payment overlay from success to error even when the HTTP call
  /// itself returned a response body.
  bool get isFailedStatus =>
      status.trim().toUpperCase() == 'FAILED' ||
      status.trim().toUpperCase() == 'EXPIRED';

  /// Every status the ledger can hold, as a short label for the history list.
  String get statusLabel {
    switch (status.trim().toUpperCase()) {
      case 'SUCCESS':
        return 'Successful';
      case 'FAILED':
        return 'Failed';
      case 'EXPIRED':
        return 'Expired';
      case 'REVERSED':
        return 'Reversed';
      case 'INITIATED':
        return 'Processing';
      case 'PENDING':
      case 'PENDING_USER_PIN':
      case 'STK_PUSH_TRIGGERED':
        return 'Pending';
      default:
        return status.trim().isEmpty ? 'Unknown' : status.trim();
    }
  }

  /// True while the money is still on its way (not final yet).
  bool get isOpenStatus {
    final s = status.trim().toUpperCase();
    return s == 'PENDING' ||
        s == 'INITIATED' ||
        s == 'PENDING_USER_PIN' ||
        s == 'STK_PUSH_TRIGGERED';
  }

  /// True for a payment that ended without the money arriving.
  bool get isUnsuccessful {
    final s = status.trim().toUpperCase();
    return s == 'FAILED' || s == 'EXPIRED' || s == 'REVERSED';
  }

  /// What kind of payment this is, in words.
  String get typeLabel {
    switch (transactionType.trim().toUpperCase()) {
      case 'P2P_TRANSFER':
        return 'Transfer to ZentraPay user';
      case 'CASH_OUT_BANK':
        return 'Bank transfer';
      case 'CASH_OUT_MOMO':
        return 'Mobile money transfer';
      case 'CASH_IN_CARD':
      case 'CASH_IN_BANK':
      case 'CASH_IN_MOMO':
      case 'WALLET_FUNDING':
        return 'Wallet top-up';
      case 'BILL_PAYMENT':
        return 'Bill payment';
      case 'SAVINGS_DEPOSIT':
        return 'Saved to goal';
      case 'SAVINGS_WITHDRAWAL':
        return 'Withdrawn from goal';
      case 'INVESTMENT_BUY':
        return 'Investment bought';
      case 'INVESTMENT_SELL':
        return 'Investment sold';
      case 'LOAN_DISBURSEMENT':
        return 'Loan received';
      case 'LOAN_REPAYMENT':
        return 'Loan repayment';
      case 'REFUND':
        return 'Refund';
      case 'PLATFORM_FEE':
        return 'Fee';
      default:
        return transactionType.trim();
    }
  }

  // @override
  // String toString() {
  //   return 'AppTransaction(id: $transactionId, txn_ref: $txnRef, name: $receiverName, identifier: $receiverPhoneNumber)';
  // }
}

/// Answer of `POST /api/payments/retry/{id}/check`: whether a failed payment can be tried again
/// (both the sender and the receiver are still valid) and, if not, why.
class RetryCheck {
  final bool retryable;
  final String message;
  final String receiverName;
  final String amount;
  final String currencyCode;

  RetryCheck({
    required this.retryable,
    required this.message,
    required this.receiverName,
    required this.amount,
    required this.currencyCode,
  });

  factory RetryCheck.fromJson(Map<String, dynamic> json) => RetryCheck(
    retryable: json['retryable'] == true,
    message: (json['message'] ?? '').toString(),
    receiverName: (json['receiverName'] ?? '').toString(),
    amount: (json['amount'] ?? '').toString(),
    currencyCode: (json['currencyCode'] ?? '').toString(),
  );
}

class TransactionPage {
  final List<AppTransaction> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  TransactionPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory TransactionPage.fromJson(Map<String, dynamic> json) =>
      TransactionPage(
        content: ((json['content'] as List?) ?? [])
            .map((e) => AppTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] ?? 0,
        size: json['size'] ?? 20,
        totalElements: json['totalElements'] ?? 0,
        totalPages: json['totalPages'] ?? 0,
      );

  bool get hasMore => page + 1 < totalPages;
}
