import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import 'token_storage_service.dart';

/// Exception API personnalisée
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

/// Client API centralisé pour SEZAM
class ApiClient {
  static ApiClient? _instance;
  final TokenStorageService _tokenStorage;

  ApiClient._internal(this._tokenStorage);

  factory ApiClient() {
    _instance ??= ApiClient._internal(TokenStorageService.instance);
    return _instance!;
  }

  /// Méthode générique pour les requêtes GET
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.get(
        uri,
        headers: await _buildHeaders(headers),
      ).timeout(
        ApiConfig.receiveTimeout,
        onTimeout: () {
          throw ApiException('Délai d\'attente dépassé lors de la connexion au serveur');
        },
      );

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      throw ApiException('Impossible de se connecter au serveur: ${e.message}');
    } on HttpException catch (e) {
      throw ApiException('Erreur HTTP: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Erreur de format: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur de connexion: ${e.toString()}');
    }
  }

  /// Méthode générique pour les requêtes POST
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.post(
        uri,
        headers: await _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        ApiConfig.receiveTimeout,
        onTimeout: () {
          throw ApiException('Délai d\'attente dépassé lors de la connexion au serveur');
        },
      );

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      throw ApiException('Impossible de se connecter au serveur: ${e.message}');
    } on HttpException catch (e) {
      throw ApiException('Erreur HTTP: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Erreur de format: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur de connexion: ${e.toString()}');
    }
  }

  /// Méthode générique pour les requêtes PUT
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.put(
        uri,
        headers: await _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        ApiConfig.receiveTimeout,
        onTimeout: () {
          throw ApiException('Délai d\'attente dépassé lors de la connexion au serveur');
        },
      );

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      throw ApiException('Impossible de se connecter au serveur: ${e.message}');
    } on HttpException catch (e) {
      throw ApiException('Erreur HTTP: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Erreur de format: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur de connexion: ${e.toString()}');
    }
  }

  /// Méthode générique pour les requêtes DELETE
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.delete(
        uri,
        headers: await _buildHeaders(headers),
      ).timeout(
        ApiConfig.receiveTimeout,
        onTimeout: () {
          throw ApiException('Délai d\'attente dépassé lors de la connexion au serveur');
        },
      );

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      throw ApiException('Impossible de se connecter au serveur: ${e.message}');
    } on HttpException catch (e) {
      throw ApiException('Erreur HTTP: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Erreur de format: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur de connexion: ${e.toString()}');
    }
  }

  /// Construire les headers avec le token d'authentification
  Future<Map<String, String>> _buildHeaders(Map<String, String>? customHeaders) async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    
    // S'assurer que le storage est initialisé avant de récupérer le token
    await _tokenStorage.init();
    
    // Ajouter le token d'authentification si disponible
    final token = _tokenStorage.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // Ajouter les headers personnalisés
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    
    return headers;
  }

  /// Gérer la réponse de l'API
  Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) async {
    try {
      // Vérifier si la réponse est vide
      if (response.body.isEmpty) {
        throw ApiException('Réponse vide du serveur', statusCode: response.statusCode);
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      
      // Log pour déboguer les réponses OTP
      if (response.request?.url.toString().contains('/otp') ?? false) {
        print('🔍 Réponse brute OTP: ${response.body}');
        print('🔍 JSON parsé: $json');
        print('🔍 Clés disponibles: ${json.keys.toList()}');
      }

      // Gérer les codes d'erreur
      if (response.statusCode >= 400) {
        String errorMessage = json['message'] as String? ?? 'Une erreur est survenue';
        
        // Si c'est une erreur de validation (422), extraire les erreurs détaillées
        if (response.statusCode == 422 && json['errors'] != null) {
          final errors = json['errors'] as Map<String, dynamic>;
          final errorList = <String>[];
          
          // Map des noms de champs pour des messages plus clairs
          final fieldNames = {
            'first_name': 'Prénom',
            'last_name': 'Nom',
            'email': 'Email',
            'phone': 'Téléphone',
            'password': 'Mot de passe',
            'password_confirmation': 'Confirmation du mot de passe',
          };
          
          errors.forEach((field, messages) {
            final fieldName = fieldNames[field] ?? field;
            if (messages is List) {
              for (var message in messages) {
                // Remplacer le nom du champ par un nom plus lisible
                String msg = message.toString();
                msg = msg.replaceAll(field, fieldName);
                errorList.add(msg);
              }
            } else {
              String msg = messages.toString();
              msg = msg.replaceAll(field, fieldName);
              errorList.add(msg);
            }
          });
          
          // Formater le message d'erreur
          if (errorList.isNotEmpty) {
            errorMessage = errorList.join('\n');
          }
        }
        
        throw ApiException(
          errorMessage,
          statusCode: response.statusCode,
          data: json,
        );
      }

      // Parser la réponse avec ApiResponse
      T? data;
      if (json['data'] != null) {
        final rawData = json['data'];
        if (fromJson != null && rawData is Map<String, dynamic>) {
          data = fromJson(rawData);
        } else if (rawData is List || rawData is Map) {
          // Pour les listes ou autres structures, retourner tel quel
          data = rawData as T;
        }
      }

      return ApiResponse<T>(
        message: json['message'] as String? ?? 'Succès',
        data: data,
        token: json['token'] as String?,
        requiresOtp: json['requires_otp'] as bool?,
        otpCode: json['otp_code'] as String?,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      
      // Gérer les erreurs de connexion
      if (e is SocketException) {
        throw ApiException('Impossible de se connecter au serveur. Vérifiez votre connexion Internet.');
      }
      
      if (e is FormatException) {
        // Réponse non-JSON, peut-être une erreur HTML
        throw ApiException('Réponse invalide du serveur (${response.statusCode})');
      }
      
      // Autres erreurs de parsing
      throw ApiException('Erreur lors du traitement de la réponse: $e');
    }
  }

  /// Vérifier si l'utilisateur est authentifié
  bool isAuthenticated() {
    return _tokenStorage.isAuthenticated();
  }

  /// Déconnexion
  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }
}

