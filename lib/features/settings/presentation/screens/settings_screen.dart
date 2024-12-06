import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            _SettingsSection(
              title: 'General',
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: settings.darkMode,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleDarkMode();
                  },
                ),
                ListTile(
                  title: const Text('Language'),
                  subtitle: Text(settings.language.toUpperCase()),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Show language selection dialog
                  },
                ),
              ],
            ),
            _SettingsSection(
              title: 'Notifications',
              children: [
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  value: settings.notificationsEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleNotifications(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  value: settings.emailNotifications,
                  enabled: settings.notificationsEnabled,
                  onChanged: settings.notificationsEnabled
                      ? (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateSettings(settings.copyWith(
                                emailNotifications: value,
                              ));
                        }
                      : null,
                ),
                SwitchListTile(
                  title: const Text('SMS Notifications'),
                  value: settings.smsNotifications,
                  enabled: settings.notificationsEnabled,
                  onChanged: settings.notificationsEnabled
                      ? (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateSettings(settings.copyWith(
                                smsNotifications: value,
                              ));
                        }
                      : null,
                ),
              ],
            ),
            _SettingsSection(
              title: 'Format',
              children: [
                ListTile(
                  title: const Text('Currency Format'),
                  subtitle: Text(settings.currencyFormat),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Show currency format selection dialog
                  },
                ),
                ListTile(
                  title: const Text('Date Format'),
                  subtitle: Text(settings.dateFormat),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Show date format selection dialog
                  },
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
}