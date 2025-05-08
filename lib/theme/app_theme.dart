import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF6200EA); // Deep Purple
  static const Color secondaryColor = Color(0xFF9C27B0); // Purple
  static const Color accentColor = Color(0xFF7C4DFF); // Deep Purple Accent
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFF3E5F5); // Light Purple
  static const Color darkBackgroundColor = Color(0xFF1A1045); // Deep Dark Purple
  
  // Text Colors
  static const Color textColor = Color(0xFF2A1B3D); // Dark Purple
  static const Color darkTextColor = Color(0xFFE9E1F9); // Light Purple
  
  // Additional Colors
  static const Color surfaceColor = Color(0xFFFAF6FF); // Very Light Purple
  static const Color darkSurfaceColor = Color(0xFF2D1B4E); // Dark Purple Surface
  static const Color errorColor = Color(0xFFB00020); // Error Red

  // Gradient Colors
  static const List<Color> lightGradientColors = [
    Color(0xFFF3E5F5), // Light Purple
    Color(0xFFE1BEE7), // Lighter Purple
    Color(0xFFD1C4E9), // Light Deep Purple
    Color(0xFFE8EAF6), // Light Indigo
  ];

  static const List<Color> darkGradientColors = [
    Color(0xFF1A1045), // Deep Dark Purple
    Color(0xFF2D1B4E), // Dark Purple
    Color(0xFF3C1B63), // Rich Purple
    Color(0xFF2B1B41), // Deep Purple
  ];

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF1E88E5),       // Bright blue
      secondary: const Color(0xFF42A5F5),     // Light blue
      tertiary: const Color(0xFF90CAF9),      // Very light blue
      background: Colors.white,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.black87,
      onSurface: Colors.black87,
      error: Colors.red.shade700,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white.withOpacity(0.9),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E88E5),
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF1E88E5),
      unselectedItemColor: Colors.black54,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF42A5F5),       // Light blue
      secondary: const Color(0xFF90CAF9),     // Very light blue
      tertiary: const Color(0xFF1E88E5),      // Bright blue
      background: const Color(0xFF1A1A1A),
      surface: const Color(0xFF2C2C2C),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
      error: Colors.red.shade300,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF2C2C2C).withOpacity(0.9),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      foregroundColor: Color(0xFF42A5F5),
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedItemColor: Color(0xFF42A5F5),
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
} 