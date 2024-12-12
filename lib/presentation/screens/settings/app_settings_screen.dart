
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:house_rental_app/presentation/shared/widgets/custom_components.dart';

class AppSettings {
  final String theme;
  final String language;
  final String currency;
  final String dateFormat;
  final bool autoBackup;
  final int backupFrequency;
  final bool analyticsEnabled;
  final Map<String, dynamic> customSettings;

  AppSettings({
    this.theme = 'system',
    this.language = 'en',
    this.currency = 'INR',
    this.dateFormat = 'dd/MM/yyyy',
    this.autoBackup = true,
    this.backupFrequency = 7,
    this.analyticsEnabled = true,
    Map<String, dynamic>? customSettings,
  }) : this.customSettings = customSettings ?? {};

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      theme: map['theme'] ?? 'system',
      language: map['language'] ?? 'en',
      currency: map['currency'] ?? 'INR',
      dateFormat: map['dateFormat'] ?? 'dd/MM/yyyy',
      autoBackup: map['autoBackup'] ?? true,
      backupFrequency: map['backupFrequency'] ?? 7,
      analyticsEnabled: map['analyticsEnabled'] ?? true,
      customSettings: Map<String, dynamic>.from(map['customSettings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'language': language,
      'currency': currency,
      'dateFormat': dateFormat,
      'autoBackup': autoBackup,
      'backupFrequency': backupFrequency,
      'analyticsEnabled': analyticsEnabled,
      'customSettings': customSettings,
    };
  }

  AppSettings copyWith({
    String? theme,
    String? language,
    String? currency,
    String? dateFormat,
    bool? autoBackup,
    int? backupFrequency,
    bool? analyticsEnabled,
    Map<String, dynamic>? customSettings,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      autoBackup: autoBackup ?? this.autoBackup,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

class AppSettingsScreen extends StatefulWidget {
  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _isLoading = false;
  late AppSettings _settings;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final List<String> _availableThemes = ['system', 'light', 'dark'];
  final List<String> _availableLanguages = ['en', 'hi', 'es'];
  final List<String> _availableCurrencies = ['INR', 'USD', 'EUR'];
  final List<String> _availableDateFormats = [
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'yyyy-MM-dd'
  ];

  @override
  void initState() {
    super.initState();
    _settings = AppSettings();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      // Load from SharedPreferences first for immediate display
      final prefs = await SharedPreferences.getInstance();
      final localSettings = prefs.getString('appSettings');
      if (localSettings != null) {
        setState(() {
          _settings = AppSettings.fromMap(
              Map<String, dynamic>.from(json.decode(localSettings)));
        });
      }

      // Then load from Firestore for sync
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('settings')
            .doc('app')
            .get();

        if (doc.exists) {
          final firebaseSettings = AppSettings.fromMap(doc.data()!);
          setState(() {
            _settings = firebaseSettings;
          });
          // Update local storage
          await prefs.setString(
              'appSettings', json.encode(firebaseSettings.toMap()));
        }
      }
    } catch (e) {
      showErrorDialog(context, 'Error loading app settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appSettings', json.encode(_settings.toMap()));

      // Save to Firestore
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('settings')
            .doc('app')
            .set(_settings.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings saved successfully')),
        );
      }

      // Apply settings
      _applySettings();
    } catch (e) {
      showErrorDialog(context, 'Error saving app settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applySettings() {
    // Apply theme
    switch (_settings.theme) {
      case 'light':
        ThemeMode.light;
        break;
      case 'dark':
        ThemeMode.dark;
        break;
      default:
        ThemeMode.system;
    }

    // Apply language
    // This would typically use a localization package
    
    // Apply currency format
    // Update currency formatter

    // Apply date format
    // Update date formatter
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

  Widget _buildSettingItem(String title, String subtitle, Widget child) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Container(
        width: 150,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Settings'),
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
                'Appearance',
                [
                  _buildSettingItem(
                    'Theme',
                    'Choose app theme',
                    DropdownButtonFormField<String>(
                      value: _settings.theme,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      items: _availableThemes.map((theme) {
                        return DropdownMenuItem(
                          value: theme,
                          child: Text(theme.capitalize()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _settings = _settings.copyWith(theme: value);
                          });
                        }
                      },
                    ),
                  ),
                  _buildSettingItem(
                    'Language',
                    'Select app language',
                    DropdownButtonFormField<String>(
                      value: _settings.language,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      items: _availableLanguages.map((lang) {
                        return DropdownMenuItem(
                          value: lang,
                          child: Text(lang.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _settings = _settings.copyWith(language: value);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              _buildSection(
                'Regional',
                [
                  _buildSettingItem(
                    'Currency',
                    'Select preferred currency',
                    DropdownButtonFormField<String>(
                      value: _settings.currency,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      items: _availableCurrencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _settings = _settings.copyWith(currency: value);
                          });
                        }
                      },
                    ),
                  ),
                  _buildSettingItem(
                    'Date Format',
                    'Choose date display format',
                    DropdownButtonFormField<String>(
                      value: _settings.dateFormat,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      items: _availableDateFormats.map((format) {
                        return DropdownMenuItem(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _settings = _settings.copyWith(dateFormat: value);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              _buildSection(
                'Backup & Security',
                [
                  SwitchListTile(
                    title: Text('Auto Backup'),
                    subtitle: Text('Automatically backup data'),
                    value: _settings.autoBackup,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(autoBackup: value);
                      });
                    },
                  ),
                  if (_settings.autoBackup)
                    _buildSettingItem(
                      'Backup Frequency',
                      'Days between backups',
                      DropdownButtonFormField<int>(
                        value: _settings.backupFrequency,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        items: [1, 3, 7, 14, 30].map((days) {
                          return DropdownMenuItem(
                            value: days,
                            child: Text('$days days'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _settings =
                                  _settings.copyWith(backupFrequency: value);
                            });
                          }
                        },
                      ),
                    ),
                  SwitchListTile(
                    title: Text('Analytics'),
                    subtitle: Text('Help improve the app by sharing usage data'),
                    value: _settings.analyticsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(analyticsEnabled: value);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
