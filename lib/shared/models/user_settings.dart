class UserSettings {
  final bool notificationsEnabled;
  final bool callSoundEnabled;
  final bool vibrationEnabled;
  final String language;
  final bool darkThemeEnabled;

  UserSettings({
    required this.notificationsEnabled,
    required this.callSoundEnabled,
    required this.vibrationEnabled,
    required this.language,
    required this.darkThemeEnabled,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      notificationsEnabled: json['notifications_enabled'] ?? true,
      callSoundEnabled: json['call_sound_enabled'] ?? true,
      vibrationEnabled: json['vibration_enabled'] ?? true,
      language: json['language'] ?? 'ru',
      darkThemeEnabled: json['dark_theme_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications_enabled': notificationsEnabled,
      'call_sound_enabled': callSoundEnabled,
      'vibration_enabled': vibrationEnabled,
      'language': language,
      'dark_theme_enabled': darkThemeEnabled,
    };
  }
  
  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? callSoundEnabled,
    bool? vibrationEnabled,
    String? language,
    bool? darkThemeEnabled,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      callSoundEnabled: callSoundEnabled ?? this.callSoundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      language: language ?? this.language,
      darkThemeEnabled: darkThemeEnabled ?? this.darkThemeEnabled,
    );
  }
}
