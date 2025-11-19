import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../documents/document_upload_screen.dart';
// import removed: personal info is listed inline in KYC screen
import '../profile/edit_profile_field_screen.dart' show EditProfileFieldScreen, FieldType;
import '../../core/services/document_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/app_event_service.dart';

/// Écran KYC pour compléter le profil - Design professionnel
class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  late AnimationController _animationController;
  List<Map<String, dynamic>> _requiredDocs = [];

  final List<KycStep> _steps = [
    KycStep(
      id: 'personal',
      icon: Icons.person_outline,
      title: 'Informations personnelles',
      description: 'Nom, prénom, date et lieu de naissance',
      route: '/kyc',
    ),
    KycStep(
      id: 'address',
      icon: Icons.location_on_outlined,
      title: 'Adresse de résidence',
      description: 'Adresse complète de votre domicile',
      route: '/profile',
    ),
    KycStep(
      id: 'documents',
      icon: Icons.description_outlined,
      title: 'Documents justificatifs',
      description: 'Pièce d\'identité et justificatifs',
      route: '/documents',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfileStatus();
      _loadRequiredDocs();
    });
  }
  Future<void> _loadRequiredDocs() async {
    try {
      final docs = await DocumentService().getRequiredDocuments();
      if (mounted) setState(() => _requiredDocs = docs);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _animationController.reset();
      _animationController.forward();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reset();
      _animationController.forward();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep--);
    }
  }

  bool _isPersonalInfoComplete(BuildContext context) {
    // Utiliser le ProfileProvider pour vérifier les champs requis pour le KYC
    final profileProvider = context.read<ProfileProvider>();
    
    // Les champs requis pour le KYC sont : birth_date, birth_place, gender_id, nationality_id, 
    // address_line1, city, country_id, occupation
    // On vérifie que les champs requis pour cette étape (informations personnelles) sont remplis
    final missingFields = profileProvider.missingFields;
    
    // Pour l'étape "informations personnelles", on vérifie les champs personnels requis
    // birth_date, birth_place, gender_id, nationality_id, occupation
    final personalRequiredFields = ['birth_date', 'nationality_id', 'occupation'];
    final missingPersonalFields = missingFields.where((field) => personalRequiredFields.contains(field)).toList();
    print('🔐 missingPersonalFields: $missingPersonalFields');
    
    return missingPersonalFields.isEmpty;
  }

  bool _isIdCardUploaded(ProfileProvider profileProvider) {
    final status = profileProvider.profileStatus;
    if (status == null) {
      print('🔐 _isIdCardUploaded: status is null');
      return false;
    }
    
    print('🔐 _isIdCardUploaded: uploadedDocuments = ${status.uploadedDocuments}');
    print('🔐 _isIdCardUploaded: _requiredDocs = $_requiredDocs');
    
    // Vérifier pour identity_card, passport, ou id_card
    // Note: uploadedDocuments contient les document_type_id, donc si on a recto+verso,
    // on aura 2 fois le même ID, mais contains() retournera true si au moins un existe
    // Pour les documents avec sides_required='both', on considère qu'ils sont complets
    // si l'ID est présent (car cela signifie qu'au moins un côté est uploadé, et le backend
    // devrait vérifier que les deux sont présents dans getMissingDocuments)
    for (final d in _requiredDocs) {
      final name = (d['name'] ?? '').toString();
      if (name == 'identity_card' || name == 'passport' || name == 'id_card') {
        final id = (d['id'] ?? '').toString();
        final sidesRequired = (d['sides_required'] ?? 'none').toString();
        
        if (id.isNotEmpty && status.uploadedDocuments.contains(id)) {
          // Si le document nécessite les deux côtés, vérifier qu'il n'est pas dans missingDocuments
          // (car le backend devrait le marquer comme manquant si un côté manque)
          if (sidesRequired == 'both') {
            // Vérifier qu'il n'est pas dans missingDocuments
            final isMissing = status.missingDocuments.any((missing) {
              final missingStr = missing.toString().toLowerCase();
              return missingStr.contains('identity') || missingStr.contains('passport');
            });
            if (!isMissing) {
              print('🔐 _isIdCardUploaded: found complete identity document (recto + verso) with id = $id');
              return true;
            }
          } else {
            // Document simple (passport, etc.)
            print('🔐 _isIdCardUploaded: found uploaded identity document with id = $id');
            return true;
          }
      }
    }
    }
    
    // Vérifier par nom aussi
    final identityNames = ['identity_card', 'passport', 'id_card'];
    for (final name in identityNames) {
      if (status.uploadedDocuments.contains(name)) {
        print('🔐 _isIdCardUploaded: found uploaded identity document by name = $name');
        return true;
      }
    }
    
    print('🔐 _isIdCardUploaded: no identity document found');
    return false;
  }

  bool _isPhotoUploaded(ProfileProvider profileProvider) {
    final status = profileProvider.profileStatus;
    if (status == null) return false;
    
    // Vérifier pour photo
    for (final d in _requiredDocs) {
      final name = (d['name'] ?? '').toString();
      if (name == 'photo') {
        final id = (d['id'] ?? '').toString();
        if (id.isNotEmpty && status.uploadedDocuments.contains(id)) {
          return true;
        }
      }
    }
    
    // Vérifier par nom aussi
    return status.uploadedDocuments.contains('photo');
  }

  bool _isAddressProofUploaded(ProfileProvider profileProvider) {
    final status = profileProvider.profileStatus;
    if (status == null) return false;
    
    // Vérifier pour proof_of_address
    for (final d in _requiredDocs) {
      final name = (d['name'] ?? '').toString();
      if (name == 'proof_of_address') {
        final id = (d['id'] ?? '').toString();
        if (id.isNotEmpty && status.uploadedDocuments.contains(id)) {
          return true;
        }
      }
    }
    
    // Vérifier par nom aussi
    return status.uploadedDocuments.contains('proof_of_address');
  }

  Future<void> _completeKyc() async {
    if (!mounted) return;

    // Vérifier que tous les champs requis sont remplis
    final profileProvider = context.read<ProfileProvider>();
    final missingFields = profileProvider.missingFields;
    
    if (missingFields.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez remplir tous les champs requis avant de valider le KYC.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Afficher le dialogue de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Appeler l'API pour marquer le KYC comme complet
      final profileService = ProfileService();
      await profileService.completeKyc();
      
      // Émettre un événement pour déclencher le rafraîchissement
      AppEventService.instance.emit(AppEventType.kycCompleted);
      
      // Recharger le statut du profil
      await profileProvider.loadProfileStatus();
      
      if (!mounted) return;
      
      // Fermer le dialogue de chargement
      Navigator.of(context).pop();
      
      // Afficher le dialogue de succès
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSuccessDialog(),
      );
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.of(context).pop();
        // Rediriger vers la sélection du motif d'utilisation après KYC
        context.go('/usage-purpose');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialogue de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            // Header simple (sans pourcentage)
            _buildHeader(profileProvider.completionPercentage),
            
            // Stepper visuel
            //_buildStepIndicator(),
            
            // Contenu principal
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildStepContent(_steps[index]);
                },
              ),
            ),
            
            // Boutons de navigation
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int progress) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo ou icône
              Container(
                padding: EdgeInsets.all(AppSpacing.spacing2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              
              SizedBox(width: AppSpacing.spacing3),
              
              // Titre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vérification d\'identité',
                      style: AppTypography.headline4.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Étape ${_currentStep + 1} sur ${_steps.length}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox.shrink(),
            ],
          ),
          
          SizedBox(height: AppSpacing.spacing3),
          
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  // step indicator removed (unused)

  Widget _buildStepContent(KycStep step) {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        )),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.spacing4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte principale
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.spacing6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Icône animée
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.1),
                                  AppColors.primary.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              step.icon,
                              size: 30,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: AppSpacing.spacing5),
                    
                    // Titre
                    Text(
                      step.title,
                      style: AppTypography.headline4.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: AppSpacing.spacing2),
                    
                    // Description
                    Text(
                      step.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Bouton d'action principal supprimé (navigation via listes interactives)
                  ],
                ),
              ),
              
              SizedBox(height: AppSpacing.spacing4),
              
              // Liste des documents pour l'étape documents
              if (step.id == 'documents') _buildDocumentsInfo(),
              
              // Affichage direct des champs pour l'étape "Informations personnelles"
              if (step.id == 'personal') _buildPersonalFieldsList(),
              
              // Informations supplémentaires pour l'étape adresse
              if (step.id == 'address') _buildAddressInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsInfo() {
    final profileStatus = context.read<ProfileProvider>().profileStatus;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    final Map<String, dynamic>? profile = (user?.profile is Map)
        ? user!.profile as Map<String, dynamic>
        : null;
    String getProfileValue(String key) {
      if (profile == null) return 'Non renseigné';
      final value = profile[key];
      if (value == null) return 'Non renseigné';
      final str = value.toString().trim();
      return str.isEmpty ? 'Non renseigné' : str;
    }
    final occupationName = getProfileValue('occupation');

    // Construire depuis le backend si disponible
    final List<Map<String, dynamic>> documents = [];
    bool hasIdentityDocument = false;
    
    // Si on a la version avec IDs, on l'utilise pour marquer 'uploaded'
    if (_requiredDocs.isNotEmpty) {
      for (final d in _requiredDocs) {
        final name = (d['name'] ?? '').toString();
        final id = (d['id'] ?? '').toString();
        if (name == 'salary_slip' && occupationName != 'Salarié') {
          continue;
        }
        
        // Fusionner les documents d'identité (identity_card, passport) en un seul
        // Pour le KYC, on demande UN SEUL document d'identité (CNI OU Passport)
        if (name == 'identity_card' || name == 'passport' || name == 'id_card') {
          if (!hasIdentityDocument) {
            // Vérifier si N'IMPORTE QUEL document d'identité est uploadé (pas seulement celui-ci)
            bool uploaded = false;
            if (profileStatus != null) {
              // Vérifier tous les types d'identité dans uploadedDocuments
              for (final uploadedDoc in profileStatus.uploadedDocuments) {
                final uploadedStr = uploadedDoc.toString().toLowerCase();
                if (uploadedStr.contains('identity_card') || 
                    uploadedStr.contains('passport') || 
                    uploadedStr.contains('id_card')) {
                  uploaded = true;
                  break;
                }
              }
              // Vérifier aussi par ID si pas trouvé par nom
              if (!uploaded) {
                for (final d in _requiredDocs) {
                  final docName = (d['name'] ?? '').toString().toLowerCase();
                  if ((docName == 'identity_card' || docName == 'passport' || docName == 'id_card')) {
                    final docId = (d['id'] ?? '').toString();
                    if (docId.isNotEmpty && profileStatus.uploadedDocuments.contains(docId)) {
                      uploaded = true;
                      break;
                    }
                  }
                }
              }
            }
            documents.add({
              'id': 'identity',
              'typeId': id,
              'icon': Icons.badge,
              'title': 'Pièce d\'identité',
              'subtitle': 'CNI, Passeport ou Carte d\'identité',
              'required': true,
              'uploaded': uploaded,
              'isIdentity': true,
            });
            hasIdentityDocument = true;
          }
          continue;
        }
        
        final uploaded = profileStatus?.uploadedDocuments.contains(id) ?? false;
        // Marquer photo et proof_of_address comme requis
        final isRequired = name == 'photo' || name == 'proof_of_address';
        documents.add({
          'id': name,
          'typeId': id,
          'icon': name == 'photo'
              ? Icons.photo_camera
              : (name == 'proof_of_address' ? Icons.home : Icons.badge),
          'title': name == 'proof_of_address'
                        ? 'Justificatif de domicile'
              : (name == 'salary_slip' ? 'Bulletin de salaire' : (name == 'photo' ? 'Photo d\'identité (Selfie)' : 'Document')),
          'subtitle': name == 'proof_of_address'
                ? 'Facture de moins de 3 mois'
              : (name == 'photo' ? 'Photo récente format identité' : 'Document'),
          'required': isRequired,
          'uploaded': uploaded,
        });
      }
    } else if (profileStatus != null && profileStatus.requiredDocuments.isNotEmpty) {
      // Utiliser les documents requis depuis profileStatus
      for (final doc in profileStatus.requiredDocuments) {
        // Ne pas demander le bulletin de salaire si l'utilisateur n'est pas salarié
        if (doc == 'salary_slip' && occupationName != 'Salarié') {
          continue;
        }
        
        // Fusionner les documents d'identité
        if (doc == 'identity_card' || doc == 'passport' || doc == 'id_card') {
          if (!hasIdentityDocument) {
            documents.add({
              'id': 'identity',
              'typeId': doc.toString(),
              'icon': Icons.badge,
              'title': 'Pièce d\'identité',
              'subtitle': 'CNI, Passeport ou Carte d\'identité',
              'required': true,
              'uploaded': false,
              'isIdentity': true,
            });
            hasIdentityDocument = true;
          }
          continue;
        }
        
        // Marquer photo et proof_of_address comme requis
        final isRequired = doc == 'photo' || doc == 'proof_of_address';
        documents.add({
          'id': doc.toString(),
          'typeId': doc.toString(),
          'icon': doc == 'photo'
              ? Icons.photo_camera
              : (doc == 'proof_of_address' ? Icons.home : Icons.badge),
          'title': doc == 'proof_of_address'
                        ? 'Justificatif de domicile'
              : (doc == 'salary_slip' ? 'Bulletin de salaire' : (doc == 'photo' ? 'Photo d\'identité (Selfie)' : 'Document')),
          'subtitle': doc == 'proof_of_address'
                ? 'Facture de moins de 3 mois'
              : (doc == 'photo' ? 'Photo récente format identité' : 'Document'),
          'required': isRequired,
          'uploaded': false,
        });
      }
    }
    
    // Si aucun document n'a été trouvé, utiliser le fallback local avec documents requis
    if (documents.isEmpty) {
      documents.addAll([
        {
          'id': 'identity',
          'typeId': null,
          'icon': Icons.badge,
          'title': 'Pièce d\'identité',
          'subtitle': 'CNI, Passeport ou Carte d\'identité',
          'required': true,
          'uploaded': false,
          'isIdentity': true,
        },
        {
          'id': 'photo',
          'typeId': null,
          'icon': Icons.photo_camera,
          'title': 'Photo d\'identité (Selfie)',
          'subtitle': 'Photo récente format identité',
          'required': true,
          'uploaded': false,
        },
        {
          'id': 'address_proof',
          'typeId': null,
          'icon': Icons.home,
          'title': 'Justificatif de domicile',
          'subtitle': 'Facture de moins de 3 mois',
          'required': true,
          'uploaded': false,
        },
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents requis',
          style: AppTypography.headline4.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: AppSpacing.spacing3),
        
        ...documents.map((doc) => _buildDocumentItem(doc)).toList(),
      ],
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> doc) {
    final hasId = doc.containsKey('id');
    
    if (!hasId) {
      return Container(
        margin: EdgeInsets.only(bottom: AppSpacing.spacing2),
        padding: EdgeInsets.all(AppSpacing.spacing3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.spacing2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                doc['icon'] as IconData,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            SizedBox(width: AppSpacing.spacing3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doc['title'] as String,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (doc['required'] == true)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'REQUIS',
                            style: AppTypography.bodyXSmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    doc['subtitle'] as String,
                    style: AppTypography.bodySmall.copyWith(
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

    final uploaded = doc.containsKey('uploaded') && doc['uploaded'] == true;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentUploadScreen(
                documentId: doc['id'] as String,
                documentTitle: doc['title'] as String,
                documentSubtitle: doc['subtitle'] as String,
                documentIcon: doc['icon'] as IconData,
                documentTypeId: (doc['typeId'] as String?),
              ),
            ),
          ).then((_) async {
            if (mounted) {
              // Recharger le statut du profil après l'upload
              await context.read<ProfileProvider>().loadProfileStatus();
              // Recharger aussi les documents requis au cas où
              await _loadRequiredDocs();
              // Forcer la reconstruction du widget
              if (mounted) {
                setState(() {});
              }
            }
          });
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.spacing2),
          padding: EdgeInsets.all(AppSpacing.spacing3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: uploaded ? AppColors.success : AppColors.gray200,
              width: uploaded ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.spacing2),
                decoration: BoxDecoration(
                  color: uploaded 
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  doc['icon'] as IconData,
                  color: uploaded ? AppColors.success : AppColors.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.spacing3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doc['title'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: uploaded ? AppColors.success : null,
                            ),
                          ),
                        ),
                        if (uploaded)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '✓ TERMINÉ',
                              style: AppTypography.bodyXSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (doc['required'] == true)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'REQUIS',
                              style: AppTypography.bodyXSmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      doc['subtitle'] as String,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                uploaded ? Icons.check_circle : Icons.chevron_right,
                color: uploaded ? AppColors.success : AppColors.gray400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Liste des champs d'informations personnelles, cliquables pour édition
  Widget _buildPersonalFieldsList() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    final profile = user?.profile;

    String getProfileValue(String key) {
      if (profile == null) return 'Non renseigné';
      final value = profile[key];
      if (value == null) return 'Non renseigné';
      final str = value.toString().trim();
      return str.isEmpty ? 'Non renseigné' : str;
    }

    String getProfileNestedValue(String key, String nestedKey) {
      if (profile == null) return 'Non renseigné';
      final nested = profile[key];
      if (nested is Map && nested[nestedKey] != null) {
        final str = nested[nestedKey].toString().trim();
        return str.isEmpty ? 'Non renseigné' : str;
      }
      return 'Non renseigné';
    }

    final occupationName = getProfileValue('occupation');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations personnelles',
          style: AppTypography.headline4.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.spacing3),
        _buildPersonalFieldItem(
          icon: Icons.badge_outlined,
          label: 'Nom et prénom',
          value: (user?.fullName ?? '').trim().isEmpty
              ? 'Non renseigné'
              : user!.fullName,
          fieldKey: 'full_name',
          fieldType: FieldType.text,
          isRequired: true,
        ),
        _buildPersonalFieldItem(
          icon: Icons.cake_outlined,
          label: 'Date de naissance',
          value: getProfileValue('birth_date'),
          fieldKey: 'birth_date',
          fieldType: FieldType.date,
          isRequired: true,
        ),
        _buildPersonalFieldItem(
          icon: Icons.flag_outlined,
          label: 'Nationalité',
          value: getProfileNestedValue('nationality', 'name'),
          fieldKey: 'nationality',
          fieldType: FieldType.select,
          isRequired: true,
        ),
        _buildPersonalFieldItem(
          icon: Icons.work_outline,
          label: 'Situation pro',
          value: getProfileValue('occupation'),
          fieldKey: 'occupation',
          fieldType: FieldType.select,
          options: const [
            'Salarié',
            'Indépendant',
            'Étudiant',
            'Sans emploi',
            'Retraité',
            'Entrepreneur',
          ],
          isRequired: true,
        ),
        if (occupationName == 'Salarié')
          _buildPersonalFieldItem(
            icon: Icons.business_outlined,
            label: 'Employeur',
            value: getProfileValue('employer'),
            fieldKey: 'employer',
            fieldType: FieldType.text,
          ),
        _buildPersonalFieldItem(
          icon: Icons.phone_outlined,
          label: 'Téléphone',
          value: (user?.phone ?? '').trim().isEmpty
              ? 'Non renseigné'
              : user!.phone!,
          fieldKey: 'phone',
          fieldType: FieldType.phone,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildPersonalFieldItem({
    required IconData icon,
    required String label,
    required String value,
    required String fieldKey,
    required FieldType fieldType,
    List<String>? options,
    bool isRequired = false,
  }) {
    final isCompleted = value != 'Non renseigné';
    final Color activeColor = AppColors.success;
    final Color inactiveColor = AppColors.gray600;
    final Color inactiveBg = AppColors.gray100;
    final Color inactiveBorder = AppColors.gray300;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileFieldScreen(
                fieldKey: fieldKey,
                label: label,
                initialValue: isCompleted ? value : null,
                fieldType: fieldType,
                options: options,
              ),
            ),
          );
          // Refresh user and profile status, then rebuild to reflect values immediately
          final authProvider = context.read<AuthProvider>();
          await authProvider.refreshUser();
          await context.read<ProfileProvider>().loadProfileStatus();
          if (mounted) setState(() {});
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.spacing2),
          padding: EdgeInsets.all(AppSpacing.spacing3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isCompleted ? activeColor.withOpacity(0.3) : inactiveBorder,
              width: isCompleted ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.spacing2),
                decoration: BoxDecoration(
                  color: isCompleted ? activeColor.withOpacity(0.1) : inactiveBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: isCompleted ? activeColor : inactiveColor,
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.spacing3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  label,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isRequired && !isCompleted) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.gray100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'REQUIS',
                                    style: AppTypography.bodyXSmall.copyWith(
                                      color: AppColors.gray600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCompleted ? activeColor.withOpacity(0.1) : inactiveBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCompleted ? 'COMPLÉTÉ' : 'À COMPLÉTER',
                            style: AppTypography.bodyXSmall.copyWith(
                              color: isCompleted ? activeColor : inactiveColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacing1),
                    Text(
                      value,
                      style: AppTypography.bodySmall.copyWith(
                        color: isCompleted 
                          ? AppColors.textPrimaryLight 
                          : AppColors.textSecondaryLight,
                        fontStyle: isCompleted ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCompleted ? Icons.check_circle : Icons.edit_outlined,
                color: isCompleted ? activeColor : inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  Widget _buildAddressInfo() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    final Map<String, dynamic>? profile = (user?.profile is Map)
        ? user!.profile as Map<String, dynamic>
        : null;

    String getProfileValue(String key) {
      if (profile == null) return 'Non renseigné';
      final value = profile[key];
      if (value == null) return 'Non renseigné';
      final str = value.toString().trim();
      return str.isEmpty ? 'Non renseigné' : str;
    }

    final occupationName = getProfileValue('occupation');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adresse',
          style: AppTypography.headline4.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.spacing3),

        _buildPersonalFieldItem(
          icon: Icons.home_outlined,
          label: 'Adresse complète',
          value: getProfileValue('address'),
          fieldKey: 'address',
          fieldType: FieldType.text,
        ),
        _buildPersonalFieldItem(
          icon: Icons.location_city_outlined,
          label: 'Ville',
          value: getProfileValue('city'),
          fieldKey: 'city',
          fieldType: FieldType.text,
        ),
        _buildPersonalFieldItem(
          icon: Icons.local_post_office_outlined,
          label: 'Code postal',
          value: getProfileValue('postal_code'),
          fieldKey: 'postal_code',
          fieldType: FieldType.text,
        ),
        /*_buildPersonalFieldItem(
          icon: Icons.flag_circle_outlined,
          label: 'Pays de résidence',
          value: (() {
            final c = profile?['country'];
            if (c is Map && c['name'] != null && c['name'].toString().trim().isNotEmpty) {
              return c['name'].toString();
            }
            return 'Non renseigné';
          })(),
          fieldKey: 'country',
          fieldType: FieldType.select,
        ),*/
      ],
    );
  }

  Widget _buildInfoCard({required String title, required List<String> items}) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              SizedBox(width: AppSpacing.spacing2),
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.spacing3),
          
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.spacing2),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppSpacing.spacing2),
                Expanded(
                  child: Text(
                    item,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == _steps.length - 1;
    final currentStepId = _steps[_currentStep].id;
    // Utiliser watch pour écouter les changements du ProfileProvider
    final profileProvider = context.watch<ProfileProvider>();
    
    // Permettre la navigation entre les étapes (pas de blocage)
    bool canProceed = true;
    if (currentStepId == 'personal') {
      // Pour l'étape personnelle, on peut toujours continuer (l'utilisateur peut revenir)
      canProceed = true;
    } else if (currentStepId == 'documents') {
      // Pour l'étape documents, on peut toujours continuer (l'utilisateur peut revenir)
      canProceed = true;
    }
    
    // Pour le bouton "Terminer", vérifier que TOUT est complet (champs + documents)
    bool canCompleteKyc = false;
    if (isLastStep) {
      // Vérifier les champs requis
      final hasAllFields = profileProvider.missingFields.isEmpty;
      
      // Vérifier les documents requis
      final hasIdentityDoc = _isIdCardUploaded(profileProvider);
      final hasPhoto = _isPhotoUploaded(profileProvider);
      final hasAddressProof = _isAddressProofUploaded(profileProvider);
      
      canCompleteKyc = hasAllFields && hasIdentityDoc && hasPhoto && hasAddressProof;
      
      if (!canCompleteKyc) {
        print('🔐 _buildNavigationButtons: canCompleteKyc = false');
        print('  - hasAllFields: $hasAllFields');
        print('  - hasIdentityDoc: $hasIdentityDoc');
        print('  - hasPhoto: $hasPhoto');
        print('  - hasAddressProof: $hasAddressProof');
        print('  - missingFields: ${profileProvider.missingFields}');
      }
    }
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton Précédent
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: Icon(Icons.arrow_back),
                label: Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimaryLight,
                  side: BorderSide(color: AppColors.gray300),
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.spacing2),
          ],
          
          // Bouton Suivant/Terminer
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton.icon(
              onPressed: isLastStep 
                  ? (canCompleteKyc ? _completeKyc : null)
                  : (canProceed ? _nextStep : null),
              icon: Icon(isLastStep ? Icons.check_circle : Icons.arrow_forward),
              label: Text(isLastStep ? 'Terminer' : 'Continuer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep ? AppColors.success : AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.spacing4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 64,
              ),
            ),
            
            SizedBox(height: AppSpacing.spacing4),
            
            Text(
              'Vérification terminée !',
              style: AppTypography.headline3.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: AppSpacing.spacing2),
            
            Text(
              'Votre profil est maintenant complet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Modèle pour les étapes KYC
class KycStep {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final String route;

  KycStep({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });
}
