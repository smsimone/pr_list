import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextTheme {
  static TextTheme light() {
    return GoogleFonts.ibmPlexSansTextTheme();
  }

  static TextTheme dark() {
    return GoogleFonts.ibmPlexSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );
  }
}
