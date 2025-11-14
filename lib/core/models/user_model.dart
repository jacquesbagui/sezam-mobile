import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// Modèle utilisateur
@JsonSerializable()
class UserModel {
  final String id;
  
  @JsonKey(name: 'first_name')
  final String firstName;
  
  @JsonKey(name: 'last_name')
  final String lastName;
  
  final String email;
  final String? phone;
  
  @JsonKey(name: 'user_code')
  final String? userCode;
  
  @JsonKey(name: 'profile_image')
  final String? profileImage;
  
  @JsonKey(name: 'email_verified_at')
  final DateTime? emailVerifiedAt;
  
  @JsonKey(name: 'mfa_enabled')
  final bool? mfaEnabled;
  
  final Map<String, dynamic>? profile;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.userCode,
    this.profileImage,
    this.emailVerifiedAt,
    this.mfaEnabled,
    this.profile,
  });

  String get fullName => '$firstName $lastName';
  
  bool get isEmailVerified => emailVerifiedAt != null;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Exemple de données utilisateur pour la démo
  static UserModel demoUser() {
    return UserModel(
      id: '1',
      firstName: 'Amadou',
      lastName: 'Mbaye',
      email: 'amadou.mbaye@email.com',
      phone: '+221 77 123 45 67',
      userCode: 'USR123456',
      profileImage: 'https://avatar.iran.liara.run/public/3',
      emailVerifiedAt: DateTime.now(),
      mfaEnabled: false,
    );
  }
}

