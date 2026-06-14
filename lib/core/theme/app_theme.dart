import 'package:flutter/material.dart';
import 'package:signfy/core/constants/colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cyan,
          brightness: Brightness.dark,
        ).copyWith(
          secondary: AppColors.purple,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cardDark,
          foregroundColor: AppColors.cyan,
          elevation: 0,
          centerTitle: true,
        ),
      );
}
