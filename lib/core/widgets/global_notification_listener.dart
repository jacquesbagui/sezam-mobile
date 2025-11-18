import 'dart:async';
import 'package:flutter/material.dart';
import '../services/app_event_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../router/app_router.dart';

/// Widget global qui écoute les événements de l'app et affiche des notifications
/// Doit être placé au niveau le plus haut de l'app (dans MaterialApp)
class GlobalNotificationListener extends StatefulWidget {
  final Widget child;

  const GlobalNotificationListener({
    super.key,
    required this.child,
  });

  @override
  State<GlobalNotificationListener> createState() => _GlobalNotificationListenerState();
}

class _GlobalNotificationListenerState extends State<GlobalNotificationListener> {
  StreamSubscription<AppEventType>? _eventSubscription;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    
    // Écouter tous les événements de l'app
    _eventSubscription = AppEventService.instance.events.listen((event) {
      print('🔔 GlobalNotificationListener: Événement reçu: $event');
      _handleAppEvent(event);
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  /// Gérer les événements de l'app et afficher des notifications
  void _handleAppEvent(AppEventType event) {
    if (!mounted) return;

    // Utiliser un délai pour s'assurer que l'app est prête
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      _tryShowNotification(event, attempt: 1);
    });
  }

  /// Essayer d'afficher la notification avec retry
  void _tryShowNotification(AppEventType event, {int attempt = 1, int maxAttempts = 3}) {
    if (!mounted) return;
    if (attempt > maxAttempts) {
      print('⚠️ Impossible d\'afficher la notification après $maxAttempts tentatives');
      return;
    }

    // Utiliser le contexte du navigateur pour trouver un Scaffold
    final navigatorContext = AppRouter.rootNavigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) {
      print('⚠️ Contexte du navigateur non disponible (tentative $attempt/$maxAttempts)');
      // Réessayer après un délai
      Future.delayed(const Duration(milliseconds: 500), () {
        _tryShowNotification(event, attempt: attempt + 1, maxAttempts: maxAttempts);
      });
      return;
    }

    // Trouver le ScaffoldMessenger depuis le contexte du navigateur
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(navigatorContext);
    if (scaffoldMessenger == null) {
      print('⚠️ ScaffoldMessenger non disponible (tentative $attempt/$maxAttempts)');
      // Réessayer après un délai
      Future.delayed(const Duration(milliseconds: 500), () {
        _tryShowNotification(event, attempt: attempt + 1, maxAttempts: maxAttempts);
      });
      return;
    }

    // Afficher la notification
    print('✅ Affichage de la notification (tentative $attempt/$maxAttempts)');
    _showNotificationForEvent(event, scaffoldMessenger);
  }

  /// Afficher la notification appropriée selon l'événement
  void _showNotificationForEvent(AppEventType event, ScaffoldMessengerState scaffoldMessenger) {
    try {
      switch (event) {
        case AppEventType.documentVerified:
          _showDocumentVerifiedNotification(scaffoldMessenger);
          break;
        
        case AppEventType.documentRejected:
          _showDocumentRejectedNotification(scaffoldMessenger);
          break;
        
        case AppEventType.documentUploaded:
          _showDocumentUploadedNotification(scaffoldMessenger);
          break;
        
        case AppEventType.profileValidated:
          _showProfileValidatedNotification(scaffoldMessenger);
          break;
        
        case AppEventType.consentRequested:
          _showConsentRequestedNotification(scaffoldMessenger);
          break;
        
        case AppEventType.consentGranted:
          _showConsentGrantedNotification(scaffoldMessenger);
          break;
        
        case AppEventType.consentDenied:
          _showConsentDeniedNotification(scaffoldMessenger);
          break;
        
        case AppEventType.consentRevoked:
          _showConsentRevokedNotification(scaffoldMessenger);
          break;
        
        case AppEventType.userCodeGenerated:
          _showUserCodeGeneratedNotification(scaffoldMessenger);
          break;
        
        case AppEventType.kycCompleted:
          _showKycCompletedNotification(scaffoldMessenger);
          break;
        
        default:
          // Autres événements ne nécessitent pas de notification visuelle
          break;
      }
    } catch (e, stackTrace) {
      print('❌ Erreur lors de l\'affichage de la notification: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Afficher une notification pour un document validé
  void _showDocumentVerifiedNotification(ScaffoldMessengerState scaffoldMessenger) {
    try {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document validé',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Votre document a été validé avec succès',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.spacing4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () {
              // Navigation sera gérée par PushNotificationService
            },
          ),
        ),
      );
    } catch (e) {
      print('❌ Erreur lors de l\'affichage de la notification documentVerified: $e');
    }
  }

  /// Afficher une notification pour un document rejeté
  void _showDocumentRejectedNotification(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Document rejeté. Vérifiez les détails.',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // Navigation sera gérée par PushNotificationService
          },
        ),
      ),
    );
  }

  /// Afficher une notification pour un profil validé
  void _showProfileValidatedNotification(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.verified_user,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Profil validé avec succès !',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  /// Afficher une notification pour un document uploadé
  void _showDocumentUploadedNotification(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.upload_file,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Document uploadé avec succès',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  /// Afficher une notification pour une demande de consentement
  void _showConsentRequestedNotification(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Nouvelle demande de consentement',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // Navigation sera gérée par PushNotificationService
          },
        ),
      ),
    );
  }

  /// Afficher une notification pour un consentement accordé
  void _showConsentGrantedNotification(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Consentement accordé',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  /// Afficher une notification pour un consentement refusé
  void _showConsentDeniedNotification(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.cancel_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Consentement refusé',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  /// Afficher une notification pour un consentement révoqué
  void _showConsentRevokedNotification(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.block,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Connexion révoquée',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // Navigation sera gérée par PushNotificationService
          },
        ),
      ),
    );
  }

  /// Afficher une notification pour un code utilisateur généré
  void _showUserCodeGeneratedNotification(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.vpn_key,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Code utilisateur généré avec succès !',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  /// Afficher une notification pour un KYC complété
  void _showKycCompletedNotification(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.verified,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Profil complété avec succès !',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: widget.child,
    );
  }
}

