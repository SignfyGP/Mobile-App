import 'package:flutter/material.dart';
import 'package:signfy/core/theme/app_theme.dart';
import 'package:signfy/screens/home_screen.dart';
import 'package:signfy/screens/splash_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const SplashScreen(nextScreen: HomePage()),
      );
}
