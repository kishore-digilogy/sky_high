import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color secondaryBlue = Color(0xFF283593);
  static const Color skyBlue = Color(0xFF03A9F4);
  
  // Accents
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentOrange = Color(0xFFFF6D00);
  
  // Neutral
  static const Color black = Color(0xFF0F172A);
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF64748B);
  static const Color lightGrey = Color(0xFFF1F5F9);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [white, lightGrey],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
