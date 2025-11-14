// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConsentModel _$ConsentModelFromJson(Map<String, dynamic> json) => ConsentModel(
  id: json['id'] as String,
  partner: json['partner'] as Map<String, dynamic>?,
  status: json['status'] as Map<String, dynamic>?,
  purpose: json['purpose'] as String?,
  grantedAt: json['granted_at'] == null
      ? null
      : DateTime.parse(json['granted_at'] as String),
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  revokedAt: json['revoked_at'] == null
      ? null
      : DateTime.parse(json['revoked_at'] as String),
  deniedAt: json['denied_at'] == null
      ? null
      : DateTime.parse(json['denied_at'] as String),
  scopes: _scopesFromJson(json['scopes']),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ConsentModelToJson(ConsentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'partner': instance.partner,
      'status': instance.status,
      'purpose': instance.purpose,
      'granted_at': instance.grantedAt?.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'revoked_at': instance.revokedAt?.toIso8601String(),
      'denied_at': instance.deniedAt?.toIso8601String(),
      'scopes': _scopesToJson(instance.scopes),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
