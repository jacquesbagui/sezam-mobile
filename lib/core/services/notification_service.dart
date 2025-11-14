import '../config/api_config.dart';
import '../models/notification_model.dart';
import 'api_client.dart';
import 'exceptions.dart';

/// Service pour gérer les notifications
class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// Récupérer toutes les notifications de l'utilisateur
  Future<List<NotificationModel>> getNotifications({bool unreadOnly = false}) async {
    try {
      final endpoint = unreadOnly 
          ? '${ApiConfig.notifications}?unread_only=true'
          : ApiConfig.notifications;
          
      final response = await _apiClient.get<List>(
        endpoint,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.data == null) {
        throw AuthenticationException('Impossible de récupérer les notifications');
      }

      if (response.data is List) {
        return (response.data as List)
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw AuthenticationException('Format de réponse invalide pour les notifications');
    } catch (e) {
      print('Erreur getNotifications: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.put(
        '${ApiConfig.notifications}/$notificationId/read',
        body: {},
      );
    } catch (e) {
      print('Erreur markAsRead: $e');
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }
}
