// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileStatusModel _$ProfileStatusModelFromJson(Map<String, dynamic> json) =>
    ProfileStatusModel(
      hasProfile: json['has_profile'] as bool,
      isComplete: json['is_complete'] as bool,
      completionPercentage: (json['completion_percentage'] as num).toInt(),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      requiredFields: (json['required_fields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      missingFields: (json['missing_fields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      requiredDocuments: ProfileStatusModel._parseDocumentList(
        json['required_documents'],
      ),
      uploadedDocuments: ProfileStatusModel._parseDocumentList(
        json['uploaded_documents'],
      ),
      missingDocuments: ProfileStatusModel._parseDocumentList(
        json['missing_documents'],
      ),
    );

Map<String, dynamic> _$ProfileStatusModelToJson(ProfileStatusModel instance) =>
    <String, dynamic>{
      'has_profile': instance.hasProfile,
      'is_complete': instance.isComplete,
      'completion_percentage': instance.completionPercentage,
      'completed_at': instance.completedAt?.toIso8601String(),
      'required_fields': instance.requiredFields,
      'missing_fields': instance.missingFields,
      'required_documents': instance.requiredDocuments,
      'uploaded_documents': instance.uploadedDocuments,
      'missing_documents': instance.missingDocuments,
    };
