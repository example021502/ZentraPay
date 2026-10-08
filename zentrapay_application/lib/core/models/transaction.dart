class AppTransaction {
  final String transactionId;
  final String receiverId;
  final String TXN_Ref;
  final String destinationIdentifier;
  final String amount;
  final String currencyCode;
  final String status;
  final String receiverName;
  final String? receiverPhoneNumber;
  final String completedAt;
  final String transactionType;

  AppTransaction({
    required this.transactionId,
    required this.receiverId,
    required this.TXN_Ref,
    required this.destinationIdentifier,
    required this.amount,
    required this.currencyCode,
    required this.status,
    required this.receiverName,
    required this.receiverPhoneNumber,
    required this.completedAt,
    required this.transactionType,
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      transactionId: (json['transactionId']?.toString()) ?? '',
      receiverId: (json['receiverId']?.toString()) ?? '',
      // The ledger's unique, human-quotable reference is internalReferenceId;
      // this model still exposes it under its legacy TXN_Ref name.
      TXN_Ref:
          (json['internalReferenceId'] ?? json['TXN_Ref'])?.toString() ?? '',
      destinationIdentifier:
          (json['destinationIdentifier'] ?? json['receiverPhoneNumber'])
              ?.toString() ??
          '',
      amount: (json['amount'] ?? '').toString(),
      // The backend folds the currency into the amount string
      // (e.g. "-GHS 0.2500") and sends no separate currencyCode field.
      currencyCode:
          (json['currencyCode'] ?? json['sourceCurrencyCode'])?.toString() ??
          '',
      status: (json['status']?.toString()) ?? '',
      receiverName: (json['receiverName']?.toString()) ?? '',
      receiverPhoneNumber: (json['receiverPhoneNumber']?.toString()) ?? '',
      // The backend's TransactionDTO exposes createdAt, not completedAt.
      // This used to be a non-null assertion (`json['completedAt']!`), which
      // threw a TypeError on every row and silently emptied the whole history
      // list — the request succeeded but the parse aborted before item 1.
      completedAt: (json['completedAt'] ?? json['createdAt'])?.toString() ?? '',
      transactionType: (json['transactionType']?.toString()) ?? '',
    );
  }

  // @override
  // String toString() {
  //   return 'AppTransaction(id: $transactionId, txn_ref: $TXN_Ref, name: $receiverName, identifier: $receiverPhoneNumber)';
  // }
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
