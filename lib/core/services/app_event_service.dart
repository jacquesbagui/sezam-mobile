import 'dart:async';
import 'package:flutter/material.dart';
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
  documentRejected,
  userCodeGenerated,
  kycCompleted,
}

/// Service pour gérer les événements de l'application et déclencher les rafraîchissements
class AppEventService {
  // Constantes
  static const _refreshDelay = Duration(milliseconds: 500); // Augmenté à 500ms
  static const _debounceDelay = Duration(milliseconds: 500); // Augmenté à 500ms
  static const _debug = true;
  
  // Singleton
  static AppEventService? _instance;
  static AppEventService get instance => _instance ??= AppEventService._();
  
  AppEventService._();

  // Stream pour les événements
  final _eventController = StreamController<AppEventType>.broadcast();
  
  // Debounce timer pour éviter les appels multiples
  Timer? _debounceTimer;
  
  // Queue pour gérer les événements en attente
  final List<AppEventType> _eventQueue = [];
  bool _isProcessing = false;
  
  /// Stream des événements
  Stream<AppEventType> get events => _eventController.stream;

  /// Émettre un événement
  void emit(AppEventType event) {
    try {
      if (_eventController.isClosed) {
        _log('⚠️ StreamController fermé, impossible d\'émettre l\'événement');
        return;
      }
      
      _log('📢 Événement émis: $event');
      
      // Émettre dans le stream pour les listeners UI (notifications visuelles)
      try {
        _eventController.add(event);
      } catch (e) {
        _log('⚠️ Erreur lors de l\'ajout à la stream: $e');
      }
      
      // Pour tous les événements, ajouter à la queue pour traitement
      _eventQueue.add(event);
      
      // Debounce pour éviter les appels multiples rapides
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDelay, () {
        _processEventQueue();
      });
    } catch (e, stackTrace) {
      _log('❌ Erreur lors de l\'émission de l\'événement: $e');
      if (_debug) {
        _log('Stack trace: $stackTrace');
      }
    }
  }

  /// Traiter la queue d'événements
  Future<void> _processEventQueue() async {
    if (_isProcessing || _eventQueue.isEmpty) {
      return;
    }

    _isProcessing = true;
    
    try {
      // Prendre le dernier événement de chaque type
      final uniqueEvents = <AppEventType, bool>{};
      for (final event in _eventQueue.reversed) {
        uniqueEvents[event] = true;
      }
      
      _eventQueue.clear();
      
      // Traiter chaque événement unique
      for (final event in uniqueEvents.keys) {
        await _handleEvent(event);
        // Petit délai entre chaque traitement
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Gérer un événement en rafraîchissant les données appropriées
  Future<void> _handleEvent(AppEventType event) async {
    // Délai pour s'assurer que l'app est prête
    await Future.delayed(_refreshDelay);
    
    // Essayer plusieurs fois d'obtenir le contexte avec retry
    BuildContext? ctx;
    int retries = 0;
    const maxRetries = 5;
    const retryDelay = Duration(milliseconds: 300);
    
    while (ctx == null && retries < maxRetries) {
      ctx = AppRouter.rootNavigatorKey.currentContext;
      
      if (ctx == null || !ctx.mounted) {
        _log('⚠️ Contexte non disponible (tentative ${retries + 1}/$maxRetries), attente...');
        await Future.delayed(retryDelay);
        retries++;
      } else {
        break;
      }
    }
    
    if (ctx == null || !ctx.mounted) {
      _log('⚠️ Impossible d\'obtenir un contexte valide après $maxRetries tentatives');
      // Même sans contexte, on peut invalider le cache pour forcer le rechargement au prochain accès
      _invalidateCachesForEvent(event);
      return;
    }

    if (!_isAuthenticated(ctx)) {
      _log('⚠️ Utilisateur non authentifié, pas de rafraîchissement');
      return;
    }

    final actions = _getRefreshActions(event);
    if (actions.isEmpty) {
      _log('⚠️ Aucune action définie pour l\'événement: $event');
      return;
    }

    await _executeRefreshActions(ctx, actions);
  }
  
  /// Invalider les caches même sans contexte (pour forcer le rechargement au prochain accès)
  void _invalidateCachesForEvent(AppEventType event) {
    _log('🔄 Invalidation des caches pour l\'événement: $event');
    
    switch (event) {
      case AppEventType.consentRequested:
      case AppEventType.consentGranted:
      case AppEventType.consentDenied:
        // Le cache sera invalidé quand on obtiendra le contexte
        _log('📋 Cache des consentements sera invalidé au prochain accès');
        break;
      case AppEventType.documentUploaded:
      case AppEventType.documentVerified:
      case AppEventType.documentRejected:
        _log('📄 Cache des documents sera invalidé au prochain accès');
        break;
      case AppEventType.profileUpdated:
      case AppEventType.profileValidated:
      case AppEventType.kycCompleted:
        _log('👤 Cache du profil sera invalidé au prochain accès');
        break;
      default:
        break;
    }
  }

  /// Récupérer les actions de rafraîchissement selon le type d'événement
  List<Future<void> Function(BuildContext)> _getRefreshActions(AppEventType event) {
    // Actions peuvent être synchrones (invalidateCache) ou asynchrones (refresh)
    switch (event) {
      case AppEventType.profileUpdated:
      case AppEventType.kycCompleted:
        _log('🔄 Actions: Rafraîchissement du profil');
        return [
          (ctx) => _safeRefresh(ctx, () => 
            Provider.of<ProfileProvider>(ctx, listen: false).refresh()
          ),
          (ctx) => _safeRefresh(ctx, () => 
            Provider.of<AuthProvider>(ctx, listen: false).refreshUser()
          ),
        ];

      case AppEventType.profileValidated:
        _log('🔄 Actions: Rafraîchissement du profil et de l\'utilisateur');
        return [
          (ctx) => _safeRefresh(ctx, () => 
            Provider.of<ProfileProvider>(ctx, listen: false).refresh()
          ),
          (ctx) => _safeRefresh(ctx, () => 
            Provider.of<AuthProvider>(ctx, listen: false).refreshUser()
          ),
        ];

      case AppEventType.consentRequested:
      case AppEventType.consentGranted:
      case AppEventType.consentDenied:
        _log('🔄 Actions: Rafraîchissement des consentements et notifications');
        return [
          (ctx) => _safeRefresh(ctx, () async {
            final provider = Provider.of<ConsentProvider>(ctx, listen: false);
            // Invalider le cache d'abord pour forcer le rechargement
            provider.invalidateCache();
            // Puis rafraîchir
            await provider.refresh();
            _log('✅ Consentements rafraîchis');
          }),
          (ctx) => _safeRefresh(ctx, () async {
            final provider = Provider.of<NotificationProvider>(ctx, listen: false);
            await provider.refresh();
            _log('✅ Notifications rafraîchies');
          }),
        ];

      case AppEventType.documentUploaded:
      case AppEventType.documentVerified:
      case AppEventType.documentRejected:
        _log('🔄 Actions: Rafraîchissement des documents, profil et notifications');
        return [
          (ctx) => _safeRefresh(ctx, () => 
            Provider.of<DocumentProvider>(ctx, listen: false).refresh()
          ),
          (ctx) => _safeRefresh(ctx, () => 
            Provider.of<ProfileProvider>(ctx, listen: false).refresh()
          ),
          (ctx) => _safeRefresh(ctx, () => 
            Provider.of<AuthProvider>(ctx, listen: false).refreshUser()
          ),
          (ctx) => _safeRefresh(ctx, () async {
            final provider = Provider.of<NotificationProvider>(ctx, listen: false);
            await provider.refresh();
            _log('✅ Notifications rafraîchies');
          }),
        ];

      case AppEventType.userCodeGenerated:
        _log('🔄 Actions: Rafraîchissement de l\'utilisateur');
        return [
          (ctx) => _safeRefresh(ctx, () => 
            Provider.of<AuthProvider>(ctx, listen: false).refreshUser()
          ),
        ];

    }
  }

  /// Exécuter les actions de rafraîchissement de manière sécurisée
  Future<void> _executeRefreshActions(
    BuildContext ctx,
    List<Future<void> Function(BuildContext)> actions,
  ) async {
    if (!ctx.mounted) {
      _log('⚠️ Widget non monté lors du rafraîchissement');
      return;
    }

    if (!_isAuthenticated(ctx)) {
      _log('⚠️ Utilisateur non authentifié, annulation du rafraîchissement');
      return;
    }

    _log('✅ Exécution de ${actions.length} action(s) de rafraîchissement');

    // Exécuter les actions séquentiellement avec un délai entre chacune
    for (int i = 0; i < actions.length; i++) {
      if (!ctx.mounted) {
        _log('⚠️ Widget démonté pendant l\'exécution, arrêt');
        break;
      }

      try {
        _log('🔄 Exécution de l\'action ${i + 1}/${actions.length}');
        await actions[i](ctx);
        
        // Petit délai entre chaque action
        if (i < actions.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e, stackTrace) {
        _log('❌ Erreur lors de l\'exécution de l\'action ${i + 1}: $e');
        if (_debug) {
          _log('Stack trace: $stackTrace');
        }
        // Continuer avec les autres actions même si une échoue
      }
    }

    _log('✅ Rafraîchissement terminé');
  }

  /// Wrapper sécurisé pour les appels de refresh
  Future<void> _safeRefresh(BuildContext ctx, Future<void> Function() refreshFn) async {
    if (!ctx.mounted) {
      _log('⚠️ Widget non monté, refresh annulé');
      return;
    }

    try {
      await refreshFn();
    } catch (e, stackTrace) {
      _log('❌ Erreur lors du refresh: $e');
      if (_debug) {
        _log('Stack trace: $stackTrace');
      }
    }
  }


  /// Vérifier si l'utilisateur est authentifié
  bool _isAuthenticated(BuildContext ctx) {
    if (!ctx.mounted) {
      return false;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
      return authProvider.isAuthenticated;
    } catch (e) {
      _log('⚠️ Erreur lors de la vérification de l\'authentification: $e');
      return false;
    }
  }

  /// Logger un message (uniquement en mode debug)
  void _log(String message) {
    if (_debug) {
      print('[AppEventService] $message');
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _log('🧹 Nettoyage des ressources');
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _eventQueue.clear();
    
    if (!_eventController.isClosed) {
      _eventController.close();
    }
  }

  /// Réinitialiser le singleton (utile pour les tests)
  void reset() {
    dispose();
    _instance = null;
    _isProcessing = false;
  }
}