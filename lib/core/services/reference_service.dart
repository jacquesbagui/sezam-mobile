import '../config/api_config.dart';
import '../models/nationality_model.dart';
import 'api_client.dart';
import 'exceptions.dart';

/// Service pour récupérer les données de référence (nationalités, pays, etc.)
class ReferenceService {
  final ApiClient _apiClient = ApiClient();

  /// Récupérer la liste des nationalités
  Future<List<NationalityModel>> getNationalities() async {
    try {
      final response = await _apiClient.get<dynamic>(
        ApiConfig.nationalities,
        fromJson: (json) => json,
      );

      if (response.data == null) {
        throw AuthenticationException('Impossible de récupérer les nationalités');
      }

      if (response.data is List) {
        return (response.data as List)
            .map((item) => NationalityModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      if (response.data is Map<String, dynamic> && (response.data as Map<String, dynamic>)['data'] is List) {
        final list = (response.data as Map<String, dynamic>)['data'] as List;
        return list
            .map((item) => NationalityModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw AuthenticationException('Format de réponse invalide pour les nationalités');
    } catch (e) {
      print('Erreur getNationalities: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Récupérer la liste des pays
  Future<List<Map<String, String>>> getCountries() async {
    try {
      final response = await _apiClient.get<dynamic>(
        ApiConfig.countries,
        fromJson: (json) => json,
      );

      dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        data = data['data'];
      }

      if (data is List) {
        return data.map<Map<String, String>>((item) {
          final map = item as Map<String, dynamic>;
          return {
            'id': (map['id'] ?? '').toString(),
            'name': (map['name'] ?? '').toString(),
            'code': (map['code'] ?? '').toString(),
          };
        }).toList();
      }

      throw AuthenticationException('Format de réponse invalide pour les pays');
    } catch (e) {
      print('Erreur getCountries: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }
}

