class AppNotification {
  final String notificationId;
  final String title;
  final String message;
  final String type;
  final String? referenceId;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    notificationId: notificationId,
    title: title,
    message: message,
    type: type,
    referenceId: referenceId,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        notificationId: json['notificationId']?.toString() ?? '',
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        type: json['type'] ?? '',
        referenceId: json['referenceId'],
        isRead: json['isRead'] ?? false,
        createdAt: json['createdAt'] ?? '',
      );
}
