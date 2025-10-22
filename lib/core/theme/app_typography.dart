import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographie de l'application SEZAM
/// Utilise SF Pro pour iOS et Roboto pour Android
class AppTypography {
  // Familles de polices
  static String get primaryFontFamily => GoogleFonts.inter().fontFamily!;
  static String get secondaryFontFamily => GoogleFonts.roboto().fontFamily!;
  
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
  static TextStyle get headline1 => GoogleFonts.inter(
    fontSize: fontSize4xl,
    fontWeight: FontWeight.bold,
    height: lineHeightTight,
  );
  
  static TextStyle get headline2 => GoogleFonts.inter(
    fontSize: fontSize3xl,
    fontWeight: FontWeight.bold,
    height: lineHeightTight,
  );
  
  static TextStyle get headline3 => GoogleFonts.inter(
    fontSize: fontSize2xl,
    fontWeight: FontWeight.bold,
    height: lineHeightTight,
  );
  
  static TextStyle get headline4 => GoogleFonts.inter(
    fontSize: fontSizeXl,
    fontWeight: FontWeight.w600,
    height: lineHeightTight,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: fontSizeLg,
    fontWeight: FontWeight.normal,
    height: lineHeightNormal,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: fontSizeBase,
    fontWeight: FontWeight.normal,
    height: lineHeightNormal,
  );
  
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: fontSizeSm,
    fontWeight: FontWeight.normal,
    height: lineHeightNormal,
  );
  
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: fontSizeXs,
    fontWeight: FontWeight.normal,
    height: lineHeightNormal,
  );
  
  static TextStyle get button => GoogleFonts.inter(
    fontSize: fontSizeBase,
    fontWeight: FontWeight.w600,
    height: lineHeightTight,
  );
  
  static TextStyle get label => GoogleFonts.inter(
    fontSize: fontSizeSm,
    fontWeight: FontWeight.w500,
    height: lineHeightTight,
  );
}
