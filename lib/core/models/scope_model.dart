import 'package:json_annotation/json_annotation.dart';

part 'scope_model.g.dart';

/// Helper pour convertir int/bool en bool
bool _boolFromJson(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  return false;
}

/// Modèle de scope (permission)
@JsonSerializable()
class ScopeModel {
  final String id;
  final String name;
  
  @JsonKey(name: 'display_name')
  final String displayName;
  
  final String? description;
  
  @JsonKey(name: 'is_sensitive', fromJson: _boolFromJson)
  final bool isSensitive;
  
  @JsonKey(name: 'requires_explicit_consent', fromJson: _boolFromJson)
  final bool requiresExplicitConsent;
  
  @JsonKey(name: 'fields_included')
  final List<String>? fieldsIncluded;

  @JsonKey(name: 'missing_fields')
  final List<String>? missingFields;

  @JsonKey(name: 'has_missing_fields', fromJson: _boolFromJson)
  final bool hasMissingFields;

  @JsonKey(defaultValue: true, fromJson: _boolFromJson)
  final bool granted;

  @JsonKey(name: 'is_required', defaultValue: false, fromJson: _boolFromJson)
  final bool isRequired;

  ScopeModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    required this.isSensitive,
    required this.requiresExplicitConsent,
    this.fieldsIncluded,
    this.missingFields,
    this.hasMissingFields = false,
    this.granted = true,
    this.isRequired = false,
  });

  factory ScopeModel.fromJson(Map<String, dynamic> json) =>
      _$ScopeModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScopeModelToJson(this);
  
  String get shortDescription => description ?? displayName;
}

