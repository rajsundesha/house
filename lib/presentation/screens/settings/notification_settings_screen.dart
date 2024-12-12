
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';


class NotificationSettings {
  final bool paymentReminders;
  final bool leaseExpiry;
  final bool maintenanceUpdates;
  final bool occupancyAlerts;
  final bool dailyReports;
  final bool tenantMessages;
  final Map<String, bool> emailNotifications;
  final Map<String, bool> pushNotifications;

  NotificationSettings({
    this.paymentReminders = true,
    this.leaseExpiry = true,
    this.maintenanceUpdates = true,
    this.occupancyAlerts = true,
    this.dailyReports = false,
    this.tenantMessages = true,
    Map<String, bool>? emailNotifications,
    Map<String, bool>? pushNotifications,
  })  : this.emailNotifications = emailNotifications ?? {
          'payments': true,
          'lease': true,
          'maintenance': true,
          'occupancy': true,
          'reports': false,
          'messages': true,
        },
        this.pushNotifications = pushNotifications ?? {
          'payments': true,
          'lease': true,
          'maintenance': true,
          'occupancy': true,
          'reports': false,
          'messages': true,
        };

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      paymentReminders: map['paymentReminders'] ?? true,
      leaseExpiry: map['leaseExpiry'] ?? true,
      maintenanceUpdates: map['maintenanceUpdates'] ?? true,
      occupancyAlerts: map['occupancyAlerts'] ?? true,
      dailyReports: map['dailyReports'] ?? false,
      tenantMessages: map['tenantMessages'] ?? true,
      emailNotifications: Map<String, bool>.from(map['emailNotifications'] ?? {}),
      pushNotifications: Map<String, bool>.from(map['pushNotifications'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentReminders': paymentReminders,
      'leaseExpiry': leaseExpiry,
      'maintenanceUpdates': maintenanceUpdates,
      'occupancyAlerts': occupancyAlerts,
      'dailyReports': dailyReports,
      'tenantMessages': tenantMessages,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
    };
  }

  NotificationSettings copyWith({
    bool? paymentReminders,
    bool? leaseExpiry,
    bool? maintenanceUpdates,
    bool? occupancyAlerts,
    bool? dailyReports,
    bool? tenantMessages,
    Map<String, bool>? emailNotifications,
    Map<String, bool>? pushNotifications,
  }) {
    return NotificationSettings(
      paymentReminders: paymentReminders ?? this.paymentReminders,
      leaseExpiry: leaseExpiry ?? this.leaseExpiry,
      maintenanceUpdates: maintenanceUpdates ?? this.maintenanceUpdates,
      occupancyAlerts: occupancyAlerts ?? this.occupancyAlerts,
      dailyReports: dailyReports ?? this.dailyReports,
      tenantMessages: tenantMessages ?? this.tenantMessages,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = false;
  late NotificationSettings _settings;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _settings = NotificationSettings();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('settings')
            .doc('notifications')
            .get();

        if (doc.exists) {
          setState(() {
            _settings = NotificationSettings.fromMap(doc.data()!);
          });
        }
      }
    } catch (e) {
      showErrorDialog(context, 'Error loading notification settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('settings')
            .doc('notifications')
            .set(_settings.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      showErrorDialog(context, 'Error saving notification settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (newValue) {
        setState(() {
          onChanged(newValue);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection(
                'General Notifications',
                [
                  _buildNotificationToggle(
                    'Payment Reminders',
                    'Get notified about upcoming and overdue payments',
                    _settings.paymentReminders,
                    (value) => _settings =
                        _settings.copyWith(paymentReminders: value),
                  ),
                  _buildNotificationToggle(
                    'Lease Expiry',
                    'Get notified about upcoming lease expirations',
                    _settings.leaseExpiry,
                    (value) => _settings = _settings.copyWith(leaseExpiry: value),
                  ),
                  _buildNotificationToggle(
                    'Maintenance Updates',
                    'Get notified about maintenance requests and updates',
                    _settings.maintenanceUpdates,
                    (value) => _settings =
                        _settings.copyWith(maintenanceUpdates: value),
                  ),
                  _buildNotificationToggle(
                    'Occupancy Alerts',
                    'Get notified about property occupancy changes',
                    _settings.occupancyAlerts,
                    (value) =>
                        _settings = _settings.copyWith(occupancyAlerts: value),
                  ),
                  _buildNotificationToggle(
                    'Daily Reports',
                    'Receive daily summary reports',
                    _settings.dailyReports,
                    (value) =>
                        _settings = _settings.copyWith(dailyReports: value),
                  ),
                  _buildNotificationToggle(
                    'Tenant Messages',
                    'Get notified about tenant communications',
                    _settings.tenantMessages,
                    (value) =>
                        _settings = _settings.copyWith(tenantMessages: value),
                  ),
                ],
              ),
              _buildSection(
                'Email Notifications',
                _settings.emailNotifications.entries.map((entry) {
                  return _buildNotificationToggle(
                    '${entry.key.substring(0, 1).toUpperCase()}${entry.key.substring(1)}',
                    'Receive email notifications for ${entry.key}',
                    entry.value,
                    (value) {
                      final newEmailSettings =
                          Map<String, bool>.from(_settings.emailNotifications);
                      newEmailSettings[entry.key] = value;
                      _settings =
                          _settings.copyWith(emailNotifications: newEmailSettings);
                    },
                  );
                }).toList(),
              ),
              _buildSection(
                'Push Notifications',
                _settings.pushNotifications.entries.map((entry) {
                  return _buildNotificationToggle(
                    '${entry.key.substring(0, 1).toUpperCase()}${entry.key.substring(1)}',
                    'Receive push notifications for ${entry.key}',
                    entry.value,
                    (value) {
                      final newPushSettings =
                          Map<String, bool>.from(_settings.pushNotifications);
                      newPushSettings[entry.key] = value;
                      _settings =
                          _settings.copyWith(pushNotifications: newPushSettings);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
