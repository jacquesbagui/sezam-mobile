import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';
import 'package:sezam/core/models/consent_model.dart';
import 'package:sezam/core/providers/consent_provider.dart';
import 'connection_detail_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Actives', 'Expirées', 'Révoquées'];
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConnections();
    });
  }

  Future<void> _loadConnections() async {
    if (!mounted || _hasLoaded) return;
    final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
    // Utiliser loadIfNeeded() pour éviter le rechargement inutile
    await consentProvider.loadIfNeeded();
    if (mounted) {
      setState(() {
        _hasLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Mes Connexions',
          style: AppTypography.headline4.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _buildConnectionsList(),
          ),
        ],
      ),
    );
  }

  /// Barre d'onglets
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTabIndex == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.gray600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Liste des connexions
  Widget _buildConnectionsList() {
    return Selector<ConsentProvider, List<ConsentModel>>(
      selector: (_, provider) => provider.consents,
      builder: (context, allConsents, child) {
        List<ConsentModel> consents;
        
        switch (_selectedTabIndex) {
          case 0:
            // Consents actifs (granted, non expirés, non révoqués, et pas en attente de révocation)
            consents = allConsents.where((c) {
              return c.isGranted && 
                     (c.expiresAt == null || c.expiresAt!.isAfter(DateTime.now())) &&
                     c.revokedAt == null &&
                     !c.statusName.toLowerCase().contains('revocation');
            }).toList();
            break;
          case 1:
            // Consents expirés
            consents = allConsents.where((c) {
              return c.isGranted && 
                     c.expiresAt != null && 
                     c.expiresAt!.isBefore(DateTime.now()) &&
                     c.revokedAt == null &&
                     !c.statusName.toLowerCase().contains('revocation');
            }).toList();
            break;
          case 2:
            // Consents révoqués ou en attente de révocation
            consents = allConsents.where((c) {
              return c.revokedAt != null || 
                     c.statusName.toLowerCase().contains('revocation');
            }).toList();
            break;
          default:
            consents = [];
        }

        if (consents.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refreshConnections,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.spacing4),
            itemCount: consents.length,
            itemBuilder: (context, index) {
              return _buildConnectionCard(consents[index], index);
            },
          ),
        );
      },
    );
  }

  /// État vide
  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_selectedTabIndex) {
      case 0:
        message = 'Aucune connexion active';
        icon = Icons.link_off;
        break;
      case 1:
        message = 'Aucune connexion expirée';
        icon = Icons.schedule;
        break;
      case 2:
        message = 'Aucune connexion révoquée';
        icon = Icons.block;
        break;
      default:
        message = 'Aucune connexion';
        icon = Icons.link_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.gray400,
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            message,
            style: AppTypography.headline4.copyWith(
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
            child: Text(
              'Vos connexions actives avec les organisations apparaîtront ici',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Carte de connexion
  Widget _buildConnectionCard(ConsentModel consent, int index) {
    final isActive = _selectedTabIndex == 0;
    final isExpired = _selectedTabIndex == 1;
    final isRevoked = _selectedTabIndex == 2;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.spacing3),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                child: InkWell(
                  onTap: () => _showConnectionDetails(consent),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.spacing4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConnectionHeader(consent),
                        const SizedBox(height: AppSpacing.spacing3),
                        _buildConnectionInfo(consent, isActive, isExpired, isRevoked),
                        const SizedBox(height: AppSpacing.spacing3),
                        _buildConnectionActions(consent, isActive, isExpired),
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

  /// En-tête de la connexion
  Widget _buildConnectionHeader(ConsentModel consent) {
    return Row(
      children: [
        // Logo de l'organisation
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            Icons.business,
            color: AppColors.gray400,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing3),
        
        // Informations de base
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                consent.partnerName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing1),
              Text(
                consent.category,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        
        // Badge de statut
        _buildStatusBadge(consent, _selectedTabIndex),
      ],
    );
  }

  /// Informations de la connexion
  Widget _buildConnectionInfo(ConsentModel consent, bool isActive, bool isExpired, bool isRevoked) {
    return Column(
      children: [
        if (consent.grantedAt != null) ...[
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.gray500,
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                'Connecté le ${_formatDate(consent.grantedAt!)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing2),
        ],
        if (consent.expiresAt != null) ...[
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: isExpired ? AppColors.error : AppColors.gray500,
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                isExpired
                    ? 'Expiré le ${_formatDate(consent.expiresAt!)}'
                    : 'Expire le ${_formatDate(consent.expiresAt!)}',
                style: AppTypography.bodySmall.copyWith(
                  color: isExpired ? AppColors.error : AppColors.gray600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing2),
        ],
        Row(
          children: [
            Icon(
              Icons.security,
              size: 16,
              color: AppColors.gray500,
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Text(
              '${consent.scopes?.length ?? 0} permission(s) accordée(s)',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Actions de la connexion
  Widget _buildConnectionActions(ConsentModel consent, bool isActive, bool isExpired) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showConnectionDetails(consent),
        icon: const Icon(Icons.visibility, size: 18),
        label: const Text('Voir les détails'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  /// Badge de statut
  Widget _buildStatusBadge(ConsentModel consent, int tabIndex) {
    Color color;
    String text;
    
    // Vérifier si la révocation est en attente
    final isRevocationPending = consent.statusName.toLowerCase().contains('revocation');
    
    if (isRevocationPending) {
      color = AppColors.warning;
      text = 'En attente';
    } else {
      switch (tabIndex) {
        case 0:
          color = AppColors.success;
          text = 'Active';
          break;
        case 1:
          color = AppColors.warning;
          text = 'Expirée';
          break;
        case 2:
          color = AppColors.error;
          text = 'Révoquée';
          break;
        default:
          color = AppColors.gray400;
          text = 'Inconnu';
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing2,
        vertical: AppSpacing.spacing1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Rafraîchir les connexions
  Future<void> _refreshConnections() async {
    final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
    await consentProvider.loadConsents();
  }

  /// Afficher les détails d'une connexion
  void _showConnectionDetails(ConsentModel consent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConnectionDetailScreen(consent: consent),
      ),
    );
  }

  /// Formater une date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
