import 'package:json_annotation/json_annotation.dart';

part 'document_model.g.dart';

/// Modèle de document
@JsonSerializable()
class DocumentModel {
  final String id;
  
  @JsonKey(name: 'document_number')
  final String? documentNumber;
  
  @JsonKey(name: 'issue_date')
  final DateTime? issueDate;
  
  @JsonKey(name: 'expiry_date')
  final DateTime? expiryDate;
  
  final DocumentType? type;
  final DocumentStatus? status;
  
  @JsonKey(name: 'issuing_country')
  final IssuingCountry? issuingCountry;
  
  @JsonKey(name: 'file_name')
  final String? fileName;
  
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  
  @JsonKey(name: 'verified_at')
  final DateTime? verifiedAt;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    this.documentNumber,
    this.issueDate,
    this.expiryDate,
    this.type,
    this.status,
    this.issuingCountry,
    this.fileName,
    this.fileUrl,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentModelFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentModelToJson(this);
  
  String get displayName => type?.displayName ?? type?.name ?? 'Document';
  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
  }
  
  String get statusName => status?.name ?? 'pending';
  bool get isVerified => statusName == 'verified';
  bool get isPending => statusName == 'pending';
  bool get isRejected => statusName == 'rejected';
}

@JsonSerializable()
class DocumentType {
  final String id;
  final String name;
  
  @JsonKey(name: 'display_name')
  final String? displayName;

  DocumentType({
    required this.id,
    required this.name,
    this.displayName,
  });

  factory DocumentType.fromJson(Map<String, dynamic> json) =>
      _$DocumentTypeFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentTypeToJson(this);
}

@JsonSerializable()
class DocumentStatus {
  final String id;
  final String name;
  
  @JsonKey(name: 'display_name')
  final String? displayName;

  DocumentStatus({
    required this.id,
    required this.name,
    this.displayName,
  });

  factory DocumentStatus.fromJson(Map<String, dynamic> json) =>
      _$DocumentStatusFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentStatusToJson(this);
}

@JsonSerializable()
class IssuingCountry {
  final String id;
  final String code;
  final String name;

  IssuingCountry({
    required this.id,
    required this.code,
    required this.name,
  });

  factory IssuingCountry.fromJson(Map<String, dynamic> json) =>
      _$IssuingCountryFromJson(json);

  Map<String, dynamic> toJson() => _$IssuingCountryToJson(this);
}

