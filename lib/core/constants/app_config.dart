import 'dart:io';

class AppConfig {
  static const String appName = "Signfy";
  static const String logo = "assets/images/logo.png";
  static const String description = "Sign Language Translator";

  static String get backendBaseUrl => 'http://51.20.32.34:8000/api' ;
}
