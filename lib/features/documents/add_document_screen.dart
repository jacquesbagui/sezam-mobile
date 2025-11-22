import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';
import 'package:sezam/core/services/document_service.dart';
import 'package:sezam/core/services/exceptions.dart';
import 'package:sezam/core/services/api_client.dart';
import 'package:sezam/core/services/app_event_service.dart';

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
  List<File> _selectedFiles = [];
  DateTime? _expiryDate;
  bool _isUploading = false;

  final List<String> _sourceTypes = ['Camera', 'Galerie', 'Fichier'];

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
                  _DocumentTypeSelector(
                    documentService: _documentService,
                    selectedTypeId: _selectedDocumentTypeId,
                    onTypeSelected: (typeId, typeName) {
                      setState(() {
                        _selectedDocumentTypeId = typeId;
                        _selectedDocumentTypeName = typeName;
                      });
                    },
                  ),
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
        onPressed: () => Navigator.pop(context),
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
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: AppSpacing.spacing4,
      ),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
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
      child: Column(
        children: [
          if (_selectedFiles.isNotEmpty) ...[
            _buildFilesPreview(),
            const SizedBox(height: AppSpacing.spacing4),
          ],
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
                      _selectedFiles.isEmpty
                          ? 'Aucun fichier sélectionné'
                          : _selectedFiles.length == 1
                              ? '1 fichier sélectionné'
                              : '${_selectedFiles.length} fichiers sélectionnés',
                      style: AppTypography.bodySmall.copyWith(
                        color: _selectedFiles.isNotEmpty
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

  /// Aperçu des fichiers sélectionnés
  Widget _buildFilesPreview() {
    if (_selectedFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedFiles.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacing2),
            child: Text(
              '${_selectedFiles.length} fichiers sélectionnés',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        // Si un seul fichier, utiliser un widget fixe au lieu d'un ListView
        _selectedFiles.length == 1
            ? ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 200,
                  minHeight: 150,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _buildFilePreviewCard(_selectedFiles[0], 0),
                ),
              )
            : SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    return _buildFilePreviewCard(_selectedFiles[index], index);
                  },
                ),
              ),
      ],
    );
  }

  /// Carte d'aperçu d'un fichier
  Widget _buildFilePreviewCard(File file, int index) {
    final isImage = _isImageFile(file);
    // Utiliser une largeur fixe pour éviter les problèmes avec ListView
    final cardWidth = _selectedFiles.length == 1 
        ? null // null signifie qu'on utilise toute la largeur disponible (dans un SizedBox)
        : 150.0;
    
    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(
        right: index < _selectedFiles.length - 1 ? AppSpacing.spacing2 : 0,
      ),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.gray300),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: isImage
                ? _buildImageThumbnail(file)
                : _buildFileIcon(file),
          ),
          Positioned(
            top: AppSpacing.spacing1,
            right: AppSpacing.spacing1,
            child: _buildRemoveButton(index),
          ),
        ],
      ),
    );
  }

  /// Vérifier si le fichier est une image
  bool _isImageFile(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png');
  }

  /// Miniature d'image sécurisée
  Widget _buildImageThumbnail(File file) {
    return FutureBuilder<bool>(
      future: _checkFileExists(file),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPlaceholder();
        }

        if (!snapshot.hasData || !snapshot.data!) {
          return _buildFileIcon(file);
        }

        return _buildImageWidget(file);
      },
    );
  }

  /// Vérifier l'existence du fichier de manière asynchrone
  Future<bool> _checkFileExists(File file) async {
    try {
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Widget d'image avec gestion d'erreur
  Widget _buildImageWidget(File file) {
    return Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _buildFileIcon(file),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null && !wasSynchronouslyLoaded) {
          return _buildLoadingPlaceholder();
        }
        return child;
      },
      cacheWidth: 300,
      cacheHeight: 300,
      filterQuality: FilterQuality.low,
    );
  }

  /// Placeholder de chargement
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.gray100,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// Icône de fichier
  Widget _buildFileIcon(File file) {
    return Container(
      color: AppColors.gray100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file,
              size: 48,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSpacing.spacing1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing2),
              child: Text(
                _getFileName(file),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtenir le nom du fichier
  String _getFileName(File file) {
    return file.path.split('/').last;
  }

  /// Bouton de suppression
  Widget _buildRemoveButton(int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFiles.removeAt(index);
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
            size: 16,
          ),
        ),
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
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
          _buildInputField(
            controller: _documentNumberController,
            label: 'Numéro du document (optionnel)',
            hint: 'Entrez le numéro du document',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: AppSpacing.spacing4),
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.source, color: AppColors.primary, size: 20),
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
          _buildSourceSelector(),
          const SizedBox(height: AppSpacing.spacing4),
          _buildCaptureZone(),
        ],
      ),
    );
  }

  /// Zone de capture/upload
  Widget _buildCaptureZone() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _selectedFiles.isNotEmpty
              ? AppColors.success
              : AppColors.gray300,
          width: 2,
        ),
      ),
      child: _selectedFiles.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Afficher seulement un message et le bouton pour ajouter plus de fichiers
                  // Les fichiers sont déjà affichés dans _buildDocumentPreview()
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.spacing3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.spacing2),
                        Expanded(
                          child: Text(
                            _selectedFiles.length == 1
                                ? '1 fichier sélectionné'
                                : '${_selectedFiles.length} fichiers sélectionnés',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing2),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleDocumentCapture,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter un autre fichier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : InkWell(
              onTap: _handleDocumentCapture,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                constraints: const BoxConstraints(minHeight: 160),
                padding: const EdgeInsets.all(AppSpacing.spacing4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: AppSpacing.spacing2),
                    Text(
                      'Vous pouvez ajouter plusieurs fichiers',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
              onPressed: _isUploading ? null : () => Navigator.pop(context),
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
              onPressed: (_isUploading || _selectedFiles.isEmpty)
                  ? null
                  : _submitDocument,
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
        prefixIcon: Icon(icon, color: AppColors.gray500),
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
        prefixIcon: Icon(Icons.calendar_today, color: AppColors.gray500),
        suffixIcon: IconButton(
          icon: Icon(Icons.event, color: AppColors.gray500),
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
              onTap: () => setState(() => _selectedSource = source),
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

  /// Gérer la capture du document
  Future<void> _handleDocumentCapture() async {
    if (!mounted) return;

    HapticFeedback.lightImpact();

    try {
      List<File> newFiles = [];

      switch (_selectedSource) {
        case 'Camera':
          final file = await _takePhoto();
          if (file != null) newFiles = [file];
          break;
        case 'Galerie':
          newFiles = await _pickImagesFromGallery();
          break;
        case 'Fichier':
          newFiles = await _pickFiles();
          break;
      }

      if (newFiles.isNotEmpty && mounted) {
        // Attendre un peu pour que les fichiers soient prêts
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        setState(() {
          _selectedFiles.addAll(newFiles);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newFiles.length == 1
                    ? 'Fichier ajouté: ${_getFileName(newFiles.first)}'
                    : '${newFiles.length} fichiers ajoutés',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
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
        final file = File(image.path);
        // Attendre que le fichier soit complètement écrit
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (await file.exists()) {
          return file;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la prise de photo: $e');
    }
  }

  /// Sélectionner plusieurs images depuis la galerie
  Future<List<File>> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      return images.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la sélection depuis la galerie: $e');
    }
  }

  /// Sélectionner plusieurs fichiers
  Future<List<File>> _pickFiles() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Erreur lors de la sélection des fichiers: $e');
    }
  }

  /// Soumettre le document
  Future<void> _submitDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFiles.isEmpty) {
      _showError('Veuillez sélectionner au moins un fichier');
      return;
    }

    if (_selectedDocumentTypeId == null) {
      _showError('Veuillez sélectionner un type de document');
      return;
    }

    // Vérifier que l'ID est un UUID valide
    if (_selectedDocumentTypeId!.length < 30 ||
        !_selectedDocumentTypeId!.contains('-')) {
      _showError('Type de document invalide. Veuillez réessayer.');
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() => _isUploading = true);

    // Afficher le dialog de chargement
    if (!mounted) return;
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
                _selectedFiles.length == 1
                    ? 'Upload du document en cours...'
                    : 'Upload de ${_selectedFiles.length} documents en cours...',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      int successCount = 0;
      int failureCount = 0;

      // Uploader chaque fichier
      for (int i = 0; i < _selectedFiles.length; i++) {
        if (!mounted) break;

        final file = _selectedFiles[i];

        try {
          if (!await file.exists()) {
            throw Exception('Fichier introuvable: ${_getFileName(file)}');
          }

          await _documentService.uploadDocument(
            documentTypeId: _selectedDocumentTypeId!,
            filePath: file.path,
            documentNumber: _documentNumberController.text.isNotEmpty && i == 0
                ? _documentNumberController.text
                : null,
            expiryDate: i == 0 ? _expiryDate : null,
          );

          successCount++;
        } catch (e) {
          failureCount++;
        }

        // Pause entre les uploads
        if (i < _selectedFiles.length - 1 && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Fermer le dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Attendre un peu
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      setState(() => _isUploading = false);

      // Retourner à la liste
      if (mounted) {
        Navigator.pop(context);
      }

      // Émettre l'événement après un délai
      if (successCount > 0) {
        await Future.delayed(const Duration(milliseconds: 1000));
        AppEventService.instance.emit(AppEventType.documentUploaded);
      }

      // Afficher le message de résultat
      if (mounted) {
        final message = failureCount == 0
            ? (successCount == 1
                ? 'Document ajouté avec succès'
                : '$successCount documents ajoutés avec succès')
            : (successCount > 0
                ? '$successCount document(s) ajouté(s), $failureCount échec(s)'
                : 'Erreur lors de l\'upload');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: failureCount == 0
                ? AppColors.success
                : (successCount > 0 ? AppColors.warning : AppColors.error),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Fermer le dialog
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      if (mounted) {
        setState(() => _isUploading = false);

        String errorMsg = 'Erreur lors de l\'upload';
        if (e is AuthenticationException) {
          errorMsg = e.message;
        } else if (e is ApiException) {
          errorMsg = e.message;
        } else {
          errorMsg = e.toString();
        }

        _showError(errorMsg);
      }
    }
  }

  /// Afficher une erreur
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Sélectionner la date d'expiration
  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _expirationDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  /// Obtenir l'icône du type de document
  IconData _getDocumentTypeIcon() {
    return _getDocumentTypeIconForName(_selectedDocumentTypeName);
  }

  /// Obtenir l'icône du type de document pour le dropdown
  IconData _getDocumentTypeIconForName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('identité') ||
        lowerName.contains('cni') ||
        lowerName.contains('id_card')) {
      return Icons.credit_card;
    } else if (lowerName.contains('passeport') ||
        lowerName.contains('passport')) {
      return Icons.description;
    } else if (lowerName.contains('permis') ||
        lowerName.contains('licence') ||
        lowerName.contains('driving')) {
      return Icons.drive_eta;
    } else if (lowerName.contains('domicile') ||
        lowerName.contains('address') ||
        lowerName.contains('proof')) {
      return Icons.home;
    } else if (lowerName.contains('naissance') ||
        lowerName.contains('birth')) {
      return Icons.child_care;
    } else if (lowerName.contains('diplôme') ||
        lowerName.contains('diploma')) {
      return Icons.school;
    }
    return Icons.description;
  }

  /// Obtenir la couleur du type de document
  Color _getDocumentTypeColor() {
    final lowerName = _selectedDocumentTypeName.toLowerCase();
    if (lowerName.contains('identité') ||
        lowerName.contains('cni') ||
        lowerName.contains('id_card')) {
      return const Color(0xFF4CAF50);
    } else if (lowerName.contains('passeport') ||
        lowerName.contains('passport')) {
      return const Color(0xFF2196F3);
    } else if (lowerName.contains('permis') ||
        lowerName.contains('licence') ||
        lowerName.contains('driving')) {
      return const Color(0xFFFF9800);
    } else if (lowerName.contains('domicile') ||
        lowerName.contains('address') ||
        lowerName.contains('proof')) {
      return const Color(0xFF9C27B0);
    } else if (lowerName.contains('naissance') ||
        lowerName.contains('birth')) {
      return const Color(0xFFE91E63);
    } else if (lowerName.contains('diplôme') ||
        lowerName.contains('diploma')) {
      return const Color(0xFF795548);
    }
    return AppColors.primary;
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
}

/// Widget séparé pour le sélecteur de type de document
class _DocumentTypeSelector extends StatefulWidget {
  final DocumentService documentService;
  final String? selectedTypeId;
  final Function(String typeId, String typeName) onTypeSelected;

  const _DocumentTypeSelector({
    required this.documentService,
    required this.selectedTypeId,
    required this.onTypeSelected,
  });

  @override
  State<_DocumentTypeSelector> createState() => _DocumentTypeSelectorState();
}

class _DocumentTypeSelectorState extends State<_DocumentTypeSelector> {
  static const List<_StaticDocumentType> _staticDocumentTypes = [
    _StaticDocumentType(
      name: 'identity_card',
      displayName: 'Carte d\'Identité',
      description: 'Carte nationale d\'identité (CNI)',
    ),
    _StaticDocumentType(
      name: 'passport',
      displayName: 'Passeport',
      description: 'Passeport',
    ),
    _StaticDocumentType(
      name: 'proof_of_address',
      displayName: 'Justificatif de Domicile',
      description: 'Justificatif de domicile',
    ),
    _StaticDocumentType(
      name: 'salary_slip',
      displayName: 'Bulletin de Salaire',
      description: 'Bulletin de salaire',
    ),
    _StaticDocumentType(
      name: 'driving_license',
      displayName: 'Permis de Conduire',
      description: 'Permis de conduire',
    ),
    _StaticDocumentType(
      name: 'birth_certificate',
      displayName: 'Acte de Naissance',
      description: 'Acte de naissance',
    ),
  ];

  late final Future<Map<String, String>> _typeIdMappingFuture;

  @override
  void initState() {
    super.initState();
    _typeIdMappingFuture = _loadTypeIdMapping();
  }

  Future<Map<String, String>> _loadTypeIdMapping() async {
    try {
      final rawDocs = await widget.documentService.getRequiredDocuments();
      final mapping = <String, String>{};

      for (final doc in rawDocs) {
        try {
          final id = doc['id']?.toString();
          final name = doc['name']?.toString();

          if (id != null &&
              name != null &&
              id.isNotEmpty &&
              name.isNotEmpty) {
            mapping[name] = id;
          }
        } catch (e) {
          continue;
        }
      }

      return mapping;
    } catch (e) {
      return {};
    }
  }

  Future<List<_DocumentType>> _getDocumentTypes() async {
    final mapping = await _typeIdMappingFuture;
    final Map<String, _DocumentType> uniqueTypes = {};

    for (final staticType in _staticDocumentTypes) {
      String? realId = mapping[staticType.name];

      if (realId == null && staticType.name == 'identity_card') {
        realId = mapping['id_card'];
      }

      if (realId != null &&
          realId.length >= 30 &&
          realId.contains('-') &&
          realId != staticType.name) {
        if (!uniqueTypes.containsKey(realId)) {
          uniqueTypes[realId] = _DocumentType(
            id: realId,
            name: staticType.name,
            displayName: staticType.displayName,
            description: staticType.description ?? '',
          );
        }
      }
    }

    return uniqueTypes.values.toList();
  }

  IconData _getDocumentTypeIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('carte') || lowerName.contains('identité')) {
      return Icons.badge_outlined;
    } else if (lowerName.contains('passeport')) {
      return Icons.airplane_ticket_outlined;
    } else if (lowerName.contains('domicile') || lowerName.contains('adresse')) {
      return Icons.home_outlined;
    } else if (lowerName.contains('salaire') || lowerName.contains('bulletin')) {
      return Icons.receipt_outlined;
    } else if (lowerName.contains('permis')) {
      return Icons.drive_eta_outlined;
    }
    return Icons.description_outlined;
  }

  void _showDocumentTypeSheet(
    BuildContext context,
    List<_DocumentType> documentTypes,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DocumentTypeSheet(
        documentTypes: documentTypes,
        selectedTypeId: widget.selectedTypeId,
        onTypeSelected: (typeId, typeName) {
          widget.onTypeSelected(typeId, typeName);
          Navigator.pop(context);
        },
        getDocumentTypeIcon: _getDocumentTypeIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.category, color: AppColors.primary, size: 20),
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
          FutureBuilder<List<_DocumentType>>(
            future: _getDocumentTypes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.spacing4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: AppSpacing.spacing2),
                      Expanded(
                        child: Text(
                          'Impossible de charger les types de documents',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final documentTypes = snapshot.data!;
              final selectedType = widget.selectedTypeId != null
                  ? documentTypes.firstWhere(
                      (type) => type.id == widget.selectedTypeId,
                      orElse: () => documentTypes.first,
                    )
                  : documentTypes.first;

              return InkWell(
                onTap: () => _showDocumentTypeSheet(context, documentTypes),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing3,
                    vertical: AppSpacing.spacing3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gray300),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    color: AppColors.gray50,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getDocumentTypeIcon(selectedType.displayName),
                        size: 20,
                        color: AppColors.gray600,
                      ),
                      const SizedBox(width: AppSpacing.spacing2),
                      Expanded(
                        child: Text(
                          selectedType.displayName,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.gray600,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DocumentType {
  final String id;
  final String name;
  final String displayName;
  final String? description;

  const _DocumentType({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
  });
}

class _StaticDocumentType {
  final String name;
  final String displayName;
  final String? description;

  const _StaticDocumentType({
    required this.name,
    required this.displayName,
    this.description,
  });
}

class _DocumentTypeSheet extends StatelessWidget {
  final List<_DocumentType> documentTypes;
  final String? selectedTypeId;
  final Function(String typeId, String typeName) onTypeSelected;
  final IconData Function(String name) getDocumentTypeIcon;

  const _DocumentTypeSheet({
    required this.documentTypes,
    required this.selectedTypeId,
    required this.onTypeSelected,
    required this.getDocumentTypeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.spacing3),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing4),
              child: Row(
                children: [
                  Icon(Icons.category, color: AppColors.primary, size: 24),
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
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppSpacing.spacing2),
                itemCount: documentTypes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.spacing1),
                itemBuilder: (context, index) {
                  final type = documentTypes[index];
                  final isSelected = type.id == selectedTypeId;

                  return InkWell(
                    onTap: () => onTypeSelected(type.id, type.displayName),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.spacing3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.spacing2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.gray100,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Icon(
                              getDocumentTypeIcon(type.displayName),
                              size: 20,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.gray600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.spacing3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.displayName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                if (type.description != null &&
                                    type.description!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    type.description!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondaryLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.spacing2),
          ],
        ),
      ),
    );
  }
}
