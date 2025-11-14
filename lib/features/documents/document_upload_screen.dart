import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/document_service.dart';
import '../../core/models/document_model.dart';
import '../../core/services/app_event_service.dart';

/// Écran pour uploader un document spécifique
class DocumentUploadScreen extends StatefulWidget {
  final String documentId;
  final String documentTitle;
  final String documentSubtitle;
  final IconData documentIcon;
  final String? documentTypeId;

  const DocumentUploadScreen({
    super.key,
    required this.documentId,
    required this.documentTitle,
    required this.documentSubtitle,
    required this.documentIcon,
    this.documentTypeId,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _hasDocument = false;
  String? _documentUrl;
  bool _isUploading = false;
  String? _existingDocumentId;
  final DocumentService _documentService = DocumentService();

  @override
  void initState() {
    super.initState();
    _checkExistingDocument();
  }

  Future<void> _checkExistingDocument() async {
    try {
      final docs = await _documentService.getDocuments();
      // Tenter d'identifier par type (selon le titre ou l'id transverse)
      DocumentModel? match;
      for (final d in docs) {
        final type = d.type;
        final name = (type != null ? (type.name.toLowerCase()) : '');
        if (name.contains(widget.documentId) || name.contains(widget.documentTitle.toLowerCase())) {
          match = d;
          break;
        }
      }
      if (mounted) {
        setState(() {
          _hasDocument = match != null;
          _existingDocumentId = match?.id;
          _documentUrl = match?.fileUrl;
        });
      }
    } catch (e) {
      // ignore silently
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        await _uploadDocument(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        await _uploadDocument(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withReadStream: false,
      );
      final path = result?.files.single.path;
      if (path != null) {
        await _uploadDocument(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _uploadDocument(String filePath) async {
    setState(() => _isUploading = true);

    try {
      // NOTE: Il faut fournir un document_type_id valide. Ici on tente un mapping simple.
      final documentTypeId = widget.documentTypeId ?? await _resolveDocumentTypeId();
      if (documentTypeId == null) {
        throw 'Type de document inconnu. Veuillez réessayer plus tard.';
      }

      final uploaded = await _documentService.uploadDocument(
        documentTypeId: documentTypeId,
        filePath: filePath,
      );
      
      // Émettre un événement pour déclencher le rafraîchissement
      AppEventService.instance.emit(AppEventType.documentUploaded);
      
      if (mounted) {
        setState(() {
          _hasDocument = true;
          _existingDocumentId = uploaded.id;
          _documentUrl = (uploaded.fileUrl != null && uploaded.fileUrl!.isNotEmpty) ? uploaded.fileUrl : filePath;
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document téléchargé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le document'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce document ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        if (_existingDocumentId != null) {
          await _documentService.deleteDocument(_existingDocumentId!);
        }
        setState(() {
          _hasDocument = false;
          _documentUrl = null;
          _existingDocumentId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document supprimé')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression: $e')),
        );
      }
    }
  }

  Future<String?> _resolveDocumentTypeId() async {
    // Tenter via les documents requis (retourne id + name)
    final req = await _documentService.getRequiredDocuments();
    if (req.isNotEmpty) {
      // Normaliser nos clés vers les noms backend
      String desiredName;
      switch (widget.documentId) {
        case 'identity':
          desiredName = 'id_card';
          break;
        case 'address_proof':
          desiredName = 'proof_of_address';
          break;
        case 'photo':
          desiredName = 'photo';
          break;
        default:
          desiredName = widget.documentId;
      }

      for (final d in req) {
        final name = (d['name'] ?? '').toString().toLowerCase();
        final display = (d['display_name'] ?? '').toString().toLowerCase();
        if (name == desiredName || display.contains(widget.documentTitle.toLowerCase())) {
          return d['id']?.toString();
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text(widget.documentTitle),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(AppSpacing.spacing4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacing3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      widget.documentIcon,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacing3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.documentTitle,
                          style: AppTypography.headline4.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacing1),
                        Text(
                          widget.documentSubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.spacing4),

            // Document existant
            if (_hasDocument)
              _buildExistingDocument()
            else
              _buildUploadOptions(),

            // Instructions
            SizedBox(height: AppSpacing.spacing6),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingDocument() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.spacing4),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            border: Border.all(color: AppColors.success),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
              SizedBox(height: AppSpacing.spacing2),
              Text(
                'Document téléchargé',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.spacing4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteDocument,
                      icon: Icon(Icons.delete_outline),
                      label: Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacing2),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.edit),
                      label: Text('Remplacer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (_documentUrl != null && _documentUrl!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.spacing3),
                Text(
                  'Aperçu: $_documentUrl',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadOptions() {
    if (_isUploading) {
      return Container(
        padding: EdgeInsets.all(AppSpacing.spacing6),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.spacing3),
              Text(
                'Upload en cours...',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Galerie
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: Icon(Icons.photo_library_outlined),
            label: Text('Choisir depuis la galerie'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1.5),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ),
        
        SizedBox(height: AppSpacing.spacing2),
        
        // Caméra
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: Icon(Icons.camera_alt_outlined),
            label: Text('Prendre une photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              elevation: 0,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.spacing2),

        // Fichier (PDF/JPG/PNG)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickFile,
            icon: Icon(Icons.attach_file),
            label: Text('Choisir un fichier'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1.5),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    final instructions = _getInstructionsForDocument(widget.documentId);
    
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
                'Instructions',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacing3),
          ...instructions.map((instruction) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.spacing2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                SizedBox(width: AppSpacing.spacing2),
                Expanded(
                  child: Text(
                    instruction,
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

  List<String> _getInstructionsForDocument(String documentId) {
    switch (documentId) {
      case 'identity':
        return [
          'Le document doit être valide et en cours de validité',
          'La photo doit être claire et complète',
          'Vérifiez que toutes les informations sont visibles',
        ];
      case 'address_proof':
        return [
          'La facture doit dater de moins de 3 mois',
          'Votre nom doit apparaître clairement',
          'Le document doit être complet et lisible',
        ];
      case 'photo':
        return [
          'Photo récente prise dans les 6 derniers mois',
          'Fond blanc ou neutre de préférence',
          'Visage clairement visible, expression neutre',
          'Photo de bonne qualité, sans flou',
        ];
      default:
        return [
          'Assurez-vous que le document est clair',
          'Vérifiez que toutes les informations sont visibles',
        ];
    }
  }
}

