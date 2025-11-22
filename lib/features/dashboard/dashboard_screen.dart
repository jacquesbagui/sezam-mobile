import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';
import 'package:sezam/core/navigation/sezam_navigation.dart';
import 'package:sezam/core/providers/auth_provider.dart';
import 'package:sezam/core/providers/consent_provider.dart';
import 'package:sezam/core/providers/profile_provider.dart';
import 'package:sezam/core/providers/notification_provider.dart';
import 'package:sezam/features/documents/documents_screen.dart';
import 'package:sezam/features/requests/requests_screen.dart';
import 'package:sezam/features/profile/profile_screen.dart';
import 'package:sezam/features/connections/connections_screen.dart';
import 'package:sezam/features/notifications/notifications_screen.dart';
import 'package:sezam/core/models/user_model.dart';
import 'package:sezam/core/models/consent_model.dart';
import 'package:sezam/core/services/profile_service.dart';
import 'package:sezam/core/services/app_event_service.dart';
import 'package:sezam/core/utils/navigation_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            Expanded(
              child: RepaintBoundary(
                child: _buildCurrentScreen(),
              ),
            ),
            RepaintBoundary(
              child: SezamBottomNavigation(
                currentIndex: _currentIndex,
                onTap: (index) {
                  // Feedback haptique pour une meilleure réactivité perçue
                  HapticFeedback.selectionClick();
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construire l'écran actuel (optimisation: ne construit que l'écran visible)
  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardHomeScreen(
          onNavigateToDocuments: () => setState(() => _currentIndex = 1),
          onNavigateToRequests: () => setState(() => _currentIndex = 2),
          onShowConnections: _showConnectionsInfo,
          onShowAlerts: _showAlertsInfo,
          onNavigateToNotifications: () => setState(() => _currentIndex = 3),
          onNavigateToPartners: () => context.go('/partners'),
        );
      case 1:
        return DocumentsScreen(onBackToDashboard: () => setState(() => _currentIndex = 0));
      case 2:
        return RequestsScreen(onBackToDashboard: () => setState(() => _currentIndex = 0));
      case 3:
        return NotificationsScreen(onBackToDashboard: () => setState(() => _currentIndex = 0));
      case 4:
        return ProfileScreen(onBackToDashboard: () => setState(() => _currentIndex = 0));
      default:
        return DashboardHomeScreen(
          onNavigateToDocuments: () => setState(() => _currentIndex = 1),
          onNavigateToRequests: () => setState(() => _currentIndex = 2),
          onShowConnections: _showConnectionsInfo,
          onShowAlerts: _showAlertsInfo,
          onNavigateToNotifications: () => setState(() => _currentIndex = 3),
          onNavigateToPartners: () => context.go('/partners'),
        );
    }
  }

  /// Afficher les informations de connexions
  void _showConnectionsInfo() {
    Navigator.push(
      context,
      NavigationHelper.slideRoute(
        const ConnectionsScreen(),
      ),
    );
  }

  /// Afficher les informations d'alertes
  void _showAlertsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mes Alertes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alertes actives :'),
            const SizedBox(height: AppSpacing.spacing3),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document expirant',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Votre CNI expire dans 30 jours',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing2),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouvelle demande',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Orange Money demande l\'accès à vos données',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

}

