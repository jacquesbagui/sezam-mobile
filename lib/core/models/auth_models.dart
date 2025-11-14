import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_models.g.dart';

/// Modèle pour les requêtes d'authentification
@JsonSerializable()
class LoginRequest {
  /// Identifiant (email ou téléphone)
  final String identifier;
  
  /// Mot de passe
  final String password;

  LoginRequest({
    required this.identifier,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

/// Modèle pour les requêtes d'inscription
@JsonSerializable()
class RegisterRequest {
  /// Prénom
  @JsonKey(name: 'first_name')
  final String firstName;
  
  /// Nom
  @JsonKey(name: 'last_name')
  final String lastName;
  
  /// Email
  final String email;
  
  /// Téléphone (optionnel)
  final String? phone;
  
  /// Mot de passe
  final String password;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.password,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

/// Modèle pour les requêtes de vérification OTP
@JsonSerializable()
class VerifyOtpRequest {
  /// Email de l'utilisateur
  final String email;
  
  /// Code OTP
  final String code;

  VerifyOtpRequest({
    required this.email,
    required this.code,
  });

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyOtpRequestToJson(this);
}

/// Modèle pour les réponses d'authentification
@JsonSerializable()
class AuthResponse {
  /// Message de réponse
  final String message;
  
  /// Données utilisateur
  final UserModel? data;
  
  /// Token d'authentification
  final String? token;
  
  /// Indique si une vérification OTP est requise
  @JsonKey(name: 'requires_otp')
  final bool requiresOtp;

  AuthResponse({
    required this.message,
    this.data,
    this.token,
    this.requiresOtp = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

/// Modèle pour les requêtes de mot de passe oublié
@JsonSerializable()
class ForgotPasswordRequest {
  /// Email
  final String email;

  ForgotPasswordRequest({
    required this.email,
  });

  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ForgotPasswordRequestToJson(this);
}

/// Modèle pour les requêtes de réinitialisation de mot de passe
@JsonSerializable()
class ResetPasswordRequest {
  /// Email
  final String email;
  
  /// Token de réinitialisation
  final String token;
  
  /// Nouveau mot de passe
  @JsonKey(name: 'password')
  final String newPassword;
  
  /// Confirmation du mot de passe
  @JsonKey(name: 'password_confirmation')
  final String passwordConfirmation;

  ResetPasswordRequest({
    required this.email,
    required this.token,
    required this.newPassword,
    required this.passwordConfirmation,
  });

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);
}

