import 'package:json_annotation/json_annotation.dart';

part 'partner_model.g.dart';

/// Modèle de partenaire
@JsonSerializable()
class PartnerModel {
  final String id;
  final String name;
  @JsonKey(name: 'legal_name')
  final String? legalName;
  @JsonKey(name: 'short_name')
  final String? shortName;
  final Map<String, dynamic>? type;
  final Map<String, dynamic>? status;
  final String? email;
  final String? phone;
  final String? website;
  @JsonKey(name: 'full_address')
  final String? fullAddress;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'verified_at')
  final DateTime? verifiedAt;
  @JsonKey(name: 'subscription_tier')
  final String? subscriptionTier;
  @JsonKey(name: 'can_access_api')
  final bool canAccessApi;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  PartnerModel({
    required this.id,
    required this.name,
    this.legalName,
    this.shortName,
    this.type,
    this.status,
    this.email,
    this.phone,
    this.website,
    this.fullAddress,
    this.logoUrl,
    required this.isVerified,
    this.verifiedAt,
    this.subscriptionTier,
    required this.canAccessApi,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) =>
      _$PartnerModelFromJson(json);

  Map<String, dynamic> toJson() => _$PartnerModelToJson(this);

  String get typeName => type?['display_name'] ?? type?['name'] ?? 'Autre';
  String get statusName => status?['display_name'] ?? status?['name'] ?? 'Inconnu';
  String get displayName => shortName ?? name;
}

