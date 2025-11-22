import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';
import 'package:sezam/core/providers/auth_provider.dart';
import 'package:sezam/core/providers/profile_provider.dart';
import 'package:sezam/core/services/profile_service.dart';
import 'package:sezam/features/profile/edit_profile_field_screen.dart' show EditProfileFieldScreen, FieldType;

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  
  const ProfileScreen({super.key, this.onBackToDashboard});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  final ImagePicker _imagePicker = ImagePicker();
  final ProfileService _profileService = ProfileService();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    
    // Charger le statut du profil et rafraîchir l'utilisateur (utiliser cache si disponible)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      profileProvider.loadIfNeeded(); // Utiliser cache si disponible
      // Rafraîchir l'utilisateur pour avoir les données à jour (notamment verified_at)
      authProvider.refreshUser().catchError((e) => print('Erreur refreshUser: $e'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          _buildSimpleHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.spacing4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
                    child: _buildProfileSection(),
                  ),
                  const SizedBox(height: AppSpacing.spacing6),
                  _buildProfileProgressSection(),
                  const SizedBox(height: AppSpacing.spacing3),
                  _buildMissingFieldsSection(),
                  const SizedBox(height: AppSpacing.spacing3),
                  _buildPersonalInfoSection(),
                  const SizedBox(height: AppSpacing.spacing4),
                  _buildSecuritySection(),
                  const SizedBox(height: AppSpacing.spacing4),
                  _buildPreferencesSection(),
                  const SizedBox(height: AppSpacing.spacing4),
                  _buildAssistanceSection(),
                  const SizedBox(height: AppSpacing.spacing4),
                  _buildAccountActionsSection(),
                  const SizedBox(height: AppSpacing.spacing4),
                  _buildVersionInfo(),
                  const SizedBox(height: AppSpacing.spacing16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHeader() {
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
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.spacing2,
        bottom: AppSpacing.spacing4,
        left: AppSpacing.spacing4,
        right: AppSpacing.spacing4,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (widget.onBackToDashboard != null) {
                widget.onBackToDashboard!();
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          Expanded(
            child: Text(
              'Mon Profil',
              style: AppTypography.headline4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Espace pour équilibrer avec le bouton retour
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.spacing6),
          child: Column(
            children: [
              _buildProfilePicture(),
              const SizedBox(height: AppSpacing.spacing4),
              _buildUserName(),
              const SizedBox(height: AppSpacing.spacing2),
              _buildEmail(),
              const SizedBox(height: AppSpacing.spacing4),
              _buildVerificationButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfilePicture() {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Photo de profil arrondie - Zone cliquable principale
          Positioned(
            top: 5,
            left: 5,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isUploadingPhoto ? null : _handleProfilePhotoTap,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gray200,
                    width: 2,
                  ),
                ),
                child: _isUploadingPhoto
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : ClipOval(
                        child: _buildProfileImage(),
                      ),
              ),
            ),
          ),
          // Bouton d'édition - Positionné en bas à droite avec Material pour élévation
          Positioned(
            bottom: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: _isUploadingPhoto,
              child: Material(
                color: Colors.transparent,
                elevation: 10,
                shadowColor: Colors.black.withValues(alpha: 0.4),
                child: InkWell(
                  onTap: () {
                    print('📸 Bouton d\'édition cliqué');
                    _handleProfilePhotoTap();
                  },
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white.withValues(alpha: 0.3),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: _isUploadingPhoto
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleProfilePhotoTap() async {
    if (_isUploadingPhoto) {
      print('⚠️ Upload en cours, ignore le clic');
      return;
    }
    
    print('📸 _handleProfilePhotoTap appelé - Ouverture du menu');
    
    if (!mounted) return;
    
    // Afficher un dialogue pour choisir la source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.error),
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      // Sélectionner l'image
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      // Uploader la photo
      setState(() {
        _isUploadingPhoto = true;
      });

      await _profileService.uploadProfilePhoto(image.path);

      // Rafraîchir l'utilisateur pour avoir la nouvelle photo
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Widget _buildProfileImage() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        // Récupérer l'URL de la photo depuis profile.profile_photo ou profileImage
        final profilePhotoUrl = user?.profile?['profile_photo'] as String? ?? user?.profileImage;
        
        if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: profilePhotoUrl,
            fit: BoxFit.cover,
            width: 100,
            height: 100,
            placeholder: (context, url) => Container(
              width: 100,
              height: 100,
              color: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 50,
              ),
            ),
            errorWidget: (context, url, error) {
              print('❌ Erreur chargement image: $error, URL: $url');
              return Container(
                width: 100,
                height: 100,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 50,
                ),
              );
            },
          );
        }
        
        return Container(
          width: 100,
          height: 100,
          color: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(
            Icons.person,
            color: AppColors.primary,
            size: 50,
          ),
        );
      },
    );
  }

  Widget _buildUserName() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final profile = user?.profile;
    final isProfileVerified = profile != null && profile['verified_at'] != null;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user?.fullName ?? 'Utilisateur',
              style: AppTypography.headline4.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
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
      ],
    );
  }

  Widget _buildEmail() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    return Text(
      user?.email ?? '',
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildVerificationButton() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final profile = user?.profile;
    final isProfileVerified = profile != null && profile['verified_at'] != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing2,
        vertical: AppSpacing.spacing2,
      ),
      decoration: BoxDecoration(
        color: isProfileVerified 
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isProfileVerified 
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isProfileVerified ? Icons.check_circle : Icons.pending,
            size: 14,
            color: isProfileVerified ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.spacing1),
          Text(
            isProfileVerified ? 'Profil validé' : 'En attente de validation',
            style: AppTypography.bodyXSmall.copyWith(
              color: isProfileVerified ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileProgressSection() {
    return Selector<ProfileProvider, Map<String, dynamic>>(
      selector: (_, provider) => {
        'isLoading': provider.isLoading,
        'profileStatus': provider.profileStatus,
      },
      builder: (context, state, child) {
        final isLoading = state['isLoading'] as bool;
        final profileStatus = state['profileStatus'] as dynamic;
        
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileStatus == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
          child: Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Complétion du profil',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '${profileStatus.completionPercentage}%',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: profileStatus.isComplete 
                            ? AppColors.success 
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacing3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: LinearProgressIndicator(
                    value: profileStatus.completionPercentage / 100,
                    backgroundColor: AppColors.gray200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      profileStatus.isComplete 
                          ? AppColors.success 
                          : AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissingFieldsSection() {
    return Selector<ProfileProvider, Map<String, dynamic>>(
      selector: (_, provider) => {
        'isLoading': provider.isLoading,
        'missingFieldsDisplay': provider.missingFieldsDisplay,
        'missingFields': provider.missingFields,
        'isComplete': provider.isComplete,
        'profileStatus': provider.profileStatus,
      },
      builder: (context, state, child) {
        // Utiliser les noms d'affichage en français
        final missingFields = state['missingFieldsDisplay'] as List<String>;
        final missingFieldsRaw = state['missingFields'] as List<String>;
        final isComplete = state['isComplete'] as bool;
        final isLoading = state['isLoading'] as bool;
        final profileStatus = state['profileStatus'] as dynamic;
        
        // Debug logs
        print('🔍 _buildMissingFieldsSection:');
        print('   - isLoading: $isLoading');
        print('   - isComplete: $isComplete');
        print('   - missingFields (raw): $missingFieldsRaw');
        print('   - missingFields (display): $missingFields');
        print('   - profileStatus: ${profileStatus != null}');
        if (profileStatus != null) {
          print('   - completionPercentage: ${profileStatus.completionPercentage}%');
        }
        
        // Si le profil est en cours de chargement, afficher un indicateur
        if (isLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing4),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        // Afficher si il y a des champs manquants
        // Note: On affiche même si isComplete est true, car l'utilisateur peut avoir validé le KYC
        // mais avoir des champs optionnels manquants
        if (missingFields.isEmpty && missingFieldsRaw.isEmpty) {
          print('   - Section masquée: aucun champ manquant');
          return const SizedBox.shrink();
        }
        
        // Si missingFieldsDisplay est vide mais missingFieldsRaw ne l'est pas,
        // c'est qu'il y a un problème de mapping
        final fieldsToDisplay = missingFields.isNotEmpty 
            ? missingFields 
            : missingFieldsRaw.map((f) => f.replaceAll('_', ' ').split(' ').map((w) => 
                w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ')).toList();
        
        print('   - Section affichée avec ${fieldsToDisplay.length} champs manquants: $fieldsToDisplay');

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
                            'Champs à compléter',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacing1),
                          Text(
                            'Complétez ces informations pour finaliser votre profil.',
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
                ...fieldsToDisplay.map((fieldName) => _buildMissingFieldItem(fieldName)),
              ],
            ),
          ),
        );
      },
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
    // Ces noms correspondent à ceux retournés par le backend
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
      'Adresse principale': {
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
      'Lieu de naissance': {
        'fieldKey': 'birth_place',
        'label': 'Lieu de naissance',
        'fieldType': FieldType.text,
      },
      'Employeur': {
        'fieldKey': 'employer',
        'label': 'Employeur',
        'fieldType': FieldType.text,
      },
      'Revenu annuel': {
        'fieldKey': 'annual_income',
        'label': 'Revenu annuel',
        'fieldType': FieldType.text,
      },
      'Source de revenu': {
        'fieldKey': 'income_source_id',
        'label': 'Source de revenu',
        'fieldType': FieldType.select,
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

    // Si la mise à jour a réussi, recharger le statut du profil
    if (result == true && mounted) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Recharger l'utilisateur et le statut du profil
      await authProvider.refreshUser();
      await profileProvider.loadProfileStatus();
      
      // Rafraîchir l'interface
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildPersonalInfoSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    // Extraire les données du profil
    final profile = user?.profile;
    
    // Debug: afficher les données du profil
    print('🔍 Profile data: $profile');
    print('🔍 User: ${user?.email}');
    if (profile != null && profile.containsKey('nationality')) {
      print('🏳️ Nationality raw data: ${profile['nationality']}');
      print('🏳️ Nationality type: ${profile['nationality'].runtimeType}');
    }
    
    // Fonction helper pour convertir les valeurs en String
    String getProfileValue(String key) {
      if (profile == null) return 'N/A';
      final value = profile[key];
      if (value == null) return 'N/A';
      return value.toString();
    }
    
    // Gérer les objets imbriqués (comme nationality)
    String getProfileNestedValue(String key, String nestedKey) {
      if (profile == null) return 'N/A';
      final nested = profile[key];
      if (nested is Map && nested[nestedKey] != null) {
        return nested[nestedKey].toString();
      }
      return 'N/A';
    }
    
    return Column(
      children: [
      // Section: Identité
      _buildInfoSubsection(
        title: 'Identité',
          fields: [
            _ProfileField(
              icon: Icons.person_outline,
              label: 'Nom complet',
              value: '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim().isEmpty ? 'N/A' : '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
              fieldKey: 'full_name',
              isReadOnly: true,
            ),
            _ProfileField(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user?.email ?? 'N/A',
              fieldKey: 'email',
              isReadOnly: true,
            ),
            _ProfileField(
              icon: Icons.phone_outlined,
              label: 'Téléphone',
              value: user?.phone ?? 'N/A',
              fieldKey: 'phone',
              isReadOnly: true,
            ),
            _ProfileField(
              icon: Icons.code_outlined,
              label: 'Code Utilisateur',
              value: user?.userCode ?? 'N/A',
              fieldKey: 'user_code',
              isReadOnly: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing4),
        // Section: Informations personnelles
        _buildInfoSubsection(
          title: 'État civil',
          fields: [
            _ProfileField(
              icon: Icons.cake_outlined,
              label: 'Date de naissance',
              value: getProfileValue('birth_date'),
              fieldKey: 'birth_date',
            ),
            _ProfileField(
              icon: Icons.flag_outlined,
              label: 'Nationalité',
              value: getProfileNestedValue('nationality', 'name'),
              fieldKey: 'nationality',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing4),
        // Section: Adresse
        _buildInfoSubsection(
          title: 'Adresse',
          fields: [
            _ProfileField(
              icon: Icons.home_outlined,
              label: 'Adresse complète',
              value: getProfileValue('address'),
              fieldKey: 'address',
            ),
            _ProfileField(
              icon: Icons.location_city_outlined,
              label: 'Ville',
              value: getProfileValue('city'),
              fieldKey: 'city',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing4),
        // Section: Professionnel
        _buildInfoSubsection(
          title: 'Professionnel',
          fields: [
            _ProfileField(
              icon: Icons.work_outline,
              label: 'Profession',
              value: getProfileValue('occupation'),
              fieldKey: 'occupation',
            ),
            _ProfileField(
              icon: Icons.business_outlined,
              label: 'Employeur',
              value: getProfileValue('employer'),
              fieldKey: 'employer',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSubsection({
    required String title,
    required List<_ProfileField> fields,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing4),
            child: Text(
              title,
              style: AppTypography.headline4.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...fields.map((field) {
            final index = fields.indexOf(field);
            return Column(
              children: [
                _buildPersonalInfoItem(
                  icon: field.icon,
                  label: field.label,
                  value: field.value,
                  isReadOnly: field.isReadOnly,
                  onTap: () {
                    if (!field.isReadOnly) {
                      _editProfileField(context, field);
                    }
                  },
                ),
                if (index < fields.length - 1) _buildDivider(),
              ],
            );
          }).toList(),
        ],
      ),
    );
    // End of _buildPersonalInfoSection
  }

  Future<void> _editProfileField(BuildContext context, _ProfileField field) async {
    // Déterminer le type de champ
    FieldType fieldType = FieldType.text;
    List<String>? options;

    switch (field.fieldKey) {
      case 'email':
        fieldType = FieldType.email;
        break;
      case 'phone':
        fieldType = FieldType.phone;
        break;
      case 'birth_date':
        fieldType = FieldType.date;
        break;
      case 'nationality':
        fieldType = FieldType.select;
        // Les options sont chargées dynamiquement depuis le backend
        options = null;
        print('🏳️ Editing nationality with initial value: ${field.value}');
        break;
      default:
        fieldType = FieldType.text;
    }

    // Naviguer vers l'écran d'édition
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileFieldScreen(
          fieldKey: field.fieldKey,
          label: field.label,
          initialValue: field.value,
          fieldType: fieldType,
          options: options,
        ),
      ),
    );

    // Recharger le statut du profil si la modification a réussi
    if (result == true && mounted) {
      print('🔄 Refresh après modification du profil...');
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Recharger l'utilisateur et le statut du profil
      await authProvider.refreshUser();
      await profileProvider.loadProfileStatus();
      
      // Rafraîchir l'interface
      if (mounted) {
        setState(() {
          print('🔄 setState appelé dans ProfileScreen');
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Appeler la méthode de déconnexion
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      // Rediriger vers l'écran d'authentification
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  Widget _buildPersonalInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isReadOnly = false,
    required VoidCallback onTap,
  }) {
    final isEmpty = value == 'N/A';
    
    return InkWell(
      onTap: isReadOnly ? null : onTap,
      child: Opacity(
        opacity: isReadOnly ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing3,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isEmpty 
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: isEmpty 
                    ? AppColors.warning 
                    : AppColors.gray600,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing1),
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isEmpty 
                          ? AppColors.warning 
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w500,
                      fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (!isReadOnly)
              Icon(
                Icons.edit_outlined,
                color: isEmpty 
                    ? AppColors.warning 
                    : AppColors.gray400,
                size: 20,
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      height: 1,
      color: AppColors.gray200,
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing4),
            child: Text(
              'Sécurité et confidentialité',
              style: AppTypography.headline4.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSecurityItem(
            icon: Icons.shield_outlined,
            label: 'Changer le mot de passe',
            onTap: () {
              // TODO: Naviguer vers le changement de mot de passe
            },
          ),
          _buildDivider(),
          _buildSecurityItem(
            icon: Icons.security,
            label: 'Authentification à deux facteurs',
            subtitle: 'Activée',
            subtitleColor: AppColors.success,
            onTap: () {
              // TODO: Naviguer vers la configuration 2FA
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing4),
            child: Text(
              'Préférences',
              style: AppTypography.headline4.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildPreferenceItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            hasSwitch: true,
            switchValue: _notificationsEnabled,
            onSwitchChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          _buildDivider(),
          _buildPreferenceItem(
            icon: Icons.language,
            label: 'Langue',
            subtitle: 'Français',
            onTap: () {
              // TODO: Naviguer vers la sélection de langue
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssistanceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing4),
            child: Text(
              'Assistance',
              style: AppTypography.headline4.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildAssistanceItem(
            icon: Icons.help_outline,
            label: 'Centre d\'aide',
            onTap: () {
              // TODO: Naviguer vers le centre d'aide
            },
          ),
          _buildDivider(),
          _buildAssistanceItem(
            icon: Icons.description_outlined,
            label: 'Conditions d\'utilisation',
            onTap: () {
              // TODO: Naviguer vers les conditions d'utilisation
            },
          ),
          _buildDivider(),
          _buildAssistanceItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Politique de confidentialité',
            onTap: () {
              // TODO: Naviguer vers la politique de confidentialité
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
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
        children: [
          _buildActionItem(
            icon: Icons.logout,
            label: 'Se déconnecter',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: _handleLogout,
          ),
          /*_buildDivider(),
          _buildActionItem(
            icon: Icons.delete_outline,
            label: 'Supprimer mon compte',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () {
              // TODO: Suppression du compte
            },
          ),*/
        ],
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? subtitleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing3,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: AppColors.gray600,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.spacing1),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleColor ?? AppColors.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.gray400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String label,
    String? subtitle,
    bool hasSwitch = false,
    bool? switchValue,
    ValueChanged<bool>? onSwitchChanged,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing3,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: AppColors.gray600,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.spacing1),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasSwitch && switchValue != null && onSwitchChanged != null)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeThumbColor: AppColors.primary,
              )
            else if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.gray400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistanceItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing3,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: AppColors.gray600,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing3),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.gray400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing3,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing3),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      child: Text(
        'Version 1.0.0',
        style: AppTypography.bodySmall.copyWith(color: AppColors.gray500),
      ),
    );
  }
}

/// Classe pour représenter un champ de profil utilisateur
class _ProfileField {
  final IconData icon;
  final String label;
  final String value;
  final String fieldKey;
  final bool isReadOnly;

  _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    required this.fieldKey,
    this.isReadOnly = false,
  });
}
