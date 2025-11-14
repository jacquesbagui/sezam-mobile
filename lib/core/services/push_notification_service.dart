import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../services/consent_service.dart';
import '../providers/document_provider.dart';
import '../providers/consent_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../../features/requests/request_detail_screen.dart';
import 'app_event_service.dart';

/// Service pour gérer les notifications push via Firebase Cloud Messaging
class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiClient _apiClient = ApiClient();

  /// Initialiser Firebase Messaging et demander les permissions
  /// isAuthenticated permet de décider si on enregistre le device immédiatement
  Future<void> initialize({bool isAuthenticated = false}) async {
    try {
      // Demander la permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permission accordée');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Permission provisoire accordée');
      } else {
        print('❌ Permission refusée');
      }

      // Obtenir le token FCM
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('📱 FCM Token obtenu: ${token.substring(0, 20)}...');
        
        // Enregistrer le device seulement si l'utilisateur est authentifié
        if (isAuthenticated) {
          await registerDeviceToken(token);
        }
      }

      // Écouter les nouveaux tokens
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 Token FCM rafraîchi');
        // On n'enregistre pas automatiquement ici, il faudra appeler registerDevice manuellement
      });

      // Gérer les notifications en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Gérer les clics sur les notifications
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // Vérifier si l'app a été ouverte depuis une notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
      }
    } catch (e) {
      // Ignorer silencieusement les erreurs APNS sur le simulateur
      if (e.toString().contains('APNS token has not been set')) {
        print('⚠️ Push notifications indisponibles sur le simulateur (normal)');
      } else {
        print('⚠️ Erreur lors de l\'initialisation de Firebase Messaging: $e');
      }
    }
  }

  /// Enregistrer le token du device auprès du backend
  /// Retourne true si l'enregistrement a réussi
  Future<bool> registerDeviceToken(String token) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      String deviceId;
      String deviceType;
      String deviceName;
      String? osVersion;
      String? deviceModel;

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceType = 'android';
        deviceName = androidInfo.device;
        osVersion = androidInfo.version.release;
        deviceModel = androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceType = 'ios';
        deviceName = iosInfo.name;
        osVersion = iosInfo.systemVersion;
        deviceModel = iosInfo.model;
      } else {
        throw UnsupportedError('Platform not supported');
      }

      await _apiClient.post(
        ApiConfig.devices,
        body: {
          'device_id': deviceId,
          'device_type': deviceType,
          'device_name': deviceName,
          'device_model': deviceModel,
          'os_version': osVersion,
          'app_version': packageInfo.version,
          'push_token': token,
        },
      );
      
      // Le backend retourne 200 si le device existe déjà, 201 si nouveau
      print('✅ Device enregistré/mis à jour avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'enregistrement du device: $e');
      return false;
    }
  }
  
  /// Récupérer le token FCM actuel (sans l'enregistrer)
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  /// Gérer les notifications reçues quand l'app est au premier plan
  void _handleForegroundMessage(RemoteMessage message) {
    print('Notification reçue en foreground: ${message.messageId}');

    final data = message.data;
    final type = data['type'];
    final consentId = data['consent_id'] ?? data['consentId'];

    // Émettre un événement pour déclencher le rafraîchissement
    _emitEventFromNotificationType(type);

    // Rafraîchir les ressources selon le type de notification (pour compatibilité)
    _refreshResources(type);

    if (type == 'consent_request' && consentId != null) {
      _navigateToConsent(consentId);
    }
  }

  /// Gérer les clics sur les notifications
  void _handleNotificationClick(RemoteMessage message) {
    print('📱 Notification cliquée: ${message.messageId}');
    
    // Extraire les données
    final data = message.data;
    final type = data['type'];
    final consentId = data['consent_id'] ?? data['consentId'];
    final screen = data['screen'];
    
    // Émettre un événement pour déclencher le rafraîchissement
    _emitEventFromNotificationType(type);
    
    // Rafraîchir les ressources selon le type de notification (pour compatibilité)
    _refreshResources(type);
    
    // Attendre un peu pour que l'app soit prête
    Future.delayed(const Duration(milliseconds: 500), () {
      _navigateFromNotification(type, screen, consentId);
    });
  }

  /// Naviguer depuis une notification
  void _navigateFromNotification(String? type, String? screen, String? consentId) {
    final ctx = AppRouter.rootNavigatorKey.currentContext;
    if (ctx == null) {
      print('⚠️ Aucun contexte de navigation disponible, navigation différée');
      // Réessayer après un délai
      Future.delayed(const Duration(seconds: 1), () {
        _navigateFromNotification(type, screen, consentId);
      });
      return;
    }

    try {
      // S'assurer d'être sur le dashboard d'abord
      if (!ctx.canPop() || !ctx.mounted) {
        // Si on n'est pas encore sur une route, aller au dashboard
        ctx.go('/dashboard');
        Future.delayed(const Duration(milliseconds: 300), () {
          _performNavigation(ctx, type, screen, consentId);
        });
      } else {
        _performNavigation(ctx, type, screen, consentId);
      }
    } catch (e) {
      print('❌ Erreur lors de la navigation: $e');
    }
  }

  /// Effectuer la navigation selon le type de notification
  void _performNavigation(BuildContext ctx, String? type, String? screen, String? consentId) {
    try {
      // Priorité 1: Utiliser le screen fourni par le backend
      if (screen != null && screen.isNotEmpty) {
        print('📍 Navigation vers: $screen');
        if (screen.startsWith('/')) {
          ctx.go(screen);
        } else {
          ctx.push('/$screen');
        }
        return;
      }

      // Priorité 2: Navigation selon le type
      switch (type) {
        case 'profile_validated':
          print('📍 Navigation vers profil');
          ctx.go('/profile');
          break;

        case 'consent_request':
          if (consentId != null) {
            print('📍 Navigation vers consent: $consentId');
            _navigateToConsent(consentId);
          } else {
            print('📍 Navigation vers requests');
            ctx.go('/dashboard');
            // Attendre un peu puis naviguer vers requests
            Future.delayed(const Duration(milliseconds: 500), () {
              if (ctx.mounted) {
                ctx.push('/requests');
              }
            });
          }
          break;

        case 'consent_granted':
        case 'consent_denied':
          print('📍 Navigation vers requests');
          ctx.go('/dashboard');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (ctx.mounted) {
              ctx.push('/requests');
            }
          });
          break;

        case 'document_verified':
        case 'document_rejected':
          print('📍 Navigation vers documents');
          ctx.go('/dashboard');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (ctx.mounted) {
              ctx.push('/documents');
            }
          });
          break;

        default:
          // Par défaut, aller au dashboard
          print('📍 Navigation vers dashboard (par défaut)');
          ctx.go('/dashboard');
          break;
      }
    } catch (e) {
      print('❌ Erreur lors de la navigation: $e');
      // Fallback: aller au dashboard
      if (ctx.mounted) {
        ctx.go('/dashboard');
      }
    }
  }

  /// Convertir le type de notification en événement
  void _emitEventFromNotificationType(String? type) {
    if (type == null) return;

    switch (type) {
      case 'profile_validated':
        AppEventService.instance.emit(AppEventType.profileValidated);
        break;
      case 'consent_request':
        AppEventService.instance.emit(AppEventType.consentRequested);
        break;
      case 'consent_granted':
        AppEventService.instance.emit(AppEventType.consentGranted);
        break;
      case 'consent_denied':
        AppEventService.instance.emit(AppEventType.consentDenied);
        break;
      case 'document_verified':
        AppEventService.instance.emit(AppEventType.documentVerified);
        break;
      default:
        // Pour les autres types, ne rien faire ou émettre un événement générique
        break;
    }
  }

  /// Rafraîchir les ressources selon le type de notification
  void _refreshResources(String? type) {
    final ctx = AppRouter.rootNavigatorKey.currentContext;
    if (ctx == null) {
      print('⚠️ Aucun contexte disponible pour rafraîchir les ressources');
      return;
    }

    try {
      switch (type) {
        case 'document_verified':
        case 'document_rejected':
          // Rafraîchir les documents et le profil
          print('🔄 Rafraîchissement des documents et du profil...');
          final documentProvider = Provider.of<DocumentProvider>(ctx, listen: false);
          documentProvider.loadDocuments();
          
          final profileProvider = Provider.of<ProfileProvider>(ctx, listen: false);
          profileProvider.loadProfileStatus();
          
          // Rafraîchir aussi l'utilisateur car son statut peut avoir changé
          final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
          authProvider.refreshUser();
          break;

        case 'consent_request':
        case 'consent_granted':
        case 'consent_denied':
        case 'consent_revoked':
          // Rafraîchir les consentements/requests
          print('🔄 Rafraîchissement des consentements/requests...');
          final consentProvider = Provider.of<ConsentProvider>(ctx, listen: false);
          consentProvider.loadConsents();
          break;

        default:
          // Pour les autres types, rafraîchir toutes les ressources importantes
          print('🔄 Rafraîchissement général des ressources...');
          final documentProvider = Provider.of<DocumentProvider>(ctx, listen: false);
          documentProvider.loadDocuments();
          
          final consentProvider = Provider.of<ConsentProvider>(ctx, listen: false);
          consentProvider.loadConsents();
          
          final profileProvider = Provider.of<ProfileProvider>(ctx, listen: false);
          profileProvider.loadProfileStatus();
          
          final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
          authProvider.refreshUser();
          break;
      }
      print('✅ Ressources rafraîchies avec succès');
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement des ressources: $e');
    }
  }

  Future<void> _navigateToConsent(String consentId) async {
    final ctx = AppRouter.rootNavigatorKey.currentContext;
    if (ctx == null) {
      print('⚠️ Aucun contexte de navigation disponible');
      return;
    }

    try {
      // Charger le consentement depuis l'API
      final consent = await ConsentService().getConsentById(consentId);
      if (consent == null) {
        // À défaut, ouvrir la liste des demandes
        ctx.push('/requests');
        return;
      }

      // S'assurer d'être sur l'écran des demandes, puis ouvrir le détail
      await ctx.push('/requests');
      await Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => RequestDetailScreen(
            consent: consent,
            currentTabIndex: 0,
          ),
        ),
      );
    } catch (e) {
      print('Erreur de navigation vers le consentement: $e');
      // Fallback: ouvrir la liste des demandes
      ctx.push('/requests');
    }
  }

  /// Abonner l'utilisateur à un topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Abonné au topic: $topic');
    } catch (e) {
      print('Erreur lors de l\'abonnement au topic: $e');
    }
  }

  /// Désabonner l'utilisateur d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Désabonné du topic: $topic');
    } catch (e) {
      print('Erreur lors du désabonnement du topic: $e');
    }
  }
}

// Note: Le handler pour les notifications en background est défini dans main.dart

