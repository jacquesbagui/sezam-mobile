import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/document_service.dart';
import '../../core/models/document_model.dart';
import '../../core/services/app_event_service.dart';
import '../../core/services/reference_service.dart';
import '../../core/widgets/sezam_text_field.dart';
import '../../core/widgets/sezam_card.dart';

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
  final ReferenceService _referenceService = ReferenceService();
  
  // Form fields
  String? _selectedDocumentTypeId;
  String? _selectedSide; // 'recto' or 'verso'
  final TextEditingController _documentNumberController = TextEditingController();
  DateTime? _issueDate;
  DateTime? _expiryDate;
  String? _selectedIssuingCountryId;
  List<Map<String, String>> _countries = [];
  List<Map<String, dynamic>> _documentTypes = [];
  
  // Track uploaded sides for documents requiring both
  bool _rectoUploaded = false;
  bool _versoUploaded = false;
  String? _rectoDocumentId; // ID du document recto existant
  String? _versoDocumentId; // ID du document verso existant
  String? _selectedDocumentTypeSidesRequired; // 'none', 'recto', 'verso', 'both'
  
  // Navigation en 2 étapes
  int _currentStep = 0; // 0 = formulaire, 1 = upload

  @override
  void initState() {
    super.initState();
    _checkExistingDocument();
    _loadDocumentTypes();
    _loadCountries();
  }
  
  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDocumentTypes() async {
    try {
      final requiredDocs = await _documentService.getRequiredDocuments();
      setState(() {
        _documentTypes = requiredDocs;
        // Si c'est un document d'identité, pré-sélectionner le premier type d'identité
        if (widget.documentId == 'identity') {
          final identityType = requiredDocs.firstWhere(
            (doc) => (doc['name'] == 'identity_card' || doc['name'] == 'passport' || doc['name'] == 'id_card'),
            orElse: () => requiredDocs.isNotEmpty ? requiredDocs.first : <String, dynamic>{},
          );
          if (identityType.isNotEmpty) {
            _selectedDocumentTypeId = identityType['id']?.toString();
            // Récupérer sides_required depuis l'API ou utiliser une valeur par défaut selon le type
            _selectedDocumentTypeSidesRequired = identityType['sides_required']?.toString();
            if (_selectedDocumentTypeSidesRequired == null || (_selectedDocumentTypeSidesRequired?.isEmpty ?? true)) {
              // Fallback: déterminer selon le nom du document
              final name = (identityType['name'] ?? '').toString();
              if (name == 'identity_card' || name == 'id_card') {
                _selectedDocumentTypeSidesRequired = 'both'; // CNI nécessite recto et verso
              } else if (name == 'passport') {
                _selectedDocumentTypeSidesRequired = 'none'; // Passeport = une seule face
              } else {
                _selectedDocumentTypeSidesRequired = 'none';
              }
            }
            // Si le document nécessite les deux côtés, commencer par recto
            if (_selectedDocumentTypeSidesRequired == 'both') {
              _selectedSide = 'recto';
            }
          }
        } else if (widget.documentTypeId != null) {
          _selectedDocumentTypeId = widget.documentTypeId;
        }
      });
    } catch (e) {
      print('Erreur chargement types: $e');
    }
  }
  
  Future<void> _loadCountries() async {
    try {
      final countries = await _referenceService.getCountries();
      setState(() => _countries = countries);
    } catch (e) {
      print('Erreur chargement pays: $e');
    }
  }

  /// Supprimer les documents d'identité d'un type spécifique (pour éviter les doublons du même type)
  /// Permet d'avoir plusieurs types différents (CNI + Passport) mais pas plusieurs du même type
  Future<void> _deleteIdentityDocumentsOfType(String documentTypeId) async {
    try {
      final docs = await _documentService.getDocuments();
      
      // Filtrer les documents du type spécifique
      final docsToDelete = docs.where((doc) {
        final type = doc.type;
        if (type == null) return false;
        // Supprimer uniquement les documents du même type que celui sélectionné
        return type.id == documentTypeId;
      }).toList();
      
      // Supprimer tous les documents du type trouvés
      for (final doc in docsToDelete) {
        try {
          await _documentService.deleteDocument(doc.id);
        } catch (e) {
          print('Erreur suppression document ${doc.id}: $e');
          // Continuer même en cas d'erreur
        }
      }
    } catch (e) {
      print('Erreur suppression documents d\'identité du type: $e');
      // Ne pas bloquer le processus en cas d'erreur
    }
  }

  Future<void> _checkExistingDocument() async {
    try {
      final docs = await _documentService.getDocuments();
      // Tenter d'identifier par type (selon le titre ou l'id transverse)
      DocumentModel? match;
      DocumentModel? rectoDoc;
      DocumentModel? versoDoc;
      
      // Utiliser le type sélectionné si disponible, sinon utiliser widget.documentTypeId
      final targetTypeId = _selectedDocumentTypeId ?? widget.documentTypeId;
      
      for (final d in docs) {
        final type = d.type;
        final name = (type != null ? (type.name.toLowerCase()) : '');
        final docTypeId = type?.id;
        
        // Vérifier si c'est le bon type de document
        if (targetTypeId != null && docTypeId == targetTypeId) {
          // Si le document a un côté, le stocker séparément
          if (d.side == 'recto') {
            rectoDoc = d;
          } else if (d.side == 'verso') {
            versoDoc = d;
          } else {
            // Document sans côté (simple)
          match = d;
          }
        } else if (targetTypeId == null && (name.contains(widget.documentId) || name.contains(widget.documentTitle.toLowerCase()))) {
          // Fallback: vérifier par nom seulement si aucun type n'est sélectionné
          if (d.side == 'recto') {
            rectoDoc = d;
          } else if (d.side == 'verso') {
            versoDoc = d;
          } else {
            match = d;
        }
      }
      }
      
      if (mounted) {
        setState(() {
          // Pour les documents avec recto/verso
          if (rectoDoc != null || versoDoc != null) {
            _rectoUploaded = rectoDoc != null;
            _versoUploaded = versoDoc != null;
            _rectoDocumentId = rectoDoc?.id;
            _versoDocumentId = versoDoc?.id;
            _hasDocument = _rectoUploaded && _versoUploaded;
            _documentUrl = rectoDoc?.fileUrl ?? versoDoc?.fileUrl;
            
            // Pré-remplir le formulaire avec les informations du premier document trouvé
            final firstDoc = rectoDoc ?? versoDoc;
            if (firstDoc != null) {
              if (firstDoc.documentNumber != null && firstDoc.documentNumber!.isNotEmpty) {
                _documentNumberController.text = firstDoc.documentNumber!;
              }
              _issueDate = firstDoc.issueDate;
              _expiryDate = firstDoc.expiryDate;
              if (firstDoc.issuingCountry != null) {
                _selectedIssuingCountryId = firstDoc.issuingCountry!.id;
              }
            }
          } else if (match != null) {
            // Document simple - pré-remplir le formulaire avec les informations existantes
            _hasDocument = true;
            _existingDocumentId = match.id;
            _documentUrl = match.fileUrl;
            // Pré-remplir les champs du formulaire
            if (match.documentNumber != null && match.documentNumber!.isNotEmpty) {
              _documentNumberController.text = match.documentNumber!;
            }
            _issueDate = match.issueDate;
            _expiryDate = match.expiryDate;
            if (match.issuingCountry != null) {
              _selectedIssuingCountryId = match.issuingCountry!.id;
            }
            // Si un document existe, rester à l'étape 0 pour permettre la modification
            _currentStep = 0;
          } else {
            // Aucun document trouvé pour ce type
            _hasDocument = false;
            _existingDocumentId = null;
            _rectoDocumentId = null;
            _versoDocumentId = null;
            _rectoUploaded = false;
            _versoUploaded = false;
            _documentUrl = null;
          }
        });
      }
    } catch (e) {
      // ignore silently
    }
  }

  /// Affiche un bottom sheet natif pour choisir la source du document
  Future<void> _showImageSourceBottomSheet() async {
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppSpacing.radiusLg),
              topRight: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: AppSpacing.spacing3),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(AppSpacing.spacing4),
                  child: Column(
                    children: [
                      Text(
                        'Choisir une source',
                        style: AppTypography.headline4.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacing4),
                      
                      // Option Caméra
                      ListTile(
                        leading: Icon(Icons.camera_alt, color: AppColors.primary),
                        title: Text('Prendre une photo'),
                        subtitle: Text('Utiliser l\'appareil photo'),
                        onTap: () {
                          Navigator.pop(context);
                          _takePhoto();
                        },
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing4,
                          vertical: AppSpacing.spacing2,
                        ),
                      ),
                      
                      Divider(height: 1),
                      
                      // Option Galerie
                      ListTile(
                        leading: Icon(Icons.photo_library, color: AppColors.primary),
                        title: Text('Galerie photo'),
                        subtitle: Text('Choisir depuis la galerie'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage();
                        },
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing4,
                          vertical: AppSpacing.spacing2,
                        ),
                      ),
                      
                      Divider(height: 1),
                      
                      // Option Fichier
                      ListTile(
                        leading: Icon(Icons.insert_drive_file, color: AppColors.primary),
                        title: Text('Fichier'),
                        subtitle: Text('PDF, JPG, PNG'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickFile();
                        },
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing4,
                          vertical: AppSpacing.spacing2,
                        ),
                      ),
                      
                      SizedBox(height: AppSpacing.spacing2),
                      
                      // Bouton Annuler
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
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
      },
    );
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
      // Utiliser le type sélectionné ou résoudre depuis le widget
      final documentTypeId = _selectedDocumentTypeId ?? widget.documentTypeId ?? await _resolveDocumentTypeId();
      if (documentTypeId == null) {
        throw 'Type de document inconnu. Veuillez réessayer plus tard.';
      }

      final uploaded = await _documentService.uploadDocument(
        documentTypeId: documentTypeId,
        filePath: filePath,
        side: _selectedSide,
        documentNumber: _documentNumberController.text.trim().isNotEmpty 
            ? _documentNumberController.text.trim() 
            : null,
        issuingCountryId: _selectedIssuingCountryId,
        issueDate: _issueDate,
        expiryDate: _expiryDate,
      );
      
      // Émettre un événement pour déclencher le rafraîchissement
      AppEventService.instance.emit(AppEventType.documentUploaded);
      
      if (mounted) {
        final sidesRequired = _selectedDocumentTypeSidesRequired ?? 'none';
        
        // Si le document nécessite les deux côtés, marquer le côté uploadé
        if (sidesRequired == 'both') {
          // Vérifier si on remplace un document existant
          final wasReplacing = (_selectedSide == 'recto' && _rectoUploaded) ||
                              (_selectedSide == 'verso' && _versoUploaded);
          
          if (_selectedSide == 'recto') {
            setState(() {
              _rectoUploaded = true;
              _rectoDocumentId = uploaded.id;
            });
          } else if (_selectedSide == 'verso') {
            setState(() {
              _versoUploaded = true;
              _versoDocumentId = uploaded.id;
            });
          }
          
          // Recharger les documents pour mettre à jour l'état
          await _checkExistingDocument();
          
          // Si les deux côtés sont uploadés, le document est complet
          if (_rectoUploaded && _versoUploaded) {
            setState(() {
              // Revenir à l'étape 0 pour afficher les informations
              _currentStep = 0;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  wasReplacing
                      ? 'Document mis à jour ! Recto et verso sont complets'
                      : 'Document complet ! Recto et verso téléchargés avec succès'
                ),
                backgroundColor: AppColors.success,
              ),
            );
          } else {
            // Message selon le côté uploadé/remplacé
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  wasReplacing
                      ? '${_selectedSide == 'recto' ? 'Recto' : 'Verso'} remplacé avec succès !'
                      : (_rectoUploaded 
                          ? 'Recto uploadé ! Veuillez maintenant uploader le verso'
                          : 'Verso uploadé ! Veuillez maintenant uploader le recto')
                ),
                backgroundColor: AppColors.primary,
              ),
            );
            
            // Réinitialiser le sélecteur de côté pour uploader l'autre côté (si pas déjà uploadé)
            if (!wasReplacing) {
              setState(() {
                _selectedSide = _rectoUploaded ? 'verso' : 'recto';
              });
            }
          }
        } else {
          // Document simple (une seule face)
        setState(() {
          _hasDocument = true;
          _existingDocumentId = uploaded.id;
          _documentUrl = (uploaded.fileUrl != null && uploaded.fileUrl!.isNotEmpty) ? uploaded.fileUrl : filePath;
            // Revenir à l'étape 0 pour afficher les informations
            _currentStep = 0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document téléchargé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        }
        
        // Recharger les documents pour mettre à jour l'état
        await _checkExistingDocument();
        
        setState(() => _isUploading = false);
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

            // Formulaire pour documents d'identité - Processus en 2 étapes
            if (widget.documentId == 'identity') ...[
              // Indicateur d'étapes
              _buildStepIndicator(),
              SizedBox(height: AppSpacing.spacing4),
              
              // Étape 1 : Formulaire d'informations OU Étape 2 : Upload
              if (_currentStep == 0)
                _buildIdentityDocumentForm()
              else
                _buildUploadStep(),
            ],

            // Document existant ou options d'upload (pas pour documents d'identité car le bouton est dans le formulaire)
            if (widget.documentId != 'identity') ...[
              if (_hasDocument && _selectedDocumentTypeSidesRequired != 'both')
              _buildExistingDocument()
              else if (!(_hasDocument && _selectedDocumentTypeSidesRequired == 'both'))
              _buildUploadOptions(),
            ],
            

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
                      onPressed: () {
                        // Passer à l'étape d'upload pour remplacer le document
                        setState(() => _currentStep = 1);
                      },
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadOptions() {
    final sidesRequired = _selectedDocumentTypeSidesRequired ?? 'none';
    
    // Ne pas afficher le bouton pour les documents d'identité (il est déjà dans _buildIdentityDocumentForm)
    final isIdentityDoc = widget.documentId == 'identity';
    
    return SezamCard(
          child: Column(
            children: [
          // Message d'aide pour documents avec recto/verso
          if (sidesRequired == 'both' && _selectedSide == null)
            Container(
              margin: EdgeInsets.only(bottom: AppSpacing.spacing4),
              padding: EdgeInsets.all(AppSpacing.spacing3),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
      children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  SizedBox(width: AppSpacing.spacing2),
                  Expanded(
                    child: Text(
                      'Veuillez sélectionner le côté à uploader (Recto ou Verso)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
              ),
            ),
          ),
                ],
        ),
            ),
        
          // Bouton unique pour ouvrir le bottom sheet en bas de la card (sauf pour documents d'identité)
          if (!isIdentityDoc)
            _buildAddDocumentButton(),
        ],
            ),
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
  
  Widget _buildIdentityDocumentForm() {
    // Filtrer les types d'identité
    final identityTypes = _documentTypes.where((doc) {
      final name = (doc['name'] ?? '').toString();
      return name == 'identity_card' || name == 'passport' || name == 'id_card';
    }).toList();
    
    return SezamCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations du document',
            style: AppTypography.headline4.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacing4),
          
          // Type de document
          if (identityTypes.isNotEmpty) ...[
            Text(
              'Type de pièce d\'identité',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.spacing2),
            DropdownButtonFormField<String>(
              value: _selectedDocumentTypeId,
              decoration: InputDecoration(
                hintText: 'Sélectionnez le type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              items: identityTypes.map((doc) {
                final id = doc['id']?.toString() ?? '';
                final displayName = doc['display_name']?.toString() ?? doc['name']?.toString() ?? '';
                return DropdownMenuItem(
                  value: id,
                  child: Text(displayName),
                );
              }).toList(),
              onChanged: (value) async {
                // Si un type était déjà sélectionné et qu'on change vers un AUTRE type,
                // supprimer uniquement les documents du type qu'on quitte (pour éviter les doublons du même type)
                // Mais permettre d'avoir plusieurs types différents (CNI + Passport)
                if (_selectedDocumentTypeId != null && _selectedDocumentTypeId != value) {
                  // Supprimer uniquement les documents du type qu'on quitte
                  await _deleteIdentityDocumentsOfType(_selectedDocumentTypeId!);
                  
                  // Émettre un événement pour déclencher le rafraîchissement
                  AppEventService.instance.emit(AppEventType.documentUploaded);
                }
                
                // Réinitialiser TOUS les états AVANT de changer le type
                setState(() {
                  _rectoUploaded = false;
                  _versoUploaded = false;
                  _hasDocument = false;
                  _existingDocumentId = null;
                  _rectoDocumentId = null;
                  _versoDocumentId = null;
                  _documentUrl = null;
                  _selectedSide = null;
                });
                
                // Maintenant changer le type et récupérer les infos
                setState(() {
                  _selectedDocumentTypeId = value;
                  // Récupérer les informations du type sélectionné
                  final selectedType = identityTypes.firstWhere(
                    (doc) => doc['id']?.toString() == value,
                    orElse: () => <String, dynamic>{},
                  );
                  // Récupérer sides_required depuis l'API ou utiliser une valeur par défaut
                  _selectedDocumentTypeSidesRequired = selectedType['sides_required']?.toString();
                  if (_selectedDocumentTypeSidesRequired == null || (_selectedDocumentTypeSidesRequired?.isEmpty ?? true)) {
                    // Fallback: déterminer selon le nom du document
                    final name = (selectedType['name'] ?? '').toString();
                    if (name == 'identity_card' || name == 'id_card') {
                      _selectedDocumentTypeSidesRequired = 'both'; // CNI nécessite recto et verso
                    } else if (name == 'passport') {
                      _selectedDocumentTypeSidesRequired = 'none'; // Passeport = une seule face
                    } else {
                      _selectedDocumentTypeSidesRequired = 'none';
                    }
                  }
                  // Si le document nécessite les deux côtés, commencer par recto
                  if (_selectedDocumentTypeSidesRequired == 'both') {
                    _selectedSide = 'recto';
                  } else if (_selectedDocumentTypeSidesRequired == 'recto') {
                    _selectedSide = 'recto';
                  } else if (_selectedDocumentTypeSidesRequired == 'verso') {
                    _selectedSide = 'verso';
                  } else {
                    _selectedSide = null;
                  }
                });
                
                // Re-vérifier les documents existants pour le nouveau type sélectionné
                await _checkExistingDocument();
              },
            ),
            SizedBox(height: AppSpacing.spacing4),
          ],
          
          // Numéro de document
          SezamTextField(
            controller: _documentNumberController,
            label: 'Numéro d\'identification',
            hint: 'Entrez le numéro du document',
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: AppSpacing.spacing4),
          
          // Date d'émission
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _issueDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _issueDate = date);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date d\'émission',
                hintText: _issueDate == null 
                    ? 'Sélectionnez la date' 
                    : '${_issueDate!.day}/${_issueDate!.month}/${_issueDate!.year}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _issueDate == null 
                    ? '' 
                    : '${_issueDate!.day}/${_issueDate!.month}/${_issueDate!.year}',
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacing4),
          
          // Date d'expiration
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _expiryDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() => _expiryDate = date);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date d\'expiration',
                hintText: _expiryDate == null 
                    ? 'Sélectionnez la date' 
                    : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _expiryDate == null 
                    ? '' 
                    : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacing4),
          
          // Pays d'émission
          if (_countries.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              value: _selectedIssuingCountryId,
              decoration: InputDecoration(
                labelText: 'Pays d\'émission',
                hintText: 'Sélectionnez le pays',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              items: _countries.map((country) {
                return DropdownMenuItem(
                  value: country['id'],
                  child: Text(country['name'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedIssuingCountryId = value);
              },
            ),
            SizedBox(height: AppSpacing.spacing4),
          ],
          
          // Bouton "Suivant" pour passer à l'étape d'upload
          SizedBox(height: AppSpacing.spacing4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canGoToNextStep() ? () {
                setState(() => _currentStep = 1);
              } : null,
              icon: Icon(Icons.arrow_forward),
              label: Text('Suivant'),
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
        ],
      ),
    );
  }
  
  Widget _buildAddDocumentButton() {
    // Vérifier si on peut uploader (côté sélectionné pour documents avec recto/verso)
    final sidesRequired = _selectedDocumentTypeSidesRequired ?? 'none';
    final canUpload = sidesRequired == 'none' || 
                      (sidesRequired == 'both' && _selectedSide != null) ||
                      (sidesRequired == 'recto' && _selectedSide == 'recto') ||
                      (sidesRequired == 'verso' && _selectedSide == 'verso');
    
    // Pour les documents d'identité, vérifier aussi que le type est sélectionné
    final isIdentityDoc = widget.documentId == 'identity';
    final isReady = !_isUploading && (!isIdentityDoc || (_selectedDocumentTypeId != null && canUpload));
    
    // Vérifier si un document existe pour le type sélectionné
    final hasDocumentForType = _selectedDocumentTypeId != null && 
                              ((sidesRequired == 'both' && _rectoUploaded && _versoUploaded) ||
                               (sidesRequired != 'both' && _hasDocument));
    
    // Pour les documents avec recto/verso, vérifier quel côté est sélectionné
    String buttonText;
    IconData buttonIcon;
    
    if (sidesRequired == 'both' && _selectedSide != null) {
      // Document avec recto/verso - adapter le texte selon le côté sélectionné
      final sideUploaded = _selectedSide == 'recto' ? _rectoUploaded : _versoUploaded;
      if (sideUploaded) {
        buttonText = 'Remplacer le ${_selectedSide == 'recto' ? 'recto' : 'verso'}';
      } else {
        buttonText = 'Ajouter le ${_selectedSide == 'recto' ? 'recto' : 'verso'}';
      }
      buttonIcon = sideUploaded ? Icons.edit : Icons.add_photo_alternate;
    } else {
      // Document simple - afficher "Remplacer" ou "Ajouter un document"
      buttonText = hasDocumentForType ? 'Remplacer' : 'Ajouter un document';
      buttonIcon = hasDocumentForType ? Icons.edit : Icons.add_photo_alternate;
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isReady ? _showImageSourceBottomSheet : null,
        icon: Icon(buttonIcon),
        label: Text(buttonText),
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
    );
  }
  
  Widget _buildStepIndicator() {
    return Row(
      children: [
        Expanded(
          child: _buildStepItem(
            step: 1,
            label: 'Informations',
            isActive: _currentStep == 0,
            isCompleted: _currentStep > 0,
          ),
        ),
        Container(
          width: 40,
          height: 2,
          color: _currentStep > 0 ? AppColors.primary : AppColors.gray300,
        ),
        Expanded(
          child: _buildStepItem(
            step: 2,
            label: 'Document',
            isActive: _currentStep == 1,
            isCompleted: false,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStepItem({
    required int step,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? AppColors.primary
                : AppColors.gray300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$step',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: AppSpacing.spacing1),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isActive || isCompleted
                ? AppColors.primary
                : AppColors.textSecondaryLight,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
  
  bool _canGoToNextStep() {
    // Vérifier que le type de document est sélectionné
    if (_selectedDocumentTypeId == null) return false;
    return true;
  }
  
  Widget _buildUploadStep() {
    final sidesRequired = _selectedDocumentTypeSidesRequired ?? 'none';
    
    return SezamCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload du document',
            style: AppTypography.headline4.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacing4),
          
          // Recto/Verso - Affichage conditionnel selon le type
          if (_selectedDocumentTypeId != null && _selectedDocumentTypeSidesRequired != null) ...[
            _buildSideSelector(),
            SizedBox(height: AppSpacing.spacing4),
          ],
          
          // Message d'aide pour documents avec recto/verso
          if (sidesRequired == 'both' && _selectedSide == null)
            Container(
              margin: EdgeInsets.only(bottom: AppSpacing.spacing4),
              padding: EdgeInsets.all(AppSpacing.spacing3),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  SizedBox(width: AppSpacing.spacing2),
                  Expanded(
                    child: Text(
                      'Veuillez sélectionner le côté à uploader (Recto ou Verso)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Bouton Ajouter un document ou card Document téléchargé
          SizedBox(height: AppSpacing.spacing4),
          // Si un document simple existe (sans recto/verso), afficher la card au lieu du bouton
          if (_hasDocument && sidesRequired != 'both' && _selectedDocumentTypeId != null)
            _buildExistingDocument()
          else
            _buildAddDocumentButton(),
          
          // Boutons Retour et Enregistrer
          SizedBox(height: AppSpacing.spacing4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _currentStep = 0);
                  },
                  icon: Icon(Icons.arrow_back),
                  label: Text('Retour'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSideSelector() {
    final sidesRequired = _selectedDocumentTypeSidesRequired ?? 'none';
    
    // Si le document ne nécessite pas de côté (ex: passeport)
    if (sidesRequired == 'none') {
      return Container(
        padding: EdgeInsets.all(AppSpacing.spacing3),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                'Ce document ne nécessite qu\'une seule photo',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Si le document nécessite recto et verso
    if (sidesRequired == 'both') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Côtés du document',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.spacing2),
          Text(
            'Ce document nécessite le recto et le verso. Commencez par uploader le recto, puis le verso.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          SizedBox(height: AppSpacing.spacing3),
          Row(
            children: [
              Expanded(
                child: _buildSideCard(
                  side: 'recto',
                  label: 'Recto',
                  icon: Icons.credit_card,
                  uploaded: _rectoUploaded,
                ),
              ),
              SizedBox(width: AppSpacing.spacing2),
              Expanded(
                child: _buildSideCard(
                  side: 'verso',
                  label: 'Verso',
                  icon: Icons.credit_card,
                  uploaded: _versoUploaded,
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    // Si le document nécessite seulement recto ou verso
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Côté du document',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.spacing2),
        Row(
          children: [
            if (sidesRequired == 'recto')
              Expanded(
                child: ChoiceChip(
                  label: Text('Recto'),
                  selected: _selectedSide == 'recto',
                  onSelected: (selected) {
                    setState(() => _selectedSide = selected ? 'recto' : null);
                  },
                ),
              ),
            if (sidesRequired == 'verso')
              Expanded(
                child: ChoiceChip(
                  label: Text('Verso'),
                  selected: _selectedSide == 'verso',
                  onSelected: (selected) {
                    setState(() => _selectedSide = selected ? 'verso' : null);
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSideCard({
    required String side,
    required String label,
    required IconData icon,
    required bool uploaded,
  }) {
    final isSelected = _selectedSide == side;
    
    return InkWell(
      onTap: () {
        setState(() => _selectedSide = side);
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacing3),
        decoration: BoxDecoration(
          color: uploaded 
              ? AppColors.success.withOpacity(0.1)
              : (isSelected 
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.white),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: uploaded 
                ? AppColors.success
                : (isSelected 
                    ? AppColors.primary
                    : AppColors.gray300),
            width: uploaded || isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Icon(
                  uploaded ? Icons.check_circle : icon,
                  color: uploaded 
                      ? AppColors.success
                      : (isSelected 
                          ? AppColors.primary
                          : AppColors.gray600),
                  size: 32,
                ),
                SizedBox(height: AppSpacing.spacing2),
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: uploaded 
                        ? AppColors.success
                        : (_selectedSide == side 
                            ? AppColors.primary
                            : AppColors.textPrimaryLight),
                  ),
                ),
                if (uploaded)
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.spacing1),
                    child: Text(
                      isSelected ? 'Remplacer' : '✓ Uploadé',
                      style: AppTypography.bodyXSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            // Indicateur de sélection en haut à droite
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
}

