class AppTransaction {
  final String transactionId;
  final String typeCode;
  final String amount;
  final String currencyCode;
  final String status;
  final String? gateway;
  final String reference;
  final String? counterpartyName;
  final String? counterpartyIdentifier;
  final String? description;
  final String createdAt;

  AppTransaction({
    required this.transactionId,
    required this.typeCode,
    required this.amount,
    required this.currencyCode,
    required this.status,
    this.gateway,
    required this.reference,
    this.counterpartyName,
    this.counterpartyIdentifier,
    this.description,
    required this.createdAt,
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) =>
      AppTransaction(
        transactionId: json['transactionId'] ?? '',
        typeCode: json['typeCode'] ?? '',
        amount: (json['amount'] ?? '0').toString(),
        currencyCode: json['currencyCode'] ?? '',
        status: json['status'] ?? '',
        gateway: json['gateway'],
        reference: json['reference'] ?? '',
        counterpartyName: json['counterpartyName'],
        counterpartyIdentifier: json['counterpartyIdentifier'],
        description: json['description'],
        createdAt: json['createdAt'] ?? '',
      );

  /// International vs. national is derived from the transaction type,
  /// replacing the old {national:[],international:[]} split the backend
  /// used to send.
  bool get isInternational => typeCode == 'REMITTANCE_SEND';
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
            .map((e) => AppTransaction.fromJson(e))
            .toList(),
        page: json['page'] ?? 0,
        size: json['size'] ?? 20,
        totalElements: json['totalElements'] ?? 0,
        totalPages: json['totalPages'] ?? 0,
      );

  bool get hasMore => page + 1 < totalPages;
}
