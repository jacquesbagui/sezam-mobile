// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  userCode: json['user_code'] as String?,
  profileImage: json['profile_image'] as String?,
  emailVerifiedAt: json['email_verified_at'] == null
      ? null
      : DateTime.parse(json['email_verified_at'] as String),
  mfaEnabled: json['mfa_enabled'] as bool?,
  profile: json['profile'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'email': instance.email,
  'phone': instance.phone,
  'user_code': instance.userCode,
  'profile_image': instance.profileImage,
  'email_verified_at': instance.emailVerifiedAt?.toIso8601String(),
  'mfa_enabled': instance.mfaEnabled,
  'profile': instance.profile,
};
