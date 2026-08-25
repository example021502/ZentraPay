class AppTransaction {
  final String transactionId;
  final String receiverId;
  final String amount;
  final String createdAt;
  final String? failureReason;
  final String status;
  final String updatedAt;
  final String transactionType;
  final String receiverName;
  final String receiverEmail;
  final String receiverPhoneNumber;
  final String? purpose;
  final String internalReferenceId;
  final String entryId;

  AppTransaction({
    required this.transactionId,
    required this.receiverId,
    required this.amount,
    required this.createdAt,
    required this.status,
    required this.internalReferenceId,
    required this.receiverName,
    required this.receiverEmail,
    required this.receiverPhoneNumber,
    this.purpose,
    this.failureReason,
    required this.updatedAt,
    required this.transactionType,
    required this.entryId,
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      transactionId: (json['transactionId']?.toString()) ?? '',
      receiverId: (json['receiverId']?.toString()) ?? '',
      transactionType: (json['transactionType']?.toString()) ?? '',
      amount: (json['amount']?.toString()) ?? '',
      status: (json['status']?.toString()) ?? '',
      internalReferenceId: (json['internalReferenceId']?.toString()) ?? '',
      receiverName: (json['receiverName']?.toString()) ?? '',
      receiverEmail: (json['receiverEmail']?.toString()) ?? '',
      receiverPhoneNumber: (json['receiverPhoneNumber']?.toString()) ?? '',
      purpose: json['purpose']?.toString(),
      failureReason: json['failureReason']?.toString(),
      updatedAt: (json['updatedAt']?.toString()) ?? '',
      createdAt: (json['createdAt']?.toString()) ?? '',
      entryId: (json['entryId']?.toString()) ?? '',
    );
  }

  @override
  String toString() {
    return 'AppTransaction(id: $transactionId, name: $receiverName, identifier: $receiverId)';
  }
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
