import 'package:flutter/material.dart';

class AppConstants {
  // Cores
  static const Color primaryColor = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFF2E7D32);
  static const Color lightGreenShade1 = Color(0xFFF0F7F0);
  static const Color lightGreenShade2 = Color(0xFFE8F0E8);
  static const Color darkerLightGreen = Color(0xFF1A5C1A);
  static const Color darkerGreen = Color(0xFF145214);
  static const Color textGrey = Colors.grey;
  static const Color textGrey200 =
      Color(0xFFEEEEEE); // Equivalente a Colors.grey.shade200
  static const Color textGrey300 =
      Color(0xFFE0E0E0); // Equivalente a Colors.grey.shade300
  static const Color textGrey400 =
      Color(0xFFB0B0B0); // Equivalente a Colors.grey.shade400
  static const Color textBlack = Colors.black;
  static const Color white = Colors.white;
  static const Color red = Colors.red;
  static const Color green = Colors.green;
  static const Color orange = Colors.orange;

  // Dimensões
  static const double defaultPadding = 16.0;
  static const double buttonHeight = 50.0;
  static const double borderRadius = 12.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 12.0;
  static const double largeSpacing = 24.0;

  // Estilos de texto
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textBlack,
  );
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: textGrey,
  );
  static const TextStyle bodyBoldStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: textGrey,
  );
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: white,
  );
}
