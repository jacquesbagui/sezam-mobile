import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';
import 'package:sezam/core/providers/document_provider.dart';
import 'package:sezam/core/models/document_model.dart';
import 'package:sezam/features/documents/add_document_screen.dart';
import 'package:sezam/features/documents/document_detail_screen.dart';
import 'package:sezam/core/utils/navigation_helper.dart';
import 'package:sezam/core/services/app_event_service.dart';

class DocumentsScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  
  const DocumentsScreen({super.key, this.onBackToDashboard});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasLoaded = false;
  StreamSubscription<AppEventType>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    // Charger les documents seulement si nécessaire (cache invalide)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoaded) {
        _hasLoaded = true;
        final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
        // Utiliser loadIfNeeded() qui vérifie le cache automatiquement
        documentProvider.loadIfNeeded();
      }
    });
    
    // Écouter les événements de documents pour rafraîchir automatiquement
    _eventSubscription = AppEventService.instance.events.listen((event) {
      if (mounted) {
        // Rafraîchir quand un document est uploadé, validé ou rejeté
        if (event == AppEventType.documentUploaded ||
            event == AppEventType.documentVerified ||
            event == AppEventType.documentRejected) {
          print('🔄 DocumentsScreen: Événement reçu - $event, rafraîchissement de la liste...');
          
          // Attendre un peu avant de rafraîchir pour éviter les problèmes de timing
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              try {
                final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
                // Invalider le cache et forcer le rechargement
                documentProvider.invalidateCache();
                documentProvider.refresh();
                print('✅ DocumentsScreen: Liste rafraîchie');
              } catch (e) {
                print('❌ DocumentsScreen: Erreur lors du rafraîchissement: $e');
              }
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterTabs(),
          Expanded(
            child: _buildDocumentsList(),
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
        onPressed: () {
          // Retour en arrière
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else if (widget.onBackToDashboard != null) {
            // Utiliser le callback pour retourner au dashboard si on est dans la bottom nav
            widget.onBackToDashboard!();
          } else {
            // Fallback: navigation par route
            context.go('/dashboard');
          }
        },
      ),
      title: Text(
        'Mes Documents',
        style: AppTypography.headline4.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: AppSpacing.spacing4),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                NavigationHelper.slideRoute(
                  const AddDocumentScreen(),
                ),
              );
            },
            icon: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          Provider.of<DocumentProvider>(context, listen: false).updateSearch(value);
        },
        decoration: InputDecoration(
          hintText: 'Rechercher un document...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.gray500,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.gray500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing4,
            vertical: AppSpacing.spacing3,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Selector<DocumentProvider, List<String>>(
      selector: (_, provider) => ['Tous', ...provider.documentTypes.where((f) => f != 'Tous')],
      builder: (context, filters, child) {
        final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
        
        return Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = documentProvider.selectedFilter == filter;
              
              return RepaintBoundary(
                child: Container(
                margin: const EdgeInsets.only(right: AppSpacing.spacing2),
                child: FilterChip(
                  label: Text(
                    filter,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.gray600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    documentProvider.setFilter(filter);
                  },
                  backgroundColor: AppColors.gray100,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
            );
            },
          ),
        );
      },
    );
  }

  Widget _buildDocumentsList() {
    return Selector<DocumentProvider, Map<String, dynamic>>(
      selector: (_, provider) => {
        'isLoading': provider.isLoading,
        'errorMessage': provider.errorMessage,
        'documentsCount': provider.documents.length,
        'searchQuery': provider.searchQuery,
        'selectedFilter': provider.selectedFilter,
      },
      builder: (context, state, child) {
        final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
        
        if (state['isLoading'] as bool) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.spacing8),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state['errorMessage'] != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(
                    state['errorMessage'] as String,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (documentProvider.documents.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(
                    'Aucun document',
                    style: AppTypography.headline4.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing2),
                  Text(
                    'Commencez par ajouter vos documents',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.spacing4),
          itemCount: documentProvider.documents.length,
          itemBuilder: (context, index) {
            final document = documentProvider.documents[index];
            return RepaintBoundary(
              child: _buildDocumentCard(document),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing1),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            NavigationHelper.slideRoute(
              DocumentDetailScreen(document: document),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing4),
          child: Row(
            children: [
              // Icône du document
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getDocumentColor(document.displayName).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  _getDocumentIcon(document.displayName),
                  color: _getDocumentColor(document.displayName),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing4),
              
              // Informations du document
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.displayName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      softWrap: true,
                    ),
                    if (document.documentNumber != null && document.documentNumber!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.spacing1),
                      Text(
                        document.documentNumber!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                    if (document.expiryDate != null) ...[
                      const SizedBox(height: AppSpacing.spacing1),
                      Text(
                        'Expire le ${_formatDate(document.expiryDate!)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ] else if (document.issueDate != null) ...[
                      const SizedBox(height: AppSpacing.spacing1),
                      Text(
                        'Émis le ${_formatDate(document.issueDate!)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Badge de statut
              _buildStatusBadge(document.statusName),
              
              const SizedBox(width: AppSpacing.spacing2),
              
              // Icône de navigation
              Icon(
                Icons.chevron_right,
                color: AppColors.gray400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case 'verified':
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        icon = Icons.check_circle;
        text = 'Vérifié';
        break;
      case 'rejected':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        icon = Icons.error;
        text = 'Rejeté';
        break;
      default:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        icon = Icons.access_time;
        text = 'En attente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing2,
        vertical: AppSpacing.spacing1,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: AppSpacing.spacing1),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String displayName) {
    final lowerName = displayName.toLowerCase();
    if (lowerName.contains('identité') || lowerName.contains('cni')) {
      return Icons.credit_card;
    } else if (lowerName.contains('passeport')) {
      return Icons.description;
    } else if (lowerName.contains('permis')) {
      return Icons.drive_eta;
    } else {
      return Icons.description_outlined;
    }
  }

  Color _getDocumentColor(String displayName) {
    final lowerName = displayName.toLowerCase();
    if (lowerName.contains('identité') || lowerName.contains('cni')) {
      return const Color(0xFF4CAF50);
    } else if (lowerName.contains('passeport')) {
      return const Color(0xFF2196F3);
    } else if (lowerName.contains('permis')) {
      return const Color(0xFFFF9800);
    } else {
      return AppColors.gray600;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