/// Écran d'accueil du dashboard
class DashboardHomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToDocuments;
  final VoidCallback onNavigateToRequests;
  final VoidCallback onShowConnections;
  final VoidCallback onShowAlerts;
  final VoidCallback onNavigateToNotifications;
  final VoidCallback onNavigateToPartners;
  
  const DashboardHomeScreen({
    super.key,
    required this.onNavigateToDocuments,
    required this.onNavigateToRequests,
    required this.onShowConnections,
    required this.onShowAlerts,
    required this.onNavigateToNotifications,
    required this.onNavigateToPartners,
  });

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  bool _isUserCodeVisible = false;
  bool _hasLoadedConsents = false;
  
  @override
  void initState() {
    super.initState();
    // Charger les données au premier affichage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
        
        // Rafraîchir l'utilisateur pour avoir les données à jour (notamment verified_at)
        authProvider.refreshUser().catchError((e) => print('Erreur refreshUser: $e'));
        
        // Charger le statut du profil seulement si nécessaire (cache invalide)
        profileProvider.loadIfNeeded().catchError((e) => print('Erreur loadProfileStatus: $e'));
        
        // Charger les consents seulement si nécessaire (cache invalide)
        if (!_hasLoadedConsents) {
          _hasLoadedConsents = true;
          consentProvider.loadIfNeeded();
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    // Rediriger vers l'authentification si l'utilisateur n'est pas connecté
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/auth');
        }
      });
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, user),
          const SizedBox(height: AppSpacing.spacing6),
          _buildProfileStatusBanner(context, user),
          const SizedBox(height: AppSpacing.spacing6),
          _buildQuickActions(context),
          const SizedBox(height: AppSpacing.spacing6),
          _buildRecentConnections(context),
          const SizedBox(height: AppSpacing.spacing16),
        ],
      ),
    );
  }

  /// Header avec informations utilisateur et statistiques
  Widget _buildHeader(BuildContext context, UserModel user) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radius3xl),
          bottomRight: Radius.circular(AppSpacing.radius3xl),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.spacing6,
        left: AppSpacing.spacing6,
        right: AppSpacing.spacing6,
        bottom: AppSpacing.spacing6,
      ),
      child: Column(
        children: [
          _buildProfileSection(context, user),
          const SizedBox(height: AppSpacing.spacing8),
          _buildStatsCards(context, user),
        ],
      ),
    );
  }

  /// Section profil avec photo, nom et badge vérifié
  Widget _buildProfileSection(BuildContext context, UserModel user) {
    final profile = user.profile;
    final isProfileVerified = profile != null && profile['verified_at'] != null;
    
    return Row(
      children: [
        // Photo de profil
        Builder(
          builder: (context) {
            // Récupérer l'URL de la photo depuis profile.profile_photo ou profileImage
            final profilePhotoUrl = user.profile?['profile_photo'] as String? ?? user.profileImage;
            final hasPhoto = profilePhotoUrl != null && profilePhotoUrl.isNotEmpty;
            
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: hasPhoto
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profilePhotoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          print('❌ Erreur chargement image dashboard: $error, URL: $url');
                          return Container(
                            color: AppColors.primary,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
            );
          },
        ),
        const SizedBox(width: AppSpacing.spacing4),
        
        // Nom et statut
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    user.fullName,
                    style: AppTypography.headline4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isProfileVerified) ...[
                    const SizedBox(width: AppSpacing.spacing2),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.spacing1),
              Text(
                isProfileVerified ? 'Profil validé' : 'En attente de validation',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        
        // Boutons d'action
        Row(
          children: [
            Selector<NotificationProvider, int>(
              selector: (_, provider) => provider.unreadCount,
              builder: (context, unreadCount, child) {
                return _buildIconButton(
                  icon: Icons.notifications_outlined,
                  onTap: widget.onNavigateToNotifications,
                  hasNotification: unreadCount > 0,
                  notificationCount: unreadCount,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Bouton icône avec notification badge optionnel
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasNotification = false,
    int notificationCount = 0,
  }) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        if (hasNotification && notificationCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              child: Text(
                notificationCount > 99 ? '99+' : notificationCount.toString(),
                style: AppTypography.bodyXSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Bannière d'information sur le statut du profil
  Widget _buildProfileStatusBanner(BuildContext context, UserModel user) {
    return RepaintBoundary(
      child: Selector<ProfileProvider, Map<String, dynamic>>(
        selector: (_, provider) => {
          'isLoading': provider.isLoading,
          'isComplete': provider.isComplete,
          'completionPercentage': provider.completionPercentage,
          'missingFields': provider.missingFields,
          'profileStatus': provider.profileStatus,
        },
        builder: (context, state, child) {
          final profile = user.profile;
          final isProfileVerified = profile != null && profile['verified_at'] != null;
          final hasUserCode = user.userCode != null;
          final isKycComplete = state['isComplete'] as bool;
          final completionPercentage = state['completionPercentage'] as int;
          final missingFields = state['missingFields'] as List<String>;
          final profileStatus = state['profileStatus'] as dynamic;
          final isLoading = state['isLoading'] as bool;

        print('🔍 _buildProfileStatusBanner:');
        print('   - isKycComplete: $isKycComplete');
        print('   - completionPercentage: $completionPercentage');
        print('   - missingFields: $missingFields');
        print('   - profileStatus: $profileStatus');
        print('   - isProfileVerified: $isProfileVerified');
        print('   - hasUserCode: $hasUserCode');
        
        // Si le statut est en cours de chargement, afficher un message générique
        if (isLoading || profileStatus == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing6),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Chargement du profil...',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vérification de votre profil en cours',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Si tout est OK (100% complété ET vérifié ET code généré), ne rien afficher
        // IMPORTANT: Vérifier le pourcentage en premier, car isKycComplete peut être true même à < 100%
        if (completionPercentage >= 100 && isProfileVerified && hasUserCode) {
          return const SizedBox.shrink();
        }
        
        // Déterminer le message et l'action selon le statut
        String title;
        String message;
        String actionLabel;
        VoidCallback? onAction;
        IconData icon;
        Color accentColor;
        
        // Afficher la bannière si le profil n'est pas complet (< 100%)
        // Priorité 1: Pourcentage < 100%
        if (completionPercentage < 100) {
          title = 'Profil incomplet';
          if (completionPercentage > 0) {
            message = 'Votre profil est complété à $completionPercentage%';
            if (missingFields.isNotEmpty) {
              message += ' - ${missingFields.length} champ${missingFields.length > 1 ? 's' : ''} manquant${missingFields.length > 1 ? 's' : ''}';
            }
          } else {
            message = missingFields.isNotEmpty
                ? '${missingFields.length} champ${missingFields.length > 1 ? 's' : ''} manquant${missingFields.length > 1 ? 's' : ''}'
                : 'Finalisez votre profil';
          }
          actionLabel = 'Compléter';
          onAction = () => context.go('/profile');
          icon = Icons.person_add_outlined;
          accentColor = AppColors.warning;
        } else if (!isProfileVerified) {
          title = 'En attente de validation';
          message = 'Validation en cours par un administrateur';
          actionLabel = 'Voir profil';
          onAction = () => context.go('/profile');
          icon = Icons.pending_outlined;
          accentColor = AppColors.warning;
        } else if (!hasUserCode) {
          title = 'Profil validé';
          message = 'Générez votre code utilisateur';
          actionLabel = 'Générer';
          onAction = () => _generateUserCode(context);
          icon = Icons.vpn_key_outlined;
          accentColor = AppColors.success;
        } else {
          return const SizedBox.shrink();
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing6),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.spacing4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icône
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing3),
                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing2),
                // Bouton
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing3,
                      vertical: AppSpacing.spacing1,
                    ),
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  /// Widget pour afficher le code utilisateur (masqué/dévoilé) ou bouton de génération
  Widget _buildStatsCards(BuildContext context, UserModel user) {
    final profile = user.profile;
    final isProfileVerified = profile != null && profile['verified_at'] != null;
    final hasUserCode = user.userCode != null;

    // Si le profil n'est pas validé, ne rien afficher
    if (!isProfileVerified) {
      return const SizedBox.shrink();
    }

    // Si le profil est validé mais pas de user_code, afficher un bouton pour générer
    if (!hasUserCode) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.spacing4),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.vpn_key_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.spacing3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Générer mon Code Utilisateur',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing3),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGeneratingCode ? null : () => _generateUserCode(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: _isGeneratingCode
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Générer mon code'),
              ),
            ),
          ],
        ),
      );
    }

    // Si le user_code existe, afficher le code normalement
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.spacing5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.spacing2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing3),
              Expanded(
                child: Text(
                  'Mon Code Utilisateur',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Badge de statut
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing2,
                  vertical: AppSpacing.spacing1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Actif',
                      style: AppTypography.bodyXSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          // Code utilisateur avec bouton de copie
          InkWell(
            onTap: () {
              setState(() {
                _isUserCodeVisible = !_isUserCodeVisible;
              });
              HapticFeedback.lightImpact();
              if (_isUserCodeVisible && user.userCode != null) {
                Clipboard.setData(ClipboardData(text: user.userCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: AppSpacing.spacing2),
                        Text('Code copié dans le presse-papiers'),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: Text(
                            _isUserCodeVisible
                                ? (user.userCode ?? 'N/A')
                                : '••••••••',
                            key: ValueKey(_isUserCodeVisible),
                            style: AppTypography.headline2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 18,
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.spacing1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      _isUserCodeVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isGeneratingCode = false;

  Future<void> _generateUserCode(BuildContext context) async {
    setState(() {
      _isGeneratingCode = true;
    });

    try {
      final profileService = ProfileService();
      await profileService.generateUserCode();
      
      // Émettre un événement pour déclencher le rafraîchissement
      AppEventService.instance.emit(AppEventType.userCodeGenerated);
      
      // Recharger l'utilisateur
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUser();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code utilisateur généré avec succès !'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingCode = false;
        });
      }
    }
  }

  /// Section Actions rapides
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: AppTypography.headline4.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ), 
          const SizedBox(height: AppSpacing.spacing4),
          Builder(
            builder: (context) {
              // Utiliser MediaQuery pour obtenir la largeur réelle de l'écran
              final screenWidth = MediaQuery.of(context).size.width;
              // Pour les très petits écrans (< 320px), utiliser une liste verticale
              // Sinon, utiliser le grid même sur les petits écrans
              if (screenWidth < 320) {
                return Column(
                  children: [
                    _buildActionCard(
                      icon: Icons.upload_file_outlined,
                      iconColor: AppColors.primary,
                      iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                      label: 'Ajouter un document',
                      onTap: widget.onNavigateToDocuments,
                    ),
                    const SizedBox(height: AppSpacing.spacing3),
                    Selector<ConsentProvider, int>(
                      selector: (_, provider) => provider.pendingConsents.length,
                      builder: (context, pendingCount, child) {
                        return _buildActionCard(
                          icon: Icons.schedule_outlined,
                          iconColor: AppColors.warning,
                          iconBgColor: AppColors.warning.withValues(alpha: 0.1),
                          label: 'Demandes en attente',
                          badge: pendingCount > 0 ? pendingCount : null,
                          onTap: widget.onNavigateToRequests,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.spacing3),
                    _buildActionCard(
                      icon: Icons.account_tree_outlined,
                      iconColor: AppColors.secondary,
                      iconBgColor: AppColors.secondary.withValues(alpha: 0.1),
                      label: 'Mes connexions',
                      onTap: widget.onShowConnections,
                    ),
                    const SizedBox(height: AppSpacing.spacing3),
                    _buildActionCard(
                      icon: Icons.business_outlined,
                      iconColor: const Color(0xFF6366F1), // Indigo
                      iconBgColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      label: 'Partenaires',
                      onTap: widget.onNavigateToPartners,
                    ),
                  ],
                );
              }
              
              // Pour tous les autres écrans, utiliser une grille à 2 colonnes
              return GridView.count(
                padding: EdgeInsets.zero,
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.spacing2,
                crossAxisSpacing: AppSpacing.spacing2,
                childAspectRatio: 1.5,
                children: [
                  _buildActionCard(
                    icon: Icons.upload_file_outlined,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                    label: 'Ajouter un\ndocument',
                    onTap: widget.onNavigateToDocuments,
                  ),
                  Selector<ConsentProvider, int>(
                    selector: (_, provider) => provider.pendingConsents.length,
                    builder: (context, pendingCount, child) {
                      return _buildActionCard(
                        icon: Icons.schedule_outlined,
                        iconColor: AppColors.warning,
                        iconBgColor: AppColors.warning.withValues(alpha: 0.1),
                        label: 'Demandes en\nattente',
                        badge: pendingCount > 0 ? pendingCount : null,
                        onTap: widget.onNavigateToRequests,
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.account_tree_outlined,
                    iconColor: AppColors.secondary,
                    iconBgColor: AppColors.secondary.withValues(alpha: 0.1),
                    label: 'Mes\nconnexions',
                    onTap: widget.onShowConnections,
                  ),
                  _buildActionCard(
                    icon: Icons.business_outlined,
                    iconColor: const Color(0xFF6366F1), // Indigo
                    iconBgColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    label: 'Partenaires',
                    onTap: widget.onNavigateToPartners,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Carte d'action rapide
  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    int? badge,
    required VoidCallback onTap,
  }) {
    return _ActionCardStateful(
      icon: icon,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
      label: label,
      badge: badge,
      onTap: onTap,
    );
  }

  /// Section Connexions récentes (basé sur les consents)
  Widget _buildRecentConnections(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connexions récentes',
            style: AppTypography.headline4.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          
          // Charger et afficher les consents
          Selector<ConsentProvider, Map<String, dynamic>>(
            selector: (_, provider) => {
              'isLoading': provider.isLoading,
              'errorMessage': provider.errorMessage,
              'activeConsentsCount': provider.activeConsents.length,
            },
            builder: (context, state, child) {
              if (state['isLoading'] as bool) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.spacing8),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state['errorMessage'] != null) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.spacing4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.spacing3),
                      Expanded(
                        child: Text(
                          state['errorMessage'] as String,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
              final recentConsents = consentProvider.activeConsents.take(5).toList();

              if (recentConsents.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.spacing4),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.gray200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.gray500,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.spacing3),
                      Expanded(
                        child: Text(
                          'Aucune connexion récente',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Afficher la liste des connexions récentes avec ListView.builder pour le lazy loading
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentConsents.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.spacing3),
                    child: _buildConnectionItem(recentConsents[index]),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Widget pour afficher un item de connexion
  Widget _buildConnectionItem(ConsentModel consent) {
    final isGranted = consent.isGranted;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isGranted 
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              isGranted ? Icons.check_circle : Icons.pending,
              color: isGranted ? AppColors.success : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consent.partnerName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing1),
                Text(
                  _formatConsentDate(consent.grantedAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing2,
              vertical: AppSpacing.spacing1,
            ),
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              isGranted ? 'Actif' : 'En attente',
              style: AppTypography.caption.copyWith(
                color: isGranted ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formater la date du consentement
  String _formatConsentDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Item d'activité (ancienne méthode, remplacée par _buildConnectionItem)
  @Deprecated('Use _buildConnectionItem instead')
  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.gray200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing1),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing1),
                Text(
                  time,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget stateful pour gérer l'animation de la carte
class _ActionCardStateful extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final int? badge;
  final VoidCallback onTap;

  const _ActionCardStateful({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  State<_ActionCardStateful> createState() => _ActionCardStatefulState();
}

class _ActionCardStatefulState extends State<_ActionCardStateful>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse().then((_) {
      widget.onTap();
    });
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing3,
              vertical: AppSpacing.spacing2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.gray200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.05,
                  ),
                  offset: const Offset(0, 2),
                  blurRadius: _isPressed ? 4 : 8,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: widget.iconColor.withValues(alpha: 0.08),
                  offset: const Offset(0, 0),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.iconBgColor,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 18,
                      ),
                    ),
                    if (widget.badge != null && widget.badge! > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceLight,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.badge! > 99 ? '99+' : widget.badge.toString(),
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacing1),
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}