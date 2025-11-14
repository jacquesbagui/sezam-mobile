import 'package:json_annotation/json_annotation.dart';

part 'profile_status_model.g.dart';

/// Modèle de statut du profil utilisateur
@JsonSerializable()
class ProfileStatusModel {
  @JsonKey(name: 'has_profile')
  final bool hasProfile;

  @JsonKey(name: 'is_complete')
  final bool isComplete;

  @JsonKey(name: 'completion_percentage')
  final int completionPercentage;

  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  @JsonKey(name: 'required_fields')
  final List<String> requiredFields;

  @JsonKey(name: 'missing_fields')
  final List<String> missingFields;

  @JsonKey(name: 'required_documents', fromJson: _parseDocumentList)
  final List<String> requiredDocuments;

  @JsonKey(name: 'uploaded_documents', fromJson: _parseDocumentList)
  final List<String> uploadedDocuments;

  @JsonKey(name: 'missing_documents', fromJson: _parseDocumentList)
  final List<String> missingDocuments;
  
  /// Parse document list - handles both string arrays and object arrays
  static List<String> _parseDocumentList(dynamic json) {
    if (json == null) return [];
    if (json is! List) return [];
    
    return json.map((e) {
      if (e is String) {
        return e;
      } else if (e is Map<String, dynamic>) {
        // If it's an object, extract 'name' or 'id' or 'document_type_id'
        return e['name'] as String? ?? 
               e['id'] as String? ?? 
               e['document_type_id'] as String? ?? 
               '';
      }
      return e.toString();
    }).where((e) => e.isNotEmpty).toList();
  }

  ProfileStatusModel({
    required this.hasProfile,
    required this.isComplete,
    required this.completionPercentage,
    this.completedAt,
    required this.requiredFields,
    required this.missingFields,
    required this.requiredDocuments,
    required this.uploadedDocuments,
    required this.missingDocuments,
  });

  factory ProfileStatusModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileStatusModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileStatusModelToJson(this);

  /// Mapping des noms de champs en français
  String getFieldDisplayName(String field) {
    final map = {
      'birth_date': 'Date de naissance',
      'birth_place': 'Lieu de naissance',
      'gender_id': 'Genre',
      'nationality_id': 'Nationalité',
      'address_line1': 'Adresse principale',
      'city': 'Ville',
      'country_id': 'Pays',
      'occupation': 'Profession',
      'employer': 'Employeur',
      'annual_income': 'Revenu annuel',
      'income_source_id': 'Source de revenu',
    };
    return map[field] ?? field;
  }

  /// Obtenir les champs manquants en français
  List<String> get missingFieldsDisplay {
    return missingFields.map((field) => getFieldDisplayName(field)).toList();
  }

  /// Mapping des documents en français
  String getDocumentDisplayName(String doc) {
    final map = {
      'id_card': 'Pièce d\'identité',
      'passport': 'Passeport',
      'proof_of_address': 'Justificatif de domicile',
      'salary_slip': 'Bulletin de salaire',
    };
    return map[doc] ?? doc;
  }

  /// Obtenir les documents manquants en français
  List<String> get missingDocumentsDisplay {
    return missingDocuments.map((doc) => getDocumentDisplayName(doc)).toList();
  }
}

