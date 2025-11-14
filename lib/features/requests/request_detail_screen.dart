import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';
import 'package:sezam/core/models/consent_model.dart';
import 'package:sezam/core/providers/consent_provider.dart';
import 'package:sezam/core/providers/auth_provider.dart';
import 'package:sezam/features/auth/widgets/otp_verification_dialog.dart';
import 'package:sezam/core/services/app_event_service.dart';
import 'package:sezam/features/profile/edit_profile_field_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final ConsentModel consent;
  final int currentTabIndex;

  const RequestDetailScreen({
    super.key,
    required this.consent,
    required this.currentTabIndex,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _isProcessing = false;
  Set<String> _selectedScopeIds = {};
  Set<String> _scopesWithMissingFields = {};
  late ConsentModel _currentConsent;

  @override
  void initState() {
    super.initState();
    // Initialiser avec le consent actuel
    _currentConsent = widget.consent;
    
    // Initialiser avec tous les scopes sélectionnés par défaut
    _selectedScopeIds = widget.consent.scopes?.map((s) {
      return s.id;
    }).toSet() ?? {};
    
    // Identifier les scopes avec champs manquants
    _scopesWithMissingFields = widget.consent.scopes
        ?.where((s) => s.hasMissingFields)
        .map((s) => s.id)
        .toSet() ?? {};
  }
  
  /// Vérifier si on peut accepter la demande
  bool get _canGrantConsent {
    // Si aucun scope sélectionné
    if (_selectedScopeIds.isEmpty) return false;
    
    // Si des scopes sélectionnés ont des champs manquants
    for (var scopeId in _selectedScopeIds) {
      if (_scopesWithMissingFields.contains(scopeId)) {
        return false;
      }
    }
    
    return true;
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
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
                _buildHeader(),
          SliverToBoxAdapter(
              child: Column(
                children: [
                      _buildPartnerInfo(),
                  const SizedBox(height: AppSpacing.spacing4),
                      _buildPurposeSection(),
                      if (_currentConsent.isPending && !_canGrantConsent && _scopesWithMissingFields.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.spacing4),
                        _buildMissingFieldsWarning(),
                      ],
                      if (_currentConsent.scopes != null && _currentConsent.scopes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.spacing4),
                        _buildScopesSection(),
                      ],
                  const SizedBox(height: AppSpacing.spacing4),
                      _buildStatusSection(),
                  const SizedBox(height: AppSpacing.spacing4),
                      _buildDatesSection(),
                      if (_currentConsent.isPending) ...[
                        const SizedBox(height: AppSpacing.spacing8),
                        _buildActionButtons(),
                        const SizedBox(height: AppSpacing.spacing8),
                      ],
                ],
            ),
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
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Détails de la demande',
        style: AppTypography.headline4.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.spacing6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
            _buildStatusBadge(),
            const SizedBox(height: AppSpacing.spacing4),
                    Text(
              _currentConsent.partnerName,
              style: AppTypography.headline3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
              textAlign: TextAlign.center,
                    ),
            const SizedBox(height: AppSpacing.spacing2),
                    Text(
              _currentConsent.category,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    if (_currentConsent.isGranted) {
      backgroundColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      text = 'Accordée';
      icon = Icons.check_circle;
    } else if (_currentConsent.isDenied) {
      backgroundColor = AppColors.error.withValues(alpha: 0.1);
      textColor = AppColors.error;
      text = 'Refusée';
      icon = Icons.cancel;
    } else {
      backgroundColor = AppColors.warning.withValues(alpha: 0.1);
      textColor = AppColors.warning;
      text = 'En attente';
      icon = Icons.access_time;
    }

    return Container(
                padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
                  vertical: AppSpacing.spacing2,
                ),
                decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: AppSpacing.spacing2),
          Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: textColor,
                    fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.spacing3),
          Text(
                'Organisation',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing3),
          _buildInfoRow('Nom', _currentConsent.partnerName),
          _buildInfoRow('Catégorie', _currentConsent.category),
        ],
      ),
    );
  }

  Widget _buildPurposeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.spacing3),
              Text(
                'Objectif',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing3),
          Text(
            _currentConsent.purpose ?? 'Aucun objectif spécifié',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            children: [
              Icon(
                Icons.list_alt,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.spacing3),
                Text(
                'Données demandées (${_currentConsent.scopes?.length ?? 0})',
                style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.spacing3),
          ..._currentConsent.scopes!.map((scope) {
            print('Scope type: ${scope.runtimeType}, id: ${scope.id}');
            return _buildScopeItem(scope);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildScopeItem(dynamic scope) {
    final isSensitive = scope.isSensitive;
    final hasMissingFields = scope.hasMissingFields ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing2),
      padding: const EdgeInsets.all(AppSpacing.spacing3),
      decoration: BoxDecoration(
        color: isSensitive || hasMissingFields
            ? AppColors.warning.withValues(alpha: 0.05)
            : AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: hasMissingFields
              ? AppColors.warning.withValues(alpha: 0.3)
              : isSensitive
                  ? AppColors.error.withValues(alpha: 0.2)
                  : AppColors.gray200,
          width: hasMissingFields ? 2 : 1,
        ),
      ),
      child: Row(
            children: [
              Icon(
                hasMissingFields
                    ? Icons.warning_amber_rounded
                    : isSensitive 
                        ? Icons.security 
                        : Icons.check_circle_outline,
                color: hasMissingFields
                    ? AppColors.warning
                    : isSensitive 
                        ? AppColors.error 
                        : AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.spacing3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scope.displayName,
                      style:AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    if (scope.description != null) ...[
                      const SizedBox(height: AppSpacing.spacing1),
                      Text(
                        scope.description!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                    if (hasMissingFields && scope.missingFields != null) ...[
                      const SizedBox(height: AppSpacing.spacing1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing2,
                          vertical: AppSpacing.spacing1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: AppSpacing.spacing1),
                            Flexible(
                              child: Text(
                                'Données manquantes: ${scope.missingFields!.join(', ')}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (scope.fieldsIncluded != null && scope.fieldsIncluded!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.spacing1),
                      Text(
                        scope.fieldsIncluded!.join(', '),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Switch
              Switch(
                value: _selectedScopeIds.contains(scope.id),
                onChanged: scope.requiresExplicitConsent 
                    ? null // Désactiver le switch si required
                    : (value) {
                        setState(() {
                          if (value) {
                            _selectedScopeIds.add(scope.id);
                          } else {
                            _selectedScopeIds.remove(scope.id);
                          }
                        });
                      },
                activeColor: AppColors.primary,
              ),
            ],
          ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
            padding: const EdgeInsets.all(AppSpacing.spacing4),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.spacing3),
                      Text(
                'Statut',
                        style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
          const SizedBox(height: AppSpacing.spacing3          ),
          _buildInfoRow('Statut', _currentConsent.statusName.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildDatesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.spacing3),
          Text(
                'Dates',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing3),
          _buildInfoRow('Créée le', _formatDate(_currentConsent.createdAt)),
          if (_currentConsent.grantedAt != null)
            _buildInfoRow('Accordée le', _formatDate(_currentConsent.grantedAt!)),
          if (_currentConsent.expiresAt != null)
            _buildInfoRow('Expire le', _formatDate(_currentConsent.expiresAt!)),
          if (_currentConsent.deniedAt != null)
            _buildInfoRow('Refusée le', _formatDate(_currentConsent.deniedAt!)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleDeny,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: const Text('Refuser'),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing4),
          Expanded(
            child: ElevatedButton(
              onPressed: _canGrantConsent ? _handleGrant : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canGrantConsent ? AppColors.success : AppColors.gray400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: const Text('Accepter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingFieldsWarning() {
    // Récupérer tous les champs manquants uniques
    final allMissingFields = <String>{};
    for (var scope in _currentConsent.scopes ?? []) {
      if (_selectedScopeIds.contains(scope.id) && scope.missingFields != null) {
        allMissingFields.addAll(scope.missingFields!);
      }
    }
    
    if (allMissingFields.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spacing4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.spacing3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Données manquantes',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing1),
                      Text(
                        'Vous devez compléter ces informations avant d\'accepter cette demande.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing4),
            // Liste des champs manquants avec boutons pour les mettre à jour
            ...allMissingFields.map((fieldName) => _buildMissingFieldItem(fieldName)),
            const SizedBox(height: AppSpacing.spacing3),
            // Bouton pour aller au profil complet
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to profile screen
                  context.push('/profile').then((_) async {
                    await _refreshConsentAfterUpdate();
                  });
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Voir tout mon profil'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: BorderSide(color: AppColors.warning),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construire un item pour un champ manquant avec bouton de mise à jour
  Widget _buildMissingFieldItem(String fieldName) {
    final fieldMapping = _getFieldMapping(fieldName);
    if (fieldMapping == null) {
      // Si on ne peut pas mapper le champ, afficher juste le nom
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.spacing2),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.warning),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                fieldName,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing3,
            vertical: AppSpacing.spacing1,
          ),
          leading: Icon(
            Icons.edit_outlined,
            size: 18,
            color: AppColors.warning,
          ),
          title: Text(
            fieldName,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.gray400,
          ),
          onTap: () => _editMissingField(fieldMapping),
        ),
      ),
    );
  }

  /// Mapper le nom d'affichage du champ vers les informations nécessaires pour l'édition
  Map<String, dynamic>? _getFieldMapping(String fieldName) {
    // Mapping des noms d'affichage vers les fieldKeys et types
    // Ces noms correspondent à ceux retournés par ScopeResource::getFieldDisplayName
    final mappings = {
      'Email': {
        'fieldKey': 'email',
        'label': 'Email',
        'fieldType': FieldType.email,
      },
      'Téléphone': {
        'fieldKey': 'phone',
        'label': 'Téléphone',
        'fieldType': FieldType.phone,
      },
      'Date de naissance': {
        'fieldKey': 'birth_date',
        'label': 'Date de naissance',
        'fieldType': FieldType.date,
      },
      'Genre': {
        'fieldKey': 'gender_id',
        'label': 'Genre',
        'fieldType': FieldType.select,
      },
      'Adresse': {
        'fieldKey': 'address_line1',
        'label': 'Adresse',
        'fieldType': FieldType.text,
      },
      'Ville': {
        'fieldKey': 'city',
        'label': 'Ville',
        'fieldType': FieldType.text,
      },
      'Pays': {
        'fieldKey': 'country_id',
        'label': 'Pays',
        'fieldType': FieldType.select,
      },
      'Nationalité': {
        'fieldKey': 'nationality_id',
        'label': 'Nationalité',
        'fieldType': FieldType.select,
      },
      'Profession': {
        'fieldKey': 'occupation',
        'label': 'Profession',
        'fieldType': FieldType.text,
      },
      'Prénom': {
        'fieldKey': 'first_name',
        'label': 'Prénom',
        'fieldType': FieldType.text,
      },
      'Nom': {
        'fieldKey': 'last_name',
        'label': 'Nom',
        'fieldType': FieldType.text,
      },
      'Nom complet': {
        'fieldKey': 'first_name', // On commence par le prénom
        'label': 'Prénom',
        'fieldType': FieldType.text,
      },
      'Documents d\'identité': {
        'fieldKey': null, // Les documents sont gérés différemment
        'label': 'Documents',
        'fieldType': FieldType.text,
      },
      'Numéro de document': {
        'fieldKey': null, // Les documents sont gérés différemment
        'label': 'Numéro de document',
        'fieldType': FieldType.text,
      },
    };

    final mapping = mappings[fieldName];
    // Si le fieldKey est null, on ne peut pas éditer ce champ depuis ici
    if (mapping != null && mapping['fieldKey'] == null) {
      return null;
    }
    return mapping;
  }

  /// Éditer un champ manquant
  Future<void> _editMissingField(Map<String, dynamic> fieldMapping) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    // Récupérer la valeur initiale du champ
    String? initialValue;
    if (fieldMapping['fieldKey'] == 'email') {
      initialValue = user?.email;
    } else if (fieldMapping['fieldKey'] == 'phone') {
      initialValue = user?.phone;
    } else if (user?.profile != null) {
      final profile = user!.profile!;
      final fieldKey = fieldMapping['fieldKey'] as String;
      initialValue = profile[fieldKey]?.toString();
    }

    // Naviguer vers l'écran d'édition
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileFieldScreen(
          fieldKey: fieldMapping['fieldKey'] as String,
          label: fieldMapping['label'] as String,
          initialValue: initialValue,
          fieldType: fieldMapping['fieldType'] as FieldType,
        ),
      ),
    );

    // Si la mise à jour a réussi, recharger le consent
    if (result == true && mounted) {
      await _refreshConsentAfterUpdate();
    }
  }

  /// Rafraîchir le consent après mise à jour du profil
  Future<void> _refreshConsentAfterUpdate() async {
    if (!mounted) return;
    
    print('🔄 Rechargement des données après mise à jour du profil...');
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUser();
    print('✅ Utilisateur rechargé');
    
    final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
    await consentProvider.loadConsents();
    print('✅ Consents rechargés: ${consentProvider.consents.length}');
    
    // Récupérer le consent mis à jour
    final updatedConsent = consentProvider.consents.firstWhere(
      (c) => c.id == widget.consent.id,
      orElse: () => widget.consent,
    );
    
    // Mettre à jour le consent actuel et les scopes avec champs manquants
    if (mounted) {
      setState(() {
        _currentConsent = updatedConsent;
        _scopesWithMissingFields = updatedConsent.scopes
            ?.where((s) => s.hasMissingFields)
            .map((s) => s.id)
            .toSet() ?? {};
      });
      
      print('📊 Scopes avec champs manquants: ${_scopesWithMissingFields.length}');
      print('✅ Mise à jour terminée');
    }
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
          Expanded(
            child: Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
          ),
        ),
      ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleGrant() async {
    // Demander l'OTP avant de valider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final userEmail = user?.email ?? '';

    if (userEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de récupérer votre email'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Afficher le dialogue OTP
    final otpCode = await _showOtpDialog(userEmail);
    
    if (otpCode == null) {
      // L'utilisateur a annulé
      return;
    }

    setState(() => _isProcessing = true);
    
    try {
      final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
      await consentProvider.grantConsent(
        widget.consent.id,
        _selectedScopeIds.toList(),
        otpCode: otpCode,
      );
      
      // Émettre un événement pour déclencher le rafraîchissement
      AppEventService.instance.emit(AppEventType.consentGranted);
      
      if (mounted) {
        Navigator.pop(context, {'action': 'granted', 'consent': widget.consent});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showOtpDialog(String email) async {
    // Demander l'OTP d'abord
    final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
    try {
      await consentProvider.requestConsentOtp(widget.consent.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi de l\'OTP: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }

    // Afficher le dialogue de vérification OTP
    return await showDialog<String>(
      context: context,
      barrierDismissible: true, // Permettre de fermer en cliquant en dehors
      builder: (context) => PopScope(
        canPop: true,
        child: OtpVerificationDialog(
          email: email,
          onResend: () async {
            try {
              await consentProvider.requestConsentOtp(widget.consent.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code renvoyé avec succès'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
          onSubmit: (code) {
            Navigator.of(context).pop(code);
          },
        ),
      ),
    );
  }

  Future<void> _handleDeny() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la demande'),
        content: const Text('Êtes-vous sûr de vouloir refuser cette demande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final consentProvider = Provider.of<ConsentProvider>(context, listen: false);
      await consentProvider.denyConsent(widget.consent.id);
      
      // Émettre un événement pour déclencher le rafraîchissement
      AppEventService.instance.emit(AppEventType.consentDenied);
      
      if (mounted) {
        Navigator.pop(context, {'action': 'denied', 'consent': widget.consent});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
              'Votre profil doit être validé par un administrateur avant de pouvoir gérer les demandes de connexion.',
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
                      'Une fois votre profil validé, vous pourrez accepter ou refuser les demandes de connexion.',
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
