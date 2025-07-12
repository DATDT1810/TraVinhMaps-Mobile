import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF158247),
      brightness: Brightness.light,
      secondary: Colors.amber,
    ),
    fontFamily: 'Montserrat',
    textTheme: GoogleFonts.montserratTextTheme(),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF158247),
      brightness: Brightness.dark,
      secondary: Colors.amber,
    ),
    fontFamily: 'Montserrat',
    textTheme: GoogleFonts.montserratTextTheme(),
  );
}
