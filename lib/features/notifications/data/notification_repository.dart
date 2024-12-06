import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AppNotification>> getNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<AppNotification> createNotification(AppNotification notification) async {
    final docRef = await _firestore
        .collection('notifications')
        .add(notification.toMap());
    return notification.copyWith(id: docRef.id);
  }

  Future<void> markAsRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
            .toList());
  }
}