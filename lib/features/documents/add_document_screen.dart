import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  final _expirationDateController = TextEditingController();
  
  String _selectedDocumentType = 'CNI';
  String _selectedSource = 'Camera';
  
  final List<String> _documentTypes = [
    'CNI',
    'Passeport',
    'Permis de conduire',
    'Justificatif de domicile',
    'Certificat de naissance',
    'Diplôme',
    'Autre'
  ];
  
  final List<String> _sourceTypes = [
    'Camera',
    'Galerie',
    'Scanner',
    'Fichier'
  ];

  @override
  void dispose() {
    _documentNumberController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildDocumentPreview(),
                  const SizedBox(height: AppSpacing.spacing4),
                  _buildDocumentTypeSection(),
                  const SizedBox(height: AppSpacing.spacing4),
                  _buildDocumentInfoSection(),
                  const SizedBox(height: AppSpacing.spacing4),
                  _buildSourceSection(),
                  const SizedBox(height: AppSpacing.spacing8),
                  _buildActionButtons(),
                  const SizedBox(height: AppSpacing.spacing8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AppBar avec effet de parallaxe
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
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

      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // Espace pour l'AppBar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.upload_file,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing2),
                Text(
                  'Nouveau document',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Aperçu du document
  Widget _buildDocumentPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4, vertical: AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getDocumentTypeColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: _getDocumentTypeColor().withValues(alpha: 0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              _getDocumentTypeIcon(),
              size: 30,
              color: _getDocumentTypeColor(),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDocumentType,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing1),
                Text(
                  'Document à ajouter',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing2,
                    vertical: AppSpacing.spacing1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'En cours d\'ajout',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section type de document
  Widget _buildDocumentTypeSection() {
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
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                'Type de document',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing3),
          DropdownButtonFormField<String>(
            initialValue: _selectedDocumentType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing3,
                vertical: AppSpacing.spacing3,
              ),
              filled: true,
              fillColor: AppColors.gray50,
            ),
            items: _documentTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      _getDocumentTypeIconForType(type),
                      size: 20,
                      color: AppColors.gray600,
                    ),
                    const SizedBox(width: AppSpacing.spacing2),
                    Text(type),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDocumentType = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Section informations du document
  Widget _buildDocumentInfoSection() {
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
            spreadRadius: 0,
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
                size: 20,
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                'Informations du document',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          
          // Numéro du document
          _buildInputField(
            controller: _documentNumberController,
            label: 'Numéro du document',
            hint: 'Entrez le numéro du document',
            icon: Icons.badge_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le numéro du document';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.spacing4),
          
          // Date d'expiration
          _buildDateField(),
        ],
      ),
    );
  }

  /// Section source du document
  Widget _buildSourceSection() {
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
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.source,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                'Source du document',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing3),
          
          // Sélection de la source
          _buildSourceSelector(),
          const SizedBox(height: AppSpacing.spacing4),
          
          // Zone de capture/upload
          _buildCaptureZone(),
        ],
      ),
    );
  }

  /// Zone de capture/upload
  Widget _buildCaptureZone() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.gray300,
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: _handleDocumentCapture,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getSourceIcon(_selectedSource) == Icons.camera_alt 
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(
                _getSourceIcon(_selectedSource),
                size: 30,
                color: _getSourceIcon(_selectedSource) == Icons.camera_alt 
                    ? AppColors.primary
                    : AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing3),
            Text(
              _getCaptureText(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray700,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing1),
            Text(
              'Appuyez pour ${_getActionText()}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Boutons d'action
  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gray600,
                side: BorderSide(color: AppColors.gray300),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing3),
          Expanded(
            child: ElevatedButton(
              onPressed: _submitDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                elevation: 2,
              ),
              child: const Text('Ajouter le document'),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtenir l'icône du type de document pour le dropdown
  IconData _getDocumentTypeIconForType(String type) {
    switch (type) {
      case 'CNI':
        return Icons.credit_card;
      case 'Passeport':
        return Icons.description;
      case 'Permis de conduire':
        return Icons.drive_eta;
      case 'Justificatif de domicile':
        return Icons.home;
      case 'Certificat de naissance':
        return Icons.child_care;
      case 'Diplôme':
        return Icons.school;
      default:
        return Icons.description;
    }
  }

  /// Champ de saisie personnalisé
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.gray500,
        ),
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing3,
          vertical: AppSpacing.spacing3,
        ),
      ),
      validator: validator,
    );
  }

  /// Champ de date personnalisé
  Widget _buildDateField() {
    return TextFormField(
      controller: _expirationDateController,
      decoration: InputDecoration(
        labelText: 'Date d\'expiration',
        hintText: 'JJ/MM/AAAA',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(
          Icons.calendar_today,
          color: AppColors.gray500,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.event,
            color: AppColors.gray500,
          ),
          onPressed: _selectExpirationDate,
        ),
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing3,
          vertical: AppSpacing.spacing3,
        ),
      ),
      readOnly: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner la date d\'expiration';
        }
        return null;
      },
    );
  }

  /// Sélecteur de source
  Widget _buildSourceSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing2),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: _sourceTypes.map((source) {
          final isSelected = _selectedSource == source;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSource = source;
                });
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.spacing2,
                  horizontal: AppSpacing.spacing2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getSourceIcon(source),
                      size: 20,
                      color: isSelected ? Colors.white : AppColors.gray600,
                    ),
                    const SizedBox(height: AppSpacing.spacing1),
                    Text(
                      source,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? Colors.white : AppColors.gray600,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Obtenir l'icône du type de document
  IconData _getDocumentTypeIcon() {
    return _getDocumentTypeIconForType(_selectedDocumentType);
  }

  /// Obtenir la couleur du type de document
  Color _getDocumentTypeColor() {
    switch (_selectedDocumentType) {
      case 'CNI':
        return const Color(0xFF4CAF50);
      case 'Passeport':
        return const Color(0xFF2196F3);
      case 'Permis de conduire':
        return const Color(0xFFFF9800);
      case 'Justificatif de domicile':
        return const Color(0xFF9C27B0);
      case 'Certificat de naissance':
        return const Color(0xFFE91E63);
      case 'Diplôme':
        return const Color(0xFF795548);
      default:
        return AppColors.primary;
    }
  }

  /// Obtenir l'icône de la source
  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'Camera':
        return Icons.camera_alt;
      case 'Galerie':
        return Icons.photo_library;
      case 'Scanner':
        return Icons.scanner;
      case 'Fichier':
        return Icons.attach_file;
      default:
        return Icons.camera_alt;
    }
  }

  /// Obtenir le texte de capture
  String _getCaptureText() {
    switch (_selectedSource) {
      case 'Camera':
        return 'Prendre une photo';
      case 'Galerie':
        return 'Sélectionner depuis la galerie';
      case 'Scanner':
        return 'Scanner le document';
      case 'Fichier':
        return 'Sélectionner un fichier';
      default:
        return 'Prendre une photo';
    }
  }

  /// Obtenir le texte d'action
  String _getActionText() {
    switch (_selectedSource) {
      case 'Camera':
        return 'prendre une photo';
      case 'Galerie':
        return 'sélectionner';
      case 'Scanner':
        return 'scanner';
      case 'Fichier':
        return 'sélectionner';
      default:
        return 'prendre une photo';
    }
  }

  /// Sélectionner la date d'expiration
  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 ans
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _expirationDateController.text = 
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  /// Gérer la capture du document
  void _handleDocumentCapture() {
    // Vibration haptique
    HapticFeedback.lightImpact();
    
    // Simulation de capture
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.spacing4),
            Text(
              _getCaptureText(),
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
    
    // Simuler le processus de capture
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document ${_getCaptureText().toLowerCase()} avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  /// Soumettre le document
  void _submitDocument() {
    if (_formKey.currentState!.validate()) {
      // Vibration haptique
      HapticFeedback.mediumImpact();
      
      // Simulation de soumission
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.spacing4),
              const Text('Ajout du document en cours...'),
            ],
          ),
        ),
      );
      
      // Simuler le processus d'ajout
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context); // Fermer le dialog de chargement
          Navigator.pop(context); // Retourner à la liste des documents
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document $_selectedDocumentType ajouté avec succès'),
              backgroundColor: AppColors.success,
              action: SnackBarAction(
                label: 'Voir',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Naviguer vers le document ajouté
                },
              ),
            ),
          );
        }
      });
    }
  }
}
