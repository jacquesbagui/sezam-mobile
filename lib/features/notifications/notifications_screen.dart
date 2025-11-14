import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/services/consent_service.dart';
import '../requests/request_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const NotificationsScreen({super.key, this.onBackToDashboard});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Toutes', 'Non lues'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.loadNotifications(unreadOnly: false);
  }

  Future<void> _refreshNotifications() async {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.loadNotifications(unreadOnly: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTypography.headline4.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.spacing4),
                child: _buildStatusTabs(notificationProvider),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  child: _buildNotificationsList(notificationProvider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusTabs(NotificationProvider notificationProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.gray700 : AppColors.gray200,
          width: 1,
        ),
      ),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTabIndex == index;
          final isUnreadTab = tab == 'Non lues';
          final unreadCount = notificationProvider.unreadCount;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing3),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUnreadTab ? Icons.mark_email_unread : Icons.notifications,
                      size: 18,
                      color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                    const SizedBox(width: AppSpacing.spacing2),
                    Text(
                      tab,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (isUnreadTab && unreadCount > 0) ...[
                      const SizedBox(width: AppSpacing.spacing2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: AppTypography.bodyXSmall.copyWith(
                            color: isSelected ? AppColors.error : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationsList(NotificationProvider notificationProvider) {
    final notifications = _selectedTabIndex == 0
        ? notificationProvider.notifications
        : notificationProvider.unreadNotifications;

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification, index);
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEmpty = _selectedTabIndex == 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEmpty ? Icons.notifications_none : Icons.mark_email_read,
              size: 70,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.spacing4),
            Text(
              isEmpty ? 'Aucune notification' : 'Aucune notification non lue',
              style: AppTypography.headline4.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing2),
            Text(
              isEmpty
                  ? 'Vous n\'avez pas encore de notifications.\nElles apparaîtront ici quand vous en recevrez.'
                  : 'Toutes vos notifications ont été lues.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uiType = notification.uiType;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: notification.isRead ? (isDark ? AppColors.gray700 : AppColors.gray200) : AppColors.primary.withValues(alpha: 0.3),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getColorForType(uiType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        _getIconForType(uiType),
                        color: _getColorForType(uiType),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spacing3),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: AppTypography.bodyLarge.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacing3),
                Text(
                  notification.body,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.spacing3),
                Row(
                  children: [
                    Text(
                      _formatDate(notification.createdAt),
                      style: AppTypography.bodyXSmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacing2,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getColorForType(uiType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        uiType.displayName,
                        style: AppTypography.bodyXSmall.copyWith(
                          color: _getColorForType(uiType),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.request:
        return Icons.notifications_outlined;
      case NotificationType.connection:
        return Icons.link;
      case NotificationType.security:
        return Icons.security;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.reminder:
        return Icons.schedule;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.request:
        return const Color(0xFF3B82F6);
      case NotificationType.connection:
        return const Color(0xFF10B981);
      case NotificationType.security:
        return const Color(0xFFEF4444);
      case NotificationType.system:
        return const Color(0xFF6B7280);
      case NotificationType.reminder:
        return const Color(0xFFF59E0B);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Marquer comme lu
    if (!notification.isRead) {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.markAsRead(notification.id);
    }

    // Naviguer selon le type de notification
    await _navigateFromNotification(notification);
  }

  /// Naviguer depuis une notification
  Future<void> _navigateFromNotification(NotificationModel notification) async {
    final type = notification.type;
    final metadata = notification.metadata ?? {};
    final screen = metadata['screen'] as String?;
    final consentId = metadata['consent_id'] as String? ?? metadata['consentId'] as String?;

    try {
      // Priorité 1: Utiliser le screen fourni dans les métadonnées
      if (screen != null && screen.isNotEmpty) {
        print('📍 Navigation vers: $screen');
        if (screen.startsWith('/')) {
          context.go(screen);
        } else {
          context.push('/$screen');
        }
        return;
      }

      // Priorité 2: Navigation selon le type
      switch (type.toLowerCase()) {
        case 'profile_validated':
          print('📍 Navigation vers profil');
          context.go('/profile');
          break;

        case 'consent_request':
        case 'consent_requested':
          if (consentId != null) {
            print('📍 Navigation vers consent: $consentId');
            await _navigateToConsent(consentId);
          } else {
            print('📍 Navigation vers requests');
            context.go('/dashboard');
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              context.push('/requests');
            }
          }
          break;

        case 'consent_granted':
        case 'consent_denied':
        case 'consent_revoked':
          print('📍 Navigation vers requests');
          context.go('/dashboard');
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            context.push('/requests');
          }
          break;

        case 'document_verified':
        case 'document_rejected':
          print('📍 Navigation vers documents');
          context.go('/dashboard');
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            context.push('/documents');
          }
          break;

        default:
          // Par défaut, rester sur la page des notifications
          print('📍 Notification de type: $type - pas de navigation spécifique');
          break;
      }
    } catch (e) {
      print('❌ Erreur lors de la navigation depuis la notification: $e');
    }
  }

  /// Naviguer vers le détail d'un consentement
  Future<void> _navigateToConsent(String consentId) async {
    try {
      // Charger le consentement depuis l'API
      final consent = await ConsentService().getConsentById(consentId);
      if (consent == null) {
        // À défaut, ouvrir la liste des demandes
        context.go('/dashboard');
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          context.push('/requests');
        }
        return;
      }

      // Naviguer vers le dashboard d'abord, puis vers le détail
      context.go('/dashboard');
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestDetailScreen(
              consent: consent,
              currentTabIndex: 0,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur de navigation vers le consentement: $e');
      // Fallback: ouvrir la liste des demandes
      context.go('/dashboard');
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        context.push('/requests');
      }
    }
  }
}

