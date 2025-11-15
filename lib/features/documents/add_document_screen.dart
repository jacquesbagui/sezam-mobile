import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';
import 'package:sezam/core/services/document_service.dart';
import 'package:sezam/core/providers/document_provider.dart';
import 'package:sezam/core/services/app_event_service.dart';
import 'package:sezam/core/services/exceptions.dart';
import 'package:sezam/core/services/api_client.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  final _expirationDateController = TextEditingController();
  
  final ImagePicker _imagePicker = ImagePicker();
  final DocumentService _documentService = DocumentService();
  
  // État
  String? _selectedDocumentTypeId;
  String _selectedDocumentTypeName = '';
  String _selectedSource = 'Camera';
  File? _selectedFile;
  DateTime? _expiryDate;
  bool _isLoading = false;
  bool _isUploading = false;
  List<Map<String, dynamic>> _documentTypes = [];
  String? _errorMessage;

  final List<String> _sourceTypes = [
    'Camera',
    'Galerie',
    'Fichier',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocumentTypes();
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  /// Charger les types de documents depuis l'API
  Future<void> _loadDocumentTypes() async {
    if (_isLoading) return; // Éviter les appels multiples
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requiredDocs = await _documentService.getRequiredDocuments();
      
      if (!mounted) return;
      
      print('📋 Documents reçus: ${requiredDocs.length}');
      
      // Filtrer et valider les documents
      final validDocs = <Map<String, dynamic>>[];
      for (final doc in requiredDocs) {
        try {
          final id = doc['id'];
          final name = doc['name'] ?? doc['display_name'];
          
          if (id != null && name != null) {
            final idStr = id.toString();
            if (idStr.isNotEmpty) {
              validDocs.add({
                'id': idStr,
                'name': name.toString(),
                'display_name': doc['display_name']?.toString() ?? name.toString(),
                'description': doc['description']?.toString(),
              });
            }
          }
        } catch (e) {
          print('⚠️ Erreur parsing doc: $e, doc: $doc');
        }
      }
      
      print('✅ Documents valides: ${validDocs.length}');
      
      if (!mounted) {
        print('⚠️ Widget non monté, arrêt du chargement');
        return;
      }
      
      print('🔄 Mise à jour du state...');
      setState(() {
        _documentTypes = validDocs;
        if (_documentTypes.isNotEmpty) {
          final firstDoc = _documentTypes.first;
          _selectedDocumentTypeId = firstDoc['id'] as String;
          _selectedDocumentTypeName = firstDoc['display_name'] as String? ?? 
                                     firstDoc['name'] as String? ?? 'Document';
          print('📌 Type sélectionné: $_selectedDocumentTypeName (id: $_selectedDocumentTypeId)');
        } else {
          _selectedDocumentTypeId = null;
          _selectedDocumentTypeName = '';
        }
        _isLoading = false;
        print('✅ _isLoading mis à false');
      });
      print('✅ setState terminé');
    } catch (e, stackTrace) {
      print('❌ Erreur _loadDocumentTypes: $e');
      print('📋 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des types de documents';
          _isLoading = false;
        });
      }
    }
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
                  if (_errorMessage != null) _buildErrorMessage(),
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

  /// Message d'erreur
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.spacing3),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
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
                const SizedBox(height: 40),
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
      child: Column(
        children: [
          // Aperçu du fichier si sélectionné
          if (_selectedFile != null) ...[
            _buildFilePreview(),
            const SizedBox(height: AppSpacing.spacing4),
          ],
          
          // Informations du document
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getDocumentTypeColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
                      _selectedDocumentTypeName.isNotEmpty 
                          ? _selectedDocumentTypeName 
                          : 'Sélectionnez un type',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing1),
                    Text(
                      _selectedFile != null 
                          ? 'Fichier sélectionné' 
                          : 'Aucun fichier sélectionné',
                      style: AppTypography.bodySmall.copyWith(
                        color: _selectedFile != null 
                            ? AppColors.success 
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Aperçu du fichier sélectionné
  Widget _buildFilePreview() {
    final isImage = _selectedFile!.path.toLowerCase().endsWith('.jpg') ||
                    _selectedFile!.path.toLowerCase().endsWith('.jpeg') ||
                    _selectedFile!.path.toLowerCase().endsWith('.png');
    
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.gray300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: isImage
            ? Image.file(
                _selectedFile!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFileIcon();
                },
              )
            : _buildFileIcon(),
      ),
    );
  }

  Widget _buildFileIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: AppSpacing.spacing2),
          Text(
            _selectedFile!.path.split('/').last,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
          Builder(
            builder: (context) {
              // Debug: afficher l'état actuel
              if (_isLoading) {
                print('🔄 Affichage du loader (isLoading: $_isLoading, types: ${_documentTypes.length})');
                return const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (_documentTypes.isEmpty) {
                print('📋 Aucun type de document (isLoading: $_isLoading, types: ${_documentTypes.length})');
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.spacing4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                      const SizedBox(width: AppSpacing.spacing2),
                      Expanded(
                        child: Text(
                          'Aucun type de document disponible',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // S'assurer que la valeur sélectionnée existe dans la liste
              final validValue = _selectedDocumentTypeId != null &&
                  _documentTypes.any((doc) => doc['id'] == _selectedDocumentTypeId)
                  ? _selectedDocumentTypeId
                  : (_documentTypes.isNotEmpty ? _documentTypes.first['id'] as String : null);
              
              print('📋 Affichage dropdown (isLoading: $_isLoading, types: ${_documentTypes.length}, validValue: $validValue)');
              
              return DropdownButtonFormField<String>(
                key: ValueKey('doc_type_${_documentTypes.length}_$validValue'),
                value: validValue,
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
                items: _documentTypes
                    .where((type) {
                      final id = type['id'];
                      return id != null && id.toString().isNotEmpty;
                    })
                    .map((type) {
                      final id = type['id'] as String;
                      final name = type['display_name'] as String? ?? 
                                  type['name'] as String? ?? 'Document';
                      
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Row(
                          children: [
                            Icon(
                              _getDocumentTypeIconForName(name),
                              size: 20,
                              color: AppColors.gray600,
                            ),
                            const SizedBox(width: AppSpacing.spacing2),
                            Expanded(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  
                  setState(() {
                    _selectedDocumentTypeId = value;
                    try {
                      final selectedType = _documentTypes.firstWhere(
                        (type) => type['id'] == value,
                      );
                      _selectedDocumentTypeName = selectedType['display_name'] as String? ?? 
                                                  selectedType['name'] as String? ?? 'Document';
                    } catch (e) {
                      print('⚠️ Erreur lors de la sélection du type: $e');
                      _selectedDocumentTypeName = 'Document';
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un type de document';
                  }
                  return null;
                },
              );
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
          
          // Numéro du document (optionnel)
          _buildInputField(
            controller: _documentNumberController,
            label: 'Numéro du document (optionnel)',
            hint: 'Entrez le numéro du document',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: AppSpacing.spacing4),
          
          // Date d'expiration (optionnel)
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
      height: _selectedFile != null ? 200 : 160,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _selectedFile != null 
              ? AppColors.success 
              : AppColors.gray300,
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: _selectedFile != null
          ? Stack(
              children: [
                _buildFilePreview(),
                Positioned(
                  top: AppSpacing.spacing2,
                  right: AppSpacing.spacing2,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(AppSpacing.spacing1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                      });
                    },
                  ),
                ),
              ],
            )
          : InkWell(
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
              onPressed: _isUploading ? null : () {
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
            flex: 2,
            child: ElevatedButton(
              onPressed: (_isUploading || _selectedFile == null) ? null : _submitDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                elevation: 2,
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Ajouter le document'),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtenir l'icône du type de document pour le dropdown
  IconData _getDocumentTypeIconForName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('identité') || lowerName.contains('cni') || lowerName.contains('id_card')) {
      return Icons.credit_card;
    } else if (lowerName.contains('passeport') || lowerName.contains('passport')) {
      return Icons.description;
    } else if (lowerName.contains('permis') || lowerName.contains('licence') || lowerName.contains('driving')) {
      return Icons.drive_eta;
    } else if (lowerName.contains('domicile') || lowerName.contains('address') || lowerName.contains('proof')) {
      return Icons.home;
    } else if (lowerName.contains('naissance') || lowerName.contains('birth')) {
      return Icons.child_care;
    } else if (lowerName.contains('diplôme') || lowerName.contains('diploma')) {
      return Icons.school;
    } else {
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
        labelText: 'Date d\'expiration (optionnel)',
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
    return _getDocumentTypeIconForName(_selectedDocumentTypeName);
  }

  /// Obtenir la couleur du type de document
  Color _getDocumentTypeColor() {
    final lowerName = _selectedDocumentTypeName.toLowerCase();
    if (lowerName.contains('identité') || lowerName.contains('cni') || lowerName.contains('id_card')) {
      return const Color(0xFF4CAF50);
    } else if (lowerName.contains('passeport') || lowerName.contains('passport')) {
      return const Color(0xFF2196F3);
    } else if (lowerName.contains('permis') || lowerName.contains('licence') || lowerName.contains('driving')) {
      return const Color(0xFFFF9800);
    } else if (lowerName.contains('domicile') || lowerName.contains('address') || lowerName.contains('proof')) {
      return const Color(0xFF9C27B0);
    } else if (lowerName.contains('naissance') || lowerName.contains('birth')) {
      return const Color(0xFFE91E63);
    } else if (lowerName.contains('diplôme') || lowerName.contains('diploma')) {
      return const Color(0xFF795548);
    } else {
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
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
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
        _expiryDate = picked;
        _expirationDateController.text = 
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  /// Gérer la capture du document
  Future<void> _handleDocumentCapture() async {
    HapticFeedback.lightImpact();
    
    try {
      File? file;
      
      switch (_selectedSource) {
        case 'Camera':
          file = await _takePhoto();
          break;
        case 'Galerie':
          file = await _pickImageFromGallery();
          break;
        case 'Fichier':
          file = await _pickFile();
          break;
      }
      
      if (file != null && mounted) {
        setState(() {
          _selectedFile = file;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier sélectionné: ${file.path.split('/').last}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
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
    }
  }

  /// Prendre une photo
  Future<File?> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la prise de photo: $e');
    }
  }

  /// Sélectionner une image depuis la galerie
  Future<File?> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la sélection depuis la galerie: $e');
    }
  }

  /// Sélectionner un fichier
  Future<File?> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la sélection du fichier: $e');
    }
  }

  /// Soumettre le document
  Future<void> _submitDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un fichier'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedDocumentTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de document'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });
    
    // Afficher un dialog de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.spacing4),
              Text(
                'Upload du document en cours...',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
    
    try {
      final uploadedDocument = await _documentService.uploadDocument(
        documentTypeId: _selectedDocumentTypeId!,
        filePath: _selectedFile!.path,
        documentNumber: _documentNumberController.text.isNotEmpty 
            ? _documentNumberController.text 
            : null,
        expiryDate: _expiryDate,
      );
      
      // Émettre un événement pour déclencher le rafraîchissement
      AppEventService.instance.emit(AppEventType.documentUploaded);
      
      // Rafraîchir la liste des documents
      if (mounted) {
        final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
        documentProvider.loadDocuments();
      }
      
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        
        setState(() {
          _isUploading = false;
        });
        
        // Retourner à la liste des documents
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document ${uploadedDocument.displayName} ajouté avec succès'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Naviguer vers le document ajouté si nécessaire
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        
        setState(() {
          _isUploading = false;
        });
        
        String errorMessage = 'Erreur lors de l\'upload du document';
        if (e is AuthenticationException) {
          errorMessage = e.message;
        } else if (e is ApiException) {
          errorMessage = e.message;
        } else {
          errorMessage = e.toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
