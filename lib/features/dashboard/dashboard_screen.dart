import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sezam_card.dart';
import '../../core/navigation/sezam_navigation.dart';

/// Écran principal (Dashboard) de l'application SEZAM
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardHomeScreen(),
    const DocumentsScreen(),
    const RequestsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SezamBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

/// Écran d'accueil du dashboard
class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: SezamAppBar(
        title: 'Accueil',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Naviguer vers les notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec informations utilisateur
            _buildUserHeader(context, isDark),
            
            const SizedBox(height: AppSpacing.spacing6),
            
            // Statistiques
            _buildStatsSection(context, isDark),
            
            const SizedBox(height: AppSpacing.spacing6),
            
            // Actions rapides
            _buildQuickActionsSection(context, isDark),
            
            const SizedBox(height: AppSpacing.spacing6),
            
            // Activité récente
            _buildRecentActivitySection(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, bool isDark) {
    return SezamCard(
      child: Row(
        children: [
          // Avatar utilisateur
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.textPrimaryDark,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing4),
          
          // Informations utilisateur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, Jean Dupont',
                  style: AppTypography.headline4.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing1),
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.spacing1),
                    Text(
                      'Compte vérifié',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Bouton profil
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Naviguer vers les paramètres
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques',
          style: AppTypography.headline4.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Documents',
                '12',
                Icons.description,
                AppColors.primary,
                isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing3),
            Expanded(
              child: _buildStatCard(
                context,
                'Connexions',
                '5',
                Icons.link,
                AppColors.secondary,
                isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing3),
            Expanded(
              child: _buildStatCard(
                context,
                'Alertes',
                '2',
                Icons.warning,
                AppColors.warning,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return SezamCard(
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppSpacing.spacing2),
          Text(
            value,
            style: AppTypography.headline3.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing1),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: AppTypography.headline4.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.spacing3,
          mainAxisSpacing: AppSpacing.spacing3,
          childAspectRatio: 1.2,
          children: [
            _buildQuickActionCard(
              context,
              'Ajouter un document',
              Icons.add_circle_outline,
              AppColors.primary,
              () {
                // TODO: Naviguer vers l'ajout de document
              },
            ),
            _buildQuickActionCard(
              context,
              'Scanner QR Code',
              Icons.qr_code_scanner,
              AppColors.secondary,
              () {
                // TODO: Ouvrir le scanner QR
              },
            ),
            _buildQuickActionCard(
              context,
              'Mes connexions',
              Icons.link,
              AppColors.success,
              () {
                // TODO: Naviguer vers les connexions
              },
            ),
            _buildQuickActionCard(
              context,
              'Demandes en attente',
              Icons.pending_actions,
              AppColors.warning,
              () {
                // TODO: Naviguer vers les demandes
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SezamCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.spacing2),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activité récente',
              style: AppTypography.headline4.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Voir toute l'activité
              },
              child: Text(
                'Voir tout',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing4),
        SezamCard(
          child: Column(
            children: [
              _buildActivityItem(
                context,
                'Document CNI ajouté',
                'Il y a 2 heures',
                Icons.description,
                AppColors.success,
              ),
              const Divider(),
              _buildActivityItem(
                context,
                'Connexion à Orange Money',
                'Il y a 1 jour',
                Icons.link,
                AppColors.primary,
              ),
              const Divider(),
              _buildActivityItem(
                context,
                'Demande de connexion',
                'Il y a 3 jours',
                Icons.notifications,
                AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing2),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.spacing3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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

// Écrans temporaires pour les autres onglets
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SezamAppBar(title: 'Documents'),
      body: const Center(
        child: Text('Écran Documents - À implémenter'),
      ),
    );
  }
}

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SezamAppBar(title: 'Demandes'),
      body: const Center(
        child: Text('Écran Demandes - À implémenter'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SezamAppBar(title: 'Profil'),
      body: const Center(
        child: Text('Écran Profil - À implémenter'),
      ),
    );
  }
}
