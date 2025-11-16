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
      print('📋 Chargement des consentements depuis l\'API...');
      final response = await _apiClient.get<List>(
        ApiConfig.consents,
      );

      // Extraire la liste des consents depuis la réponse
      if (response.data != null && response.data is List) {
        final dataList = response.data as List;
        print('📦 ${dataList.length} consentement(s) reçu(s) de l\'API');
        final consents = <ConsentModel>[];
        
        for (var item in dataList) {
          try {
            if (item is Map<String, dynamic>) {
              // Log les données brutes pour déboguer
              print('  📦 Parsing consent: ${item['id']}');
              if (item['status'] != null) {
                print('     Status: ${item['status']}');
              }
              if (item['scopes'] != null && item['scopes'] is List) {
                print('     Scopes count: ${(item['scopes'] as List).length}');
                if ((item['scopes'] as List).isNotEmpty) {
                  final firstScope = (item['scopes'] as List).first;
                  if (firstScope is Map) {
                    print('     First scope: ${firstScope.keys.join(', ')}');
                  }
                }
              }
              
              final consent = ConsentModel.fromJson(item);
              consents.add(consent);
              print('  ✅ Consent ${consent.id}: status=${consent.statusName}, partner=${consent.partnerName}');
            }
          } catch (e, stackTrace) {
            // Ignorer les items invalides mais logger l'erreur complète
            print('❌ Erreur parsing consent: $e');
            print('   Stack trace: $stackTrace');
            if (item is Map) {
              print('   Item keys: ${item.keys.join(', ')}');
              final itemStr = item.toString();
              print('   Item preview: ${itemStr.substring(0, itemStr.length > 500 ? 500 : itemStr.length)}');
            } else {
              print('   Item is not a Map');
            }
          }
        }
        
        // Log des statistiques
        final pending = consents.where((c) => c.isPending).length;
        final granted = consents.where((c) => c.isGranted).length;
        final denied = consents.where((c) => c.isDenied).length;
        print('📊 Statistiques: $pending en attente, $granted accordés, $denied refusés');
        
        return consents;
      }
      
      print('⚠️ Aucune donnée reçue ou format invalide');
      // Si data est null ou pas une liste, retourner liste vide
      return [];
    } catch (e) {
      print('❌ Erreur getConsents: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }
  
  /// Demander l'OTP pour valider un consentement
  /// Retourne le code OTP en mode test (si disponible dans la réponse)
  Future<String?> requestConsentOtp(String consentId) async {
    try {
      print('📤 Demande d\'OTP pour consentement: $consentId');
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.consents}/$consentId/otp',
        body: {},
        fromJson: (json) => json,
      );
      
      print('📥 Réponse OTP complète:');
      print('   - message: ${response.message}');
      print('   - data: ${response.data}');
      print('   - otpCode: ${response.otpCode}');
      
      // Le code OTP peut être dans response.otpCode (extrait directement du JSON)
      if (response.otpCode != null && response.otpCode!.isNotEmpty) {
        print('✅ Code OTP trouvé dans response.otpCode: ${response.otpCode}');
        return response.otpCode;
      }
      
      // Sinon, chercher dans response.data si présent
      if (response.data != null && response.data is Map<String, dynamic>) {
        Map<String, dynamic> dataToCheck = response.data as Map<String, dynamic>;
        
        // Si response.data contient une clé 'data', utiliser celle-ci
        if (dataToCheck.containsKey('data') && dataToCheck['data'] is Map) {
          dataToCheck = dataToCheck['data'] as Map<String, dynamic>;
          print('📦 Code OTP dans data.data: $dataToCheck');
        }
        
        // Chercher le code dans plusieurs clés possibles
        final otpCode = dataToCheck['otp_code'] as String?;
        final testCode = dataToCheck['test_code'] as String?;
        final code = dataToCheck['code'] as String?;
        final otp = dataToCheck['otp'] as String?;
        
        print('🔍 Recherche du code OTP dans data:');
        print('   - otp_code: $otpCode');
        print('   - test_code: $testCode');
        print('   - code: $code');
        print('   - otp: $otp');
        
        final finalCode = otpCode ?? testCode ?? code ?? otp;
        if (finalCode != null && finalCode.isNotEmpty) {
          print('✅ Code OTP trouvé dans data (mode test): $finalCode');
          return finalCode;
        }
      }
      
      print('⚠️ Aucun code OTP trouvé dans la réponse');
      return null;
    } catch (e) {
      print('❌ Erreur requestConsentOtp: $e');
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

