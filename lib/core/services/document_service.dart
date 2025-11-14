import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/document_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'exceptions.dart';
import 'token_storage_service.dart';

/// Service pour gérer les documents
class DocumentService {
  final ApiClient _apiClient;

  DocumentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer les documents de l'utilisateur
  Future<List<DocumentModel>> getDocuments() async {
    try {
      final response = await _apiClient.get<List>(
        ApiConfig.documents,
      );

      if (response.data != null && response.data is List) {
        final dataList = response.data as List;
        final documents = <DocumentModel>[];
        
        for (var item in dataList) {
          try {
            if (item is Map<String, dynamic>) {
              documents.add(DocumentModel.fromJson(item));
            }
          } catch (e) {
            print('Erreur parsing document: $e');
          }
        }
        return documents;
      }
      
      return [];
    } catch (e) {
      print('Erreur getDocuments: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Uploader un document (multipart/form-data)
  Future<DocumentModel> uploadDocument({
    required String documentTypeId,
    required String filePath,
    String? documentNumber,
    String? issuingCountryId,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    try {
      // Validate file size before upload (10 MB = 10 * 1024 * 1024 bytes)
      const maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
      final file = File(filePath);
      if (!await file.exists()) {
        throw ApiException('Le fichier n\'existe pas');
      }
      
      final fileSize = await file.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      
      // Log file size for debugging
      print('📄 Taille du fichier: $fileSizeMB MB (${fileSize} bytes)');
      
      if (fileSize > maxFileSizeBytes) {
        throw ApiException('Fichier trop volumineux ($fileSizeMB MB). Taille maximale autorisée : 10 MB');
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.documents}');
      final request = http.MultipartRequest('POST', uri);

      // Auth header
      final token = TokenStorageService.instance.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Fields
      request.fields['document_type_id'] = documentTypeId;
      if (documentNumber != null && documentNumber.isNotEmpty) {
        request.fields['document_number'] = documentNumber;
      }
      if (issuingCountryId != null && issuingCountryId.isNotEmpty) {
        request.fields['issuing_country_id'] = issuingCountryId;
      }
      if (issueDate != null) {
        request.fields['issue_date'] = issueDate.toIso8601String().split('T').first;
      }
      if (expiryDate != null) {
        request.fields['expiry_date'] = expiryDate.toIso8601String().split('T').first;
      }

      // File
      final filePathParts = filePath.split('.');
      final ext = filePathParts.length > 1 
          ? filePathParts.last.toLowerCase() 
          : 'jpg'; // Default to jpg if no extension
      String mime = 'application/octet-stream';
      if (ext == 'pdf') mime = 'application/pdf';
      if (ext == 'jpg' || ext == 'jpeg') mime = 'image/jpeg';
      if (ext == 'png') mime = 'image/png';
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType.parse(mime),
      );
      request.files.add(multipartFile);

      // Calculate approximate request size (file + fields overhead)
      final approximateRequestSize = fileSize + 10000; // ~10KB for headers and fields
      final requestSizeMB = (approximateRequestSize / (1024 * 1024)).toStringAsFixed(2);
      print('📤 Taille approximative de la requête: $requestSizeMB MB');

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      
      print('📥 Réponse reçue: Status ${response.statusCode}');
      
      // Handle 500 server error
      if (response.statusCode == 500) {
        String errorDetails = '';
        if (response.bodyBytes.isNotEmpty) {
          try {
            final errorBody = utf8.decode(response.bodyBytes);
            errorDetails = '\nRéponse serveur: ${errorBody.substring(0, errorBody.length > 500 ? 500 : errorBody.length)}';
            print('❌ Erreur serveur 500: $errorBody');
          } catch (e) {
            errorDetails = '\nImpossible de décoder la réponse d\'erreur';
          }
        }
        throw ApiException(
          'Erreur serveur lors de l\'upload (500).\n'
          'Le serveur a rencontré une erreur interne.$errorDetails'
          '\nVeuillez réessayer plus tard ou contacter le support.'
        );
      }

      // Check if response body is empty
      if (response.bodyBytes.isEmpty) {
        throw ApiException('Réponse vide du serveur (status ${response.statusCode})');
      }

      // Decode and validate JSON response
      String responseBody;
      try {
        responseBody = utf8.decode(response.bodyBytes);
      } catch (e) {
        throw ApiException('Erreur de décodage de la réponse: $e');
      }

      // Handle 413 Payload Too Large error specifically
      if (response.statusCode == 413) {
        throw ApiException(
          'Erreur 413: Requête trop volumineuse.\n'
          'Fichier: $fileSizeMB MB | Requête totale: ~$requestSizeMB MB\n'
          'La limite PHP (post_max_size) est probablement trop basse.\n'
          'Vérifiez la configuration PHP (voir PHP_CONFIG_FIX.md) ou réduisez la taille du fichier.'
        );
      }

      // Check if response is JSON
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json') && response.statusCode != 200 && response.statusCode != 201) {
        // For non-JSON responses, provide a helpful message
        String errorMessage = 'Erreur du serveur (${response.statusCode})';
        if (responseBody.toLowerCase().contains('too large') || responseBody.toLowerCase().contains('413')) {
          errorMessage = 'Fichier trop volumineux. Taille maximale autorisée : 10 MB.';
        } else {
          errorMessage += ': ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}';
        }
        throw ApiException(errorMessage);
      }

      // Parse JSON
      Map<String, dynamic> body;
      try {
        body = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (e) {
        // Provide more context about the parsing error
        throw ApiException('Erreur de parsing JSON: $e. Réponse reçue: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}');
      }

      if (response.statusCode >= 400) {
        throw ApiException(body['message'] as String? ?? 'Erreur upload (status ${response.statusCode})');
      }
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        print('❌ Réponse sans champ data. Body complet: $body');
        throw ApiException('Réponse invalide lors de l\'upload: champ "data" manquant');
      }
      
      // Log pour debugging
      print('📦 Données reçues: $data');
      
      // Validate required fields before parsing
      if (data['id'] == null) {
        print('❌ Champ "id" manquant dans la réponse');
        throw ApiException('Réponse invalide: champ "id" manquant');
      }
      if (data['created_at'] == null) {
        print('❌ Champ "created_at" manquant dans la réponse');
        throw ApiException('Réponse invalide: champ "created_at" manquant');
      }
      if (data['updated_at'] == null) {
        print('❌ Champ "updated_at" manquant dans la réponse');
        throw ApiException('Réponse invalide: champ "updated_at" manquant');
      }
      
      // Validate nested objects structure (optional but good for debugging)
      if (data['type'] != null && data['type'] is! Map<String, dynamic>) {
        print('⚠️ Champ "type" n\'est pas un objet: ${data['type']}');
        // Remove invalid type to avoid parsing error
        data.remove('type');
      }
      if (data['status'] != null && data['status'] is! Map<String, dynamic>) {
        print('⚠️ Champ "status" n\'est pas un objet: ${data['status']}');
        data.remove('status');
      }
      if (data['issuing_country'] != null && data['issuing_country'] is! Map<String, dynamic>) {
        print('⚠️ Champ "issuing_country" n\'est pas un objet: ${data['issuing_country']}');
        data.remove('issuing_country');
      }
      
      try {
        return DocumentModel.fromJson(data);
      } catch (e, stackTrace) {
        print('❌ Erreur lors du parsing du document: $e');
        print('📋 Stack trace: $stackTrace');
        print('📦 Données problématiques: $data');
        throw ApiException('Erreur lors du parsing de la réponse du serveur: $e');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur upload document: $e');
    }
  }

  /// Supprimer un document
  Future<void> deleteDocument(String documentId) async {
    try {
      await _apiClient.delete('${ApiConfig.documents}/$documentId');
    } catch (e) {
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Récupérer les documents requis (avec ids) depuis le statut profil
  Future<List<Map<String, dynamic>>> getRequiredDocuments() async {
    try {
      final resp = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.userProfileStatus,
        fromJson: (json) => json,
      );
      final data = resp.data;
      if (data == null) return [];
      final list = data['required_documents'];
      if (list is List) {
        return list.map<Map<String, dynamic>>((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

