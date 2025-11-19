import '../models/partner_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'exceptions.dart';

/// Service pour gérer les partenaires
class PartnerService {
  final ApiClient _apiClient;

  PartnerService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer la liste des partenaires
  Future<List<PartnerModel>> getPartners() async {
    try {
      print('🏢 Chargement des partenaires depuis l\'API...');
      print('📍 URL: ${ApiConfig.baseUrl}${ApiConfig.partners}');
      final response = await _apiClient.get<List>(
        ApiConfig.partners,
      );

      // Extraire la liste des partenaires depuis la réponse
      if (response.data != null && response.data is List) {
        final dataList = response.data as List;
        print('📦 ${dataList.length} partenaire(s) reçu(s) de l\'API');
        final partners = <PartnerModel>[];
        
        for (var item in dataList) {
          try {
            if (item is Map<String, dynamic>) {
              final partner = PartnerModel.fromJson(item);
              partners.add(partner);
              print('  ✅ Partenaire ${partner.id}: ${partner.name}');
            }
          } catch (e, stackTrace) {
            print('❌ Erreur parsing partenaire: $e');
            print('   Stack trace: $stackTrace');
          }
        }
        
        return partners;
      }
      
      print('⚠️ Aucune donnée reçue ou format invalide');
      return [];
    } catch (e) {
      print('❌ Erreur getPartners: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }
}

