// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PartnerModel _$PartnerModelFromJson(Map<String, dynamic> json) => PartnerModel(
  id: json['id'] as String,
  name: json['name'] as String,
  legalName: json['legal_name'] as String?,
  shortName: json['short_name'] as String?,
  type: json['type'] as Map<String, dynamic>?,
  status: json['status'] as Map<String, dynamic>?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  website: json['website'] as String?,
  fullAddress: json['full_address'] as String?,
  logoUrl: json['logo_url'] as String?,
  isVerified: json['is_verified'] as bool,
  verifiedAt: json['verified_at'] == null
      ? null
      : DateTime.parse(json['verified_at'] as String),
  subscriptionTier: json['subscription_tier'] as String?,
  canAccessApi: json['can_access_api'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PartnerModelToJson(PartnerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'legal_name': instance.legalName,
      'short_name': instance.shortName,
      'type': instance.type,
      'status': instance.status,
      'email': instance.email,
      'phone': instance.phone,
      'website': instance.website,
      'full_address': instance.fullAddress,
      'logo_url': instance.logoUrl,
      'is_verified': instance.isVerified,
      'verified_at': instance.verifiedAt?.toIso8601String(),
      'subscription_tier': instance.subscriptionTier,
      'can_access_api': instance.canAccessApi,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
