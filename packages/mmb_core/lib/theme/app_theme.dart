import 'package:flutter/material.dart';

class MmbColors {
  static const deepBlue = Color(0xFF1746D1);
  static const darkBlue = Color(0xFF0B2A8A);
  static const orange = Color(0xFFFF7A00);
  static const yellow = Color(0xFFFFC107);
  static const bg = Color(0xFFF3F6FD);
  static const success = Color(0xFF1FA463);
  static const danger = Color(0xFFE5393F);
}

class MmbTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: MmbColors.deepBlue,
      brightness: b,
      primary: isDark ? const Color(0xFF8FA8FF) : MmbColors.deepBlue,
      secondary: MmbColors.orange,
      tertiary: MmbColors.yellow,
    );
    final radius = BorderRadius.circular(14);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F1220) : MmbColors.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF171B2E) : MmbColors.deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF1B2036) : Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1B2036) : Colors.white,
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: MmbColors.deepBlue, width: 1.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MmbColors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: MmbColors.yellow.withValues(alpha: 0.35),
        height: 66,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
