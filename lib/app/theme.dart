import 'package:flutter/material.dart';

const appPrimary = Color(0xFF3DDC97);
const appAccent = Color(0xFFE8A33B);
const appBackground = Color(0xFF0E1210);
const appSurface = Color(0xFF171F1B);
const appMuted = Color(0xFF9AAEA4);
const appBlue = Color(0xFF5EB3FF);
const appWhatsApp = Color(0xFF25D366);

ThemeData buildAppTheme() {
  final colorScheme = const ColorScheme.dark(
    primary: appPrimary,
    secondary: appAccent,
    surface: appSurface,
    onPrimary: Color(0xFF0A1511),
    onSecondary: Color(0xFF1F2019),
    onSurface: Color(0xFFE8F0EC),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: appBackground,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: appSurface,
      indicatorColor: appPrimary.withValues(alpha: 0.22),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: appBackground,
      foregroundColor: Color(0xFFE8F0EC),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: appSurface,
      labelStyle: const TextStyle(color: appMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: appPrimary.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: appPrimary, width: 1.4),
      ),
    ),
    cardTheme: CardThemeData(
      color: appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: appPrimary,
        foregroundColor: const Color(0xFF0A1511),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return appPrimary.withValues(alpha: 0.22);
          }
          return appSurface;
        }),
      ),
    ),
  );
}
