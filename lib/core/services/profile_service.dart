import '../config/api_config.dart';
import '../models/profile_status_model.dart';
import 'exceptions.dart';
import 'api_client.dart';

/// Service pour la gestion du profil utilisateur
class ProfileService {
  final ApiClient _apiClient = ApiClient();

  /// Obtenir le statut du profil
  Future<ProfileStatusModel> getProfileStatus() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.userProfileStatus,
        fromJson: (json) => json,
      );      
      if (response.data == null) {
        throw AuthenticationException('Impossible de récupérer le statut du profil');
      }
      return ProfileStatusModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      print('❌ Erreur getProfileStatus: $e');
      print('📚 StackTrace: $stackTrace');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _apiClient.put(
        ApiConfig.updateProfile,
        body: data,
      );
    } catch (e) {
      print('Erreur updateProfile: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Construit le payload pour la mise à jour d'un champ spécifique
  Map<String, dynamic> buildUpdatePayload({
    required String fieldKey,
    String? text,
    DateTime? selectedDate,
    String? selectedId,
  }) {
    print('🔄 buildUpdatePayload: $fieldKey, $text, $selectedDate');
    final value = (text ?? '').trim();
    switch (fieldKey) {
      case 'birth_date':
        String isoDate;
        if (selectedDate != null) {
          isoDate = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        } else {
          // tente de parser JJ/MM/AAAA
          final m = RegExp(r'^(\\d{1,2})\\/(\\d{1,2})\\/(\\d{4})$').firstMatch(value);
          if (m != null) {
            final d = m.group(1)!.padLeft(2, '0');
            final mo = m.group(2)!.padLeft(2, '0');
            final y = m.group(3)!;
            isoDate = '$y-$mo-$d';
          } else {
            isoDate = value;
          }
        }
        return {'birth_date': isoDate};

      case 'occupation':
        return {'occupation': value};

      case 'employer':
        return {'employer': value};

      case 'address':
        // alias address_line1 côté backend
        return {'address_line1': value};

      case 'city':
        return {'city': value};

      case 'postal_code':
        return {'postal_code': value};

      case 'country':
        // envoyer de préférence l'id
        if ((selectedId ?? '').isNotEmpty) {
          return {'country_id': selectedId};
        }
        return {'country': value};

      case 'nationality':
        // envoyer de préférence l'id
        if ((selectedId ?? '').isNotEmpty) {
          return {'nationality_id': selectedId};
        }
        return {'nationality': value};

      case 'phone':
        // Envoi du numéro national (indicatif géré à part si nécessaire)
        return {'phone': value};

      default:
        return {fieldKey: value};
    }
  }

  /// Générer le code utilisateur
  Future<void> generateUserCode() async {
    try {
      await _apiClient.post(
        ApiConfig.generateUserCode,
        body: {},
      );
    } catch (e) {
      print('Erreur generateUserCode: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Compléter le KYC (marquer comme complet)
  Future<void> completeKyc() async {
    try {
      await _apiClient.post(
        ApiConfig.completeKyc,
        body: {},
      );
    } catch (e) {
      print('Erreur completeKyc: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Mettre à jour le motif d'utilisation
  Future<void> updateUsagePurpose(String usagePurpose) async {
    try {
      await _apiClient.put(
        ApiConfig.updateProfile,
        body: {
          'metadata': {
            'usage_purpose': usagePurpose,
          },
        },
      );
    } catch (e) {
      print('Erreur updateUsagePurpose: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Accepter les conditions d'utilisation
  Future<void> acceptTerms() async {
    try {
      await _apiClient.put(
        ApiConfig.updateProfile,
        body: {
          'metadata': {
            'terms_accepted': true,
            'terms_accepted_at': DateTime.now().toIso8601String(),
          },
        },
      );
    } catch (e) {
      print('Erreur acceptTerms: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Vérifier si l'utilisateur a déjà rempli usage_purpose et terms_accepted
  Future<bool> hasCompletedOnboarding() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.userProfile,
        fromJson: (json) => json,
      );
      
      if (response.data == null) return false;
      
      final user = response.data!;
      final metadata = user['metadata'] as Map<String, dynamic>?;
      
      if (metadata == null) return false;
      
      final hasUsagePurpose = metadata['usage_purpose'] != null;
      final hasTermsAccepted = metadata['terms_accepted'] == true;
      
      return hasUsagePurpose && hasTermsAccepted;
    } catch (e) {
      print('Erreur hasCompletedOnboarding: $e');
      return false;
    }
  }
  
  /// Vérifier les métadonnées du profil (usage_purpose et terms_accepted)
  /// Retourne un Map avec les statuts de chaque champ
  Future<Map<String, bool>> checkOnboardingMetadata() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.userProfile,
        fromJson: (json) => json,
      );
      
      if (response.data == null) {
        return {'hasUsagePurpose': false, 'hasTermsAccepted': false};
      }
      
      final user = response.data!;
      final metadata = user['metadata'] as Map<String, dynamic>?;
      
      if (metadata == null) {
        return {'hasUsagePurpose': false, 'hasTermsAccepted': false};
      }
      
      final hasUsagePurpose = metadata['usage_purpose'] != null;
      final hasTermsAccepted = metadata['terms_accepted'] == true;
      
      return {
        'hasUsagePurpose': hasUsagePurpose,
        'hasTermsAccepted': hasTermsAccepted,
      };
    } catch (e) {
      print('Erreur checkOnboardingMetadata: $e');
      return {'hasUsagePurpose': false, 'hasTermsAccepted': false};
    }
  }
}

