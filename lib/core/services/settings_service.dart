import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyBackendUrl = 'backend_base_url';

  static SettingsService? _instance;
  static SettingsService get instance => _instance!;

  late final SharedPreferences _prefs;

  SettingsService._();

  static Future<void> initialize() async {
    final service = SettingsService._();
    service._prefs = await SharedPreferences.getInstance();
    _instance = service;
  }

  static String get _platformDefault =>
      Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';

  String get backendBaseUrl =>
      _prefs.getString(_keyBackendUrl) ?? _platformDefault;

  Future<void> setBackendBaseUrl(String url) =>
      _prefs.setString(_keyBackendUrl, url);

  Future<void> resetToDefaults() => _prefs.remove(_keyBackendUrl);
}
