import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

/// Modèle générique pour les réponses API SEZAM
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  /// Message de réponse
  final String message;
  
  /// Données de la réponse (générique)
  final T? data;
  
  /// Token d'authentification (optionnel)
  final String? token;
  
  /// Indique si une vérification OTP est requise
  @JsonKey(name: 'requires_otp')
  final bool? requiresOtp;

  ApiResponse({
    required this.message,
    this.data,
    this.token,
    this.requiresOtp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}

