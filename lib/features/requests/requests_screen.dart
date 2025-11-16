import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';
import 'package:sezam/core/models/consent_model.dart';
import 'package:sezam/core/providers/consent_provider.dart';
import 'package:sezam/core/providers/auth_provider.dart';
import 'package:sezam/features/requests/request_detail_screen.dart';

class RequestsScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  
  const RequestsScreen({super.key, this.onBackToDashboard});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['En attente', 'Refusées'];

  @override
  void initState() {
    super.initState();
    // Reporter le chargement après le premier build pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConsents();
    });
  }

  Future<void> _loadConsents() async {
    if (!mounted) return;
    print('🔄 RequestsScreen: Chargement des consentements...');
    final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
    // Forcer le rechargement pour s'assurer d'avoir les dernières données
    await consentProvider.refresh();
    if (mounted) {
      print('📊 RequestsScreen: ${consentProvider.pendingConsents.length} en attente, ${consentProvider.deniedConsents.length} refusées');
      print('📊 Total: ${consentProvider.consents.length} consentement(s)');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si le profil est validé
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final profile = user?.profile;
    final isProfileVerified = profile != null && profile['verified_at'] != null;

    // Si le profil n'est pas validé, afficher un message de blocage
    if (!isProfileVerified) {
      return Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: _buildAppBar(),
        body: _buildLockedView(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatusTabs(),
          Expanded(
            child: _buildRequestsList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          if (widget.onBackToDashboard != null) {
            widget.onBackToDashboard!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        'Demandes connexions',
        style: AppTypography.headline4.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTabIndex == index;
          final isPendingTab = index == 0;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.spacing3,
                  horizontal: AppSpacing.spacing2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Builder(
                  builder: (context) {
                    final consentProvider = Provider.of<ConsentProvider>(context, listen: true);
                    final count = isPendingTab 
                        ? consentProvider.pendingConsents.length 
                        : consentProvider.deniedConsents.length;
                    
                    return Stack(
                      children: [
                        Center(
                          child: Text(
                            tab,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isSelected ? AppColors.textPrimaryLight : AppColors.gray600,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isPendingTab && count > 0)
                          Positioned(
                            right: 8,
                            top: 4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  count.toString(),
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestsList() {
    return Consumer<ConsentProvider>(
      builder: (context, consentProvider, child) {
        if (consentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (consentProvider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(
                    consentProvider.errorMessage!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  ElevatedButton(
                    onPressed: () => _loadConsents(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final requests = _selectedTabIndex == 0 
            ? consentProvider.pendingConsents 
            : consentProvider.deniedConsents;

        if (requests.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadConsents,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing4,
              vertical: AppSpacing.spacing2,
            ),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final consent = requests[index];
              return _buildRequestCard(consent, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String emptyMessage;
    IconData emptyIcon;
    
    switch (_selectedTabIndex) {
      case 0:
        emptyMessage = 'Aucune demande en attente';
        emptyIcon = Icons.pending_outlined;
        break;
      case 1:
        emptyMessage = 'Aucune demande refusée';
        emptyIcon = Icons.cancel_outlined;
        break;
      default:
        emptyMessage = 'Aucune demande';
        emptyIcon = Icons.inbox_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                emptyIcon,
                size: 48,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing6),
            Text(
              emptyMessage,
              style: AppTypography.headline4.copyWith(
                color: AppColors.gray600,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing2),
            Text(
              'Les organisations vous enverront des demandes d\'accès à vos données',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(ConsentModel consent, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.spacing4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _showRequestDetails(consent);
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.spacing4),
                    child: Row(
                      children: [
                        // Icône de l'organisation
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Icon(
                            _getCategoryIcon(consent.category),
                            color: _getCategoryColor(consent.category),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spacing4),
                        
                        // Informations de la demande
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                consent.partnerName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.spacing1),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.spacing2,
                                      vertical: AppSpacing.spacing1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.gray100,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                    ),
                                    child: Text(
                                      consent.category,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.gray600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.spacing2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.spacing2,
                                      vertical: AppSpacing.spacing1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(_selectedTabIndex).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                    ),
                                    child: Text(
                                      _getStatusText(_selectedTabIndex),
                                      style: AppTypography.caption.copyWith(
                                        color: _getStatusColor(_selectedTabIndex),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.spacing1),
                              Row(
                                children: [
                                  Icon(
                                    Icons.data_usage,
                                    size: 16,
                                    color: AppColors.gray500,
                                  ),
                                  const SizedBox(width: AppSpacing.spacing1),
                                  Text(
                                    '${consent.scopesCount} données demandées',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Flèche de navigation
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.gray400,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return AppColors.warning;
      case 1:
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  String _getStatusText(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'En attente';
      case 1:
        return 'Refusée';
      default:
        return '';
    }
  }

  IconData _getCategoryIcon(String category) {
    final lowerName = category.toLowerCase();
    if (lowerName.contains('banque') || lowerName.contains('bank')) {
      return Icons.account_balance;
    } else if (lowerName.contains('assurance')) {
      return Icons.security;
    } else if (lowerName.contains('mobile') || lowerName.contains('money')) {
      return Icons.phone_android;
    } else {
      return Icons.business;
    }
  }

  Color _getCategoryColor(String category) {
    final lowerName = category.toLowerCase();
    if (lowerName.contains('banque') || lowerName.contains('bank')) {
      return const Color(0xFFFFD700);
    } else if (lowerName.contains('assurance')) {
      return const Color(0xFFE53E3E);
    } else if (lowerName.contains('mobile') || lowerName.contains('money')) {
      return const Color(0xFFFF6B35);
    } else {
      return AppColors.primary;
    }
  }

  void _showRequestDetails(ConsentModel consent) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailScreen(
          consent: consent,
          currentTabIndex: _selectedTabIndex,
        ),
      ),
    );

    // Recharger les consents si une action a été effectuée
    if (result != null) {
      _loadConsents();
    }
  }

  /// Widget pour afficher le message de blocage si le profil n'est pas validé
  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 48,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing6),
            Text(
              'Profil non validé',
              style: AppTypography.headline4.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing3),
            Text(
              'Votre profil doit être validé par un administrateur avant de pouvoir recevoir des demandes de connexion.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing6),
            Container(
              padding: const EdgeInsets.all(AppSpacing.spacing4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.spacing3),
                  Expanded(
                    child: Text(
                      'Une fois votre profil validé, vous pourrez recevoir et gérer les demandes de connexion.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
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

}
