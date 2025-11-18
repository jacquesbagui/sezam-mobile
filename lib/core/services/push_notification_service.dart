import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../services/consent_service.dart';
import '../../features/requests/request_detail_screen.dart';
import '../../features/connections/connection_detail_screen.dart';
import 'app_event_service.dart';

/// Service pour gérer les notifications push via Firebase Cloud Messaging
class PushNotificationService {
  // Singleton
  static PushNotificationService? _instance;
  static PushNotificationService get instance => _instance ??= PushNotificationService._();
  
  PushNotificationService._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiClient _apiClient = ApiClient();
  
  // Plugin pour les notifications locales
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Cache du token actuel
  String? _currentToken;
  
  // Flag pour éviter les initialisations multiples
  bool _isInitialized = false;
  
  // Timer pour gérer les tentatives de navigation différées
  static const _navigationRetryDelay = Duration(seconds: 1);
  static const _navigationMaxRetries = 3;
  static const _navigationMediumDelay = Duration(milliseconds: 500);

  /// Initialiser Firebase Messaging et demander les permissions
  /// isAuthenticated permet de décider si on enregistre le device immédiatement
  Future<void> initialize({bool isAuthenticated = false}) async {
    if (_isInitialized) {
      print('⚠️ Push notification service déjà initialisé');
      return;
    }

    try {
      // Demander la permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _logPermissionStatus(settings.authorizationStatus);

      // Initialiser les notifications locales pour Android
      if (Platform.isAndroid) {
        await _initializeLocalNotifications();
      }

      // Obtenir le token FCM
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _currentToken = token;
        print('📱 FCM Token obtenu: ${token.substring(0, 20)}...');
        
        // Enregistrer le device seulement si l'utilisateur est authentifié
        if (isAuthenticated) {
          await registerDeviceToken(token);
        }
      }

      // Écouter les nouveaux tokens
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 Token FCM rafraîchi: ${newToken.substring(0, 20)}...');
        _currentToken = newToken;
        // Le token sera enregistré lors de la prochaine connexion
      });

      // Gérer les notifications en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Gérer les clics sur les notifications
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // Vérifier si l'app a été ouverte depuis une notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('📱 App ouverte via notification: ${initialMessage.messageId}');
        // Attendre que l'app soit complètement initialisée
        Future.delayed(_navigationMediumDelay, () {
          _handleNotificationClick(initialMessage);
        });
      }

      _isInitialized = true;
      print('✅ Push notification service initialisé avec succès');
    } catch (e) {
      // Ignorer silencieusement les erreurs APNS sur le simulateur
      if (e.toString().contains('APNS token has not been set') ||
          e.toString().contains('MissingPluginException')) {
        print('⚠️ Push notifications indisponibles sur le simulateur (normal)');
      } else {
        print('❌ Erreur lors de l\'initialisation de Firebase Messaging: $e');
      }
    }
  }

  /// Logger le statut de permission
  void _logPermissionStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        print('✅ Permission accordée');
        break;
      case AuthorizationStatus.provisional:
        print('⚠️ Permission provisoire accordée');
        break;
      case AuthorizationStatus.denied:
        print('❌ Permission refusée');
        break;
      case AuthorizationStatus.notDetermined:
        print('⚠️ Permission non déterminée');
        break;
    }
  }

  /// Enregistrer le token du device auprès du backend
  /// Retourne true si l'enregistrement a réussi
  Future<bool> registerDeviceToken([String? token]) async {
    try {
      // Utiliser le token fourni ou le token en cache
      final deviceToken = token ?? _currentToken;
      
      if (deviceToken == null) {
        print('⚠️ Aucun token FCM disponible pour l\'enregistrement');
        // Essayer de récupérer un nouveau token
        final newToken = await _firebaseMessaging.getToken();
        if (newToken == null) {
          print('❌ Impossible d\'obtenir un token FCM');
          return false;
        }
        _currentToken = newToken;
        return registerDeviceToken(newToken);
      }

      final deviceInfo = await _getDeviceInfo();
      if (deviceInfo == null) {
        print('❌ Impossible de récupérer les informations du device');
        return false;
      }

      await _apiClient.post(
        ApiConfig.devices,
        body: {
          ...deviceInfo,
          'push_token': deviceToken,
        },
      );
      
      // Le backend retourne 200 si le device existe déjà, 201 si nouveau
      print('✅ Device enregistré/mis à jour avec succès');
      return true;
    } catch (e) {
      // Gérer spécifiquement l'erreur d'authentification
      if (e.toString().contains('Unauthenticated') || 
          e.toString().contains('401') ||
          e.toString().contains('unauthenticated')) {
        print('⚠️ Authentification requise pour enregistrer le device');
        return false;
      }
      print('❌ Erreur lors de l\'enregistrement du device: $e');
      return false;
    }
  }

  /// Récupérer les informations du device
  Future<Map<String, dynamic>?> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return {
          'device_id': androidInfo.id,
          'device_type': 'android',
          'device_name': androidInfo.device,
          'device_model': androidInfo.model,
          'os_version': androidInfo.version.release,
          'app_version': packageInfo.version,
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return {
          'device_id': iosInfo.identifierForVendor ?? 'unknown',
          'device_type': 'ios',
          'device_name': iosInfo.name,
          'device_model': iosInfo.model,
          'os_version': iosInfo.systemVersion,
          'app_version': packageInfo.version,
        };
      } else {
        print('❌ Plateforme non supportée');
        return null;
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des infos device: $e');
      return null;
    }
  }
  
  /// Récupérer le token FCM actuel (sans l'enregistrer)
  Future<String?> getToken() async {
    try {
      if (_currentToken != null) {
        return _currentToken;
      }
      
      final token = await _firebaseMessaging.getToken();
      _currentToken = token;
      return token;
    } catch (e) {
      print('❌ Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  /// Initialiser les notifications locales pour Android
  Future<void> _initializeLocalNotifications() async {
    if (!Platform.isAndroid) return;

    // Créer le canal de notification Android avec son
    const androidChannel = AndroidNotificationChannel(
      'sezam_channel',
      'SEZAM Notifications',
      description: 'Notifications importantes de SEZAM',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Créer le canal (nécessaire pour Android 8.0+)
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidChannel);
      print('✅ Canal de notification Android créé');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Gérer le clic sur la notification locale
        if (response.payload != null) {
          try {
            final data = Map<String, dynamic>.from(
              Uri.splitQueryString(response.payload!),
            );
            final type = data['type'];
            if (type != null) {
              _emitEventFromNotificationType(type);
              _navigateFromNotification(
                type: type,
                screen: data['screen'],
                consentId: data['consent_id'],
              );
            }
          } catch (e) {
            print('❌ Erreur lors du traitement du clic notification locale: $e');
          }
        }
      },
    );
  }

  /// Gérer les notifications reçues quand l'app est au premier plan
  void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Notification reçue en foreground: ${message.messageId}');
    
    try {
      final data = message.data;
      final type = data['type'];
      final title = message.notification?.title ?? 'SEZAM';
      final body = message.notification?.body ?? '';
      
      // Afficher une notification système Android avec son
      if (Platform.isAndroid) {
        _showLocalNotification(
          title: title,
          body: body,
          data: data,
        );
      }
      
      if (type != null) {
        print('📌 Type de notification: $type');
        
        // Toujours émettre l'événement, même sans contexte
        // AppEventService gérera le retry automatiquement
        _emitEventFromNotificationType(type);
        
        // Si le contexte est disponible, on peut aussi naviguer
        final ctx = AppRouter.rootNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          print('✅ Contexte disponible, navigation possible');
        } else {
          print('⚠️ Contexte non disponible, événement émis quand même (retry automatique)');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Erreur lors du traitement de la notification foreground: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Afficher une notification locale avec son
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    if (!Platform.isAndroid) return;

    try {
      // Créer un payload pour le clic
      final payload = Uri(queryParameters: {
        'type': data['type'] ?? '',
        'screen': data['screen'] ?? '',
        'consent_id': data['consent_id'] ?? data['consentId'] ?? '',
      }).query;

      const androidDetails = AndroidNotificationDetails(
        'sezam_channel',
        'SEZAM Notifications',
        channelDescription: 'Notifications importantes de SEZAM',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        // Utiliser le son par défaut du système
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('✅ Notification locale affichée avec son');
    } catch (e) {
      print('❌ Erreur lors de l\'affichage de la notification locale: $e');
    }
  }

  /// Gérer les clics sur les notifications
  void _handleNotificationClick(RemoteMessage message) {
    print('📱 Notification cliquée: ${message.messageId}');
    
    try {
      // Extraire les données
      final data = message.data;
      final type = data['type'];
      final consentId = data['consent_id'] ?? data['consentId'];
      final screen = data['screen'];
      
      print('📊 Données notification - Type: $type, Screen: $screen, ConsentId: $consentId');
      
      // Émettre un événement pour déclencher le rafraîchissement
      if (type != null) {
        _emitEventFromNotificationType(type);
      }
      
      // Attendre que l'app soit prête avant de naviguer
      Future.delayed(_navigationMediumDelay, () {
        _navigateFromNotification(
          type: type,
          screen: screen,
          consentId: consentId,
        );
      });
    } catch (e) {
      print('❌ Erreur lors du traitement du clic notification: $e');
    }
  }

  /// Naviguer depuis une notification avec retry
  void _navigateFromNotification({
    String? type,
    String? screen,
    String? consentId,
    int retryCount = 0,
  }) {
    final ctx = AppRouter.rootNavigatorKey.currentContext;
    
    if (ctx == null || !ctx.mounted) {
      if (retryCount < _navigationMaxRetries) {
        print('⚠️ Contexte non disponible, tentative ${retryCount + 1}/$_navigationMaxRetries');
        Future.delayed(_navigationRetryDelay, () {
          _navigateFromNotification(
            type: type,
            screen: screen,
            consentId: consentId,
            retryCount: retryCount + 1,
          );
        });
      } else {
        print('❌ Impossible de naviguer après $_navigationMaxRetries tentatives');
      }
      return;
    }

    try {
      _performNavigation(ctx, type, screen, consentId);
    } catch (e) {
      print('❌ Erreur lors de la navigation: $e');
      // Fallback: aller au dashboard
      _safePush(ctx, '/dashboard');
    }
  }

  /// Liste des routes valides dans l'application
  static const Set<String> _validRoutes = {
    '/splash',
    '/onboarding',
    '/auth',
    '/otp-verification',
    '/registration-success',
    '/dashboard',
    '/documents',
    '/requests',
    '/connections',
    '/profile',
    '/kyc',
    '/usage-purpose',
    '/terms-consent',
  };

  /// Vérifier si une route est valide
  bool _isValidRoute(String route) {
    // Normaliser la route (enlever les query parameters)
    final normalizedRoute = route.split('?').first;
    return _validRoutes.contains(normalizedRoute);
  }

  /// Effectuer la navigation selon le type de notification
  void _performNavigation(
    BuildContext ctx,
    String? type,
    String? screen,
    String? consentId,
  ) {
    if (!ctx.mounted) {
      print('⚠️ Widget non monté, navigation annulée');
      return;
    }

    try {
      // Priorité 1: Si un consentId est fourni pour les types de consentement, naviguer vers le détail
      if (consentId != null && 
          (type == 'consent_granted' || type == 'consent_denied' || type == 'consent_revoked' || type == 'consent_request')) {
        print('📍 Navigation vers détail (consentId fourni): $consentId');
        _navigateToConsent(consentId);
        return;
      }

      // Priorité 2: Utiliser le screen fourni par le backend (seulement si valide)
      if (screen != null && screen.isNotEmpty) {
        // Normaliser la route
        final normalizedScreen = screen.startsWith('/') ? screen : '/$screen';
        
        if (_isValidRoute(normalizedScreen)) {
          print('📍 Navigation vers: $normalizedScreen');
          _safePush(ctx, normalizedScreen);
          return;
        } else {
          print('⚠️ Route invalide fournie par le backend: $screen, utilisation du type de notification');
          // Continuer avec la logique basée sur le type
        }
      }

      // Priorité 3: Navigation selon le type
      switch (type) {
        case 'profile_validated':
          print('📍 Navigation vers profil');
          _safePush(ctx, '/profile');
          break;

        case 'consent_request':
          print('📍 Navigation vers requests');
          _safePush(ctx, '/requests');
          break;

        case 'consent_granted':
        case 'consent_denied':
        case 'consent_revoked':
          // Naviguer vers la liste des connexions
          print('📍 Navigation vers connections');
          _safePush(ctx, '/connections');
          break;

        case 'document_verified':
        case 'document_rejected':
          print('📍 Navigation vers documents');
          _safePush(ctx, '/documents');
          break;

        default:
          // Par défaut, aller au dashboard
          print('📍 Navigation vers dashboard (par défaut)');
          _safePush(ctx, '/dashboard');
          break;
      }
    } catch (e) {
      print('❌ Erreur lors de la navigation: $e');
      _safePush(ctx, '/dashboard');
    }
  }

  /// Navigation sécurisée avec gestion des erreurs
  void _safePush(BuildContext ctx, String route) {
    if (!ctx.mounted) {
      print('⚠️ Widget non monté, impossible de naviguer');
      return;
    }

    try {
      if (route.startsWith('/')) {
        ctx.go(route);
      } else {
        ctx.push('/$route');
      }
    } catch (e) {
      print('❌ Erreur lors de la navigation vers $route: $e');
      // Dernier fallback
      try {
        ctx.go('/dashboard');
      } catch (e2) {
        print('❌ Impossible de naviguer vers le dashboard: $e2');
      }
    }
  }

  /// Convertir le type de notification en événement
  void _emitEventFromNotificationType(String type) {
    final eventMap = {
      'profile_validated': AppEventType.profileValidated,
      'consent_request': AppEventType.consentRequested,
      'consent_granted': AppEventType.consentGranted,
      'consent_denied': AppEventType.consentDenied,
      'consent_revoked': AppEventType.consentRevoked,
      'document_verified': AppEventType.documentVerified,
      'document_rejected': AppEventType.documentRejected,
      'document_uploaded': AppEventType.documentUploaded,
      'user_code_generated': AppEventType.userCodeGenerated,
      'kyc_completed': AppEventType.kycCompleted,
    };

    final eventType = eventMap[type];
    if (eventType != null) {
      print('📢 Émission de l\'événement: $eventType');
      AppEventService.instance.emit(eventType);
    } else {
      print('⚠️ Type de notification non reconnu: $type');
    }
  }

  /// Naviguer vers le détail d'un consentement
  Future<void> _navigateToConsent(String consentId) async {
    final ctx = AppRouter.rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      print('⚠️ Aucun contexte de navigation disponible');
      return;
    }

    try {
      print('🔍 Chargement du consentement: $consentId');
      
      // Attendre un peu pour s'assurer que l'app est prête
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!ctx.mounted) {
        print('⚠️ Widget non monté après délai');
        return;
      }
      
      // Charger le consentement depuis l'API
      final consent = await ConsentService().getConsentById(consentId);
      
      if (consent == null) {
        print('⚠️ Consentement introuvable (ID: $consentId), redirection vers /connections');
        _safePush(ctx, '/connections');
        return;
      }

      if (!ctx.mounted) {
        print('⚠️ Widget non monté après chargement');
        return;
      }

      print('✅ Consentement chargé: ${consent.id}, status: ${consent.statusName}, granted: ${consent.isGranted}');

      // Naviguer vers le détail de la connexion
      // Utiliser ConnectionDetailScreen pour les connexions (consent_granted, consent_denied, consent_revoked)
      // et RequestDetailScreen pour les demandes en attente (consent_request)
      final isConnection = consent.isGranted || consent.revokedAt != null || consent.deniedAt != null;
      
      if (isConnection) {
        print('📍 Navigation vers ConnectionDetailScreen');
        // Pour les connexions, utiliser ConnectionDetailScreen
        await Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => ConnectionDetailScreen(consent: consent),
          ),
        );
      } else {
        print('📍 Navigation vers RequestDetailScreen');
        // Pour les demandes en attente, utiliser RequestDetailScreen
        await Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => RequestDetailScreen(
              consent: consent,
              currentTabIndex: 0,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Erreur de navigation vers le consentement: $e');
      print('Stack trace: $stackTrace');
      // Fallback: ouvrir la liste des connexions
      if (ctx.mounted) {
        print('📍 Fallback: navigation vers /connections');
        _safePush(ctx, '/connections');
      }
    }
  }

  /// Abonner l'utilisateur à un topic
  Future<bool> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Abonné au topic: $topic');
      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'abonnement au topic $topic: $e');
      return false;
    }
  }

  /// Désabonner l'utilisateur d'un topic
  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Désabonné du topic: $topic');
      return true;
    } catch (e) {
      print('❌ Erreur lors du désabonnement du topic $topic: $e');
      return false;
    }
  }

  /// Réinitialiser le service (utile pour les tests ou déconnexion)
  void reset() {
    _currentToken = null;
    _isInitialized = false;
    _instance = null;
  }
}