// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scope_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScopeModel _$ScopeModelFromJson(Map<String, dynamic> json) => ScopeModel(
  id: json['id'] as String,
  name: json['name'] as String,
  displayName: json['display_name'] as String,
  description: json['description'] as String?,
  isSensitive: _boolFromJson(json['is_sensitive']),
  requiresExplicitConsent: _boolFromJson(json['requires_explicit_consent']),
  fieldsIncluded: (json['fields_included'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  missingFields: (json['missing_fields'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  hasMissingFields: json['has_missing_fields'] == null
      ? false
      : _boolFromJson(json['has_missing_fields']),
  granted: json['granted'] == null ? true : _boolFromJson(json['granted']),
  isRequired: json['is_required'] == null
      ? false
      : _boolFromJson(json['is_required']),
);

Map<String, dynamic> _$ScopeModelToJson(ScopeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'display_name': instance.displayName,
      'description': instance.description,
      'is_sensitive': instance.isSensitive,
      'requires_explicit_consent': instance.requiresExplicitConsent,
      'fields_included': instance.fieldsIncluded,
      'missing_fields': instance.missingFields,
      'has_missing_fields': instance.hasMissingFields,
      'granted': instance.granted,
      'is_required': instance.isRequired,
    };
