import 'package:flutter/material.dart';
import 'package:pr_list/shared/theme/app_colors.dart';
import 'package:pr_list/shared/theme/app_text_theme.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kSeed,
        brightness: Brightness.light,
      ),
      textTheme: AppTextTheme.light(),
      scaffoldBackgroundColor: AppColors.kBackgroundLight,
      cardColor: AppColors.kSurfaceLight,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kSeed,
        brightness: Brightness.dark,
      ),
      textTheme: AppTextTheme.dark(),
      scaffoldBackgroundColor: AppColors.kBackgroundDark,
      cardColor: AppColors.kSurfaceDark,
    );
  }
}
