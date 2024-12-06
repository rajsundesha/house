class AppSettings {
  final bool darkMode;
  final String language;
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool smsNotifications;
  final String currencyFormat;
  final String dateFormat;

  AppSettings({
    this.darkMode = false,
    this.language = 'en',
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.smsNotifications = true,
    this.currencyFormat = 'USD',
    this.dateFormat = 'dd/MM/yyyy',
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      darkMode: map['darkMode'] ?? false,
      language: map['language'] ?? 'en',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      emailNotifications: map['emailNotifications'] ?? true,
      smsNotifications: map['smsNotifications'] ?? true,
      currencyFormat: map['currencyFormat'] ?? 'USD',
      dateFormat: map['dateFormat'] ?? 'dd/MM/yyyy',
    );
  }

  Map<String, dynamic> toMap() => {
    'darkMode': darkMode,
    'language': language,
    'notificationsEnabled': notificationsEnabled,
    'emailNotifications': emailNotifications,
    'smsNotifications': smsNotifications,
    'currencyFormat': currencyFormat,
    'dateFormat': dateFormat,
  };

  AppSettings copyWith({
    bool? darkMode,
    String? language,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? smsNotifications,
    String? currencyFormat,
    String? dateFormat,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      currencyFormat: currencyFormat ?? this.currencyFormat,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }
}