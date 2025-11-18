import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';
import 'package:sezam/core/models/consent_model.dart';
import 'package:sezam/core/models/scope_model.dart';
import 'package:sezam/core/providers/consent_provider.dart';
import 'package:sezam/core/services/app_event_service.dart';

class ConnectionDetailScreen extends StatelessWidget {
  final ConsentModel consent;

  const ConnectionDetailScreen({
    super.key,
    required this.consent,
  });

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
            // Navigation sécurisée : vérifier si on peut pop, sinon naviguer vers /connections
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/connections');
            }
          },
        ),
        title: Text(
          'Détails de la connexion',
          style: AppTypography.headline4.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.spacing6),
            _buildOrganizationInfo(),
            const SizedBox(height: AppSpacing.spacing6),
            _buildDatesSection(),
            const SizedBox(height: AppSpacing.spacing6),
            _buildPurposeSection(),
            const SizedBox(height: AppSpacing.spacing6),
            _buildScopesSection(context),
            const SizedBox(height: AppSpacing.spacing6),
            if (_isActive()) _buildActionsSection(context),
          ],
        ),
      ),
    );
  }

  /// En-tête avec le statut
  Widget _buildHeader() {
    final Color statusColor;
    final String statusText;

    if (consent.revokedAt != null) {
      statusColor = AppColors.error;
      statusText = 'Révoquée';
    } else if (consent.expiresAt != null && consent.expiresAt!.isBefore(DateTime.now())) {
      statusColor = AppColors.warning;
      statusText = 'Expirée';
    } else {
      statusColor = AppColors.success;
      statusText = 'Active';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.1),
            statusColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.business,
              color: statusColor,
              size: 35,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consent.partnerName,
                  style: AppTypography.headline3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.spacing2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing3,
                    vertical: AppSpacing.spacing2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing2),
                      Text(
                        statusText,
                        style: AppTypography.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Informations de l'organisation
  Widget _buildOrganizationInfo() {
    return _buildSection(
      title: 'Informations',
      children: [
        _buildInfoRow('Type de service', consent.category),
        if (consent.purpose != null) _buildInfoRow('Objectif', consent.purpose!),
      ],
    );
  }

  /// Section dates
  Widget _buildDatesSection() {
    return _buildSection(
      title: 'Dates importantes',
      children: [
        if (consent.grantedAt != null)
          _buildInfoRow('Connecté le', _formatDateTime(consent.grantedAt!)),
        if (consent.expiresAt != null)
          _buildInfoRow(
            'Expire le',
            _formatDateTime(consent.expiresAt!),
            warning: consent.expiresAt!.isBefore(DateTime.now()),
          ),
        if (consent.revokedAt != null)
          _buildInfoRow('Révoqué le', _formatDateTime(consent.revokedAt!)),
        _buildInfoRow('Créé le', _formatDateTime(consent.createdAt)),
      ],
    );
  }

  /// Section objectif
  Widget _buildPurposeSection() {
    if (consent.purpose == null) return const SizedBox.shrink();

    return             _buildSection(
              title: 'Objectif de la connexion',
              children: [
        Text(
          consent.purpose!,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Section des scopes
  Widget _buildScopesSection(BuildContext context) {
    if (consent.scopes == null || consent.scopes!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Séparer les scopes actifs et désactivés
    final activeScopes = consent.scopes!.where((scope) => scope.granted).toList();
    final inactiveScopes = consent.scopes!.where((scope) => !scope.granted).toList();

    return Column(
      children: [
        // Scopes actifs
        if (activeScopes.isNotEmpty)
          _buildSection(
            title: 'Données partagées (${activeScopes.length})',
            children: [
              ...activeScopes.map((scope) => _buildScopeItem(context, scope, isActive: true)),
            ],
          ),
        // Scopes désactivés
        if (inactiveScopes.isNotEmpty && _isActive()) ...[
          const SizedBox(height: AppSpacing.spacing6),
          _buildSection(
            title: 'Données désactivées (${inactiveScopes.length})',
            children: [
              ...inactiveScopes.map((scope) => _buildScopeItem(context, scope, isActive: false)),
            ],
          ),
        ],
      ],
    );
  }

  /// Item de scope
  Widget _buildScopeItem(BuildContext context, dynamic scope, {required bool isActive}) {
    // Déterminer l'icône selon le type de scope
    IconData icon = Icons.security;
    Color iconColor = AppColors.primary;
    
    // Utiliser la couleur basée sur la sensibilité du scope
    if (scope is ScopeModel && scope.isSensitive) {
      iconColor = AppColors.warning;
    } else if (scope is Map && (scope['is_sensitive'] == true)) {
      iconColor = AppColors.warning;
    }
    
    // Déterminer l'icône selon le type de scope
    if (scope.name.contains('email') || scope.name.contains('phone')) {
      icon = Icons.contact_mail;
    } else if (scope.name.contains('document') || scope.name.contains('identity')) {
      icon = Icons.badge;
    } else if (scope.name.contains('ademe') || scope.name.contains('financial')) {
      icon = Icons.account_balance;
    } else if (scope.name.contains('profile')) {
      icon = Icons.person;
    }
    
    // Ajuster les couleurs si le scope est désactivé
    if (!isActive) {
      iconColor = AppColors.gray400;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing3),
      padding: const EdgeInsets.all(AppSpacing.spacing3),
      decoration: BoxDecoration(
        color: isActive 
            ? iconColor.withValues(alpha: 0.05)
            : AppColors.gray100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isActive 
              ? iconColor.withValues(alpha: 0.2)
              : AppColors.gray300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive 
                  ? iconColor.withValues(alpha: 0.1)
                  : AppColors.gray200,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scope.displayName ?? scope.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isActive 
                              ? AppColors.textPrimaryLight
                              : AppColors.gray600,
                          decoration: isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    if (_isScopeRequired(scope))
                      Container(
                        margin: const EdgeInsets.only(left: AppSpacing.spacing2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Requis',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (!isActive && !_isScopeRequired(scope))
                      Container(
                        margin: const EdgeInsets.only(left: AppSpacing.spacing2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray300,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          'Désactivé',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.gray600,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (scope.description != null && scope.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    scope.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isActive ? AppColors.gray600 : AppColors.gray500,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (_isActive())
            isActive
                ? IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: _isScopeRequired(scope) ? AppColors.gray400 : AppColors.error,
                      size: 22,
                    ),
                    onPressed: _isScopeRequired(scope) 
                        ? null 
                        : () => _showRemoveScopeDialog(context, scope),
                    tooltip: _isScopeRequired(scope) 
                        ? 'Ce scope est requis et ne peut pas être désactivé' 
                        : 'Désactiver ce scope',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 22,
                    ),
                    onPressed: () => _showEnableScopeDialog(context, scope),
                    tooltip: 'Réactiver ce scope',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
          else
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 22,
            ),
        ],
      ),
    );
  }

  /// Afficher le dialog de confirmation pour réactiver un scope
  void _showEnableScopeDialog(BuildContext context, dynamic scope) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Réactiver ce scope',
                style: AppTypography.headline4.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir réactiver l\'accès à :',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.spacing3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.success, size: 20),
                  const SizedBox(width: AppSpacing.spacing2),
                  Expanded(
                    child: Text(
                      scope.displayName ?? scope.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spacing3),
            Text(
              'Le partenaire ${consent.partnerName} aura à nouveau accès à ces données.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              try {
                final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
                await consentProvider.enableScope(consent.id, scope.id);
                
                // Émettre un événement pour déclencher le rafraîchissement
                AppEventService.instance.emit(AppEventType.consentGranted);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Scope "${scope.displayName ?? scope.name}" réactivé avec succès'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  // Recharger les données
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réactiver'),
          ),
        ],
      ),
    );
  }

  /// Afficher le dialog de confirmation pour retirer un scope
  void _showRemoveScopeDialog(BuildContext context, dynamic scope) {
    // Vérifier si le scope est requis
    if (_isScopeRequired(scope)) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 28),
              const SizedBox(width: AppSpacing.spacing2),
              Expanded(
                child: Text(
                  'Scope requis',
                  style: AppTypography.headline4.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Ce scope fait partie de la demande initiale et ne peut pas être désactivé.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray700,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Désactiver ce scope',
                style: AppTypography.headline4.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir désactiver l\'accès à :',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.spacing3),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.spacing2),
                  Expanded(
                    child: Text(
                      scope.displayName ?? scope.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spacing3),
            Text(
              'Le partenaire ${consent.partnerName} n\'aura plus accès à ces données.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              try {
                final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
                await consentProvider.removeScope(consent.id, scope.id);
                
                // Émettre un événement pour déclencher le rafraîchissement
                AppEventService.instance.emit(AppEventType.consentGranted);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Scope "${scope.displayName ?? scope.name}" désactivé avec succès'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  // Recharger les données - navigation sécurisée
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // Si on ne peut pas pop, naviguer vers /connections
                    context.go('/connections');
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  /// Section des actions
  Widget _buildActionsSection(BuildContext context) {
    // Vérifier si la révocation est en attente
    final isRevocationPending = _isRevocationPending();
    
    if (isRevocationPending) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.spacing4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              color: AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.spacing3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Révocation en attente',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Votre demande est en attente de validation par un administrateur.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showRevokeDialog(context),
          icon: const Icon(Icons.block),
          label: const Text('Révoquer la connexion'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
        ),
      ],
    );
  }

  /// Vérifier si la révocation est en attente
  bool _isRevocationPending() {
    final status = consent.statusName;
    return status.toLowerCase().contains('revocation') || 
           status.toLowerCase().contains('pending');
  }

  /// Section générique
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headline4.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          ...children,
        ],
      ),
    );
  }

  /// Ligne d'information
  Widget _buildInfoRow(String label, String value, {bool warning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing1),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: warning ? AppColors.error : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  /// Formater une date et heure
  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Vérifier si la connexion est active
  bool _isActive() {
    return consent.revokedAt == null &&
           (consent.expiresAt == null || consent.expiresAt!.isAfter(DateTime.now()));
  }

  /// Vérifier si un scope est requis (ne peut pas être désactivé)
  /// Un scope est requis UNIQUEMENT s'il nécessite un consentement explicite
  /// Les scopes de la demande initiale ne sont plus automatiquement requis
  bool _isScopeRequired(dynamic scope) {
    // Si c'est un objet ScopeModel, vérifier uniquement requiresExplicitConsent
    if (scope is ScopeModel) {
      return scope.requiresExplicitConsent;
    }
    // Vérifier si le scope a la propriété requires_explicit_consent (Map ou autre)
    if (scope is Map) {
      return scope['requires_explicit_consent'] == true;
    }
    // Sinon, essayer d'accéder via toJson() si disponible
    try {
      if (scope != null && scope.runtimeType.toString().contains('Scope')) {
        final scopeMap = scope.toJson();
        return scopeMap['requires_explicit_consent'] == true;
      }
    } catch (e) {
      // Si la propriété n'existe pas, retourner false
    }
    return false;
  }

  /// Afficher le dialog de révocation
  void _showRevokeDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error, size: 28),
            const SizedBox(width: AppSpacing.spacing2),
            const Expanded(child: Text('Demander la révocation')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vous allez demander la révocation de l\'accès de ${consent.partnerName}. Cette demande nécessite une validation par un administrateur.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing4),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Raison (optionnelle)',
                hintText: 'Expliquez pourquoi vous souhaitez révoquer cet accès',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.pop(dialogContext);
              
              try {
                final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
                await consentProvider.requestRevocation(
                  consent.id,
                  reason: reason.isNotEmpty ? reason : null,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Demande de révocation soumise. En attente de validation.'),
                      backgroundColor: AppColors.warning,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  // Navigation sécurisée : vérifier si on peut pop, sinon naviguer vers /connections
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // Si on ne peut pas pop (écran ouvert depuis notification), naviguer vers /connections
                    context.go('/connections');
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Demander la révocation'),
          ),
        ],
      ),
    );
  }
}

