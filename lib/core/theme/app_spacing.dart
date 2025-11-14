import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Espacement et dimensions de l'application SEZAM
/// Basé sur un système de grille de 8pt
class AppSpacing {
  // Espacement de base (8pt grid)
  static const double spacing1 = 4.0;   // 0.5 * 8
  static const double spacing2 = 8.0;   // 1 * 8
  static const double spacing3 = 12.0;  // 1.5 * 8
  static const double spacing4 = 16.0;  // 2 * 8
  static const double spacing5 = 20.0;  // 2.5 * 8
  static const double spacing6 = 24.0;  // 3 * 8
  static const double spacing8 = 32.0;  // 4 * 8
  static const double spacing10 = 40.0; // 5 * 8
  static const double spacing12 = 48.0; // 6 * 8
  static const double spacing16 = 64.0; // 8 * 8
  static const double spacing20 = 80.0; // 10 * 8
  static const double spacing24 = 96.0; // 12 * 8
  
  // Rayons de bordure
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2xl = 24.0;
  static const double radius3xl = 32.0;
  static const double radius4xl = 40.0;
  static const double radius5xl = 48.0;
  static const double radius6xl = 56.0;
  static const double radius7xl = 64.0;
  static const double radius8xl = 72.0;
  static const double radius9xl = 80.0;
  static const double radius10xl = 88.0;
  static const double radiusFull = 9999.0;
  
  // Ombres
  static const List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];
  
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x05000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];
  
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
    ),
    BoxShadow(
      color: Color(0x05000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];
  
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 10),
      blurRadius: 15,
    ),
    BoxShadow(
      color: Color(0x05000000),
      offset: Offset(0, 4),
      blurRadius: 6,
    ),
  ];
  
  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 20),
      blurRadius: 25,
    ),
    BoxShadow(
      color: Color(0x05000000),
      offset: Offset(0, 10),
      blurRadius: 10,
    ),
  ];
  
  // Ombres colorées pour les éléments primaires
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: AppColors.primaryWithOpacity(0.3),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];
  
  static List<BoxShadow> get secondaryShadow => [
    BoxShadow(
      color: AppColors.secondaryWithOpacity(0.3),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];
  
  // Durées d'animation
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Courbes d'animation
  static const Curve animationCurve = Curves.easeInOut;
  static const Curve animationCurveFast = Curves.easeOut;
  static const Curve animationCurveSlow = Curves.easeInOutCubic;
}
