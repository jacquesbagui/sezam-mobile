import '../models/consent_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'exceptions.dart';

/// Service pour gérer les consentements
class ConsentService {
  final ApiClient _apiClient;

  ConsentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer les consentements de l'utilisateur
  Future<List<ConsentModel>> getConsents() async {
    try {
      final response = await _apiClient.get<List>(
        ApiConfig.consents,
      );

      // Extraire la liste des consents depuis la réponse
      if (response.data != null && response.data is List) {
        final dataList = response.data as List;
        final consents = <ConsentModel>[];
        
        for (var item in dataList) {
          try {
            if (item is Map<String, dynamic>) {
              consents.add(ConsentModel.fromJson(item));
            }
          } catch (e) {
            // Ignorer les items invalides
            print('Erreur parsing consent: $e');
          }
        }
        return consents;
      }
      
      // Si data est null ou pas une liste, retourner liste vide
      return [];
    } catch (e) {
      print('Erreur getConsents: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }
  
  /// Demander l'OTP pour valider un consentement
  Future<void> requestConsentOtp(String consentId) async {
    try {
      await _apiClient.post(
        '${ApiConfig.consents}/$consentId/otp',
        body: {},
      );
    } catch (e) {
      print('Erreur requestConsentOtp: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Accorder un consentement (avec OTP requis)
  Future<void> grantConsent(String consentId, List<String> scopeIds, {required String otpCode}) async {
    try {
      await _apiClient.post(
        '${ApiConfig.consents}/$consentId/grant',
        body: {
          'scope_ids': scopeIds,
          'otp_code': otpCode,
        },
      );
    } catch (e) {
      print('Erreur grantConsent: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }
  
  /// Refuser un consentement
  Future<void> denyConsent(String consentId) async {
    try {
      await _apiClient.post(
        '${ApiConfig.consents}/$consentId/deny',
      );
    } catch (e) {
      print('Erreur denyConsent: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Demander la révocation d'un consentement (nécessite validation admin)
  Future<void> requestRevocation(String consentId, {String? reason}) async {
    try {
      await _apiClient.post(
        '${ApiConfig.consents}/$consentId/revoke',
        body: reason != null ? {'reason': reason} : {},
      );
    } catch (e) {
      print('Erreur requestRevocation: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Récupérer un consentement spécifique par ID
  Future<ConsentModel?> getConsentById(String consentId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.consents}/$consentId',
        fromJson: (json) => json,
      );

      if (response.data != null) {
        return ConsentModel.fromJson(response.data!);
      }
      
      return null;
    } catch (e) {
      print('Erreur getConsentById: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Retirer un scope d'un consentement (désactiver)
  Future<void> removeScope(String consentId, String scopeId) async {
    try {
      await _apiClient.post(
        '${ApiConfig.consents}/$consentId/scopes/$scopeId/remove',
        body: {},
      );
    } catch (e) {
      print('Erreur removeScope: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Réactiver un scope d'un consentement
  Future<void> enableScope(String consentId, String scopeId) async {
    try {
      await _apiClient.post(
        '${ApiConfig.consents}/$consentId/scopes/$scopeId/enable',
        body: {},
      );
    } catch (e) {
      print('Erreur enableScope: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }
}

