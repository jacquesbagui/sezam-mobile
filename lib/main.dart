import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/consent_provider.dart';
import 'core/providers/document_provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/app_event_service.dart';
import 'core/widgets/app_lifecycle_listener.dart' show SezamAppLifecycleListener;
import 'core/widgets/global_notification_listener.dart';

// Handler pour les notifications en background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Handling background message: ${message.messageId}');
  
  // Extraire le type de notification
  final data = message.data;
  final type = data['type'] as String?;
  
  // Émettre un événement pour déclencher le rafraîchissement quand l'app revient au premier plan
  if (type != null) {
    switch (type) {
      case 'consent_request':
        AppEventService.instance.emit(AppEventType.consentRequested);
        break;
      case 'consent_granted':
        AppEventService.instance.emit(AppEventType.consentGranted);
        break;
      case 'consent_denied':
        AppEventService.instance.emit(AppEventType.consentDenied);
        break;
      case 'profile_validated':
        AppEventService.instance.emit(AppEventType.profileValidated);
        break;
      case 'document_verified':
        AppEventService.instance.emit(AppEventType.documentVerified);
        break;
      case 'document_rejected':
        AppEventService.instance.emit(AppEventType.documentRejected);
        break;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configurer le handler pour les notifications en background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialiser le service de notifications push (sans enregistrer le device)
    final pushNotificationService = PushNotificationService.instance;
    await pushNotificationService.initialize(isAuthenticated: false);
  } catch (e) {
    print('⚠️ Erreur lors de l\'initialisation de Firebase: $e');
    // L'app continue même si Firebase n'est pas configuré
    // Les erreurs SERVICE_NOT_AVAILABLE sont normales sur certains émulateurs/simulateurs
    if (e.toString().contains('SERVICE_NOT_AVAILABLE')) {
      print('ℹ️ Firebase Messaging non disponible (normal sur certains émulateurs)');
    }
  }
  
  runApp(const SezamApp());
}

/// Application principale SEZAM
class SezamApp extends StatelessWidget {
  const SezamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConsentProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: SezamAppLifecycleListener(
        child: GlobalNotificationListener(
          child: MaterialApp.router(
            title: 'SEZAM - Identité Numérique',
            debugShowCheckedModeBanner: false,
            
            // Thèmes
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            
            // Router
            routerConfig: AppRouter.router,
            
            // Localisation
            locale: const Locale('fr', 'FR'),
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      ),
    );
  }
}
