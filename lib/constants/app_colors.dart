import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF00897B);
  static const Color primaryDark = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF4DB6AC);

  // Accent Colors
  static const Color accent = Color(0xFFFFB300);
  static const Color accentLight = Color(0xFFFFD54F);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);

  // Category Colors (Gradient Pairs)
  static const List<List<Color>> categoryGradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)], // Purple
    [Color(0xFFf093fb), Color(0xFFf5576c)], // Pink
    [Color(0xFF4facfe), Color(0xFF00f2fe)], // Blue
    [Color(0xFF43e97b), Color(0xFF38f9d7)], // Green
    [Color(0xFFfa709a), Color(0xFFfee140)], // Orange
    [Color(0xFF30cfd0), Color(0xFF330867)], // Teal
    [Color(0xFFa8edea), Color(0xFFfed6e3)], // Pastel
    [Color(0xFFff9a56), Color(0xFFff6a88)], // Coral
  ];

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF29B6F6);

  // Get gradient by category
  static List<Color> getGradientForCategory(String? category) {
    if (category == null) return categoryGradients[0];
    int index = category.hashCode.abs() % categoryGradients.length;
    return categoryGradients[index];
  }

  // Get single color from hex
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
