import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/consent_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/document_provider.dart';
import '../providers/notification_provider.dart';
import '../router/app_router.dart';

/// Types d'événements pour déclencher le rafraîchissement
enum AppEventType {
  profileUpdated,
  profileValidated,
  consentRequested,
  consentGranted,
  consentDenied,
  documentUploaded,
  documentVerified,
  userCodeGenerated,
  kycCompleted,
}

/// Service pour gérer les événements de l'application et déclencher les rafraîchissements
class AppEventService {
  static AppEventService? _instance;
  static AppEventService get instance => _instance ??= AppEventService._();
  
  AppEventService._();

  final _eventController = StreamController<AppEventType>.broadcast();
  
  /// Stream des événements
  Stream<AppEventType> get events => _eventController.stream;

  /// Émettre un événement
  void emit(AppEventType event) {
    print('📢 Événement émis: $event');
    _eventController.add(event);
    _handleEvent(event);
  }

  /// Gérer un événement en rafraîchissant les données appropriées
  void _handleEvent(AppEventType event) {
    final ctx = AppRouter.rootNavigatorKey.currentContext;
    if (ctx == null) {
      print('⚠️ Aucun contexte disponible pour gérer l\'événement');
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
      
      // Ne rafraîchir que si l'utilisateur est authentifié
      if (!authProvider.isAuthenticated) {
        return;
      }

      switch (event) {
        case AppEventType.profileUpdated:
        case AppEventType.kycCompleted:
          print('🔄 Rafraîchissement du profil...');
          Provider.of<ProfileProvider>(ctx, listen: false).loadProfileStatus();
          authProvider.refreshUser();
          break;

        case AppEventType.profileValidated:
          print('🔄 Rafraîchissement du profil et de l\'utilisateur...');
          Provider.of<ProfileProvider>(ctx, listen: false).loadProfileStatus();
          authProvider.refreshUser();
          break;

        case AppEventType.consentRequested:
        case AppEventType.consentGranted:
        case AppEventType.consentDenied:
          print('🔄 Rafraîchissement des consentements et notifications...');
          Provider.of<ConsentProvider>(ctx, listen: false).loadConsents();
          Provider.of<NotificationProvider>(ctx, listen: false).loadNotifications();
          break;

        case AppEventType.documentUploaded:
        case AppEventType.documentVerified:
          print('🔄 Rafraîchissement des documents et du profil...');
          Provider.of<DocumentProvider>(ctx, listen: false).loadDocuments();
          Provider.of<ProfileProvider>(ctx, listen: false).loadProfileStatus();
          authProvider.refreshUser();
          break;

        case AppEventType.userCodeGenerated:
          print('🔄 Rafraîchissement de l\'utilisateur...');
          authProvider.refreshUser();
          break;
      }
    } catch (e) {
      print('❌ Erreur lors de la gestion de l\'événement $event: $e');
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _eventController.close();
  }
}

