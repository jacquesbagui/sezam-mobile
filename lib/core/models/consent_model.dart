import 'package:json_annotation/json_annotation.dart';
import 'scope_model.dart';

part 'consent_model.g.dart';

/// Modèle de consentement
@JsonSerializable()
class ConsentModel {
  final String id;
  
  final Map<String, dynamic>? partner;
  
  final Map<String, dynamic>? status;
  
  final String? purpose;
  
  @JsonKey(name: 'granted_at')
  final DateTime? grantedAt;
  
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  
  @JsonKey(name: 'revoked_at')
  final DateTime? revokedAt;
  
  @JsonKey(name: 'denied_at')
  final DateTime? deniedAt;
  
  @JsonKey(fromJson: _scopesFromJson, toJson: _scopesToJson)
  final List<ScopeModel>? scopes;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  ConsentModel({
    required this.id,
    this.partner,
    this.status,
    this.purpose,
    this.grantedAt,
    this.expiresAt,
    this.revokedAt,
    this.deniedAt,
    this.scopes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConsentModel.fromJson(Map<String, dynamic> json) =>
      _$ConsentModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConsentModelToJson(this);
  
  String get partnerName => partner?['name'] ?? 'Inconnu';
  
  /// Obtenir le nom du statut (gère différents formats possibles)
  String get statusName {
    if (status == null) {
      // Si pas de statut mais qu'il y a des dates, déterminer le statut
      if (grantedAt != null) return 'granted';
      if (deniedAt != null) return 'denied';
      if (revokedAt != null) return 'revoked';
      // Par défaut, si aucune date et pas de statut, considérer comme pending
      return 'pending';
    }
    
    // Essayer différents formats possibles
    final name = status?['name'];
    if (name != null && name is String) {
      return name.toLowerCase();
    }
    
    // Essayer avec 'status' directement
    final directStatus = status?['status'];
    if (directStatus != null && directStatus is String) {
      return directStatus.toLowerCase();
    }
    
    // Fallback: déterminer par les dates
    if (grantedAt != null) return 'granted';
    if (deniedAt != null) return 'denied';
    if (revokedAt != null) return 'revoked';
    
    return 'pending';
  }
  
  bool get isGranted => statusName == 'granted';
  bool get isPending => statusName == 'pending';
  bool get isDenied => statusName == 'denied' || statusName == 'refused';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  int get scopesCount => scopes?.length ?? 0;
  String get category => partner?['category'] ?? 'Organisation';
}

// Helper functions pour la sérialisation des scopes implicit
List<ScopeModel>? _scopesFromJson(dynamic json) {
  if (json == null) return null;
  if (json is List) {
    return json
        .where((item) => item is Map<String, dynamic>)
        .map((item) => ScopeModel.fromJson(item))
        .toList();
  }
  return null;
}

dynamic _scopesToJson(List<ScopeModel>? scopes) {
  return scopes?.map((scope) => scope.toJson()).toList();
}

