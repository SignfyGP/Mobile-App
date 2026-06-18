import 'dart:io';

class AppConfig {
  static const String appName = "Signfy";
  static const String logo = "assets/images/logo.png";
  static const String description = "Sign Language Translator";

  static String get backendBaseUrl =>
      Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';
}
