import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyLanguage = 'app_language';

  static SettingsService? _instance;
  static SettingsService get instance => _instance!;

  late final SharedPreferences _prefs;

  SettingsService._();

  static Future<void> initialize() async {
    final service = SettingsService._();
    service._prefs = await SharedPreferences.getInstance();
    _instance = service;
  }

  String get appLanguage => _prefs.getString(_keyLanguage) ?? 'ar';

  Future<void> setAppLanguage(String lang) =>
      _prefs.setString(_keyLanguage, lang);

  Future<void> resetToDefaults() => _prefs.remove(_keyLanguage);
}
