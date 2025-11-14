import 'package:json_annotation/json_annotation.dart';

part 'scope_model.g.dart';

/// Modèle de scope (permission)
@JsonSerializable()
class ScopeModel {
  final String id;
  final String name;
  
  @JsonKey(name: 'display_name')
  final String displayName;
  
  final String? description;
  
  @JsonKey(name: 'is_sensitive')
  final bool isSensitive;
  
  @JsonKey(name: 'requires_explicit_consent')
  final bool requiresExplicitConsent;
  
  @JsonKey(name: 'fields_included')
  final List<String>? fieldsIncluded;

  @JsonKey(name: 'missing_fields')
  final List<String>? missingFields;

  @JsonKey(name: 'has_missing_fields')
  final bool hasMissingFields;

  @JsonKey(defaultValue: true)
  final bool granted;

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
  });

  factory ScopeModel.fromJson(Map<String, dynamic> json) =>
      _$ScopeModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScopeModelToJson(this);
  
  String get shortDescription => description ?? displayName;
}

