import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/app_settings.dart';
import '../../data/settings_repository.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>(
  (ref) => SettingsNotifier(ref.watch(settingsRepositoryProvider)),
);

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _repository.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    try {
      await _repository.saveSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleDarkMode() async {
    state.whenData((settings) async {
      final newSettings = settings.copyWith(darkMode: !settings.darkMode);
      await updateSettings(newSettings);
    });
  }

  Future<void> updateLanguage(String language) async {
    state.whenData((settings) async {
      final newSettings = settings.copyWith(language: language);
      await updateSettings(newSettings);
    });
  }

  Future<void> toggleNotifications(bool enabled) async {
    state.whenData((settings) async {
      final newSettings = settings.copyWith(notificationsEnabled: enabled);
      await updateSettings(newSettings);
    });
  }

  Future<void> updateCurrencyFormat(String format) async {
    state.whenData((settings) async {
      final newSettings = settings.copyWith(currencyFormat: format);
      await updateSettings(newSettings);
    });
  }

  Future<void> updateDateFormat(String format) async {
    state.whenData((settings) async {
      final newSettings = settings.copyWith(dateFormat: format);
      await updateSettings(newSettings);
    });
  }
}