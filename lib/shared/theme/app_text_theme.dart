import 'package:flutter/material.dart';

class AppTextTheme {
  static const kFontFamily = 'IBMPlexSans';

  static TextTheme light() {
    return ThemeData(
      brightness: Brightness.light,
    ).textTheme.apply(fontFamily: kFontFamily);
  }

  static TextTheme dark() {
    return ThemeData(
      brightness: Brightness.dark,
    ).textTheme.apply(fontFamily: kFontFamily);
  }
}
