enum NotificationType {
  paymentDue,
  paymentReceived,
  maintenanceRequest,
  maintenanceUpdate,
  leaseExpiring,
  documentUploaded,
  general
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final String userId;
  final bool isRead;
  final String? relatedId;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.userId,
    this.isRead = false,
    this.relatedId,
    this.data,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      title: map['title'],
      message: map['message'],
      type: NotificationType.values.byName(map['type']),
      createdAt: DateTime.parse(map['createdAt']),
      userId: map['userId'],
      isRead: map['isRead'] ?? false,
      relatedId: map['relatedId'],
      data: map['data'],
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'message': message,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'userId': userId,
    'isRead': isRead,
    'relatedId': relatedId,
    'data': data,
  };

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    String? userId,
    bool? isRead,
    String? relatedId,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      data: data ?? this.data,
    );
  }
}