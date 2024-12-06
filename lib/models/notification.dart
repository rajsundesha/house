// enum NotificationType { payment, lease, maintenance, document, system }

// class Notification {
//   final String id;
//   final String title;
//   final String message;
//   final NotificationType type;
//   final DateTime timestamp;
//   final String? targetId;
//   final String? targetType;
//   final bool isRead;
//   final Map<String, dynamic>? data;

//   Notification({
//     required this.id,
//     required this.title,
//     required this.message,
//     required this.type,
//     required this.timestamp,
//     this.targetId,
//     this.targetType,
//     this.isRead = false,
//     this.data,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'title': title,
//       'message': message,
//       'type': type.toString().split('.').last,
//       'timestamp': timestamp,
//       'targetId': targetId,
//       'targetType': targetType,
//       'isRead': isRead,
//       'data': data,
//     };
//   }

//   factory Notification.fromMap(Map<String, dynamic> map) {
//     return Notification(
//       id: map['id'],
//       title: map['title'],
//       message: map['message'],
//       type: NotificationType.values.firstWhere(
//         (e) => e.toString().split('.').last == map['type'],
//       ),
//       timestamp: map['timestamp'].toDate(),
//       targetId: map['targetId'],
//       targetType: map['targetType'],
//       isRead: map['isRead'] ?? false,
//       data: map['data'],
//     );
//   }
// }
