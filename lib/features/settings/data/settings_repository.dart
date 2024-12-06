import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../domain/app_settings.dart';

class SettingsRepository {
  static const String _settingsKey = 'app_settings';

  Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson == null) return AppSettings();

    try {
      final settingsMap = json.decode(settingsJson);
      return AppSettings.fromMap(settingsMap);
    } catch (e) {
      print('Error loading settings: $e');
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toMap()));
  }

  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }
}