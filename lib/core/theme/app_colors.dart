import 'package:flutter/material.dart';

/// Couleurs principales de l'application SEZAM
/// Basées sur la palette "Confiance & Sécurité" du contexte
class AppColors {
  // Couleurs primaires
  static const Color primary = Color(0xFF0066FF); // Bleu électrique
  static const Color primaryDark = Color(0xFF0047B3);
  static const Color secondary = Color(0xFF00D4AA); // Vert/turquoise - validation
  
  // Couleurs de fond
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundLightSecondary = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1D23);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightSecondary = Color(0xFFF5F6F7);
  static const Color surfaceDark = Color(0xFF25282E);
  
  // Couleurs d'état
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color success = Color(0xFF34C759);
  
  // Couleurs de texte
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color textSecondaryDark = Color(0xFFAEAEB2);
  
  // Couleurs neutres
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  
  // Couleurs avec opacité
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color secondaryWithOpacity(double opacity) => secondary.withOpacity(opacity);
  static Color errorWithOpacity(double opacity) => error.withOpacity(opacity);
  static Color warningWithOpacity(double opacity) => warning.withOpacity(opacity);
  static Color successWithOpacity(double opacity) => success.withOpacity(opacity);
}
