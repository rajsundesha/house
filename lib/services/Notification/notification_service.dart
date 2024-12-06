// lib/services/notification/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/notification.dart' as model;

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      const initializationSettingsAndroid = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings();
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Handle FCM messages
      FirebaseMessaging.onMessage.listen(_handleMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      // Get FCM token
      String? token = await _fcm.getToken();
      print('FCM Token: $token');
    }
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    model.Notification notification = model.Notification(
      id: message.messageId ?? DateTime.now().toString(),
      title: message.notification?.title ?? '',
      message: message.notification?.body ?? '',
      type: _getNotificationType(message.data['type']),
      timestamp: DateTime.now(),
      targetId: message.data['targetId'],
      targetType: message.data['targetType'],
      data: message.data,
    );

    // Show local notification
    await _showLocalNotification(notification);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    // Handle notification tap when app is in background
    print('Message opened app: ${message.data}');
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle local notification tap
    print('Notification tapped: ${response.payload}');
  }

  NotificationType _getNotificationType(String? type) {
    switch (type) {
      case 'payment':
        return NotificationType.payment;
      case 'lease':
        return NotificationType.lease;
      case 'maintenance':
        return NotificationType.maintenance;
      case 'document':
        return NotificationType.document;
      default:
        return NotificationType.system
    }

          Future<void> _showLocalNotification(model.Notification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.message,
      notificationDetails,
      payload: notification.id,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? data,
  }) async {
    // Implementation would typically involve a server-side function
    // This is a placeholder for the client-side implementation
    print('Sending notification to user: $userId');
  }
}
