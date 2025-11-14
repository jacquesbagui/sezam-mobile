import 'dart:math';

/// Service de gestion de la double authentification
class TwoFactorAuthService {
  static final TwoFactorAuthService _instance = TwoFactorAuthService._internal();
  factory TwoFactorAuthService() => _instance;
  TwoFactorAuthService._internal();

  /// Générer un code de vérification à 6 chiffres
  static String generateVerificationCode() {
    final random = Random();
    final code = random.nextInt(900000) + 100000; // Entre 100000 et 999999
    return code.toString();
  }

  /// Envoyer un code de vérification par SMS
  static Future<bool> sendSMSVerificationCode(String phoneNumber) async {
    try {
      // Simulation d'envoi SMS
      await Future.delayed(const Duration(seconds: 1));
      
      // Dans une vraie implémentation, vous utiliseriez un service SMS comme Twilio
      // await TwilioService.sendSMS(phoneNumber, 'Votre code SEZAM: $code');
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Envoyer un code de vérification par email
  static Future<bool> sendEmailVerificationCode(String email) async {
    try {
      // Simulation d'envoi email
      await Future.delayed(const Duration(seconds: 1));
      
      // Dans une vraie implémentation, vous utiliseriez un service email
      // await EmailService.sendEmail(email, 'Code de vérification SEZAM', 'Votre code: $code');
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Vérifier un code de vérification
  static Future<bool> verifyCode(String inputCode, String expectedCode) async {
    try {
      // Simulation de vérification
      await Future.delayed(const Duration(milliseconds: 500));
      
      return inputCode == expectedCode;
    } catch (e) {
      return false;
    }
  }

  /// Vérifier l'authentification biométrique
  static Future<bool> verifyBiometricAuth() async {
    try {
      // Simulation d'authentification biométrique
      await Future.delayed(const Duration(seconds: 1));
      
      // Dans une vraie implémentation, vous utiliseriez local_auth
      // final LocalAuthentication auth = LocalAuthentication();
      // return await auth.authenticate(
      //   localizedReason: 'Confirmez votre identité pour valider la demande',
      //   options: const AuthenticationOptions(
      //     biometricOnly: true,
      //     stickyAuth: true,
      //   ),
      // );
      
      // Simulation : 90% de succès
      return Random().nextDouble() > 0.1;
    } catch (e) {
      return false;
    }
  }

  /// Valider une demande avec double authentification
  static Future<TwoFactorAuthResult> validateRequest({
    required String requestId,
    required String verificationCode,
    required String expectedCode,
    bool useBiometric = false,
  }) async {
    try {
      bool isValid = false;
      
      if (useBiometric) {
        isValid = await verifyBiometricAuth();
      } else {
        isValid = await verifyCode(verificationCode, expectedCode);
      }

      if (isValid) {
        // Simulation de validation de la demande
        await Future.delayed(const Duration(seconds: 1));
        
        return TwoFactorAuthResult.success(
          message: 'Demande validée avec succès',
          requestId: requestId,
        );
      } else {
        return TwoFactorAuthResult.failure(
          message: useBiometric 
              ? 'Authentification biométrique échouée'
              : 'Code de vérification incorrect',
        );
      }
    } catch (e) {
      return TwoFactorAuthResult.failure(
        message: 'Erreur lors de la validation: ${e.toString()}',
      );
    }
  }

  /// Obtenir le temps d'expiration du code (en secondes)
  static int getCodeExpirationTime() {
    return 300; // 5 minutes
  }

  /// Vérifier si un code est expiré
  static bool isCodeExpired(DateTime sentTime) {
    final now = DateTime.now();
    final difference = now.difference(sentTime).inSeconds;
    return difference > getCodeExpirationTime();
  }
}

/// Résultat de la double authentification
class TwoFactorAuthResult {
  final bool isSuccess;
  final String message;
  final String? requestId;
  final DateTime timestamp;

  TwoFactorAuthResult._({
    required this.isSuccess,
    required this.message,
    this.requestId,
    required this.timestamp,
  });

  factory TwoFactorAuthResult.success({
    required String message,
    String? requestId,
  }) {
    return TwoFactorAuthResult._(
      isSuccess: true,
      message: message,
      requestId: requestId,
      timestamp: DateTime.now(),
    );
  }

  factory TwoFactorAuthResult.failure({
    required String message,
  }) {
    return TwoFactorAuthResult._(
      isSuccess: false,
      message: message,
      timestamp: DateTime.now(),
    );
  }
}

/// Configuration de la double authentification
class TwoFactorAuthConfig {
  final bool enableSMS;
  final bool enableEmail;
  final bool enableBiometric;
  final int codeLength;
  final int expirationTimeMinutes;

  const TwoFactorAuthConfig({
    this.enableSMS = true,
    this.enableEmail = true,
    this.enableBiometric = true,
    this.codeLength = 6,
    this.expirationTimeMinutes = 5,
  });

  static const TwoFactorAuthConfig defaultConfig = TwoFactorAuthConfig();
}
