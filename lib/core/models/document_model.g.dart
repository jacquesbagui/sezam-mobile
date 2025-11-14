// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentModel _$DocumentModelFromJson(Map<String, dynamic> json) =>
    DocumentModel(
      id: json['id'] as String,
      documentNumber: json['document_number'] as String?,
      issueDate: json['issue_date'] == null
          ? null
          : DateTime.parse(json['issue_date'] as String),
      expiryDate: json['expiry_date'] == null
          ? null
          : DateTime.parse(json['expiry_date'] as String),
      type: json['type'] == null
          ? null
          : DocumentType.fromJson(json['type'] as Map<String, dynamic>),
      status: json['status'] == null
          ? null
          : DocumentStatus.fromJson(json['status'] as Map<String, dynamic>),
      issuingCountry: json['issuing_country'] == null
          ? null
          : IssuingCountry.fromJson(
              json['issuing_country'] as Map<String, dynamic>,
            ),
      fileName: json['file_name'] as String?,
      fileUrl: json['file_url'] as String?,
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(json['verified_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DocumentModelToJson(DocumentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'document_number': instance.documentNumber,
      'issue_date': instance.issueDate?.toIso8601String(),
      'expiry_date': instance.expiryDate?.toIso8601String(),
      'type': instance.type,
      'status': instance.status,
      'issuing_country': instance.issuingCountry,
      'file_name': instance.fileName,
      'file_url': instance.fileUrl,
      'verified_at': instance.verifiedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

DocumentType _$DocumentTypeFromJson(Map<String, dynamic> json) => DocumentType(
  id: json['id'] as String,
  name: json['name'] as String,
  displayName: json['display_name'] as String?,
);

Map<String, dynamic> _$DocumentTypeToJson(DocumentType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'display_name': instance.displayName,
    };

DocumentStatus _$DocumentStatusFromJson(Map<String, dynamic> json) =>
    DocumentStatus(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String?,
    );

Map<String, dynamic> _$DocumentStatusToJson(DocumentStatus instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'display_name': instance.displayName,
    };

IssuingCountry _$IssuingCountryFromJson(Map<String, dynamic> json) =>
    IssuingCountry(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$IssuingCountryToJson(IssuingCountry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };
