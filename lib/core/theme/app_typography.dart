import 'package:flutter/material.dart';

/// Typographie de l'application SEZAM
/// Utilise les polices système par défaut (Roboto sur Android, SF Pro sur iOS)
class AppTypography {
  // Familles de polices - utilise les polices système par défaut
  // null = utilise la police système par défaut de la plateforme
  static String? get primaryFontFamily {
    // Utiliser les polices système natives pour éviter les problèmes de réseau
    // null = Flutter utilisera automatiquement Roboto sur Android et SF Pro sur iOS
    return null;
  }
  
  static String? get secondaryFontFamily {
    return null; // Utilise la police système par défaut
  }
  
  // Helper pour créer un TextStyle avec fallback
  static TextStyle _createTextStyle({
    required double fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) {
    return TextStyle(
      // null = utilise la police système par défaut (Roboto sur Android, SF Pro sur iOS)
      fontFamily: primaryFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      height: height,
      color: color,
      // Fallback vers les polices système si la police spécifiée n'est pas disponible
      fontFamilyFallback: const ['sans-serif'],
    );
  }
  
  // Tailles de police
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 24.0;
  static const double fontSize3xl = 30.0;
  static const double fontSize4xl = 36.0;
  
  // Hauteurs de ligne
  static const double lineHeightTight = 1.25;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;
  
  // Styles de texte prédéfinis
  static TextStyle get headline1 => _createTextStyle(
    fontSize: fontSize4xl,
    fontWeight: FontWeight.bold,
    height: lineHeightTight,
  );
  
  static TextStyle get headline2 => _createTextStyle(
    fontSize: fontSize3xl,
    fontWeight: FontWeight.bold,
    height: lineHeightTight,
  );
  
  static TextStyle get headline3 => _createTextStyle(
    fontSize: fontSize2xl,
    fontWeight: FontWeight.bold,
    height: lineHeightTight,
  );
  
  static TextStyle get headline4 => _createTextStyle(
    fontSize: fontSizeXl,
    fontWeight: FontWeight.w600,
    height: lineHeightTight,
  );
  
  static TextStyle get bodyLarge => _createTextStyle(
    fontSize: fontSizeLg,
    fontWeight: FontWeight.normal,
    height: lineHeightNormal,
  );
  
  static TextStyle get bodyMedium => _createTextStyle(
    fontSize: fontSizeBase,
    fontWeight: FontWeight.normal,
    height: lineHeightNormal,
  );
  
  static TextStyle get bodySmall => _createTextStyle(
    fontSize: fontSizeSm,
    fontWeight: FontWeight.normal,
    height: lineHeightNormal,
  );

  static TextStyle get bodyXSmall => _createTextStyle(
    fontSize: fontSizeXs,
    fontWeight: FontWeight.normal,
    height: lineHeightNormal,
  );
  
  static TextStyle get caption => _createTextStyle(
    fontSize: fontSizeXs,
    fontWeight: FontWeight.normal,
    height: lineHeightNormal,
  );
  
  static TextStyle get button => _createTextStyle(
    fontSize: fontSizeBase,
    fontWeight: FontWeight.w600,
    height: lineHeightTight,
  );
  
  static TextStyle get label => _createTextStyle(
    fontSize: fontSizeSm,
    fontWeight: FontWeight.w500,
    height: lineHeightTight,
  );
}
